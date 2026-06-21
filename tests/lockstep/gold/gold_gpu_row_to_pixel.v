// =====================================================================
//  gpu_row_to_pixel.v
//  GPU COMPANION: converts the row-parallel MONO screen interface of the
//  BITFries GPUs into the pixel-serial interface, with a valid/ready
//  handshake on both sides.
//
//  The family has two screen dialects: monochrome GPUs present whole
//  ROWS (mono_valid, mono_y, four 64-bit slices), colour GPUs present
//  PIXELS (px_valid, px_x, px_y). This adapter lets a mono source drive
//  any pixel-stream consumer - a serial display, a shifter chain, or
//  gpu_frame_crc32 for signature testing.
//
//      GPU (mono, wait_for_screen=1)            consumer
//        mono_valid  ---------------> in
//        mono_y/s0..s3 -------------> in        px_valid  ---> in
//        screen_ready <--- row_ready out        px_x/y/on ---> in
//                                               px_ready  <--- out
//
//  PROTOCOL
//   * row_ready is high while the adapter can take a row; wire it to the
//     GPU's screen_ready so the GPU presents exactly one row per request
//     (the GPU must be in wait_for_screen mode).
//   * On mono_valid the row is latched into a 256-bit shift register and
//     row_ready drops; the row is then emitted LSB-first as width pixels
//     (width = w_field+1, matching the GPU CONFIG), each held until the
//     consumer raises px_ready.
//   * px_on is the pixel bit; px_x counts 0..width-1; px_y echoes the
//     row's mono_y.
//
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_gpu_row_to_pixel(
    input  wire        clk,
    input  wire        reset,
    // geometry (mirror the GPU CONFIG: actual width = w_field+1, max 256)
    input  wire [7:0]  w_field,
    // row side (from a mono GPU)
    input  wire        mono_valid,
    input  wire [7:0]  mono_y,
    input  wire [63:0] mono_s0,
    input  wire [63:0] mono_s1,
    input  wire [63:0] mono_s2,
    input  wire [63:0] mono_s3,
    output wire        row_ready,     // wire to the GPU's screen_ready
    // pixel side (to the consumer)
    output reg         px_valid,
    output reg  [7:0]  px_x,
    output reg  [7:0]  px_y,
    output reg         px_on,
    input  wire        px_ready
);
    // define clk         input  97.160.255
    // define reset       input  36.255.145
    // define w_field     input  255.190.70
    // define mono_valid  input  68.68.242
    // define mono_y      input  68.68.242
    // define mono_s0     input  68.68.242
    // define mono_s1     input  68.68.242
    // define mono_s2     input  68.68.242
    // define mono_s3     input  68.68.242
    // define row_ready   output 120.200.255
    // define px_valid    output 255.140.60
    // define px_x        output 255.140.60
    // define px_y        output 255.140.60
    // define px_on       output 255.255.120
    // define px_ready    input  36.200.145

    localparam ST_IDLE  = 1'b0;     // waiting for a row
    localparam ST_SHIFT = 1'b1;     // emitting pixels

    reg         state;
    reg [255:0] row;
    reg [7:0]   xcnt;

    assign row_ready = (state == ST_IDLE) && !reset;

    always @(posedge clk) begin
        if (reset) begin
            state    <= ST_IDLE;
            row      <= 256'd0;
            xcnt     <= 8'd0;
            px_valid <= 1'b0;
            px_x     <= 8'd0;
            px_y     <= 8'd0;
            px_on    <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    px_valid <= 1'b0;
                    if (mono_valid) begin
                        row      <= {mono_s3, mono_s2, mono_s1, mono_s0};
                        px_y     <= mono_y;
                        xcnt     <= 8'd0;
                        px_x     <= 8'd0;
                        px_on    <= mono_s0[0];
                        px_valid <= 1'b1;
                        state    <= ST_SHIFT;
                    end
                end
                ST_SHIFT: begin
                    if (px_ready) begin
                        if (xcnt == w_field) begin
                            px_valid <= 1'b0;        // row finished
                            state    <= ST_IDLE;
                        end else begin
                            row   <= {1'b0, row[255:1]};
                            xcnt  <= xcnt + 8'd1;
                            px_x  <= xcnt + 8'd1;
                            px_on <= row[1];         // next bit after shift
                        end
                    end
                end
            endcase
        end
    end
endmodule


