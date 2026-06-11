// =====================================================================
//  regfile_riscv_8x8.v
//  8x8 RISC register file (r0 = zero).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module regfile_riscv_8x8(input clk, input we, input [2:0] waddr, input [7:0] wdata,
    input [2:0] raddr_a, input [2:0] raddr_b, output [7:0] rdata_a, output [7:0] rdata_b);
    // define clk input 255.230.80   // define we input 255.180.80
    // 8x8 register file; register 0 hardwired to zero (RISC convention).
    reg [7:0] regs [1:7];
    always @(posedge clk) if (we && waddr!=3'b0) regs[waddr] <= wdata;
    assign rdata_a = (raddr_a==3'b0) ? 8'b0 : regs[raddr_a];
    assign rdata_b = (raddr_b==3'b0) ? 8'b0 : regs[raddr_b];
endmodule


