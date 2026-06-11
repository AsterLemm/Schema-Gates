// =====================================================================
//  rom_decoder_8x8.v
//  Decoder-based ROM 8x8 (BITF_DECODER directive).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rom_decoder_8x8(input [2:0] addr, output [7:0] data);
    // define addr input 80.160.255   // define data output 120.255.160
    // BITF_DECODER addr_bits=3
    // Decoder-driven ROM: one-hot address selects a hardwired word.
    wire [7:0] sel;
    assign sel[0] = (addr == 3'd0);
    assign sel[1] = (addr == 3'd1);
    assign sel[2] = (addr == 3'd2);
    assign sel[3] = (addr == 3'd3);
    assign sel[4] = (addr == 3'd4);
    assign sel[5] = (addr == 3'd5);
    assign sel[6] = (addr == 3'd6);
    assign sel[7] = (addr == 3'd7);
    reg [7:0] word [0:7];
    integer k; initial for (k=0;k<8;k=k+1) word[k]=k[7:0];
    integer j; reg [7:0] acc;
    always @(*) begin acc=8'b0; for (j=0;j<8;j=j+1) if (sel[j]) acc=word[j]; end
    assign data = acc;
endmodule


