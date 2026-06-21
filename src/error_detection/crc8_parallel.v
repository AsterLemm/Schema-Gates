// =====================================================================
//  crc8_parallel.v
//  CRC-8 parallel (whole word), poly 0x7.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module crc8_parallel(input [7:0] data, input [7:0] crc_in, output [7:0] crc_out);
    // define data input 80.160.255
    // define crc_in input 80.200.255
    // define crc_out output 120.255.160
    // CRC-8 parallel update over 8 data bits, poly 0x7
    integer i; reg [7:0] c; reg fb;
    always @(*) begin
        c = crc_in;
        for (i=7; i>=0; i=i-1) begin
            fb = c[7] ^ data[i];
            c = {c[6:0],1'b0} ^ (fb ? 8'h7 : 8'b0);
        end
    end
    assign crc_out = c;
endmodule


