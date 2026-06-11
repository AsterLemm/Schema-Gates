// =====================================================================
//  gpu_scene_player.v
//  GPU COMPANION: a standalone MMIO driver that programs the flagship
//  GPU with a demo scene and then ANIMATES it forever - no CPU needed.
//
//  Wire its gpu_we/gpu_addr/gpu_wdata straight to the GPU's bus inputs
//  and its frame_done input to the GPU's frame_done. On release from
//  reset it plays an embedded command sequence:
//
//    1. CONFIG    32 x 32, RGB12, orthographic
//    2. CONTROL   enable | wait_for_screen
//    3. SEL       slot 0, vertex 0
//    4. PRIMHDR   3D filled triangle (vcount=3, en, fill, is3d, polygon)
//    5. PRIMCOL   colour 0xF80 (RGB12 amber)
//    6-8. VERT    (-20,-12,0)  (20,-12,0)  (0,18,0)   [model space]
//    9. CONTROL   commit | wait | enable      -> first frame renders
//
//  then loops:  wait frame_done -> ROT { az=0, ay=angle, ax=angle>>1 }
//               -> CONTROL re-commit -> angle += step
//
//  giving a triangle tumbling about two axes, one rotation step per
//  frame. `step` is an input so the spin rate is dial-able; `angle` is
//  exported for observation. The player drives the same register map as
//  RV32IM_SYSTEM's MMIO bridge, so anything it does a CPU can also do.
//
//  Companion wiring (typical standalone demo):
//      gpu_scene_player -> GPU bus;  gpu_frame_pacer -> GPU.screen_ready
//      GPU.px_* -> gpu_frame_crc32 (signatures) or a display shifter.
//
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gpu_scene_player(
    input  wire        clk,
    input  wire        reset,
    // GPU MMIO master
    output reg         gpu_we,
    output reg  [3:0]  gpu_addr,
    output reg  [31:0] gpu_wdata,
    // GPU status
    input  wire        frame_done,
    // animation control / observation
    input  wire [7:0]  step,          // angle increment per frame (e.g. 3)
    output reg  [7:0]  angle,
    output reg         playing        // high once the scene is committed
);
    // define clk         input  97.160.255
    // define reset       input  36.255.145
    // define gpu_we      output 120.200.255
    // define gpu_addr    output 120.200.255
    // define gpu_wdata   output 120.200.255
    // define frame_done  input  68.68.242
    // define step        input  255.190.70
    // define angle       output 255.140.60
    // define playing     output 255.255.120

    // ---- the embedded command sequence (init script) -------------------
    //  10-bit signed vertex fields: -20 = 10'h3EC, -12 = 10'h3F4,
    //  20 = 10'h014, 18 = 10'h012 ; VERT packs {2'b0, z[9:0], y[9:0], x[9:0]}
    localparam [3:0]  N_INIT = 4'd9;
    reg [35:0] script;                 // {addr[3:0], wdata[31:0]}
    reg [3:0]  pcnt;
    always @(*) begin
        case (pcnt)
            4'd0: script = {4'd0, 32'h00021F1F};  // CONFIG: RGB12 32x32 ortho
            4'd1: script = {4'd1, 32'h00000009};  // CONTROL: wait | enable
            4'd2: script = {4'd4, 32'h00000000};  // SEL: slot 0, vert 0
            4'd3: script = {4'd5, 32'h0000007E};  // PRIMHDR: 3,en,fill,3d,poly
            4'd4: script = {4'd6, 32'h00000F80};  // PRIMCOL: amber (RGB12)
            4'd5: script = {4'd7, {2'b00, 10'h000, 10'h3F4, 10'h3EC}}; // V0
            4'd6: script = {4'd7, {2'b00, 10'h000, 10'h3F4, 10'h014}}; // V1
            4'd7: script = {4'd7, {2'b00, 10'h000, 10'h012, 10'h000}}; // V2
            4'd8: script = {4'd1, 32'h00000019};  // CONTROL: commit|wait|en
            default: script = 36'd0;
        endcase
    end

    // ---- player FSM ------------------------------------------------------
    localparam ST_INIT   = 2'd0;   // stream the script, one write per clock
    localparam ST_WAIT   = 2'd1;   // scene committed: wait for frame_done
    localparam ST_ROT    = 2'd2;   // write the new rotation
    localparam ST_COMMIT = 2'd3;   // strobe commit, back to waiting

    reg [1:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state    <= ST_INIT;
            pcnt     <= 4'd0;
            angle    <= 8'd0;
            playing  <= 1'b0;
            gpu_we   <= 1'b0;
            gpu_addr <= 4'd0;
            gpu_wdata<= 32'd0;
        end else begin
            gpu_we <= 1'b0;                            // default: idle bus
            case (state)
                ST_INIT: begin
                    gpu_we    <= 1'b1;
                    gpu_addr  <= script[35:32];
                    gpu_wdata <= script[31:0];
                    if (pcnt == N_INIT - 4'd1) begin
                        state   <= ST_WAIT;
                        playing <= 1'b1;
                    end else begin
                        pcnt <= pcnt + 4'd1;
                    end
                end
                ST_WAIT: if (frame_done) begin
                    angle <= angle + step;
                    state <= ST_ROT;
                end
                ST_ROT: begin
                    gpu_we    <= 1'b1;                 // ROT: ax=angle/2,
                    gpu_addr  <= 4'd2;                 //      ay=angle, az=0
                    gpu_wdata <= {8'd0, 8'd0, angle, {1'b0, angle[7:1]}};
                    state     <= ST_COMMIT;
                end
                ST_COMMIT: begin
                    gpu_we    <= 1'b1;
                    gpu_addr  <= 4'd1;
                    gpu_wdata <= 32'h00000019;         // commit | wait | en
                    state     <= ST_WAIT;
                end
            endcase
        end
    end
endmodule


