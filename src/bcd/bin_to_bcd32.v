// =====================================================================
//  bin_to_bcd32.v
//  32-bit binary -> 10-digit BCD (double-dabble).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_bcd32(input [31:0] a, output [39:0] bcd);
    // define a input 80.160.255   // define bcd output 120.255.160
    // Double-dabble (shift-and-add-3) binary to 10-digit BCD.
    integer k; reg [71:0] shift; integer d;
    always @(*) begin
        shift = 0; shift[31:0] = a;
        for (k=0; k<32; k=k+1) begin
            if (shift[35:32] >= 5) shift[35:32] = shift[35:32] + 4'd3;
            if (shift[39:36] >= 5) shift[39:36] = shift[39:36] + 4'd3;
            if (shift[43:40] >= 5) shift[43:40] = shift[43:40] + 4'd3;
            if (shift[47:44] >= 5) shift[47:44] = shift[47:44] + 4'd3;
            if (shift[51:48] >= 5) shift[51:48] = shift[51:48] + 4'd3;
            if (shift[55:52] >= 5) shift[55:52] = shift[55:52] + 4'd3;
            if (shift[59:56] >= 5) shift[59:56] = shift[59:56] + 4'd3;
            if (shift[63:60] >= 5) shift[63:60] = shift[63:60] + 4'd3;
            if (shift[67:64] >= 5) shift[67:64] = shift[67:64] + 4'd3;
            if (shift[71:68] >= 5) shift[71:68] = shift[71:68] + 4'd3;
            shift = shift << 1;
        end
    end
    assign bcd = shift[71:32];
endmodule


