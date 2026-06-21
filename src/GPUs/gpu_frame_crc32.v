// =====================================================================
//  gpu_frame_crc32.v
//  GPU COMPANION: per-frame CRC-32 signature analyzer for the pixel
//  stream - framebuffer-free rendering verification.
//
//  The GPUs never store a frame, so "did it draw the right thing?" has
//  no memory to inspect. This block computes a CRC-32 (IEEE polynomial
//  0x04C11DB7, MSB-first, init 0xFFFFFFFF) over every ACCEPTED pixel of
//  a frame and latches it at frame_done:
//
//      record per pixel = { px_x[7:0], px_y[7:0], px_rgb[23:0] }
//
//  Two equal frames give equal signatures; one different pixel anywhere
//  changes it. Use it to regression-test scenes, to prove animation is
//  actually animating (rotating scenes -> changing signatures), or as a
//  cheap "screen checksum" peripheral on the MMIO bus side of a CPU.
//
//  WIRING
//   * colour GPUs: px_valid/px_x/px_y/px_rgb straight in (px_x/px_y are
//     5-bit there - zero-extend). accept = the same condition the real
//     consumer uses (screen_ready in wait mode, 1'b1 in free flow).
//   * mono GPUs: go through gpu_row_to_pixel first and feed px_on as
//     px_rgb = {23'd0, px_on}, accept = px_ready.
//   * frame_start clears the accumulator, frame_done latches it into
//     frame_sig and pulses sig_valid; frame_index counts latched frames.
//
//  MODULAR: the unrolled CRC cascade is a drillable leaf unit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- gpu_frame_crc32_step : CRC-32 over one 40-bit pixel record ---
// IEEE polynomial 0x04C11DB7, MSB-first, fully unrolled (the gate mass
// of this design lives here).
module gpu_frame_crc32_step(
    input  wire [31:0] c,
    input  wire [39:0] d,
    output wire [31:0] n
);
    localparam [31:0] POLY = 32'h04C11DB7;

    function [31:0] crc40;
        input [31:0] c;
        input [39:0] d;
        integer k;
        reg fb;
        begin
            crc40 = c;
            for (k = 39; k >= 0; k = k - 1) begin
                fb    = crc40[31] ^ d[k];
                crc40 = {crc40[30:0], 1'b0} ^ (fb ? POLY : 32'd0);
            end
        end
    endfunction

    assign n = crc40(c, d);
endmodule

module gpu_frame_crc32(
    input  wire        clk,
    input  wire        reset,
    // pixel stream tap
    input  wire        px_valid,
    input  wire        accept,        // handshake qualifier (e.g. screen_ready)
    input  wire [7:0]  px_x,
    input  wire [7:0]  px_y,
    input  wire [23:0] px_rgb,
    // frame boundaries (from the GPU)
    input  wire        frame_start,
    input  wire        frame_done,
    // results
    output reg  [31:0] frame_sig,
    output reg         sig_valid,     // 1-cycle pulse when frame_sig updates
    output reg  [15:0] frame_index
);
    // define clk          input  97.160.255
    // define reset        input  36.255.145
    // define px_valid     input  68.68.242
    // define accept       input  36.200.145
    // define px_x         input  68.68.242
    // define px_y         input  68.68.242
    // define px_rgb       input  68.68.242
    // define frame_start  input  255.190.70
    // define frame_done   input  255.190.70
    // define frame_sig    output 255.140.60
    // define sig_valid    output 255.255.120
    // define frame_index  output 120.200.255

    // the unrolled CRC cascade lives in gpu_frame_crc32_step above
    reg [31:0] acc;
    wire [31:0] crc_next;
    gpu_frame_crc32_step u_step(
        .c(acc), .d({px_x, px_y, px_rgb}), .n(crc_next)
    );

    always @(posedge clk) begin
        if (reset) begin
            acc         <= 32'hFFFFFFFF;
            frame_sig   <= 32'd0;
            sig_valid   <= 1'b0;
            frame_index <= 16'd0;
        end else begin
            sig_valid <= 1'b0;
            if (frame_start) begin
                acc <= 32'hFFFFFFFF;
            end else if (px_valid && accept) begin
                acc <= crc_next;
            end
            if (frame_done) begin
                frame_sig   <= acc;
                sig_valid   <= 1'b1;
                frame_index <= frame_index + 16'd1;
            end
        end
    end
endmodule


