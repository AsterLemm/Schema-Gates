// =====================================================================
//  black_cell.v
//  Prefix 'black' cell (full carry-merge operator).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module black_cell(input gk, input pk, input gj, input pj, output g, output p);
    // (g,p) o (gj,pj): g = gk | (pk & gj); p = pk & pj
    assign g = gk | (pk & gj);
    assign p = pk & pj;
endmodule


