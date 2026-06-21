// =====================================================================
//  uart_baud_gen.v
//  UART baud-rate tick generator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module uart_baud_gen(input clk, input rst, input [15:0] divisor, output reg tick);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define divisor input 80.160.255
    // define tick output 120.255.160
    reg [15:0] cnt;
    always @(posedge clk) begin
        if (rst) begin cnt<=0; tick<=0; end
        else if (cnt>=divisor) begin cnt<=0; tick<=1; end
        else begin cnt<=cnt+1'b1; tick<=0; end
    end
endmodule


