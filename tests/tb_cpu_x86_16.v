// Golden test: 16-bit x86-flavoured CISC CPU. fib(10) via LOOP, a PUSH/POP
// round-trip across a clobber, CALL/RET, and the authentic flag quirks:
// INC preserves CF, NOT touches no flags, logic clears CF.
// Encoding: [15:12]op [11:10]r [9:8]m [7:0]imm8 ; regs AX BX CX DX = 0..3.
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg  [15:0] rom [0:255];
    wire [7:0]  ia; wire [15:0] od; wire ov, hl; wire [15:0] dd;
    cpu_x86_16 u(.clk(clk), .rst(rst), .imem_addr(ia), .imem_data(rom[ia]),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(3'd5), .dbg_data(dd), .dbg_pc());   // dbg 5 = FLAGS {V,S,Z,C}
    always #5 clk = ~clk;

    reg [15:0] outs [0:7];
    always @(posedge clk) if (ov) begin outs[n] = od; n = n + 1; end

    initial begin
        for (i = 0; i < 256; i = i + 1) rom[i] = 16'hF100;   // HLT
        // ---- fib(10) = 55 via LOOP (CX = 9 body iterations) ----
        rom[0] = 16'h1000;   // MOV AX,#0
        rom[1] = 16'h1401;   // MOV BX,#1
        rom[2] = 16'h1809;   // MOV CX,#9
        rom[3] = 16'h0C00;   // MOV DX,AX
        rom[4] = 16'h2D00;   // ADD DX,BX
        rom[5] = 16'h0100;   // MOV AX,BX
        rom[6] = 16'h0700;   // MOV BX,DX
        rom[7] = 16'hDD03;   // LOOP @3
        // ---- stack survives a clobber ----
        rom[8] = 16'hC400;   // PUSH BX
        rom[9] = 16'h18AA;   // MOV CX,#0xAA
        rom[10]= 16'hC500;   // POP BX
        // ---- CALL/RET: subroutine outputs BX ----
        rom[11]= 16'hC20E;   // CALL @14
        rom[12]= 16'hD011;   // JMP @17 (cond 0 = always)
        rom[14]= 16'h0100;   // MOV AX,BX
        rom[15]= 16'hF200;   // OUT AX            -> 55
        rom[16]= 16'hC300;   // RET
        // ---- flag quirks ----
        // CF=1 from 0xFF+... : MOV AX,#0xFF ; MOVH AX,#0xFF (AX=0xFFFF) ; ADD AX,AX -> CF=1
        rom[17]= 16'h10FF;   // MOV  AX,#0xFF
        rom[18]= 16'hE0FF;   // MOVH AX,#0xFF     AX = 0xFFFF
        rom[19]= 16'h2000;   // ADD  AX,AX        CF=1
        rom[20]= 16'h8400;   // INC  BX           (CF must SURVIVE)
        rom[21]= 16'h1100;   // MOV  AX,#0  (no flags)
        rom[22]= 16'hD313;   // JC  @19? no -> JC cond3 to @0x13... see below
        rom[22]= 16'h1402;   // MOV BX,#2
        rom[23]= 16'hD31A;   // JC  @26  (cond 3 = {0,3}) taken if CF held
        rom[24]= 16'h1400;   // MOV BX,#0   (skipped when CF survived INC)
        rom[26]= 16'hF600;   // OUT BX -> 2 if INC preserved CF
        // NOT touches no flags: CF still 1 after NOT DX
        rom[27]= 16'h8E00;   // NOT DX  (r=3? bits[11:10]=3 -> 8'hE? op8 r=3 m=2: 16'h8E00)
        rom[28]= 16'h1801;   // MOV CX,#1
        rom[29]= 16'hD320;   // JC @32 (CF must still be 1)
        rom[30]= 16'h1800;   // MOV CX,#0   (skipped)
        rom[32]= 16'hFA00;   // OUT CX            -> 1
        // logic clears CF: AND AX,AX then JNC
        rom[33]= 16'h4000;   // AND AX,AX         CF<=0
        rom[34]= 16'h1C07;   // MOV DX,#7
        rom[35]= 16'hD425;   // JNC @37 (cond 4)
        rom[36]= 16'h1C00;   // MOV DX,#0   (skipped)
        rom[37]= 16'hFE00;   // OUT DX            -> 7
        rom[38]= 16'hF100;   // HLT
        repeat (3) @(posedge clk); rst = 0;
        repeat (300) @(posedge clk);
        if (!hl)               errs = errs + 1;
        if (n   !== 4)         errs = errs + 1;
        if (outs[0] !== 16'd55) errs = errs + 1;
        if (outs[1] !== 16'd2)  errs = errs + 1;   // INC preserved CF
        if (outs[2] !== 16'd1)  errs = errs + 1;   // NOT left CF alone
        if (outs[3] !== 16'd7)  errs = errs + 1;   // AND cleared CF
        $display("cpu_x86_16 quirk suite: %0d errors", errs);
        $finish;
    end
endmodule
