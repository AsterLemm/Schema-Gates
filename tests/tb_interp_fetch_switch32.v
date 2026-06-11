// FT_ALSO: interpreters/interp_riscv_to_arm_16.v CPUs/cpu_arm16.v
// Golden test: ONE cpu_arm16 host, flipped at runtime between its native
// ARM program (outputs 11) and a RISC-V binary through the interpreter
// (outputs 22) -- "convert the CPU into another without rebuilding it".
module tb;
    integer errs = 0, i;
    reg clk = 0, rst = 1;
    reg mode;
    reg [31:0] nrom [0:255];
    reg [31:0] grom [0:31];
    wire [7:0] ha; wire [31:0] xinstr, hinstr; wire [4:0] gaddr;
    wire xtrap, trap; wire [15:0] od; wire ov, hl;
    interp_riscv_to_arm_16 it(.host_addr(ha), .host_instr(xinstr),
        .guest_addr(gaddr), .guest_instr(grom[gaddr]), .trap(xtrap));
    interp_fetch_switch32 sw(.mode(mode), .native_instr(nrom[ha]),
        .xlat_instr(xinstr), .xlat_trap(xtrap),
        .host_instr(hinstr), .trap_out(trap));
    cpu_arm16 host(.clk(clk), .rst(rst), .imem_addr(ha), .imem_data(hinstr),
        .out_data(od), .out_valid(ov), .halted(hl),
        .dbg_sel(4'd0), .dbg_data(), .dbg_pc());
    always #5 clk = ~clk;

    reg [15:0] got; reg seen;
    always @(posedge clk) if (ov) begin got = od; seen = 1; end

    initial begin
        // native ARM: MOV r1,#11 ; OUT r1 ; HALT
        for (i = 0; i < 256; i = i + 1)
            nrom[i] = {4'd14, 1'b0, 2'b11, 4'd4, 4'd0, 17'd0};
        nrom[0] = {4'd14, 1'b0, 2'b01, 4'd8, 4'd1, 4'd0, 8'd11, 5'd0};
        nrom[1] = {4'd14, 1'b0, 2'b11, 4'd3, 4'd0, 4'd1, 13'd0};
        // guest RV-lite: ADDI x1,x0,22 ; OUT x1 ; HALT
        for (i = 0; i < 32; i = i + 1) grom[i] = 32'hF0000000;
        grom[0] = 32'h11000016;
        grom[1] = 32'hE0100000;
        // run native
        mode = 0; seen = 0;
        repeat (3) @(posedge clk); rst = 0;
        repeat (40) @(posedge clk);
        if (!hl)            errs = errs + 1;
        if (!seen)          errs = errs + 1;
        if (got !== 16'd11) errs = errs + 1;
        // flip the switch, re-run: same silicon executes the RV binary
        rst = 1; mode = 1; seen = 0;
        repeat (3) @(posedge clk); rst = 0;
        repeat (80) @(posedge clk);
        if (!hl)            errs = errs + 1;
        if (!seen)          errs = errs + 1;
        if (got !== 16'd22) errs = errs + 1;
        $display("fetch switch32 native/xlat flip: %0d errors", errs);
        $finish;
    end
endmodule
