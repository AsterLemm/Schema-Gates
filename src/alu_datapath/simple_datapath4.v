// =====================================================================
//  simple_datapath4.v
//  4-bit simple accumulator datapath (ALU + accumulator).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module simple_datapath4(input clk, input rst, input [3:0] data_in, input [3:0] alu_op, input acc_en, output [3:0] acc_out, output zero);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define data_in input 80.160.255
    // define alu_op input 200.120.255
    // define acc_out output 120.255.160
    // define zero output 255.255.255
    reg [3:0] acc;
    reg [4:0] t;
    always @(*) begin case(alu_op)
        4'h0: t={1'b0,acc}+{1'b0,data_in};
        4'h1: t={1'b0,acc}-{1'b0,data_in};
        4'h4: t={1'b0,(acc&data_in)};
        4'h5: t={1'b0,(acc|data_in)};
        4'h6: t={1'b0,(acc^data_in)};
        default: t={1'b0,data_in};
    endcase end
    always @(posedge clk) if (rst) acc<=4'b0; else if (acc_en) acc<=t[3:0];
    assign acc_out=acc; assign zero=(acc==4'b0);
endmodule


