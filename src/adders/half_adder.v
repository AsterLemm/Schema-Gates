// =====================================================================
//  half_adder.v
//  Half adder: sum=a^b, carry=a&b.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


