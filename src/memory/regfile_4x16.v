// =====================================================================
//  regfile_4x16.v
//  4x16 register file (1W/2R).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module regfile_4x16(input clk, input we, input [1:0] waddr, input [15:0] wdata,
    input [1:0] raddr_a, input [1:0] raddr_b, output [15:0] rdata_a, output [15:0] rdata_b);
    // define clk input 255.230.80
    // define we input 255.180.80
    // define waddr input 200.120.255
    // define wdata input 80.200.255
    // define rdata_a output 120.255.160
    // define rdata_b output 120.255.160
    // 4x16 register file, 1 write / 2 read ports (64 bits).
    reg [15:0] regs [0:3];
    always @(posedge clk) if (we) regs[waddr] <= wdata;
    assign rdata_a = regs[raddr_a];
    assign rdata_b = regs[raddr_b];
endmodule


