// =====================================================================
//  bin_to_bcd8.v
//  8-bit binary -> 3-digit BCD (double-dabble).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_bcd8(input [7:0] a, output [11:0] bcd);
    // define a input 80.160.255   // define bcd output 120.255.160
    // Double-dabble (shift-and-add-3) binary to 3-digit BCD.
    integer k; reg [19:0] shift; integer d;
    always @(*) begin
        shift = 0; shift[7:0] = a;
        for (k=0; k<8; k=k+1) begin
            if (shift[11:8] >= 5) shift[11:8] = shift[11:8] + 4'd3;
            if (shift[15:12] >= 5) shift[15:12] = shift[15:12] + 4'd3;
            if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 4'd3;
            shift = shift << 1;
        end
    end
    assign bcd = shift[19:8];
endmodule


