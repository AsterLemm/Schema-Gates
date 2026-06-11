// =====================================================================
//  crc16_parallel.v
//  CRC-16 parallel (whole word), poly 0x1021.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module crc16_parallel(input [15:0] data, input [15:0] crc_in, output [15:0] crc_out);
    // define data input 80.160.255   // define crc_in input 80.200.255   // define crc_out output 120.255.160
    // CRC-16 parallel update over 16 data bits, poly 0x1021
    integer i; reg [15:0] c; reg fb;
    always @(*) begin
        c = crc_in;
        for (i=15; i>=0; i=i-1) begin
            fb = c[15] ^ data[i];
            c = {c[14:0],1'b0} ^ (fb ? 16'h1021 : 16'b0);
        end
    end
    assign crc_out = c;
endmodule


