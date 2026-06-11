// =====================================================================
//  branch_target_adder4.v
//  4-bit branch-target adder (pc+offset).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module branch_target_adder4(input [3:0] pc, input signed [3:0] offset, output [3:0] target);
    // define pc input 80.160.255   // define offset input 80.200.255   // define target output 120.255.160
    assign target = pc + offset;
endmodule


