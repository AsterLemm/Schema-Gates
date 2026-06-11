// FT_ALSO: CPUs/cpu_x86_16.v
// Golden test: a cpu_arm16 binary running on the cpu_x86_16 HOST through
// the fetch-path interpreter. SUBS loop (55), conditional execution with
// a poison ADDNE, MOVS flag refresh feeding ADDEQ, BL with link write,
// then BX -- which must TRAP (the host has no indirect jump).
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg [31:0] grom [0:31];

    function [31:0] dpi; input [3:0] cond, op, rd, rn; input s; input [7:0] imm;
        dpi = {cond, s, 2'b01, op, rd, rn, imm, 5'b00000};
    endfunction
    function [31:0] dpr; input [3:0] cond, op, rd, rn, rm; input s;
        dpr = {cond, s, 2'b00, op, rd, rn, rm, 2'd0, 5'd0, 2'b00};
    endfunction
    function [31:0] flow; input [3:0] cond, op; input [16:0] imm;
        flow = {cond, 1'b0, 2'b11, op, 4'd0, imm[16:0]};
    endfunction
    function [31:0] flowr; input [3:0] cond, op, rn;
        flowr = {cond, 1'b0, 2'b11, op, 4'd0, rn, 13'd0};
    endfunction
    localparam AL=4'd14, EQ=4'd0, NE=4'd1;
    localparam OP_SUB=4'd2, OP_ADD=4'd4, OP_MOV=4'd8, OP_CMP=4'd12;
    localparam F_B=4'd0, F_BL=4'd1, F_BX=4'd2, F_OUT=4'd3, F_HLT=4'd4;

    wire [7:0] ha; wire [15:0] hi_, od; wire [4:0] ga; wire ov, hl, trp;
    interp_arm_to_x86_16 it(.host_addr(ha), .host_instr(hi_),
        .guest_addr(ga), .guest_instr(grom[ga]), .trap(trp));
    cpu_x86_16 host(.clk(clk), .rst(rst), .imem_addr(ha), .imem_data(hi_),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(3'd0), .dbg_data(), .dbg_pc());
    always #5 clk = ~clk;

    reg [15:0] outs [0:3]; reg trapped;
    always @(posedge clk) begin
        if (ov) begin outs[n] = od; n = n + 1; end
        if (trp) trapped = 1;
    end

    initial begin
        for (i = 0; i < 32; i = i + 1) grom[i] = flow(AL, F_HLT, 17'd0);
        grom[0] = dpi(AL, OP_MOV, 4'd0, 4'd0, 1'b0, 8'd10);
        grom[1] = dpi(AL, OP_MOV, 4'd1, 4'd0, 1'b0, 8'd0);
        grom[2] = dpr(AL, OP_ADD, 4'd1, 4'd1, 4'd0, 1'b0);
        grom[3] = dpi(AL, OP_SUB, 4'd0, 4'd0, 1'b1, 8'd1);      // SUBS
        grom[4] = flow(NE, F_B, -17'sd2);                        // BNE @2
        grom[5] = flowr(AL, F_OUT, 4'd1);                        // -> 55
        grom[6] = dpi(AL, OP_CMP, 4'd0, 4'd1, 1'b0, 8'd55);
        grom[7] = dpi(EQ, OP_MOV, 4'd2, 4'd0, 1'b0, 8'd7);
        grom[8] = dpi(NE, OP_MOV, 4'd2, 4'd0, 1'b0, 8'd9);
        grom[9] = dpi(NE, OP_ADD, 4'd1, 4'd1, 1'b0, 8'd100);    // poison
        grom[10]= flowr(AL, F_OUT, 4'd2);                        // -> 7
        grom[11]= dpi(AL, OP_MOV, 4'd3, 4'd0, 1'b1, 8'd0);      // MOVS r3,#0
        grom[12]= dpi(EQ, OP_ADD, 4'd3, 4'd3, 1'b0, 8'd30);     // taken iff Z
        grom[13]= flow(AL, F_BL, 17'sd7);                        // BL @20
        grom[14]= flow(AL, F_HLT, 17'd0);                        // (not reached)
        grom[20]= flowr(AL, F_OUT, 4'd3);                        // -> 30
        grom[21]= flowr(AL, F_BX, 4'd14);                        // TRAP
        trapped = 0;
        repeat (4) @(posedge clk); rst = 0;
        repeat (1200) @(posedge clk);
        if (!hl)                errs = errs + 1;
        if (!trapped)           errs = errs + 1;
        if (n !== 3)            errs = errs + 1;
        if (outs[0] !== 16'd55) errs = errs + 1;
        if (outs[1] !== 16'd7)  errs = errs + 1;
        if (outs[2] !== 16'd30) errs = errs + 1;
        $display("interp arm-on-x86 program: %0d errors", errs);
        $finish;
    end
endmodule
