// =====================================================================
//  piso4.v
//  4-bit parallel-in serial-out shift register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module piso4(input clk, input load, input [3:0] d, output sout);
    // define clk input 255.230.80   // define load input 255.180.80   // define d input 80.160.255   // define sout output 120.255.160
    reg [3:0] sr;
    always @(posedge clk) if (load) sr <= d; else sr <= {1'b0, sr[3:1]};
    assign sout = sr[0];
endmodule


