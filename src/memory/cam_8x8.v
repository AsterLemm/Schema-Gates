// =====================================================================
//  cam_8x8.v
//  8x8 content-addressable memory (parallel match).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module cam_8x8(input clk, input we, input [2:0] waddr, input [7:0] wdata,
    input [7:0] search, output [7:0] match, output hit);
    // define clk input 255.230.80   // define search input 80.160.255   // define match output 120.255.160
    // 8-entry x 8-bit content-addressable memory.
    reg [7:0] mem [0:7];
    always @(posedge clk) if (we) mem[waddr]<=wdata;
    genvar i;
    generate for (i=0;i<8;i=i+1) begin : cmp
        assign match[i] = (mem[i]==search);
    end endgenerate
    assign hit = |match;
endmodule


