// =====================================================================
//  crc8_serial.v
//  CRC-8 serial (LFSR), poly 0x7.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module crc8_serial(input clk, input rst, input en, input bit_in, output [7:0] crc);
    // define clk input 255.230.80   // define rst input 255.80.80   // define en input 255.180.80
    // define bit_in input 80.160.255   // define crc output 120.255.160
    // CRC-8, polynomial 0x7
    reg [7:0] reg_crc;
    wire fb = reg_crc[7] ^ bit_in;
    always @(posedge clk) begin
        if (rst) reg_crc <= 8'b0;
        else if (en) reg_crc <= ({reg_crc[6:0],1'b0}) ^ (fb ? 8'h7 : 8'b0);
    end
    assign crc = reg_crc;
endmodule


