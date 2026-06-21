// =====================================================================
//  parallel_to_serial16.v
//  16-bit parallel-in to serial-out converter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module parallel_to_serial16(input clk, input rst, input load, input [15:0] din, output sout, output done);
    // define clk input 255.230.80
    // define load input 255.180.80
    // define din input 80.160.255
    // define sout output 120.255.160
    reg [15:0] sh; reg [4:0] cnt; reg active;
    always @(posedge clk) begin
        if (rst) begin active<=0; cnt<=0; end
        else if (load) begin sh<=din; cnt<=16; active<=1; end
        else if (active) begin sh<={1'b0,sh[15:1]}; cnt<=cnt-1'b1; if (cnt==5'd1) active<=0; end
    end
    assign sout = sh[0];
    assign done = (cnt==5'd0);
endmodule


