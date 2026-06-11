// Golden test: 16-bit zero-address stack CPU. DUP/ADD doubling, a 5-deep
// push burst that exercises the TOS/NOS spill RAM, STORE/LOAD round-trip,
// SWAP/OVER shuffles, and CALL/RET through the separate return stack.
// Encoding: [15:12]op [11:0]imm12.
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg  [15:0] rom [0:255];
    wire [7:0]  ia; wire [15:0] od; wire ov, hl; wire [4:0] dep;
    cpu_stack16 u(.clk(clk), .rst(rst), .imem_addr(ia), .imem_data(rom[ia]),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_tos(), .dbg_depth(dep), .dbg_pc());
    always #5 clk = ~clk;

    reg [15:0] outs [0:3];
    always @(posedge clk) if (ov) begin outs[n] = od; n = n + 1; end

    initial begin
        for (i = 0; i < 256; i = i + 1) rom[i] = 16'hF002;   // HALT
        // (1) (3+4) DUP ADD = 14
        rom[0] = 16'h0003;   // PUSHI 3
        rom[1] = 16'h0004;   // PUSHI 4
        rom[2] = 16'h3000;   // ADD          -> 7
        rom[3] = 16'h8000;   // DUP
        rom[4] = 16'h3000;   // ADD          -> 14
        rom[5] = 16'hF001;   // OUT          -> 14
        // (2) deep spill: push 1..5 (3 cells spill), collapse with 4 ADDs
        rom[6] = 16'h0001; rom[7] = 16'h0002; rom[8] = 16'h0003;
        rom[9] = 16'h0004; rom[10]= 16'h0005;
        rom[11]= 16'h3000; rom[12]= 16'h3000;
        rom[13]= 16'h3000; rom[14]= 16'h3000;
        rom[15]= 16'hF001;   // OUT          -> 15
        // (3) STORE/LOAD + SWAP + OVER + CALL/RET:
        //     9 STORE[5] ; 100 ; LOAD[5]   stack: 100 9   (tos=9)
        //     SWAP                          stack: 9 100
        //     OVER                          stack: 9 100 9
        //     CALL add-sub                  stack: 9 109
        //     OUT                           -> 109
        rom[16]= 16'h0009;   // PUSHI 9
        rom[17]= 16'h2005;   // STORE [5]
        rom[18]= 16'h0064;   // PUSHI 100
        rom[19]= 16'h1005;   // LOAD  [5]
        rom[20]= 16'hA000;   // SWAP
        rom[21]= 16'hB000;   // OVER
        rom[22]= 16'hE019;   // CALL @25
        rom[23]= 16'hF001;   // OUT          -> 109
        rom[24]= 16'hF002;   // HALT
        rom[25]= 16'h3000;   // ADD (subroutine)
        rom[26]= 16'hF000;   // RET
        repeat (3) @(posedge clk); rst = 0;
        repeat (120) @(posedge clk);
        if (!hl)                 errs = errs + 1;
        if (n   !== 3)           errs = errs + 1;
        if (outs[0] !== 16'd14)  errs = errs + 1;
        if (outs[1] !== 16'd15)  errs = errs + 1;
        if (outs[2] !== 16'd109) errs = errs + 1;
        if (dep !== 5'd1)        errs = errs + 1;   // one 9 left behind
        $display("cpu_stack16 stack suite: %0d errors", errs);
        $finish;
    end
endmodule
