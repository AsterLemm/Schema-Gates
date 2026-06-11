// =====================================================================
//  crc4_parallel.v
//  CRC-4 parallel (whole word), poly 0x3.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module crc4_parallel(input [3:0] data, input [3:0] crc_in, output [3:0] crc_out);
    // define data input 80.160.255   // define crc_in input 80.200.255   // define crc_out output 120.255.160
    // CRC-4 parallel update over 4 data bits, poly 0x3
    integer i; reg [3:0] c; reg fb;
    always @(*) begin
        c = crc_in;
        for (i=3; i>=0; i=i-1) begin
            fb = c[3] ^ data[i];
            c = {c[2:0],1'b0} ^ (fb ? 4'h3 : 4'b0);
        end
    end
    assign crc_out = c;
endmodule


