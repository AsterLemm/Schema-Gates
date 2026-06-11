// =====================================================================
//  bin_to_bcd4.v
//  4-bit binary -> 2-digit BCD (double-dabble).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_bcd4(input [3:0] a, output [7:0] bcd);
    // define a input 80.160.255   // define bcd output 120.255.160
    // Double-dabble (shift-and-add-3) binary to 2-digit BCD.
    integer k; reg [11:0] shift; integer d;
    always @(*) begin
        shift = 0; shift[3:0] = a;
        for (k=0; k<4; k=k+1) begin
            if (shift[7:4] >= 5) shift[7:4] = shift[7:4] + 4'd3;
            if (shift[11:8] >= 5) shift[11:8] = shift[11:8] + 4'd3;
            shift = shift << 1;
        end
    end
    assign bcd = shift[11:4];
endmodule


