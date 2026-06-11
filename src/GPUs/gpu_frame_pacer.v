// =====================================================================
//  gpu_frame_pacer.v
//  GPU COMPANION: programmable scan pacer for the BITFries GPU family.
//
//  The GPUs race the beam: with CONTROL.wait_for_screen=1 the scan
//  advances one step per screen_ready assertion. This block generates
//  that heartbeat at a programmable rate, turning "slow the clock down"
//  into "dial a register", and counts completed frames as a bonus.
//
//      rate = 0      -> screen_ready held high (free flow, full speed)
//      rate = N > 0  -> one-cycle screen_ready pulse every N+1 clocks
//                       (each pulse advances the scan by one step:
//                        one ROW in mono modes, one PIXEL in colour)
//
//  Wiring:  pacer.screen_ready -> GPU.screen_ready
//           GPU.frame_start    -> pacer.frame_start
//           GPU.frame_done     -> pacer.frame_done
//
//  frame_count increments at every frame_done (wraps at 65535);
//  frame_tick is a registered one-cycle echo of frame_done, handy as a
//  "vsync" for external logic; in_frame is high between start and done.
//
//  Works with every member of the family (gpu_dot8 ... GPU): they all
//  share the same screen_ready / frame_start / frame_done contract.
//
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gpu_frame_pacer(
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] rate,          // 0 = free flow; N = pulse every N+1
    input  wire        frame_start,   // from the GPU
    input  wire        frame_done,    // from the GPU
    output reg         screen_ready,  // to the GPU
    output reg  [15:0] frame_count,
    output reg         frame_tick,    // 1-cycle echo of frame_done
    output reg         in_frame
);
    // define clk          input  97.160.255
    // define reset        input  36.255.145
    // define rate         input  255.190.70
    // define frame_start  input  68.68.242
    // define frame_done   input  68.68.242
    // define screen_ready output 120.200.255
    // define frame_count  output 255.140.60
    // define frame_tick   output 255.255.120
    // define in_frame     output 200.200.200

    reg [15:0] cnt;

    always @(posedge clk) begin
        if (reset) begin
            cnt          <= 16'd0;
            screen_ready <= 1'b0;
            frame_count  <= 16'd0;
            frame_tick   <= 1'b0;
            in_frame     <= 1'b0;
        end else begin
            // ---- heartbeat ----
            if (rate == 16'd0) begin
                screen_ready <= 1'b1;             // free flow
                cnt          <= 16'd0;
            end else if (cnt == rate) begin
                screen_ready <= 1'b1;             // one pulse ...
                cnt          <= 16'd0;
            end else begin
                screen_ready <= 1'b0;             // ... every rate+1 clocks
                cnt          <= cnt + 16'd1;
            end
            // ---- frame bookkeeping ----
            frame_tick <= frame_done;
            if (frame_done)  frame_count <= frame_count + 16'd1;
            if (frame_start) in_frame <= 1'b1;
            else if (frame_done) in_frame <= 1'b0;
        end
    end
endmodule


