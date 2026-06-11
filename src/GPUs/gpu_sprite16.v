// =====================================================================
//  gpu_sprite16.v
//  16x16 MUX-COLOUR sprite GPU: four 8x8 1-bpp sprite stamps with
//  per-sprite 4-bit colour and free (x,y) placement. Pixel-serial
//  racing-the-beam scanout with painter priority (higher slot wins).
//  Double-buffered scene store; same bus + CONTROL map as GPU.v.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

//  gpu_sprite16: 4 sprite slots (8x8 stamp, 1 bpp, 4-bit MUX colour) on 16x16.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
//  REGISTER MAP (gpu_addr):
//   1  CONTROL  { continuous, wait_for_screen, scene_clear*, commit*,
//                 fill, enable }                 (* = self-clearing strobe)
//   3  FILLCOLOR { mux[3:0] }        colour used while CONTROL.fill=1
//   4  SEL      { row_ptr[6:4], slot[1:0] }   staging target + stamp row ptr
//   5  PRIMHDR  { en = bit4 }
//   6  PRIMCOL  { mux[3:0] }        sprite colour index
//   7  VERT     { y[13:10], x[3:0] }          top-left corner of the stamp
//   9  STAMPROW { bits[7:0] }       stamp row at SEL.row_ptr (auto-increments)
//   read -> STATUS { 22'd0, frame_done, busy, px_y[3:0], px_x[3:0] }
//
//  SCANOUT: one pixel per handshake -- px_valid / px_x / px_y / px_mux.
//  Coverage per slot is OPERAND-ISOLATED: a disabled slot's position
//  subtractors see all-zero inputs and stay quiet (flagship technique).
//
module gpu_sprite16 (
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
    output reg         px_valid,
    output reg [3:0]   px_x,
    output reg [3:0]   px_y,
    output reg [3:0]   px_mux
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
    // define px_valid     output 68.213.242
    // define px_x         output 24.242.97
    // define px_y         output 153.15.130
    // define px_mux       output 255.210.120

    // ---- CONTROL register (flagship bit map) ------------------------------
    reg ctl_enable, ctl_fill, ctl_wait, ctl_cont;
    assign enable = ctl_enable;
    assign fill   = ctl_fill;
    wire advance = (~ctl_wait) | screen_ready;   // free-run unless waiting

    // ---- scene store: staging + active -------------------------------------
    reg       s_en  [0:3];   reg       a_en  [0:3];
    reg [3:0] s_x   [0:3];   reg [3:0] a_x   [0:3];
    reg [3:0] s_y   [0:3];   reg [3:0] a_y   [0:3];
    reg [3:0] s_col [0:3];   reg [3:0] a_col [0:3];
    reg [7:0] s_stamp [0:31];   // 4 slots x 8 rows  ({slot,row})
    reg [7:0] a_stamp [0:31];
    reg [3:0] fill_col;
    reg [1:0] sel_slot;
    reg [2:0] sel_row;

    wire commit_strobe = gpu_we && (gpu_addr == 4'd1) && gpu_wdata[4];

    // ---- per-slot coverage at scan position (x,y) ---------------------------
    reg [3:0] sx, sy;          // scan position

    // operand isolation: gate the position inputs of each comparator
    //   dx = sx - a_x : in-stamp when 0..7 ; same for dy
    wire [3:0] q0x = sx & {4{a_en[0]}};  wire [3:0] q0y = sy & {4{a_en[0]}};
    wire [3:0] q1x = sx & {4{a_en[1]}};  wire [3:0] q1y = sy & {4{a_en[1]}};
    wire [3:0] q2x = sx & {4{a_en[2]}};  wire [3:0] q2y = sy & {4{a_en[2]}};
    wire [3:0] q3x = sx & {4{a_en[3]}};  wire [3:0] q3y = sy & {4{a_en[3]}};

    wire [4:0] d0x = {1'b0,q0x} - {1'b0,a_x[0]};  wire [4:0] d0y = {1'b0,q0y} - {1'b0,a_y[0]};
    wire [4:0] d1x = {1'b0,q1x} - {1'b0,a_x[1]};  wire [4:0] d1y = {1'b0,q1y} - {1'b0,a_y[1]};
    wire [4:0] d2x = {1'b0,q2x} - {1'b0,a_x[2]};  wire [4:0] d2y = {1'b0,q2y} - {1'b0,a_y[2]};
    wire [4:0] d3x = {1'b0,q3x} - {1'b0,a_x[3]};  wire [4:0] d3y = {1'b0,q3y} - {1'b0,a_y[3]};

    wire in0 = a_en[0] & ~d0x[4] & (d0x[3:0] < 4'd8) & ~d0y[4] & (d0y[3:0] < 4'd8);
    wire in1 = a_en[1] & ~d1x[4] & (d1x[3:0] < 4'd8) & ~d1y[4] & (d1y[3:0] < 4'd8);
    wire in2 = a_en[2] & ~d2x[4] & (d2x[3:0] < 4'd8) & ~d2y[4] & (d2y[3:0] < 4'd8);
    wire in3 = a_en[3] & ~d3x[4] & (d3x[3:0] < 4'd8) & ~d3y[4] & (d3y[3:0] < 4'd8);

    wire c0 = in0 & a_stamp[{2'd0, d0y[2:0]}][d0x[2:0]];
    wire c1 = in1 & a_stamp[{2'd1, d1y[2:0]}][d1x[2:0]];
    wire c2 = in2 & a_stamp[{2'd2, d2y[2:0]}][d2x[2:0]];
    wire c3 = in3 & a_stamp[{2'd3, d3y[2:0]}][d3x[2:0]];

    // painter priority: highest slot wins
    wire [3:0] scene_mux = c3 ? a_col[3] : c2 ? a_col[2]
                         : c1 ? a_col[1] : c0 ? a_col[0] : 4'd0;
    wire [3:0] pix_mux   = ctl_fill ? fill_col : scene_mux;

    // ---- scan FSM ------------------------------------------------------------
    localparam S_IDLE = 2'd0, S_PIX = 2'd1, S_NEXT = 2'd2;
    reg [1:0] state;
    reg busy;
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 2'd0; sel_row <= 3'd0; fill_col <= 4'd0;
            state <= S_IDLE; busy <= 1'b0; sx <= 4'd0; sy <= 4'd0;
            px_valid <= 1'b0; px_x <= 4'd0; px_y <= 4'd0; px_mux <= 4'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_x[i] <= 4'd0; a_x[i] <= 4'd0; s_y[i] <= 4'd0; a_y[i] <= 4'd0;
                s_col[i] <= 4'd0; a_col[i] <= 4'd0;
            end
            for (i = 0; i < 32; i = i + 1) begin
                s_stamp[i] <= 8'd0; a_stamp[i] <= 8'd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) -----------------------------
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
                4'd3: fill_col <= gpu_wdata[3:0];
                4'd4: begin sel_slot <= gpu_wdata[1:0]; sel_row <= gpu_wdata[6:4]; end
                4'd5: s_en[sel_slot] <= gpu_wdata[4];
                4'd6: s_col[sel_slot] <= gpu_wdata[3:0];
                4'd7: begin s_x[sel_slot] <= gpu_wdata[3:0];
                            s_y[sel_slot] <= gpu_wdata[13:10]; end
                4'd9: begin s_stamp[{sel_slot, sel_row}] <= gpu_wdata[7:0];
                            sel_row <= sel_row + 3'd1; end   // auto-increment
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            px_valid    <= 1'b0;

            gpu_rdata <= {22'd0, frame_done, busy, sy, sx};

            // -------- the scan -------------------------------------------------
            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 4; i = i + 1) begin
                        a_en[i] <= s_en[i]; a_x[i] <= s_x[i]; a_y[i] <= s_y[i];
                        a_col[i] <= s_col[i];
                    end
                    for (i = 0; i < 32; i = i + 1) a_stamp[i] <= s_stamp[i];
                    busy <= 1'b1; sx <= 4'd0; sy <= 4'd0; state <= S_PIX;
                end
            end
            S_PIX: if (advance && ctl_enable) begin
                px_valid <= 1'b1;
                px_x <= sx; px_y <= sy; px_mux <= pix_mux;
                if (sx == 4'd0 && sy == 4'd0) frame_start <= 1'b1;
                state <= S_NEXT;
            end
            S_NEXT: begin
                if (sx == 4'd15 && sy == 4'd15) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin sx <= 4'd0; sy <= 4'd0; state <= S_PIX; end
                    else          begin state <= S_IDLE; end
                end else begin
                    if (sx == 4'd15) begin sx <= 4'd0; sy <= sy + 4'd1; end
                    else             sx <= sx + 4'd1;
                    state <= S_PIX;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule


