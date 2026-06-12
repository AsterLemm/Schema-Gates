// =====================================================================
//  gpu_pipelined32.v
//  32x32 RGB24 PIPELINED GPU: the scene model of gpu_vector32 pushed
//  through a 3-STAGE PIXEL PIPELINE (GEN -> EVAL -> COMPOSE), one
//  pixel in flight per stage. The per-class coverage datapaths are
//  gated by external PIPELINE SYNCHRONIZER strobes (ppln_point /
//  ppln_line / ppln_rect -- drive high for normal run), the same
//  convention as the flagship RV32IM_SYSTEM.v execution units.
//  screen_ready back-pressure stalls the WHOLE pipe (single pipe_en).
//  MODULAR: 8 gated coverage leaf units + a painter colour mux.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- gpu_pipelined32_cov : one slot's coverage test, class-gated by ppln_* ---
// pipeline synchronizer gating: external strobe AND slot class. With a
// strobe low that class's comparators see all-zero inputs and emit no
// coverage; drive all three strobes high for normal operation.
module gpu_pipelined32_cov(
    input  wire [4:0] sx,
    input  wire [4:0] sy,
    input  wire       en,
    input  wire [1:0] ty,
    input  wire [4:0] x0,
    input  wire [4:0] y0,
    input  wire [4:0] x1,
    input  wire [4:0] y1,
    input  wire       ppln_point,
    input  wire       ppln_line,
    input  wire       ppln_rect,
    output wire       cov
);
    wire is_pt = (ty == 2'd0);
    wire is_ln = (ty == 2'd1) | (ty == 2'd2);
    wire is_rc = (ty == 2'd3);
    wire gate  = en & ( (is_pt & ppln_point)
                      | (is_ln & ppln_line)
                      | (is_rc & ppln_rect) );
    // operand isolation: comparator inputs forced to zero when gated off
    wire [4:0] gx = sx & {5{gate}};
    wire [4:0] gy = sy & {5{gate}};
    wire xe = (gx == x0);
    wire ye = (gy == y0);
    wire xr = (gx >= x0) & (gx <= x1);
    wire yr = (gy >= y0) & (gy <= y1);
    assign cov = gate & (
          (ty == 2'd0) ? (xe & ye)
        : (ty == 2'd1) ? (ye & xr)
        : (ty == 2'd2) ? (xe & yr)
        :                (xr & yr));
endmodule

// --- gpu_pipelined32_colmux : painter priority colour mux (STAGE 3 datapath) ---
module gpu_pipelined32_colmux(
    input  wire [7:0]  cov,
    input  wire [23:0] col0, input wire [23:0] col1,
    input  wire [23:0] col2, input wire [23:0] col3,
    input  wire [23:0] col4, input wire [23:0] col5,
    input  wire [23:0] col6, input wire [23:0] col7,
    input  wire        ctl_fill,
    input  wire [23:0] fill_col,
    output wire [23:0] comp_rgb
);
    wire [23:0] comp_col =
          cov[7] ? col7 : cov[6] ? col6
        : cov[5] ? col5 : cov[4] ? col4
        : cov[3] ? col3 : cov[2] ? col2
        : cov[1] ? col1 : cov[0] ? col0 : 24'd0;
    assign comp_rgb = ctl_fill ? fill_col : comp_col;
endmodule

//  gpu_pipelined32: 8 slots x {point | hline | vline | rect} on 32x32, RGB24,
//  rendered by a 3-stage pixel pipeline:
//
//      GEN ----------> EVAL ----------> COMPOSE
//      coordinate      8 parallel        painter priority,
//      stepper         coverage tests    colour mux, px_* port
//      (sx,sy)         (operand-         (handshake lives here;
//                       isolated)         stall freezes all stages)
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
//  REGISTER MAP (gpu_addr):
//   1  CONTROL  { continuous, wait_for_screen, scene_clear*, commit*,
//                 fill, enable }                 (* = self-clearing strobe)
//   3  FILLCOLOR { rgb24[23:0] }
//   4  SEL      { vert_ptr[4], slot[2:0] }
//   5  PRIMHDR  { en = bit4, type[1:0] = bits[1:0] }
//                type: 00 point | 01 hline | 10 vline | 11 rect
//   6  PRIMCOL  { rgb24[23:0] }
//   7  VERT     { y[14:10], x[4:0] }  vert 0 = origin, vert 1 = extent
//   read -> STATUS { 22'd0, frame_done, busy, 3'd0, st1_y[4:0] }
//
//  PIPELINE SYNCHRONIZERS: gate_class = ppln_class & slot_is_class & slot_en.
//  With a strobe low that class's comparators see all-zero inputs and emit
//  no coverage; drive all three high for normal operation.
//
module gpu_pipelined32 (
    input              clk,
    input              reset,
    input              gpu_we,
    input      [3:0]   gpu_addr,
    input      [31:0]  gpu_wdata,
    output reg [31:0]  gpu_rdata,
    // pipeline synchronizer strobes -- drive high for normal run
    input              ppln_point,
    input              ppln_line,
    input              ppln_rect,
    input              screen_ready,
    output reg         frame_start,
    output reg         frame_done,
    output             enable,
    output             fill,
    output reg         px_valid,
    output reg [4:0]   px_x,
    output reg [4:0]   px_y,
    output reg [23:0]  px_rgb
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
    // define ppln_point   input  242.24.242
    // define ppln_line    input  242.24.180
    // define ppln_rect    input  242.24.120
    // define px_valid     output 68.213.242
    // define px_x         output 24.242.97
    // define px_y         output 153.15.130
    // define px_rgb       output 255.60.60

    // ---- CONTROL register (flagship bit map) ------------------------------
    reg ctl_enable, ctl_fill, ctl_wait, ctl_cont;
    assign enable = ctl_enable;
    assign fill   = ctl_fill;
    wire advance = (~ctl_wait) | screen_ready;   // free-run unless waiting

    // ---- scene store: staging + active --------------------------------------
    reg        s_en  [0:7];   reg        a_en  [0:7];
    reg [1:0]  s_ty  [0:7];   reg [1:0]  a_ty  [0:7];
    reg [23:0] s_col [0:7];   reg [23:0] a_col [0:7];
    reg [4:0]  s_x0  [0:7];   reg [4:0]  a_x0  [0:7];
    reg [4:0]  s_y0  [0:7];   reg [4:0]  a_y0  [0:7];
    reg [4:0]  s_x1  [0:7];   reg [4:0]  a_x1  [0:7];
    reg [4:0]  s_y1  [0:7];   reg [4:0]  a_y1  [0:7];
    reg [23:0] fill_col;
    reg [2:0]  sel_slot;
    reg        sel_vert;

    wire commit_strobe = gpu_we && (gpu_addr == 4'd1) && gpu_wdata[4];

    // =========================================================================
    //  STAGE 1 -- GEN: coordinate stepper
    // =========================================================================
    reg        st1_v;
    reg [4:0]  st1_x, st1_y;
    wire       st1_last = (st1_x == 5'd31) && (st1_y == 5'd31);

    // =========================================================================
    //  STAGE 2 -- EVAL: 8 coverage tests, class datapaths gated by ppln_*
    //  (one gpu_pipelined32_cov leaf per slot, see modules above)
    // =========================================================================
    reg        st2_v;
    reg [4:0]  st2_x, st2_y;
    reg [7:0]  st2_cov;
    reg        st2_first, st2_last;

    wire [7:0] cov_w;
    gpu_pipelined32_cov u_cov0(.sx(st1_x), .sy(st1_y),
                       .en(a_en[0]), .ty(a_ty[0]),
                       .x0(a_x0[0]), .y0(a_y0[0]),
                       .x1(a_x1[0]), .y1(a_y1[0]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[0]));
    gpu_pipelined32_cov u_cov1(.sx(st1_x), .sy(st1_y),
                       .en(a_en[1]), .ty(a_ty[1]),
                       .x0(a_x0[1]), .y0(a_y0[1]),
                       .x1(a_x1[1]), .y1(a_y1[1]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[1]));
    gpu_pipelined32_cov u_cov2(.sx(st1_x), .sy(st1_y),
                       .en(a_en[2]), .ty(a_ty[2]),
                       .x0(a_x0[2]), .y0(a_y0[2]),
                       .x1(a_x1[2]), .y1(a_y1[2]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[2]));
    gpu_pipelined32_cov u_cov3(.sx(st1_x), .sy(st1_y),
                       .en(a_en[3]), .ty(a_ty[3]),
                       .x0(a_x0[3]), .y0(a_y0[3]),
                       .x1(a_x1[3]), .y1(a_y1[3]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[3]));
    gpu_pipelined32_cov u_cov4(.sx(st1_x), .sy(st1_y),
                       .en(a_en[4]), .ty(a_ty[4]),
                       .x0(a_x0[4]), .y0(a_y0[4]),
                       .x1(a_x1[4]), .y1(a_y1[4]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[4]));
    gpu_pipelined32_cov u_cov5(.sx(st1_x), .sy(st1_y),
                       .en(a_en[5]), .ty(a_ty[5]),
                       .x0(a_x0[5]), .y0(a_y0[5]),
                       .x1(a_x1[5]), .y1(a_y1[5]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[5]));
    gpu_pipelined32_cov u_cov6(.sx(st1_x), .sy(st1_y),
                       .en(a_en[6]), .ty(a_ty[6]),
                       .x0(a_x0[6]), .y0(a_y0[6]),
                       .x1(a_x1[6]), .y1(a_y1[6]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[6]));
    gpu_pipelined32_cov u_cov7(.sx(st1_x), .sy(st1_y),
                       .en(a_en[7]), .ty(a_ty[7]),
                       .x0(a_x0[7]), .y0(a_y0[7]),
                       .x1(a_x1[7]), .y1(a_y1[7]),
                       .ppln_point(ppln_point), .ppln_line(ppln_line),
                       .ppln_rect(ppln_rect), .cov(cov_w[7]));

    // =========================================================================
    //  STAGE 3 -- COMPOSE: painter priority + output port (handshake here)
    //  (the colour mux lives in gpu_pipelined32_colmux above)
    // =========================================================================
    wire [23:0] comp_rgb;
    gpu_pipelined32_colmux u_colmux(
        .cov(st2_cov),
        .col0(a_col[0]), .col1(a_col[1]), .col2(a_col[2]), .col3(a_col[3]),
        .col4(a_col[4]), .col5(a_col[5]), .col6(a_col[6]), .col7(a_col[7]),
        .ctl_fill(ctl_fill), .fill_col(fill_col),
        .comp_rgb(comp_rgb)
    );

    //  back-pressure: the output pixel may only leave when the screen is
    //  ready (or we're free-running); otherwise the WHOLE pipe freezes.
    wire pipe_en = advance | ~px_valid;  // hold ALL stages while the output
                                         // pixel sits unconsumed at the port

    reg busy;
    reg draining;          // frame fully generated, pipe emptying
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 3'd0; sel_vert <= 1'b0; fill_col <= 24'd0;
            busy <= 1'b0; draining <= 1'b0;
            st1_v <= 1'b0; st1_x <= 5'd0; st1_y <= 5'd0;
            st2_v <= 1'b0; st2_x <= 5'd0; st2_y <= 5'd0;
            st2_cov <= 8'd0; st2_first <= 1'b0; st2_last <= 1'b0;
            px_valid <= 1'b0; px_x <= 5'd0; px_y <= 5'd0; px_rgb <= 24'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 8; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_ty[i] <= 2'd0; a_ty[i] <= 2'd0;
                s_col[i] <= 24'd0; a_col[i] <= 24'd0;
                s_x0[i] <= 5'd0; a_x0[i] <= 5'd0; s_y0[i] <= 5'd0; a_y0[i] <= 5'd0;
                s_x1[i] <= 5'd0; a_x1[i] <= 5'd0; s_y1[i] <= 5'd0; a_y1[i] <= 5'd0;
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
                        for (i = 0; i < 8; i = i + 1) s_en[i] <= 1'b0;
                    end
                    // commit (bit 4) is sampled by the scan FSM below
                end
                4'd3: fill_col <= gpu_wdata[23:0];
                4'd4: begin sel_slot <= gpu_wdata[2:0]; sel_vert <= gpu_wdata[4]; end
                4'd5: begin s_en[sel_slot] <= gpu_wdata[4];
                            s_ty[sel_slot] <= gpu_wdata[1:0]; end
                4'd6: s_col[sel_slot] <= gpu_wdata[23:0];
                4'd7: begin
                    if (sel_vert == 1'b0) begin
                        s_x0[sel_slot] <= gpu_wdata[4:0];
                        s_y0[sel_slot] <= gpu_wdata[14:10];
                    end else begin
                        s_x1[sel_slot] <= gpu_wdata[4:0];
                        s_y1[sel_slot] <= gpu_wdata[14:10];
                    end
                    sel_vert <= ~sel_vert;
                end
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;

            gpu_rdata <= {22'd0, frame_done, busy, 3'd0, st1_y};

            // -------- frame launch ----------------------------------------------
            if (!busy && commit_strobe) begin
                for (i = 0; i < 8; i = i + 1) begin
                    a_en[i] <= s_en[i]; a_ty[i] <= s_ty[i]; a_col[i] <= s_col[i];
                    a_x0[i] <= s_x0[i]; a_y0[i] <= s_y0[i];
                    a_x1[i] <= s_x1[i]; a_y1[i] <= s_y1[i];
                end
                busy <= 1'b1; draining <= 1'b0;
                st1_v <= 1'b1; st1_x <= 5'd0; st1_y <= 5'd0;
                st2_v <= 1'b0; px_valid <= 1'b0;
            end else if (busy && pipe_en && ctl_enable) begin
                // ---- STAGE 3 latches STAGE 2 (output port) ----
                px_valid <= st2_v;
                px_x     <= st2_x;
                px_y     <= st2_y;
                px_rgb   <= comp_rgb;
                if (st2_v && st2_first) frame_start <= 1'b1;
                if (st2_v && st2_last) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin           // immediately rescan
                        st1_v <= 1'b1; st1_x <= 5'd0; st1_y <= 5'd0;
                        draining <= 1'b0;
                    end else begin
                        busy <= st1_v | st2_v;    // let the pipe drain
                        draining <= 1'b1;
                    end
                end
                // ---- STAGE 2 latches STAGE 1 (coverage evaluated combinationally
                //      on st1_* this cycle, registered here) ----
                st2_v     <= st1_v;
                st2_x     <= st1_x;
                st2_y     <= st1_y;
                st2_cov   <= cov_w;
                st2_first <= st1_v && (st1_x == 5'd0) && (st1_y == 5'd0);
                st2_last  <= st1_v && st1_last;
                // ---- STAGE 1 steps the coordinates ----
                if (st1_v) begin
                    if (st1_last) st1_v <= 1'b0;          // frame generated
                    else if (st1_x == 5'd31) begin
                        st1_x <= 5'd0; st1_y <= st1_y + 5'd1;
                    end else st1_x <= st1_x + 5'd1;
                end
                if (draining && !st1_v && !st2_v) begin
                    busy <= 1'b0; px_valid <= 1'b0; draining <= 1'b0;
                end
            end else if (busy && !pipe_en) begin
                // stalled: hold everything (px_valid stays asserted so the
                // screen can take the pixel when ready)
            end
        end
    end
endmodule


