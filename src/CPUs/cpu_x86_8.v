// =====================================================================
//  cpu_x86_8.v
//  8-bit x86-FLAVOURED CISC CPU (two-operand destructive ISA).
//  AX/BX/CX/DX + FLAGS(CF ZF SF OF) + SP, descending stack in a
//  32-word unified data/stack RAM. Authentic flag quirks kept:
//  INC/DEC preserve CF, NOT touches no flags, LOOP uses CX.
//  16-bit Harvard instructions on imem_*. See docs/cpus.md.
//  MODULAR: decode / cond / ALU(arith+logic+shift) / regfile / ram /
//  flags / wbsel / pcnext submodules; pc/sp/out/halt stay in the top.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- cpu_x86_8_decode : fields + instruction class decode ---
module cpu_x86_8_decode(
    input  wire [15:0] ir,
    output wire [3:0]  op,
    output wire [1:0]  rsel,
    output wire [1:0]  msel,
    output wire [7:0]  imm8,
    output wire [3:0]  cond,
    output wire        is_movrr,
    output wire        is_movi,
    output wire        is_add,
    output wire        is_sub,
    output wire        is_and,
    output wire        is_or,
    output wire        is_xor,
    output wire        is_cmp,
    output wire        is_unary,
    output wire        is_shift,
    output wire        is_load,
    output wire        is_store,
    output wire        is_stk,
    output wire        is_jcc,
    output wire        is_movh,
    output wire        is_misc,
    output wire        is_push,
    output wire        is_pop,
    output wire        is_call,
    output wire        is_ret,
    output wire        is_hlt,
    output wire        is_out,
    output wire        is_loop,
    output wire        sel_arith,
    output wire        sel_logic,
    output wire        sel_shift
);
    assign op   = ir[15:12];
    assign rsel = ir[11:10];
    assign msel = ir[9:8];
    assign imm8 = ir[7:0];
    assign cond = {rsel, msel};

    // ---- class decode -------------------------------------------------
    assign is_movrr = (op == 4'h0);
    assign is_movi = (op == 4'h1);
    assign is_add = (op == 4'h2);
    assign is_sub = (op == 4'h3);
    assign is_and = (op == 4'h4);
    assign is_or = (op == 4'h5);
    assign is_xor = (op == 4'h6);
    assign is_cmp = (op == 4'h7);
    assign is_unary = (op == 4'h8);
    assign is_shift = (op == 4'h9);
    assign is_load = (op == 4'hA);
    assign is_store = (op == 4'hB);
    assign is_stk = (op == 4'hC);
    assign is_jcc = (op == 4'hD);
    assign is_movh = (op == 4'hE);
    assign is_misc = (op == 4'hF);

    assign is_push = is_stk & (msel == 2'd0);
    assign is_pop = is_stk & (msel == 2'd1);
    assign is_call = is_stk & (msel == 2'd2);
    assign is_ret = is_stk & (msel == 2'd3);
    assign is_hlt = is_misc & (msel == 2'd1);
    assign is_out = is_misc & (msel == 2'd2);
    assign is_loop = is_jcc & (cond == 4'd13);

    assign sel_arith = is_add | is_sub | is_cmp
                   | (is_unary & (msel != 2'd2));   // INC DEC NEG
    assign sel_logic = is_and | is_or | is_xor | (is_unary & (msel == 2'd2));
    assign sel_shift = is_shift;
endmodule

// --- cpu_x86_8_alu_arith : add/sub path with carry-chain CF/OF view ---
// (leaf of cpu_x86_8_alu)
module cpu_x86_8_alu_arith(
    input  wire [7:0] ar_a,
    input  wire [7:0] ar_b,
    input  wire        ar_subop,
    output wire [7:0] ar_y,
    output wire        ar_c,
    output wire        ar_v
);
    wire [8:0] ar_full = ar_subop ? ({1'b0, ar_a} - {1'b0, ar_b})
                                    : ({1'b0, ar_a} + {1'b0, ar_b});
    assign ar_y = ar_full[7:0];
    assign ar_c = ar_full[8];                       // carry / borrow
    assign ar_v = ar_subop ? ((ar_a[7] != ar_b[7]) & (ar_y[7] != ar_a[7]))
                         : ((ar_a[7] == ar_b[7]) & (ar_y[7] != ar_a[7]));
endmodule

// --- cpu_x86_8_alu_logic : AND / OR / XOR / NOT path (leaf of cpu_x86_8_alu) ---
module cpu_x86_8_alu_logic(
    input  wire [7:0] lg_a,
    input  wire [7:0] lg_b,
    input  wire        is_and,
    input  wire        is_or,
    input  wire        is_xor,
    output wire [7:0] lg_y
);
    assign lg_y = is_and ? (lg_a & lg_b)
                : is_or  ? (lg_a | lg_b)
                : is_xor ? (lg_a ^ lg_b)
                :          (~lg_a);          // NOT
endmodule

// --- cpu_x86_8_alu_shift : single-position shifts, x86 flag semantics ---
// (leaf of cpu_x86_8_alu)
module cpu_x86_8_alu_shift(
    input  wire [7:0] sh_a,
    input  wire [1:0]  msel,
    output wire [7:0] sh_y,
    output wire        sh_c,
    output wire        sh_v
);
    assign sh_y = (msel == 2'd0) ? {sh_a[6:0], 1'b0}        // SHL
                : (msel == 2'd1) ? {1'b0, sh_a[7:1]}        // SHR
                : (msel == 2'd2) ? {sh_a[7], sh_a[7:1]}    // SAR
                :                  {sh_a[6:0], sh_a[7]};   // ROL
    assign sh_c = (msel == 2'd0) ? sh_a[7]
              : (msel == 2'd3) ? sh_a[7]
              :                  sh_a[0];
    assign sh_v = (msel == 2'd0) ? (sh_y[7] ^ sh_c)    // SHL: OF = CF^MSB(result)
              : (msel == 2'd1) ? sh_a[7]             // SHR: OF = old MSB
              : (msel == 2'd3) ? (sh_y[7] ^ sh_c)    // ROL
              :                  1'b0;                // SAR: OF = 0
endmodule

// --- cpu_x86_8_alu : operand-isolated 3-path ALU (flagship technique) ---
// operand muxes for the unary ops (INC/DEC use +/-1, NEG uses 0-r)
// live here; each path's inputs are ANDed with its select line.
module cpu_x86_8_alu(
    input  wire [7:0] rv,
    input  wire [7:0] mv,
    input  wire [1:0]  msel,
    input  wire        is_sub,
    input  wire        is_cmp,
    input  wire        is_unary,
    input  wire        is_and,
    input  wire        is_or,
    input  wire        is_xor,
    input  wire        sel_arith,
    input  wire        sel_logic,
    input  wire        sel_shift,
    output wire [7:0] ar_y,
    output wire        ar_c,
    output wire        ar_v,
    output wire [7:0] lg_y,
    output wire [7:0] sh_y,
    output wire        sh_c,
    output wire        sh_v
);
    // arithmetic path: y = a +/- b (+carry chain view for CF/OF)
    wire [7:0] ar_a = (is_unary ? ((msel == 2'd3) ? {8{1'b0}} : rv) : rv)
                        & {8{sel_arith}};
    wire [7:0] ar_b = (is_unary ? ((msel == 2'd3) ? rv : {{7{1'b0}}, 1'b1}) : mv)
                        & {8{sel_arith}};
    wire ar_subop = is_sub | is_cmp
                  | (is_unary & ((msel == 2'd1) | (msel == 2'd3))); // DEC NEG
    cpu_x86_8_alu_arith u_arith(.ar_a(ar_a), .ar_b(ar_b), .ar_subop(ar_subop),
                          .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v));

    // logic path
    wire [7:0] lg_a = rv & {8{sel_logic}};
    wire [7:0] lg_b = mv & {8{sel_logic}};
    cpu_x86_8_alu_logic u_logic(.lg_a(lg_a), .lg_b(lg_b),
                          .is_and(is_and), .is_or(is_or), .is_xor(is_xor),
                          .lg_y(lg_y));

    // shift path (single position, x86 flag semantics)
    wire [7:0] sh_a = rv & {8{sel_shift}};
    cpu_x86_8_alu_shift u_shift(.sh_a(sh_a), .msel(msel),
                          .sh_y(sh_y), .sh_c(sh_c), .sh_v(sh_v));
endmodule

// --- cpu_x86_8_cond : x86 Jcc condition table ---
module cpu_x86_8_cond(
    input  wire [3:0]  cond,
    input  wire        zf,
    input  wire        cf,
    input  wire        sf,
    input  wire        vf,
    input  wire [7:0] cxv,
    output reg         ctaken
);
    always @(*) begin case (cond)
        4'd0:  ctaken = 1'b1;            // JMP
        4'd1:  ctaken = zf;              // JZ
        4'd2:  ctaken = ~zf;             // JNZ
        4'd3:  ctaken = cf;              // JC
        4'd4:  ctaken = ~cf;             // JNC
        4'd5:  ctaken = sf;              // JS
        4'd6:  ctaken = ~sf;             // JNS
        4'd7:  ctaken = vf;              // JO
        4'd8:  ctaken = ~vf;             // JNO
        4'd9:  ctaken = sf ^ vf;         // JL  (signed <)
        4'd10: ctaken = ~(sf ^ vf);      // JGE
        4'd11: ctaken = ~zf & ~(sf ^ vf);// JG
        4'd12: ctaken = zf | (sf ^ vf);  // JLE
        4'd13: ctaken = (cxv != {8{1'b0}});  // LOOP looks at CX-1... see EXEC
        default: ctaken = 1'b0;          // 14/15 never
    endcase end
endmodule

// --- cpu_x86_8_regfile : AX/BX/CX/DX (single muxed write port) ---
// all writing instruction classes are mutually exclusive, so one
// port (driven by cpu_x86_8_wbsel) carries every result; LOOP writes CX.
module cpu_x86_8_regfile(
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [1:0]  waddr,
    input  wire [7:0] wdata,
    input  wire [1:0]  rsel,
    input  wire [1:0]  msel,
    output wire [7:0] rv,
    output wire [7:0] mv,
    output wire [7:0] cxv,
    input  wire [1:0]  dbg_sel,
    output wire [7:0] dbg_data
);
    reg [7:0] regs [0:3];      // 0 AX, 1 BX, 2 CX, 3 DX

    assign rv = regs[rsel];   // destination operand (read)
    assign mv = regs[msel];   // source operand
    assign cxv = regs[2];     // LOOP counter
    assign dbg_data = regs[dbg_sel];

    // sync reset clears all four, exactly as before (no async edge)
    always @(posedge clk) begin
        if (rst) begin
            regs[0] <= {8{1'b0}}; regs[1] <= {8{1'b0}};
            regs[2] <= {8{1'b0}}; regs[3] <= {8{1'b0}};
        end else if (we) regs[waddr] <= wdata;
    end
endmodule

// --- cpu_x86_8_ram : 32-word unified data + descending stack RAM ---
// one muxed write port (MOV [imm8],r / PUSH / CALL are exclusive),
// two async read ports (stack top at sp, data at imm8).
module cpu_x86_8_ram(
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  waddr,
    input  wire [7:0] wdata,
    input  wire [4:0]  raddr_s,
    input  wire [4:0]  raddr_i,
    output wire [7:0] rdata_s,
    output wire [7:0] rdata_i
);
    reg [7:0] ram [0:31];     // unified data + descending stack

    assign rdata_s = ram[raddr_s];
    assign rdata_i = ram[raddr_i];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) ram[waddr] <= wdata;
    end
endmodule

// --- cpu_x86_8_wbsel : register write-back select (one port, many sources) ---
module cpu_x86_8_wbsel(
    input  wire        is_movrr,
    input  wire        is_movi,
    input  wire        is_add,
    input  wire        is_sub,
    input  wire        is_and,
    input  wire        is_or,
    input  wire        is_xor,
    input  wire        is_unary,
    input  wire        is_shift,
    input  wire        is_load,
    input  wire        is_pop,
    input  wire        is_loop,
    input  wire        is_movh,
    input  wire [1:0]  msel,
    input  wire [1:0]  rsel,
    input  wire [7:0]  imm8,
    input  wire [7:0] rv,
    input  wire [7:0] mv,
    input  wire [7:0] ar_y,
    input  wire [7:0] lg_y,
    input  wire [7:0] sh_y,
    input  wire [7:0] ram_rd,
    input  wire [7:0] stk_top,
    input  wire [7:0] cx_dec,
    output wire        wb_en,
    output wire [1:0]  wb_addr,
    output wire [7:0] wb_data
);
    // every register-writing arm of the old EXEC case, one-hot by op
    assign wb_en = is_movrr | is_movi | is_add | is_sub
                 | is_and | is_or | is_xor
                 | is_unary | is_shift | is_load
                 | is_pop | is_loop | is_movh;
    assign wb_addr = is_loop ? 2'd2 : rsel;            // LOOP: CX--
    assign wb_data = is_movrr ? mv                                // MOV r,m
                   : is_movi  ? imm8         // MOV r,imm8
                   : (is_add | is_sub) ? ar_y                     // ADD SUB
                   : (is_and | is_or | is_xor) ? lg_y             // AND OR XOR
                   : is_unary ? ((msel == 2'd2) ? lg_y : ar_y)    // NOT vs INC/DEC/NEG
                   : is_shift ? sh_y                              // shifts by 1
                   : is_load  ? ram_rd                            // MOV r,[imm8]
                   : is_pop   ? stk_top                           // POP r
                   : is_loop  ? cx_dec                            // CX-- (no flags)
                   :            imm8;     // MOVH == MOV on W=8
endmodule

// --- cpu_x86_8_flags : CF ZF SF OF with the authentic x86 quirks ---
// INC/DEC preserve CF; NOT touches no flags; NEG CF=0 only if src was 0;
// logic ops clear CF/OF; rotates leave ZF/SF untouched.
module cpu_x86_8_flags(
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [3:0]  op,
    input  wire [1:0]  msel,
    input  wire [7:0] rv,
    input  wire [7:0] ar_y,
    input  wire        ar_c,
    input  wire        ar_v,
    input  wire [7:0] lg_y,
    input  wire [7:0] sh_y,
    input  wire        sh_c,
    input  wire        sh_v,
    output reg         cf,
    output reg         zf,
    output reg         sf,
    output reg         vf
);
    always @(posedge clk) begin
        if (rst) begin
            cf <= 1'b0; zf <= 1'b0; sf <= 1'b0; vf <= 1'b0;
        end else if (we) begin
            case (op)
                4'h2, 4'h3: begin                              // ADD SUB
                    cf <= ar_c; zf <= (ar_y == {8{1'b0}});
                    sf <= ar_y[7]; vf <= ar_v;
                end
                4'h4, 4'h5, 4'h6: begin                        // AND OR XOR
                    cf <= 1'b0; vf <= 1'b0;                    // x86: logic clears CF/OF
                    zf <= (lg_y == {8{1'b0}}); sf <= lg_y[7];
                end
                4'h7: begin                                    // CMP (flags only)
                    cf <= ar_c; zf <= (ar_y == {8{1'b0}});
                    sf <= ar_y[7]; vf <= ar_v;
                end
                4'h8: case (msel)                              // unary
                    2'd0, 2'd1: begin                          // INC DEC
                        zf <= (ar_y == {8{1'b0}}); sf <= ar_y[7]; vf <= ar_v;
                    end                                        // CF PRESERVED (x86 quirk)
                    2'd2: ;                                    // NOT: no flags (x86 quirk)
                    2'd3: begin                                // NEG = 0 - r
                        cf <= (rv != {8{1'b0}});            // x86: CF=0 only if src was 0
                        zf <= (ar_y == {8{1'b0}}); sf <= ar_y[7]; vf <= ar_v;
                    end
                endcase
                4'h9: begin                                    // shifts by 1
                    cf <= sh_c; vf <= sh_v;
                    if (msel != 2'd3) begin                    // ROL: ZF/SF untouched
                        zf <= (sh_y == {8{1'b0}}); sf <= sh_y[7];
                    end
                end
                default: ;
            endcase
        end
    end
endmodule

// --- cpu_x86_8_pcnext : next-PC select (default +1; flow ops override) ---
module cpu_x86_8_pcnext(
    input  wire [7:0]  pc,
    input  wire [7:0]  imm8,
    input  wire [7:0] stk_top,
    input  wire        is_call,
    input  wire        is_ret,
    input  wire        is_jcc,
    input  wire        is_loop,
    input  wire        loop_take,
    input  wire        ctaken,
    input  wire        is_hlt,
    output wire [7:0]  next_pc
);
    wire [7:0] pc1w = pc + 8'd1;
    assign next_pc = is_call ? imm8
                   : is_ret  ? stk_top[7:0]
                   : (is_jcc & (is_loop ? loop_take : ctaken)) ? imm8
                   : is_hlt  ? pc
                   :           pc1w;
endmodule

module cpu_x86_8(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [15:0] imem_data,
    // OUT instruction port
    output reg  [7:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    input  wire [2:0]  dbg_sel,      // 0..3 AX..DX, 4 SP, 5 FLAGS, 6 PC
    output wire [7:0]  dbg_data,
    output wire [7:0]  dbg_pc
);
    // define clk                    input   255.230.80
    // define rst                    input   255.80.80
    // define imem_addr              output  38.15.153
    // define imem_data              input   126.199.90
    // define out_data               output  120.255.160
    // define out_valid              output  97.255.239
    // define halted                 output  255.120.120
    // define dbg_sel                input   200.120.255
    // define dbg_data               output  178.54.0
    // define dbg_pc                 output  255.0.26

    reg [7:0] pc;
    reg [5:0] sp;                  // stack pointer (init 32 = empty)

    // ---- decode ------------------------------------------------------
    wire [3:0] op, cond;
    wire [1:0] rsel, msel;
    wire [7:0] imm8;
    wire is_movrr, is_movi, is_add, is_sub, is_and, is_or, is_xor;
    wire is_cmp, is_unary, is_shift, is_load, is_store, is_stk;
    wire is_jcc, is_movh, is_misc;
    wire is_push, is_pop, is_call, is_ret, is_hlt, is_out, is_loop;
    wire sel_arith, sel_logic, sel_shift;
    cpu_x86_8_decode u_decode(
        .ir(imem_data),
        .op(op), .rsel(rsel), .msel(msel), .imm8(imm8), .cond(cond),
        .is_movrr(is_movrr), .is_movi(is_movi), .is_add(is_add),
        .is_sub(is_sub), .is_and(is_and), .is_or(is_or),
        .is_xor(is_xor), .is_cmp(is_cmp), .is_unary(is_unary),
        .is_shift(is_shift), .is_load(is_load), .is_store(is_store),
        .is_stk(is_stk), .is_jcc(is_jcc), .is_movh(is_movh),
        .is_misc(is_misc),
        .is_push(is_push), .is_pop(is_pop), .is_call(is_call),
        .is_ret(is_ret), .is_hlt(is_hlt), .is_out(is_out),
        .is_loop(is_loop),
        .sel_arith(sel_arith), .sel_logic(sel_logic),
        .sel_shift(sel_shift)
    );

    // write gating: identical condition to the old monolithic block
    // (writes happened only in the `else if (!halted)` branch).
    wire wr_gate = ~rst & ~halted;

    // ---- register file + write-back select ---------------------------
    wire [7:0] rv, mv, cxv, rf_dbg;
    wire [7:0] ar_y, lg_y, sh_y, ram_rd, stk_top;
    wire ar_c, ar_v, sh_c, sh_v;
    wire [7:0] cx_dec = cxv - {{7{1'b0}}, 1'b1};
    wire loop_take = (cx_dec != {8{1'b0}});
    wire wb_en;
    wire [1:0] wb_addr;
    wire [7:0] wb_data;
    cpu_x86_8_wbsel u_wbsel(
        .is_movrr(is_movrr), .is_movi(is_movi), .is_add(is_add),
        .is_sub(is_sub), .is_and(is_and), .is_or(is_or),
        .is_xor(is_xor), .is_unary(is_unary), .is_shift(is_shift),
        .is_load(is_load), .is_pop(is_pop), .is_loop(is_loop),
        .is_movh(is_movh),
        .msel(msel), .rsel(rsel), .imm8(imm8),
        .rv(rv), .mv(mv), .ar_y(ar_y), .lg_y(lg_y), .sh_y(sh_y),
        .ram_rd(ram_rd), .stk_top(stk_top), .cx_dec(cx_dec),
        .wb_en(wb_en), .wb_addr(wb_addr), .wb_data(wb_data)
    );
    cpu_x86_8_regfile u_regfile(
        .clk(clk), .rst(rst),
        .we(wr_gate & wb_en), .waddr(wb_addr), .wdata(wb_data),
        .rsel(rsel), .msel(msel),
        .rv(rv), .mv(mv), .cxv(cxv),
        .dbg_sel(dbg_sel[1:0]), .dbg_data(rf_dbg)
    );

    // ---- ALU (operand-isolated paths inside) ------------------------
    cpu_x86_8_alu u_alu(
        .rv(rv), .mv(mv), .msel(msel),
        .is_sub(is_sub), .is_cmp(is_cmp), .is_unary(is_unary),
        .is_and(is_and), .is_or(is_or), .is_xor(is_xor),
        .sel_arith(sel_arith), .sel_logic(sel_logic),
        .sel_shift(sel_shift),
        .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v),
        .lg_y(lg_y),
        .sh_y(sh_y), .sh_c(sh_c), .sh_v(sh_v)
    );

    // ---- FLAGS unit ---------------------------------------------------
    wire cf, zf, sf, vf;
    cpu_x86_8_flags u_flags(
        .clk(clk), .rst(rst), .we(wr_gate),
        .op(op), .msel(msel), .rv(rv),
        .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v),
        .lg_y(lg_y), .sh_y(sh_y), .sh_c(sh_c), .sh_v(sh_v),
        .cf(cf), .zf(zf), .sf(sf), .vf(vf)
    );

    // ---- condition evaluation (x86 Jcc table) -------------------------
    wire ctaken;
    cpu_x86_8_cond u_cond(
        .cond(cond), .zf(zf), .cf(cf), .sf(sf), .vf(vf),
        .cxv(cxv),
        .ctaken(ctaken)
    );

    // ---- unified data + stack RAM ------------------------------------
    wire ram_we = wr_gate & (is_store | is_push | is_call);
    wire [4:0] ram_waddr = is_store ? imm8[4:0] : (sp[4:0] - 5'd1);
    wire [7:0] ram_wdata = is_call ? pc1w : rv;
    cpu_x86_8_ram u_ram(
        .clk(clk),
        .we(ram_we), .waddr(ram_waddr), .wdata(ram_wdata),
        .raddr_s(sp[4:0]), .raddr_i(imm8[4:0]),
        .rdata_s(stk_top), .rdata_i(ram_rd)
    );

    // ---- next PC -------------------------------------------------------
    wire [7:0] pc1w = pc + 8'd1;       // return address (CALL)
    wire [7:0] next_pc;
    cpu_x86_8_pcnext u_pcnext(
        .pc(pc), .imm8(imm8), .stk_top(stk_top),
        .is_call(is_call), .is_ret(is_ret), .is_jcc(is_jcc),
        .is_loop(is_loop), .loop_take(loop_take), .ctaken(ctaken),
        .is_hlt(is_hlt),
        .next_pc(next_pc)
    );

    assign imem_addr = pc;
    assign dbg_pc    = pc;
    assign dbg_data  = (dbg_sel < 3'd4) ? rf_dbg
                     : (dbg_sel == 3'd4) ? {{2{1'b0}}, sp}
                     : (dbg_sel == 3'd5) ? {{4{1'b0}}, {vf, sf, zf, cf}}
                     :                    pc;

    // sequencing: identical to the monolithic core; the regfile, ram
    // and flag writes moved into their modules with the same conditions.
    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; sp <= 6'd32; halted <= 1'b0;
            out_data <= {8{1'b0}};
        end else if (!halted) begin
            pc <= next_pc;
            sp <= (is_push | is_call) ? sp - 6'd1
                : (is_pop  | is_ret)  ? sp + 6'd1
                :                       sp;
            if (is_out) begin out_data <= rv; out_valid <= 1'b1; end
            if (is_hlt) halted <= 1'b1;
        end
    end
endmodule


