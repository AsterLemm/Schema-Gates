// =====================================================================
//  regfile_8x4.v
//  8x4 register file (1W/2R).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module regfile_8x4(input clk, input we, input [2:0] waddr, input [3:0] wdata,
    input [2:0] raddr_a, input [2:0] raddr_b, output [3:0] rdata_a, output [3:0] rdata_b);
    // define clk input 255.230.80   // define we input 255.180.80   // define waddr input 200.120.255
    // define wdata input 80.200.255   // define rdata_a output 120.255.160   // define rdata_b output 120.255.160
    // 8x4 register file, 1 write / 2 read ports (32 bits).
    reg [3:0] regs [0:7];
    always @(posedge clk) if (we) regs[waddr] <= wdata;
    assign rdata_a = regs[raddr_a];
    assign rdata_b = regs[raddr_b];
endmodule


