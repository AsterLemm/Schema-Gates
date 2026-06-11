// =====================================================================
//  rom_decoder_16x8.v
//  Decoder-based ROM 16x8 (BITF_DECODER directive).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rom_decoder_16x8(input [3:0] addr, output [7:0] data);
    // define addr input 80.160.255   // define data output 120.255.160
    // BITF_DECODER addr_bits=4
    // Decoder-driven ROM: one-hot address selects a hardwired word.
    wire [15:0] sel;
    assign sel[0] = (addr == 4'd0);
    assign sel[1] = (addr == 4'd1);
    assign sel[2] = (addr == 4'd2);
    assign sel[3] = (addr == 4'd3);
    assign sel[4] = (addr == 4'd4);
    assign sel[5] = (addr == 4'd5);
    assign sel[6] = (addr == 4'd6);
    assign sel[7] = (addr == 4'd7);
    assign sel[8] = (addr == 4'd8);
    assign sel[9] = (addr == 4'd9);
    assign sel[10] = (addr == 4'd10);
    assign sel[11] = (addr == 4'd11);
    assign sel[12] = (addr == 4'd12);
    assign sel[13] = (addr == 4'd13);
    assign sel[14] = (addr == 4'd14);
    assign sel[15] = (addr == 4'd15);
    reg [7:0] word [0:15];
    integer k; initial for (k=0;k<16;k=k+1) word[k]=k[7:0];
    integer j; reg [7:0] acc;
    always @(*) begin acc=8'b0; for (j=0;j<16;j=j+1) if (sel[j]) acc=word[j]; end
    assign data = acc;
endmodule


