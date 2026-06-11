// =====================================================================
//  gpu_dot8.v
//  8x8 MONOCHROME point-plotter GPU -- the smallest member of the
//  family and the gentlest introduction to the flagship conventions:
//  MMIO scene store, double-buffered commit, racing-the-beam ROW-serial
//  scanout (no framebuffer), screen_ready handshake, frame strobes.
//  Scene: 4 point slots. Same bus + CONTROL bit map as src/GPUs/GPU.v.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

//  gpu_dot8: 4 point slots on an 8x8 monochrome screen, row-serial scanout.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
//  REGISTER MAP (gpu_addr):
//   1  CONTROL  { continuous, wait_for_screen, scene_clear*, commit*,
//                 fill, enable }                 (* = self-clearing strobe)
//   4  SEL      { slot[1:0] }                  selects the staging slot
//   5  PRIMHDR  { en = bit4 }                  enables slot SEL.slot
//   7  VERT     { y[2:0] = bits[12:10], x[2:0] = bits[2:0] }
//   read -> STATUS { 22'd0, frame_done, busy, 5'd0, cur_y[2:0] }
//
//  Writes land in a STAGING copy of the scene; CONTROL.commit* flips the
//  staging copy into the ACTIVE copy between frames (tear-free updates).
//  SCANOUT: one 8-bit row bitmap per handshake (racing the beam, no
//  framebuffer). CONTROL.fill floods every row with 8'hFF.
//
module gpu_dot8 (
    input              clk,
    input              reset,
    input              gpu_we,
    input      [3:0]   gpu_addr,
    input      [31:0]  gpu_wdata,
    output reg [31:0]  gpu_rdata,
    input              screen_ready,
    output reg         frame_start,
    output reg         frame_done,
    output             enable,
    output             fill,
    output reg         mono_valid,
    output reg [2:0]   mono_y,
    output reg [7:0]   mono_row
);

    // define clk          input  97.160.255
    // define reset        input  36.255.145
    // define gpu_we       input  97.153.69
    // define gpu_addr     input  255.190.70
    // define gpu_wdata    input  68.68.242
    // define gpu_rdata    output 120.200.255
    // define screen_ready input  153.43.43
    // define frame_start  output 133.242.24
    // define frame_done   output 120.255.180
    // define enable       output 90.255.120
    // define fill         output 255.140.60
    // define mono_valid   output 24.133.242
    // define mono_y       output 109.109.242
    // define mono_row     output 255.255.255

    // ---- CONTROL register (flagship bit map) ------------------------------
    reg ctl_enable, ctl_fill, ctl_wait, ctl_cont;
    assign enable = ctl_enable;
    assign fill   = ctl_fill;
    wire advance = (~ctl_wait) | screen_ready;   // free-run unless waiting

    // ---- scene store: staging + active (double-buffered) ------------------
    reg        s_en [0:3];     reg        a_en [0:3];
    reg [2:0]  s_x  [0:3];     reg [2:0]  a_x  [0:3];
    reg [2:0]  s_y  [0:3];     reg [2:0]  a_y  [0:3];
    reg [1:0]  sel_slot;

    wire commit_strobe = gpu_we && (gpu_addr == 4'd1) && gpu_wdata[4];

    // ---- row composer: OR of every active point on this row ---------------
    // (operand isolation: a slot's decoder only fires while its enable is
    //  high, so disabled slots contribute constant zeros)
    reg [2:0] cur_y;
    wire [7:0] hit0 = (a_en[0] && a_y[0] == cur_y) ? (8'd1 << a_x[0]) : 8'd0;
    wire [7:0] hit1 = (a_en[1] && a_y[1] == cur_y) ? (8'd1 << a_x[1]) : 8'd0;
    wire [7:0] hit2 = (a_en[2] && a_y[2] == cur_y) ? (8'd1 << a_x[2]) : 8'd0;
    wire [7:0] hit3 = (a_en[3] && a_y[3] == cur_y) ? (8'd1 << a_x[3]) : 8'd0;
    wire [7:0] row_pix = ctl_fill ? 8'hFF : (hit0 | hit1 | hit2 | hit3);

    // ---- scan FSM ----------------------------------------------------------
    localparam S_IDLE = 2'd0, S_ROW = 2'd1, S_NEXT = 2'd2;
    reg [1:0] state;
    reg busy;
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 2'd0; state <= S_IDLE; busy <= 1'b0; cur_y <= 3'd0;
            mono_valid <= 1'b0; mono_y <= 3'd0; mono_row <= 8'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_x[i] <= 3'd0; a_x[i] <= 3'd0; s_y[i] <= 3'd0; a_y[i] <= 3'd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) ---------------------------
            if (gpu_we) begin
                case (gpu_addr)
                4'd1: begin
                    ctl_enable <= gpu_wdata[0];
                    ctl_fill   <= gpu_wdata[1];
                    ctl_wait   <= gpu_wdata[3];
                    ctl_cont   <= gpu_wdata[5];
                    if (gpu_wdata[2]) begin          // scene_clear*
                        s_en[0] <= 1'b0; s_en[1] <= 1'b0;
                        s_en[2] <= 1'b0; s_en[3] <= 1'b0;
                    end
                    // commit (bit 4) is sampled by the scan FSM below
                end
                4'd4: sel_slot <= gpu_wdata[1:0];
                4'd5: s_en[sel_slot] <= gpu_wdata[4];
                4'd7: begin s_x[sel_slot] <= gpu_wdata[2:0];
                            s_y[sel_slot] <= gpu_wdata[12:10]; end
                default: ;
                endcase
            end

            // strobe / valid defaults
            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            mono_valid  <= 1'b0;

            // status read
            gpu_rdata <= {22'd0, frame_done, busy, 5'd0, cur_y};

            // -------- the scan ----------------------------------------------
            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 4; i = i + 1) begin   // staging -> active
                        a_en[i] <= s_en[i]; a_x[i] <= s_x[i]; a_y[i] <= s_y[i];
                    end
                    busy <= 1'b1; cur_y <= 3'd0; state <= S_ROW;
                end
            end
            // present one row per handshake (racing the beam)
            S_ROW: if (advance && ctl_enable) begin
                mono_valid <= 1'b1;
                mono_y     <= cur_y;
                mono_row   <= row_pix;
                if (cur_y == 3'd0) frame_start <= 1'b1;
                state <= S_NEXT;
            end
            S_NEXT: begin
                if (cur_y == 3'd7) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin cur_y <= 3'd0; state <= S_ROW; end
                    else          begin state <= S_IDLE; end
                end else begin
                    cur_y <= cur_y + 3'd1;
                    state <= S_ROW;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule


