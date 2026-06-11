// =====================================================================
//  gpu_pipelined32.v
//  32x32 RGB24 PIPELINED GPU: the scene model of gpu_vector32 pushed
//  through a 3-STAGE PIXEL PIPELINE (GEN -> EVAL -> COMPOSE), one
//  pixel in flight per stage. The per-class coverage datapaths are
//  gated by external PIPELINE SYNCHRONIZER strobes (ppln_point /
//  ppln_line / ppln_rect -- drive high for normal run), the same
//  convention as the flagship RV32IM_SYSTEM.v execution units.
//  screen_ready back-pressure stalls the WHOLE pipe (single pipe_en).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

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
    // =========================================================================
    reg        st2_v;
    reg [4:0]  st2_x, st2_y;
    reg [7:0]  st2_cov;
    reg        st2_first, st2_last;

    wire [7:0] cov_w;
    genvar g;
    generate for (g = 0; g < 8; g = g + 1) begin : COV
        // pipeline synchronizer gating: external strobe AND slot class
        wire is_pt = (a_ty[g] == 2'd0);
        wire is_ln = (a_ty[g] == 2'd1) | (a_ty[g] == 2'd2);
        wire is_rc = (a_ty[g] == 2'd3);
        wire gate  = a_en[g] & ( (is_pt & ppln_point)
                               | (is_ln & ppln_line)
                               | (is_rc & ppln_rect) );
        // operand isolation: comparator inputs forced to zero when gated off
        wire [4:0] gx = st1_x & {5{gate}};
        wire [4:0] gy = st1_y & {5{gate}};
        wire xe = (gx == a_x0[g]);
        wire ye = (gy == a_y0[g]);
        wire xr = (gx >= a_x0[g]) & (gx <= a_x1[g]);
        wire yr = (gy >= a_y0[g]) & (gy <= a_y1[g]);
        assign cov_w[g] = gate & (
              (a_ty[g] == 2'd0) ? (xe & ye)
            : (a_ty[g] == 2'd1) ? (ye & xr)
            : (a_ty[g] == 2'd2) ? (xe & yr)
            :                     (xr & yr));
    end endgenerate

    // =========================================================================
    //  STAGE 3 -- COMPOSE: painter priority + output port (handshake here)
    // =========================================================================
    wire [23:0] comp_col =
          st2_cov[7] ? a_col[7] : st2_cov[6] ? a_col[6]
        : st2_cov[5] ? a_col[5] : st2_cov[4] ? a_col[4]
        : st2_cov[3] ? a_col[3] : st2_cov[2] ? a_col[2]
        : st2_cov[1] ? a_col[1] : st2_cov[0] ? a_col[0] : 24'd0;
    wire [23:0] comp_rgb = ctl_fill ? fill_col : comp_col;

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


