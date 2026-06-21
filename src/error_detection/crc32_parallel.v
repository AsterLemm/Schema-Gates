// =====================================================================
//  crc32_parallel.v
//  CRC-32 parallel (whole word), poly 0x4C11DB7.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module crc32_parallel(input [31:0] data, input [31:0] crc_in, output [31:0] crc_out);
    // define data input 80.160.255
    // define crc_in input 80.200.255
    // define crc_out output 120.255.160
    // CRC-32 parallel update over 32 data bits, poly 0x4C11DB7
    integer i; reg [31:0] c; reg fb;
    always @(*) begin
        c = crc_in;
        for (i=31; i>=0; i=i-1) begin
            fb = c[31] ^ data[i];
            c = {c[30:0],1'b0} ^ (fb ? 32'h4c11db7 : 32'b0);
        end
    end
    assign crc_out = c;
endmodule


