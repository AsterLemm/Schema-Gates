// =====================================================================
//  gpu_raster64.v
//  64x64 MONO triangle rasteriser: 4 triangle slots rendered with
//  EDGE FUNCTIONS  E(x,y) = A*x + B*y + C  (A = dy, B = -dx).
//  The Cs are seeded with multiplies ONCE per commit, then the scan
//  steps them purely incrementally (E += A per pixel, +B per row) --
//  the exact technique of the flagship GPU.v polygon path. Coverage =
//  all three edge values share a sign. Row-serial 64-bit scanout.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

//  gpu_raster64: 4 triangle slots on a 64x64 monochrome screen.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
//  REGISTER MAP (gpu_addr):
//   1  CONTROL  { continuous, wait_for_screen, scene_clear*, commit*,
//                 fill, enable }                 (* = self-clearing strobe)
//   4  SEL      { vert_ptr[5:4], slot[1:0] }
//   5  PRIMHDR  { en = bit4 }
//   7  VERT     { y[15:10], x[5:0] }   3 vertices per slot (ptr 0,1,2;
//                                       auto-increments, wraps at 3)
//   read -> STATUS { 22'd0, frame_done, busy, 2'd0, cur_y[5:0] }
//
//  RENDER MATH (flagship technique):
//    edge k of a triangle (xk,yk) -> (xn,yn):  A = yn-yk, B = -(xn-xk),
//    C = yk*xn - xk*yn.   E(x,y) = A*x + B*y + C  is seeded at (0,0) by a
//    short multiply pass at commit (S_SEED, one edge per cycle); after that
//    the whole frame uses ONLY adds:  E += A stepping x, rowE += B per row.
//    A pixel is inside when E0,E1,E2 are all >= 0 or all <= 0 (winding-
//    independent, edge-inclusive). Disabled slots are operand-isolated.
//
module gold_gpu_raster64 (
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
    output reg [5:0]   mono_y,
    output reg [63:0]  mono_s0
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
    // define mono_s0      output 255.255.255

    // ---- CONTROL register (flagship bit map) ------------------------------
    reg ctl_enable, ctl_fill, ctl_wait, ctl_cont;
    assign enable = ctl_enable;
    assign fill   = ctl_fill;
    wire advance = (~ctl_wait) | screen_ready;   // free-run unless waiting

    // ---- scene store: staging + active (4 slots x 3 vertices) ---------------
    reg        s_en [0:3];    reg        a_en [0:3];
    reg [5:0]  s_vx [0:11];   reg [5:0]  a_vx [0:11];   // {slot,vert}
    reg [5:0]  s_vy [0:11];   reg [5:0]  a_vy [0:11];
    reg [1:0]  sel_slot;
    reg [1:0]  sel_vert;

    wire commit_strobe = gpu_we && (gpu_addr == 4'd1) && gpu_wdata[4];

    // ---- edge cells: 4 slots x 3 edges -----------------------------------
    //  e_A/e_B are the per-step increments; e_row is E at the start of the
    //  current row; e_cur is E at the current pixel. 16-bit signed is ample
    //  (|A|,|B| <= 63 ; |C| <= 63*63).
    reg signed [15:0] e_A   [0:11];
    reg signed [15:0] e_B   [0:11];
    reg signed [15:0] e_row [0:11];
    reg signed [15:0] e_cur [0:11];

    // ---- coverage at the current pixel (operand-isolated per slot) ---------
    //  sign test only: no arithmetic on parked slots' values is performed.
    wire [3:0] allp, alln;
    genvar g;
    generate for (g = 0; g < 4; g = g + 1) begin : SGN
        wire s0 = e_cur[g*3+0][15];   // sign bits
        wire s1 = e_cur[g*3+1][15];
        wire s2 = e_cur[g*3+2][15];
        wire z0 = (e_cur[g*3+0] == 16'sd0);
        wire z1 = (e_cur[g*3+1] == 16'sd0);
        wire z2 = (e_cur[g*3+2] == 16'sd0);
        assign allp[g] = a_en[g] & (~s0 | z0) & (~s1 | z1) & (~s2 | z2);
        assign alln[g] = a_en[g] & ( s0 | z0) & ( s1 | z1) & ( s2 | z2);
    end endgenerate
    wire covered = |(allp | alln);
    wire pix_on  = ctl_fill | covered;

    // ---- scan FSM ------------------------------------------------------------
    //  S_SEED: 12 cycles, one edge per cycle, the ONLY multiplies in the design
    //  S_PIX : step x 0..63, shifting pixels into the row register
    //  S_ROW : present the finished row, then add B to every row accumulator
    localparam S_IDLE = 3'd0, S_SEED = 3'd1, S_PIX = 3'd2,
               S_ROW = 3'd3, S_NEXT = 3'd4;
    reg [2:0] state;
    reg [3:0] seed_i;          // 0..11 edge being seeded
    reg [5:0] cur_x, cur_y;
    reg [63:0] rowbits;
    reg busy;
    integer i;

    // seeding helpers: edge seed_i belongs to slot seed_i/3, joins vertex k
    // to vertex (k+1) mod 3
    wire [1:0] sd_slot = (seed_i >= 4'd9) ? 2'd3 :
                         (seed_i >= 4'd6) ? 2'd2 :
                         (seed_i >= 4'd3) ? 2'd1 : 2'd0;
    wire [1:0] sd_k    = (seed_i >= 4'd9) ? (seed_i - 4'd9)
                       : (seed_i >= 4'd6) ? (seed_i - 4'd6)
                       : (seed_i >= 4'd3) ? (seed_i - 4'd3) : seed_i;
    wire [1:0] sd_kn   = (sd_k == 2'd2) ? 2'd0 : (sd_k + 2'd1);
    wire signed [15:0] xk = {10'd0, a_vx[{sd_slot, sd_k }]};
    wire signed [15:0] yk = {10'd0, a_vy[{sd_slot, sd_k }]};
    wire signed [15:0] xn = {10'd0, a_vx[{sd_slot, sd_kn}]};
    wire signed [15:0] yn = {10'd0, a_vy[{sd_slot, sd_kn}]};

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 2'd0; sel_vert <= 2'd0;
            state <= S_IDLE; busy <= 1'b0; seed_i <= 4'd0;
            cur_x <= 6'd0; cur_y <= 6'd0; rowbits <= 64'd0;
            mono_valid <= 1'b0; mono_y <= 6'd0; mono_s0 <= 64'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin s_en[i] <= 1'b0; a_en[i] <= 1'b0; end
            for (i = 0; i < 12; i = i + 1) begin
                s_vx[i] <= 6'd0; a_vx[i] <= 6'd0; s_vy[i] <= 6'd0; a_vy[i] <= 6'd0;
                e_A[i] <= 16'sd0; e_B[i] <= 16'sd0;
                e_row[i] <= 16'sd0; e_cur[i] <= 16'sd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) -------------------------------
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
                4'd4: begin sel_slot <= gpu_wdata[1:0]; sel_vert <= gpu_wdata[5:4]; end
                4'd5: s_en[sel_slot] <= gpu_wdata[4];
                4'd7: begin
                    s_vx[{sel_slot, sel_vert}] <= gpu_wdata[5:0];
                    s_vy[{sel_slot, sel_vert}] <= gpu_wdata[15:10];
                    sel_vert <= (sel_vert == 2'd2) ? 2'd0 : (sel_vert + 2'd1);
                end
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            mono_valid  <= 1'b0;

            gpu_rdata <= {22'd0, frame_done, busy, 2'd0, cur_y};

            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 4; i = i + 1)  a_en[i] <= s_en[i];
                    for (i = 0; i < 12; i = i + 1) begin
                        a_vx[i] <= s_vx[i]; a_vy[i] <= s_vy[i];
                    end
                    busy <= 1'b1; seed_i <= 4'd0; state <= S_SEED;
                end
            end

            // ---- seed pass: the only multiplies, one edge per cycle ---------
            S_SEED: begin
                e_A  [seed_i] <= yn - yk;                 // A =  dy
                e_B  [seed_i] <= xk - xn;                 // B = -dx
                e_row[seed_i] <= yk * xn - xk * yn;       // C = E(0,0)
                e_cur[seed_i] <= yk * xn - xk * yn;
                if (seed_i == 4'd11) begin
                    cur_x <= 6'd0; cur_y <= 6'd0; rowbits <= 64'd0;
                    state <= S_PIX;
                end else seed_i <= seed_i + 4'd1;
            end

            // ---- build one row: pure increments, one pixel per cycle --------
            S_PIX: begin
                rowbits[cur_x] <= pix_on;
                for (i = 0; i < 12; i = i + 1)
                    e_cur[i] <= e_cur[i] + e_A[i];        // E += A  (step x)
                if (cur_x == 6'd63) state <= S_ROW;
                else                cur_x <= cur_x + 6'd1;
            end

            // ---- present the row, advance y ---------------------------------
            S_ROW: if (advance && ctl_enable) begin
                mono_valid <= 1'b1;
                mono_y     <= cur_y;
                mono_s0    <= rowbits;
                if (cur_y == 6'd0) frame_start <= 1'b1;
                for (i = 0; i < 12; i = i + 1) begin
                    e_row[i] <= e_row[i] + e_B[i];        // rowE += B (step y)
                    e_cur[i] <= e_row[i] + e_B[i];
                end
                state <= S_NEXT;
            end
            S_NEXT: begin
                rowbits <= 64'd0; cur_x <= 6'd0;
                if (cur_y == 6'd63) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin
                        cur_y <= 6'd0;
                        for (i = 0; i < 12; i = i + 1) begin
                            e_row[i] <= e_row[i] - (e_B[i] <<< 6);  // rewind 64 rows
                            e_cur[i] <= e_row[i] - (e_B[i] <<< 6);
                        end
                        state <= S_PIX;
                    end else state <= S_IDLE;
                end else begin
                    cur_y <= cur_y + 6'd1;
                    state <= S_PIX;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule


