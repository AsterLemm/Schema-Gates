// Golden test: 32-bit RV-lite 5-stage pipeline. Exercises the hazard
// machinery specifically: EX forwarding (back-to-back dependent ALU ops),
// the load-use interlock, and branch flush (poison instructions in the
// shadow of a taken branch must not retire).
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg  [31:0] rom [0:255];
    wire [7:0]  ia; wire [31:0] od; wire ov, hl;
    cpu_riscv_pipelined32 u(.clk(clk), .rst(rst),
        .imem_addr(ia), .imem_data(rom[ia]),
        .ppln_add(1'b1), .ppln_logic(1'b1), .ppln_shift(1'b1), .ppln_cmp(1'b1),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(4'd0), .dbg_data(), .dbg_pc());
    always #5 clk = ~clk;

    reg [31:0] outs [0:7];
    always @(posedge clk) if (ov) begin outs[n] = od; n = n + 1; end

    initial begin
        for (i = 0; i < 256; i = i + 1) rom[i] = 32'hF0000000;   // HALT
        // (1) forwarding chain: x1=5; x1=x1+x1; x1=x1+x1 -> 20 (EX->EX twice)
        rom[0] = 32'h11000005;   // ADDI x1,x0,5
        rom[1] = 32'h01110000;   // ADD  x1,x1,x1
        rom[2] = 32'h01110000;   // ADD  x1,x1,x1
        rom[3] = 32'hE0100000;   // OUT  x1            -> 20
        // (2) load-use: SW x1,3(x0); LW x2,3(x0); ADD x3,x2,x2 -> 40
        rom[4] = 32'h70010003;   // SW   x1,3(x0)
        rom[5] = 32'h62000003;   // LW   x2,3(x0)
        rom[6] = 32'h03220000;   // ADD  x3,x2,x2      (needs interlock)
        rom[7] = 32'hE0300000;   // OUT  x3            -> 40
        // (3) branch shadow: BEQ x0,x0,+3 skips two poison OUTs
        rom[8] = 32'h80000003;   // BEQ  x0,x0,+3      -> pc 11
        rom[9] = 32'hE0100000;   // OUT  x1   POISON (must be flushed)
        rom[10]= 32'hE0100000;   // OUT  x1   POISON
        rom[11]= 32'h14000063;   // ADDI x4,x0,99
        rom[12]= 32'hE0400000;   // OUT  x4            -> 99
        // (4) sum loop (forward + taken-backward branch interplay)
        rom[13]= 32'h11000000;   // ADDI x1,x0,0
        rom[14]= 32'h1200000A;   // ADDI x2,x0,10
        rom[15]= 32'h01120000;   // ADD  x1,x1,x2
        rom[16]= 32'h1220FFFF;   // ADDI x2,x2,-1
        rom[17]= 32'h9020FFFE;   // BNE  x2,x0,-2
        rom[18]= 32'hE0100000;   // OUT  x1            -> 55
        rom[19]= 32'hF0000000;   // HALT
        repeat (3) @(posedge clk); rst = 0;
        repeat (300) @(posedge clk);
        if (!hl)                 errs = errs + 1;
        if (n   !== 4)           errs = errs + 1;   // poisons must NOT fire
        if (outs[0] !== 32'd20)  errs = errs + 1;
        if (outs[1] !== 32'd40)  errs = errs + 1;
        if (outs[2] !== 32'd99)  errs = errs + 1;
        if (outs[3] !== 32'd55)  errs = errs + 1;
        $display("cpu_riscv_pipelined32 hazard suite: %0d errors", errs);
        $finish;
    end
endmodule
