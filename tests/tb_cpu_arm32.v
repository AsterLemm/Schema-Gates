// Golden test: 32-bit ARM-flavoured CPU. SUBS loop, conditional execution
// (MOVEQ/MOVNE with a poison ADDNE), BL/BX linkage, and the barrel
// shifter on operand 2 (LSL and ASR, including sign extension).
// Encoding helpers below mirror docs/cpus.md.
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg  [31:0] rom [0:255];
    wire [7:0]  ia; wire [31:0] od; wire ov, hl;
    cpu_arm32 u(.clk(clk), .rst(rst), .imem_addr(ia), .imem_data(rom[ia]),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(4'd1), .dbg_data(), .dbg_pc());
    always #5 clk = ~clk;

    // ---- tiny assembler -------------------------------------------------
    function [31:0] dpi;   // data-processing, immediate op2
        input [3:0] cond, op, rd, rn; input s; input [7:0] imm;
        dpi = {cond, s, 2'b01, op, rd, rn, imm, 5'b00000};
    endfunction
    function [31:0] dpr;   // data-processing, shifted-register op2
        input [3:0] cond, op, rd, rn, rm; input s; input [1:0] sht; input [4:0] sha;
        dpr = {cond, s, 2'b00, op, rd, rn, rm, sht, sha, 2'b00};
    endfunction
    function [31:0] flow;  // B / BL (pc-relative imm17) / HALT
        input [3:0] cond, op; input [16:0] imm;
        flow = {cond, 1'b0, 2'b11, op, 4'd0, imm[16:0]};
    endfunction
    function [31:0] flowr; // BX / OUT (register rn)
        input [3:0] cond, op, rn;
        flowr = {cond, 1'b0, 2'b11, op, 4'd0, rn, 13'd0};
    endfunction
    localparam AL=4'd14, EQ=4'd0, NE=4'd1;
    localparam OP_SUB=4'd2, OP_RSB=4'd3, OP_ADD=4'd4, OP_MOV=4'd8, OP_CMP=4'd12;
    localparam F_B=4'd0, F_BL=4'd1, F_BX=4'd2, F_OUT=4'd3, F_HLT=4'd4;
    localparam SH_LSL=2'd0, SH_ASR=2'd2;

    reg [31:0] outs [0:7];
    always @(posedge clk) if (ov) begin outs[n] = od; n = n + 1; end

    initial begin
        for (i = 0; i < 256; i = i + 1) rom[i] = flow(AL, F_HLT, 17'd0);
        // (1) SUBS loop: r1 = sum 1..10 = 55
        rom[0] = dpi(AL, OP_MOV, 4'd0, 4'd0, 1'b0, 8'd10);
        rom[1] = dpi(AL, OP_MOV, 4'd1, 4'd0, 1'b0, 8'd0);
        rom[2] = dpr(AL, OP_ADD, 4'd1, 4'd1, 4'd0, 1'b0, SH_LSL, 5'd0);
        rom[3] = dpi(AL, OP_SUB, 4'd0, 4'd0, 1'b1, 8'd1);     // SUBS
        rom[4] = flow(NE, F_B, -17'sd2);                       // BNE @2
        rom[5] = flowr(AL, F_OUT, 4'd1);                       // -> 55
        // (2) conditional execution: CMP r1,#55 then EQ/NE pair + poison
        rom[6] = dpi(AL, OP_CMP, 4'd0, 4'd1, 1'b0, 8'd55);
        rom[7] = dpi(EQ, OP_MOV, 4'd2, 4'd0, 1'b0, 8'd7);
        rom[8] = dpi(NE, OP_MOV, 4'd2, 4'd0, 1'b0, 8'd9);
        rom[9] = dpi(NE, OP_ADD, 4'd1, 4'd1, 1'b0, 8'd100);   // poison
        rom[10]= flowr(AL, F_OUT, 4'd2);                       // -> 7
        // (3) BL to a subroutine behind the HALT; it outputs 42, BX r14 back
        rom[11]= flow(AL, F_BL, 17'sd9);                       // BL @20 (lr=12)
        // (4) barrel shifter: ASR must sign-extend, LSL must scale
        rom[12]= dpi(AL, OP_MOV, 4'd4, 4'd0, 1'b0, 8'd8);
        rom[13]= dpi(AL, OP_RSB, 4'd4, 4'd4, 1'b0, 8'd0);      // r4 = 0-8 = -8
        rom[14]= dpr(AL, OP_MOV, 4'd5, 4'd0, 4'd4, 1'b0, SH_ASR, 5'd2);
        rom[15]= flowr(AL, F_OUT, 4'd5);                       // -> 0xFFFFFFFE
        rom[16]= dpi(AL, OP_MOV, 4'd6, 4'd0, 1'b0, 8'd5);
        rom[17]= dpr(AL, OP_MOV, 4'd7, 4'd0, 4'd6, 1'b0, SH_LSL, 5'd3);
        rom[18]= flowr(AL, F_OUT, 4'd7);                       // -> 40
        rom[19]= flow(AL, F_HLT, 17'd0);
        // ---- subroutine (reached only via the BL) ----
        rom[20]= dpi(AL, OP_MOV, 4'd3, 4'd0, 1'b0, 8'd42);
        rom[21]= flowr(AL, F_OUT, 4'd3);                       // -> 42
        rom[22]= flowr(AL, F_BX, 4'd14);                       // return to 12
        repeat (3) @(posedge clk); rst = 0;
        repeat (300) @(posedge clk);
        if (!hl)                       errs = errs + 1;
        if (n   !== 5)                 errs = errs + 1;
        if (outs[0] !== 32'd55)        errs = errs + 1;
        if (outs[1] !== 32'd7)         errs = errs + 1;   // poison skipped
        if (outs[2] !== 32'd42)        errs = errs + 1;   // BL/BX
        if (outs[3] !== 32'hFFFFFFFE)  errs = errs + 1;   // ASR sign-extends
        if (outs[4] !== 32'd40)        errs = errs + 1;   // LSL
        $display("cpu_arm32 feature suite: %0d errors", errs);
        $finish;
    end
endmodule
