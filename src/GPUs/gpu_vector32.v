// =====================================================================
//  gpu_vector32.v
//  32x32 RGB12 vector GPU: 8 primitive slots, each point / hline /
//  vline / rect with its own RGB12 colour. Pixel-serial racing-the-
//  beam scanout, painter priority (higher slot on top), double-
//  buffered scene. Same bus + CONTROL bit map as the flagship GPU.v;
//  RGB12 is nibble-expanded onto px_rgb[23:0] exactly like GPU.v.
//  MODULAR: 8 coverage leaf units + a painter colour mux unit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- gpu_vector32_cov : one slot's coverage test (point/hline/vline/rect) ---
// covered =
//   point: x==x0 && y==y0
//   hline: y==y0 && x0<=x<=x1
//   vline: x==x0 && y0<=y<=y1
//   rect : x0<=x<=x1 && y0<=y<=y1
// operand isolation on the scan coordinates: parked slots hold zeros.
module gpu_vector32_cov(
    input  wire [4:0] sx,
    input  wire [4:0] sy,
    input  wire       en,
    input  wire [1:0] ty,
    input  wire [4:0] x0,
    input  wire [4:0] y0,
    input  wire [4:0] x1,
    input  wire [4:0] y1,
    output wire       cov
);
    wire [4:0] gx = sx & {5{en}};
    wire [4:0] gy = sy & {5{en}};
    wire xe = (gx == x0);
    wire ye = (gy == y0);
    wire xr = (gx >= x0) & (gx <= x1);
    wire yr = (gy >= y0) & (gy <= y1);
    assign cov = en & (
          (ty == 2'd0) ? (xe & ye)
        : (ty == 2'd1) ? (ye & xr)
        : (ty == 2'd2) ? (xe & yr)
        :                (xr & yr));
endmodule

// --- gpu_vector32_colmux : painter priority + fill + RGB12->RGB24 expand ---
module gpu_vector32_colmux(
    input  wire [7:0]  cov,
    input  wire [11:0] col0, input wire [11:0] col1,
    input  wire [11:0] col2, input wire [11:0] col3,
    input  wire [11:0] col4, input wire [11:0] col5,
    input  wire [11:0] col6, input wire [11:0] col7,
    input  wire        ctl_fill,
    input  wire [11:0] fill_col,
    output wire [23:0] pix_rgb_w
);
    // painter priority: highest covering slot wins
    wire [11:0] scene_col =
          cov[7] ? col7 : cov[6] ? col6
        : cov[5] ? col5 : cov[4] ? col4
        : cov[3] ? col3 : cov[2] ? col2
        : cov[1] ? col1 : cov[0] ? col0 : 12'd0;
    wire [11:0] pix12 = ctl_fill ? fill_col : scene_col;
    // RGB12 -> RGB24 nibble expansion (flagship convention)
    assign pix_rgb_w = {pix12[11:8], pix12[11:8],
                        pix12[7:4],  pix12[7:4],
                        pix12[3:0],  pix12[3:0]};
endmodule

//  gpu_vector32: 8 slots x {point | hline | vline | rect} on 32x32, RGB12.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
//  REGISTER MAP (gpu_addr):
//   1  CONTROL  { continuous, wait_for_screen, scene_clear*, commit*,
//                 fill, enable }                 (* = self-clearing strobe)
//   3  FILLCOLOR { rgb12[11:0] }     colour used while CONTROL.fill=1
//   4  SEL      { vert_ptr[4], slot[2:0] }
//   5  PRIMHDR  { en = bit4, type[1:0] = bits[1:0] }
//                type: 00 point | 01 hline | 10 vline | 11 rect
//   6  PRIMCOL  { rgb12[11:0] }
//   7  VERT     { y[14:10], x[4:0] }  vert 0 = origin, vert 1 = extent
//                (auto-increments SEL.vert_ptr; extents are INCLUSIVE)
//   read -> STATUS { 22'd0, frame_done, busy, 3'd0, px_y[4:0] }
//
//  Coverage tests are OPERAND-ISOLATED per slot: every comparator input is
//  ANDed with the slot enable, so parked slots hold constant zeros.
//
module gpu_vector32 (
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
    reg [11:0] s_col [0:7];   reg [11:0] a_col [0:7];
    reg [4:0]  s_x0  [0:7];   reg [4:0]  a_x0  [0:7];
    reg [4:0]  s_y0  [0:7];   reg [4:0]  a_y0  [0:7];
    reg [4:0]  s_x1  [0:7];   reg [4:0]  a_x1  [0:7];
    reg [4:0]  s_y1  [0:7];   reg [4:0]  a_y1  [0:7];
    reg [11:0] fill_col;
    reg [2:0]  sel_slot;
    reg        sel_vert;

    wire commit_strobe = gpu_we && (gpu_addr == 4'd1) && gpu_wdata[4];

    reg [4:0] sx, sy;          // scan position

    // ---- per-slot coverage (one gpu_vector32_cov leaf per slot) ------------------
    wire [7:0] cov;
    gpu_vector32_cov u_cov0(.sx(sx), .sy(sy), .en(a_en[0]), .ty(a_ty[0]),
                       .x0(a_x0[0]), .y0(a_y0[0]),
                       .x1(a_x1[0]), .y1(a_y1[0]), .cov(cov[0]));
    gpu_vector32_cov u_cov1(.sx(sx), .sy(sy), .en(a_en[1]), .ty(a_ty[1]),
                       .x0(a_x0[1]), .y0(a_y0[1]),
                       .x1(a_x1[1]), .y1(a_y1[1]), .cov(cov[1]));
    gpu_vector32_cov u_cov2(.sx(sx), .sy(sy), .en(a_en[2]), .ty(a_ty[2]),
                       .x0(a_x0[2]), .y0(a_y0[2]),
                       .x1(a_x1[2]), .y1(a_y1[2]), .cov(cov[2]));
    gpu_vector32_cov u_cov3(.sx(sx), .sy(sy), .en(a_en[3]), .ty(a_ty[3]),
                       .x0(a_x0[3]), .y0(a_y0[3]),
                       .x1(a_x1[3]), .y1(a_y1[3]), .cov(cov[3]));
    gpu_vector32_cov u_cov4(.sx(sx), .sy(sy), .en(a_en[4]), .ty(a_ty[4]),
                       .x0(a_x0[4]), .y0(a_y0[4]),
                       .x1(a_x1[4]), .y1(a_y1[4]), .cov(cov[4]));
    gpu_vector32_cov u_cov5(.sx(sx), .sy(sy), .en(a_en[5]), .ty(a_ty[5]),
                       .x0(a_x0[5]), .y0(a_y0[5]),
                       .x1(a_x1[5]), .y1(a_y1[5]), .cov(cov[5]));
    gpu_vector32_cov u_cov6(.sx(sx), .sy(sy), .en(a_en[6]), .ty(a_ty[6]),
                       .x0(a_x0[6]), .y0(a_y0[6]),
                       .x1(a_x1[6]), .y1(a_y1[6]), .cov(cov[6]));
    gpu_vector32_cov u_cov7(.sx(sx), .sy(sy), .en(a_en[7]), .ty(a_ty[7]),
                       .x0(a_x0[7]), .y0(a_y0[7]),
                       .x1(a_x1[7]), .y1(a_y1[7]), .cov(cov[7]));

    // painter priority + fill + nibble expansion (see gpu_vector32_colmux above)
    wire [23:0] pix_rgb_w;
    gpu_vector32_colmux u_colmux(
        .cov(cov),
        .col0(a_col[0]), .col1(a_col[1]), .col2(a_col[2]), .col3(a_col[3]),
        .col4(a_col[4]), .col5(a_col[5]), .col6(a_col[6]), .col7(a_col[7]),
        .ctl_fill(ctl_fill), .fill_col(fill_col),
        .pix_rgb_w(pix_rgb_w)
    );

    // ---- scan FSM -------------------------------------------------------------
    localparam S_IDLE = 2'd0, S_PIX = 2'd1, S_NEXT = 2'd2;
    reg [1:0] state;
    reg busy;
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 3'd0; sel_vert <= 1'b0; fill_col <= 12'd0;
            state <= S_IDLE; busy <= 1'b0; sx <= 5'd0; sy <= 5'd0;
            px_valid <= 1'b0; px_x <= 5'd0; px_y <= 5'd0; px_rgb <= 24'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 8; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_ty[i] <= 2'd0; a_ty[i] <= 2'd0;
                s_col[i] <= 12'd0; a_col[i] <= 12'd0;
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
                4'd3: fill_col <= gpu_wdata[11:0];
                4'd4: begin sel_slot <= gpu_wdata[2:0]; sel_vert <= gpu_wdata[4]; end
                4'd5: begin s_en[sel_slot] <= gpu_wdata[4];
                            s_ty[sel_slot] <= gpu_wdata[1:0]; end
                4'd6: s_col[sel_slot] <= gpu_wdata[11:0];
                4'd7: begin
                    if (sel_vert == 1'b0) begin
                        s_x0[sel_slot] <= gpu_wdata[4:0];
                        s_y0[sel_slot] <= gpu_wdata[14:10];
                    end else begin
                        s_x1[sel_slot] <= gpu_wdata[4:0];
                        s_y1[sel_slot] <= gpu_wdata[14:10];
                    end
                    sel_vert <= ~sel_vert;       // auto-increment 0 -> 1 -> 0
                end
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            px_valid    <= 1'b0;

            gpu_rdata <= {22'd0, frame_done, busy, 3'd0, sy};

            // -------- the scan ----------------------------------------------------
            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        a_en[i] <= s_en[i]; a_ty[i] <= s_ty[i]; a_col[i] <= s_col[i];
                        a_x0[i] <= s_x0[i]; a_y0[i] <= s_y0[i];
                        a_x1[i] <= s_x1[i]; a_y1[i] <= s_y1[i];
                    end
                    busy <= 1'b1; sx <= 5'd0; sy <= 5'd0; state <= S_PIX;
                end
            end
            S_PIX: if (advance && ctl_enable) begin
                px_valid <= 1'b1;
                px_x <= sx; px_y <= sy; px_rgb <= pix_rgb_w;
                if (sx == 5'd0 && sy == 5'd0) frame_start <= 1'b1;
                state <= S_NEXT;
            end
            S_NEXT: begin
                if (sx == 5'd31 && sy == 5'd31) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin sx <= 5'd0; sy <= 5'd0; state <= S_PIX; end
                    else          begin state <= S_IDLE; end
                end else begin
                    if (sx == 5'd31) begin sx <= 5'd0; sy <= sy + 5'd1; end
                    else             sx <= sx + 5'd1;
                    state <= S_PIX;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule


