// Golden test: 32-bit RV-lite single-cycle CPU. Sum 1..10 loop, then an
// op mini-suite: LUI placement, SLT/SLTU, SLL/SRA, LW/SW round-trip.
// Encoding: [31:28]op [27:24]rd [23:20]rs1 [19:16]rs2 [15:0]imm16.
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg  [31:0] rom [0:255];
    wire [7:0]  ia; wire [31:0] od; wire ov, hl;
    cpu_riscv32 u(.clk(clk), .rst(rst), .imem_addr(ia), .imem_data(rom[ia]),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(4'd0), .dbg_data(), .dbg_pc());
    always #5 clk = ~clk;

    reg [31:0] outs [0:7];
    always @(posedge clk) if (ov) begin outs[n] = od; n = n + 1; end

    initial begin
        for (i = 0; i < 256; i = i + 1) rom[i] = 32'hF0000000;   // HALT
        // sum 1..10 -> x1 = 55
        rom[0] = 32'h11000000;   // ADDI x1,x0,0
        rom[1] = 32'h1200000A;   // ADDI x2,x0,10
        rom[2] = 32'h01120000;   // ADD  x1,x1,x2
        rom[3] = 32'h1220FFFF;   // ADDI x2,x2,-1
        rom[4] = 32'h9020FFFE;   // BNE  x2,x0,-2
        rom[5] = 32'hE0100000;   // OUT  x1            -> 55
        // LUI top-16 placement
        rom[6] = 32'h5300ABCD;   // LUI  x3,0xABCD     -> 0xABCD0000
        rom[7] = 32'hE0300000;   // OUT  x3
        // SLT: -1 < 55 signed -> 1 ; SLTU: 0xFFFFFFFF < 55 -> 0
        rom[8] = 32'h14000000 | 32'h0000FFFF;  // ADDI x4,x0,-1
        rom[9] = 32'h05410008;   // ALU-R rd=5 rs1=4 rs2=1 funct=8 (SLT)
        rom[10]= 32'hE0500000;   // OUT  x5            -> 1
        rom[11]= 32'h06410009;   // SLTU x6,x4,x1
        rom[12]= 32'hE0600000;   // OUT  x6            -> 0
        // SLL / SRA: (55 << 2) = 220 ; (-1 >>> 4) = -1
        rom[13]= 32'h17000002;   // ADDI x7,x0,2
        rom[14]= 32'h08170005;   // SLL  x8,x1,x7
        rom[15]= 32'hE0800000;   // OUT  x8            -> 220
        rom[16]= 32'h09470007;   // SRA  x9,x4,x7
        rom[17]= 32'hE0900000;   // OUT  x9            -> 0xFFFFFFFF
        // LW/SW round-trip through dmem[7]
        rom[18]= 32'h70180007;   // SW   x8,7(x0)   (rs1=0 rs2=8? fields: rd=0 rs1=1? see below)
        rom[18]= 32'h70080007;   // SW: op=7 rd=- rs1=0 rs2=8 imm=7
        rom[19]= 32'h6A000007;   // LW   x10,7(x0)
        rom[20]= 32'hE0A00000;   // OUT  x10           -> 220
        rom[21]= 32'hF0000000;   // HALT
        repeat (3) @(posedge clk); rst = 0;
        repeat (200) @(posedge clk);
        if (!hl)                      errs = errs + 1;
        if (n   !== 7)                errs = errs + 1;
        if (outs[0] !== 32'd55)       errs = errs + 1;
        if (outs[1] !== 32'hABCD0000) errs = errs + 1;
        if (outs[2] !== 32'd1)        errs = errs + 1;
        if (outs[3] !== 32'd0)        errs = errs + 1;
        if (outs[4] !== 32'd220)      errs = errs + 1;
        if (outs[5] !== 32'hFFFFFFFF) errs = errs + 1;
        if (outs[6] !== 32'd220)      errs = errs + 1;
        $display("cpu_riscv32 program suite: %0d errors", errs);
        $finish;
    end
endmodule
