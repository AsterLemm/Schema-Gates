// =====================================================================
//  ascii_digit_to_bin.v
//  ASCII hex character to 4-bit nibble (+valid).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module ascii_digit_to_bin(input [7:0] ascii, output [3:0] a, output valid);
    // define ascii input 80.160.255
    // define a output 120.255.160
    // define valid output 255.255.255
    wire is_dig = (ascii >= 8'h30) && (ascii <= 8'h39);
    wire is_uc  = (ascii >= 8'h41) && (ascii <= 8'h46);
    wire is_lc  = (ascii >= 8'h61) && (ascii <= 8'h66);
    assign a = is_dig ? (ascii - 8'h30) : is_uc ? (ascii - 8'h41 + 4'd10) : is_lc ? (ascii - 8'h61 + 4'd10) : 4'd0;
    assign valid = is_dig | is_uc | is_lc;
endmodule


