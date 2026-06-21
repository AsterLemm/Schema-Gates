// Golden test: the 16-bit fetch switch is a pure mux with trap gating --
// xlat_trap must only reach trap_out while the interpreter is selected.
module tb;
    integer errs = 0;
    reg mode; reg [15:0] ni, xi; reg xt;
    wire [15:0] hi_; wire to;
    interp_fetch_switch16 u(.mode(mode), .native_instr(ni), .xlat_instr(xi),
        .xlat_trap(xt), .host_instr(hi_), .trap_out(to));
    initial begin
        ni = 16'h1234; xi = 16'hABCD;
        mode = 0; xt = 1; #1;
        if (hi_ !== 16'h1234) errs = errs + 1;
        if (to  !== 1'b0)     errs = errs + 1;   // trap masked in native mode
        mode = 1; #1;
        if (hi_ !== 16'hABCD) errs = errs + 1;
        if (to  !== 1'b1)     errs = errs + 1;
        xt = 0; #1;
        if (to  !== 1'b0)     errs = errs + 1;
        $display("fetch switch16 mux/trap gating: %0d errors", errs);
        $finish;
    end
endmodule
