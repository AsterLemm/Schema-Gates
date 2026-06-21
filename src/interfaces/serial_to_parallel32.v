// =====================================================================
//  serial_to_parallel32.v
//  32-bit serial-in to parallel-out converter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module serial_to_parallel32(input clk, input rst, input en, input sin, output reg [31:0] dout, output reg valid);
    // define clk input 255.230.80
    // define en input 255.180.80
    // define sin input 80.160.255
    // define dout output 120.255.160
    reg [5:0] cnt;
    always @(posedge clk) begin
        if (rst) begin cnt<=0; valid<=0; end
        else if (en) begin dout<={sin,dout[31:1]}; cnt<=cnt+1'b1;
            if (cnt==6'd31) begin valid<=1; cnt<=0; end else valid<=0;
        end else valid<=0;
    end
endmodule


