// Golden test: 8-bit von Neumann SAP CPU. Loads a multiply-by-repeated-
// addition program through the unified-memory port, runs it, and checks
// the OUT value and the data cell it stores. 5 x 3 = 15.
module tb;
    integer errs = 0;
    reg clk = 0, rst = 1, run = 0;
    reg prog_we = 0; reg [3:0] prog_addr; reg [7:0] prog_data;
    wire [7:0] out_data; wire out_valid, halted;
    cpu_vonneumann8 u(.clk(clk), .rst(rst), .run(run),
        .prog_we(prog_we), .prog_addr(prog_addr), .prog_data(prog_data),
        .out_data(out_data), .out_valid(out_valid), .halted(halted),
        .dbg_acc(), .dbg_pc());
    always #5 clk = ~clk;

    task load; input [3:0] a; input [7:0] d;
        begin @(posedge clk); prog_we<=1; prog_addr<=a; prog_data<=d;
              @(posedge clk); prog_we<=0; end
    endtask

    reg [7:0] got; reg seen;
    always @(posedge clk) if (out_valid) begin got <= out_data; seen <= 1; end

    initial begin
        seen = 0;
        repeat (3) @(posedge clk); rst = 0;
        // mem[13]=5 (a)  mem[14]=3 (counter)  mem[15]=sum
        // loop: LDA 15; ADD 13; STA 15; LDA 14; SUB const1@12; STA 14; JZ end; JMP loop
        load(4'd0,  8'h1F);   // LDA 15
        load(4'd1,  8'h3D);   // ADD 13
        load(4'd2,  8'h2F);   // STA 15
        load(4'd3,  8'h1E);   // LDA 14
        load(4'd4,  8'h4C);   // SUB 12
        load(4'd5,  8'h2E);   // STA 14
        load(4'd6,  8'hA8);   // JZ  8
        load(4'd7,  8'h90);   // JMP 0
        load(4'd8,  8'h1F);   // LDA 15
        load(4'd9,  8'hE0);   // OUT
        load(4'd10, 8'hF0);   // HLT
        load(4'd12, 8'd1);    // const 1
        load(4'd13, 8'd5);    // a = 5
        load(4'd14, 8'd3);    // counter = 3
        load(4'd15, 8'd0);    // sum = 0
        @(posedge clk); run <= 1;
        repeat (120) @(posedge clk);
        if (!halted)          errs = errs + 1;
        if (!seen)            errs = errs + 1;
        if (got !== 8'd15)    errs = errs + 1;
        $display("cpu_vonneumann8 multiply program: %0d errors", errs);
        $finish;
    end
endmodule
