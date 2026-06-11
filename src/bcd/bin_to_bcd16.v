// =====================================================================
//  bin_to_bcd16.v
//  16-bit binary -> 5-digit BCD (double-dabble).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_bcd16(input [15:0] a, output [19:0] bcd);
    // define a input 80.160.255   // define bcd output 120.255.160
    // Double-dabble (shift-and-add-3) binary to 5-digit BCD.
    integer k; reg [35:0] shift; integer d;
    always @(*) begin
        shift = 0; shift[15:0] = a;
        for (k=0; k<16; k=k+1) begin
            if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 4'd3;
            if (shift[23:20] >= 5) shift[23:20] = shift[23:20] + 4'd3;
            if (shift[27:24] >= 5) shift[27:24] = shift[27:24] + 4'd3;
            if (shift[31:28] >= 5) shift[31:28] = shift[31:28] + 4'd3;
            if (shift[35:32] >= 5) shift[35:32] = shift[35:32] + 4'd3;
            shift = shift << 1;
        end
    end
    assign bcd = shift[35:16];
endmodule


