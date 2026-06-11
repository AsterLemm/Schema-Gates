// =====================================================================
//  full_adder_using_nor.v
//  Full adder using only NOR gates (verified).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module full_adder_using_nor(input a, input b, input cin, output sum, output cout);
    // axb = a^b
    wire na, nab, nb, ab, axb;
    assign na  = ~(a   | a);
    assign nab = ~(a   | b);
    assign nb  = ~(b   | b);
    assign ab  = ~(na  | nb);    // a & b
    assign axb = ~(nab | ab);    // a ^ b
    // sum = axb ^ cin
    wire nx, nxc, nc, xc, sx;
    assign nx  = ~(axb | axb);   // ~axb
    assign nxc = ~(axb | cin);
    assign nc  = ~(cin | cin);   // ~cin
    assign xc  = ~(nx  | nc);    // axb & cin
    assign sum = ~(nxc | xc);    // axb ^ cin
    // cout = (a&b) | (cin & axb) = ab | xc   (OR via double-NOR)
    wire nor_oc;
    assign nor_oc = ~(ab | xc);  // ab NOR xc
    assign cout   = ~(nor_oc | nor_oc);
endmodule


