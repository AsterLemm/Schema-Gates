// =====================================================================
//  demo_half_adder.v
//  Demo: a single half adder.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_half_adder(input a, input b, output sum, output carry);
    // define a input 80.160.255   // define b input 80.200.255   // define sum output 120.255.160   // define carry output 255.120.120
    half_adder ha(.a(a),.b(b),.sum(sum),.carry(carry));
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


