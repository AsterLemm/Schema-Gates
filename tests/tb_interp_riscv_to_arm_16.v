// FT_ALSO: CPUs/cpu_arm16.v
// Golden test: a cpu_riscv16 (RV-lite) binary running on the cpu_arm16
// HOST through the fetch-path interpreter: sum 1..10 loop with a
// negative ADDI (becomes SUB), SW/LW round-trip, SLT, the x0 INVARIANT
// (a write to x0 must read back as zero), then SLL-by-register, which
// must TRAP (the host barrel shifter takes immediate amounts only).
// Expected OUT sequence: 55, 55, 1, 0; then trap + halt.
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg [31:0] grom [0:31];
    wire [7:0] ha; wire [31:0] hi_; wire [4:0] ga; wire [15:0] od;
    wire ov, hl, trp;
    interp_riscv_to_arm_16 it(.host_addr(ha), .host_instr(hi_),
        .guest_addr(ga), .guest_instr(grom[ga]), .trap(trp));
    cpu_arm16 host(.clk(clk), .rst(rst), .imem_addr(ha), .imem_data(hi_),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(4'd0), .dbg_data(), .dbg_pc());
    always #5 clk = ~clk;

    reg [15:0] outs [0:7]; reg trapped;
    always @(posedge clk) begin
        if (ov) begin outs[n] = od; n = n + 1; end
        if (trp) trapped = 1;
    end

    initial begin
        for (i = 0; i < 32; i = i + 1) grom[i] = 32'hF0000000;  // HALT
        grom[0] = 32'h11000000;  // ADDI x1,x0,0
        grom[1] = 32'h1200000A;  // ADDI x2,x0,10
        grom[2] = 32'h01120000;  // ADD  x1,x1,x2      <- loop
        grom[3] = 32'h1220FFFF;  // ADDI x2,x2,-1      (SUB path)
        grom[4] = 32'h9020FFFE;  // BNE  x2,x0,-2      -> @2
        grom[5] = 32'hE0100000;  // OUT  x1            -> 55
        grom[6] = 32'h70010005;  // SW   x1,5(x0)
        grom[7] = 32'h63000005;  // LW   x3,5(x0)
        grom[8] = 32'hE0300000;  // OUT  x3            -> 55
        grom[9] = 32'h04030008;  // SLT  x4,x0,x3      (0<55 -> 1)
        grom[10]= 32'hE0400000;  // OUT  x4            -> 1
        grom[11]= 32'h10000007;  // ADDI x0,x0,7       (must vanish)
        grom[12]= 32'hE0000000;  // OUT  x0            -> 0
        grom[13]= 32'h05120005;  // SLL  x5,x1,x2      -> TRAP
        trapped = 0;
        repeat (4) @(posedge clk); rst = 0;
        repeat (1500) @(posedge clk);
        if (!hl)                errs = errs + 1;
        if (!trapped)           errs = errs + 1;
        if (n !== 4)            errs = errs + 1;
        if (outs[0] !== 16'd55) errs = errs + 1;
        if (outs[1] !== 16'd55) errs = errs + 1;
        if (outs[2] !== 16'd1)  errs = errs + 1;
        if (outs[3] !== 16'd0)  errs = errs + 1;
        $display("interp rv-on-arm program: %0d errors", errs);
        $finish;
    end
endmodule
