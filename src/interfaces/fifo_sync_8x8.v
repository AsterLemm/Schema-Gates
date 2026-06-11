// =====================================================================
//  fifo_sync_8x8.v
//  Synchronous FIFO, 8 deep x 8-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fifo_sync_8x8(input clk, input rst, input wr, input rd, input [7:0] din,
    output reg [7:0] dout, output empty, output full, output [3:0] count);
    // define clk input 255.230.80   // define wr input 255.180.80   // define rd input 255.180.80
    // define din input 80.160.255   // define dout output 120.255.160   // define empty output 255.255.255   // define full output 255.120.120
    reg [7:0] mem [0:7];
    reg [2:0] wptr, rptr; reg [3:0] cnt;
    assign empty = (cnt==0);
    assign full  = (cnt==8);
    assign count = cnt;
    always @(posedge clk) begin
        if (rst) begin wptr<=0; rptr<=0; cnt<=0; end
        else begin
            if (wr && !full) begin mem[wptr]<=din; wptr<=wptr+1'b1; end
            if (rd && !empty) begin dout<=mem[rptr]; rptr<=rptr+1'b1; end
            case ({wr && !full, rd && !empty})
                2'b10: cnt<=cnt+1'b1;
                2'b01: cnt<=cnt-1'b1;
                default: cnt<=cnt;
            endcase
        end
    end
endmodule


