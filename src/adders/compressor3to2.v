// =====================================================================
//  compressor3to2.v
//  3:2 compressor (full adder counting cell).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module compressor3to2(input a, input b, input c, output sum, output carry);
    assign sum   = a ^ b ^ c;
    assign carry = (a & b) | (b & c) | (a & c);
endmodule


