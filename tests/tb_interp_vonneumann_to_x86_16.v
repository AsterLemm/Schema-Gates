// FT_ALSO: CPUs/cpu_x86_16.v
// Golden test: a cpu_vonneumann16 binary running on the cpu_x86_16 HOST
// through the fetch-path interpreter. Straight-line program covering
// LDI/STA/ADD/SUB/SHL/SHR/JC/OUT/HLT with data established by code.
// Expected OUT sequence: 15, 7, 0xFFFE; host halts; trap never fires.
module tb;
    integer errs = 0, n = 0, i;
    reg clk = 0, rst = 1;
    reg [15:0] grom [0:15];
    wire [7:0] ha; wire [15:0] hi_, od; wire [3:0] ga; wire ov, hl, trp;
    interp_vonneumann_to_x86_16 it(.host_addr(ha), .host_instr(hi_),
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
        for (i = 0; i < 16; i = i + 1) grom[i] = 16'hF000;   // HLT
        grom[0] = 16'h8009;  // LDI 9
        grom[1] = 16'h2005;  // STA 5
        grom[2] = 16'h8006;  // LDI 6
        grom[3] = 16'h3005;  // ADD 5      acc = 15
        grom[4] = 16'hE000;  // OUT        -> 15
        grom[5] = 16'hC000;  // SHL        acc = 30
        grom[6] = 16'hD000;  // SHR        acc = 15
        grom[7] = 16'hD000;  // SHR        acc = 7
        grom[8] = 16'hE000;  // OUT        -> 7
        grom[9] = 16'h2006;  // STA 6
        grom[10]= 16'h8005;  // LDI 5
        grom[11]= 16'h4006;  // SUB 6      5-7 = 0xFFFE, carry(borrow)=1
        grom[12]= 16'hB00E;  // JC 14      (must be taken)
        grom[13]= 16'hF000;  // HLT        (failure path)
        grom[14]= 16'hE000;  // OUT        -> 0xFFFE
        grom[15]= 16'hF000;  // HLT
        trapped = 0;
        repeat (4) @(posedge clk); rst = 0;
        repeat (200) @(posedge clk);
        if (!hl)                  errs = errs + 1;
        if (trapped)              errs = errs + 1;
        if (n !== 3)              errs = errs + 1;
        if (outs[0] !== 16'd15)   errs = errs + 1;
        if (outs[1] !== 16'd7)    errs = errs + 1;
        if (outs[2] !== 16'hFFFE) errs = errs + 1;
        $display("interp vN-on-x86 program: %0d errors", errs);
        $finish;
    end
endmodule
