// FT_ALSO: CPUs/cpu_arm16.v
// Golden test: a cpu_x86_16 binary running on the cpu_arm16 HOST through
// the fetch-path interpreter: fib(10) via LOOP, PUSH/POP across a
// clobber, and CALL/RET -- RET pops the guest return address and
// rescales it into bundle space at runtime with LSL #2 + BX.
// Expected: OUT 55; host halts; full ISA coverage so trap never fires.
module tb;
    integer errs = 0, i;
    reg clk = 0, rst = 1;
    reg [15:0] grom [0:63];
    wire [7:0] ha; wire [31:0] hi_; wire [5:0] ga; wire [15:0] od;
    wire ov, hl, trp;
    interp_x86_to_arm_16 it(.host_addr(ha), .host_instr(hi_),
        .guest_addr(ga), .guest_instr(grom[ga]), .trap(trp));
    cpu_arm16 host(.clk(clk), .rst(rst), .imem_addr(ha), .imem_data(hi_),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(4'd0), .dbg_data(), .dbg_pc());
    always #5 clk = ~clk;

    reg [15:0] got; reg seen, trapped; integer n;
    always @(posedge clk) begin
        if (ov) begin got = od; seen = 1; n = n + 1; end
        if (trp) trapped = 1;
    end

    initial begin
        for (i = 0; i < 64; i = i + 1) grom[i] = 16'hF100;   // HLT
        grom[0] = 16'h1000;   // MOV AX,#0
        grom[1] = 16'h1401;   // MOV BX,#1
        grom[2] = 16'h1809;   // MOV CX,#9
        grom[3] = 16'h0C00;   // MOV DX,AX       <- loop
        grom[4] = 16'h2D00;   // ADD DX,BX
        grom[5] = 16'h0100;   // MOV AX,BX
        grom[6] = 16'h0700;   // MOV BX,DX
        grom[7] = 16'hDD03;   // LOOP @3
        grom[8] = 16'hC400;   // PUSH BX
        grom[9] = 16'h18AA;   // MOV CX,#0xAA    (clobber)
        grom[10]= 16'hC500;   // POP BX
        grom[11]= 16'hC20E;   // CALL @14
        grom[12]= 16'hF100;   // HLT
        grom[14]= 16'h0100;   // MOV AX,BX       (subroutine)
        grom[15]= 16'hF200;   // OUT AX          -> 55
        grom[16]= 16'hC300;   // RET
        seen = 0; trapped = 0; n = 0;
        repeat (4) @(posedge clk); rst = 0;
        repeat (600) @(posedge clk);
        if (!hl)             errs = errs + 1;
        if (trapped)         errs = errs + 1;
        if (n !== 1)         errs = errs + 1;
        if (got !== 16'd55)  errs = errs + 1;
        $display("interp x86-on-arm program: %0d errors", errs);
        $finish;
    end
endmodule
