"""
gen_cpu_arm.py  ->  src/CPUs/cpu_arm{4,8,16,32,64}.v

ARM-FLAVOURED CPU (classic ARM data-processing model, teaching subset).
Single-cycle Harvard core, 32-bit instructions, data width W.

The defining ARM traits are kept:
  * EVERY instruction is CONDITIONALLY EXECUTED via a 4-bit cond field
    read against the NZCV flags (EQ NE CS CC MI PL VS VC HI LS GE LT GT LE AL NV)
  * 3-operand data processing:  rd = rn OP op2
  * op2 passes through an inline BARREL SHIFTER (LSL LSR ASR ROR by imm5)
    whose carry-out feeds the C flag on logical ops
  * the S bit selects whether flags are written (CMP/CMN/TST/TEQ always do)
  * SUBtraction sets C = NOT borrow (the ARM convention), ADC/SBC chain it
  * BL writes the return address into r14 (LR); return with BX r14

INSTRUCTION WORD
  [31:28]=cond [27]=S [26:25]=cls [24:21]=op4 [20:17]=rd [16:13]=rn
  [12:9]=rm [8:7]=shtyp [6:2]=shamt5 [1:0]=00
  cls 00  DP-register : op2 = barrel(R[rm], shtyp, shamt5)
  cls 01  DP-immediate: op2 = zero-extended imm8 = instr[12:5]
  cls 10  memory      : op4[0]=0 LDR rd,[rn+imm8] | 1 STR rd,[rn+imm8]
                        (imm8 = instr[12:5]; 32-word data RAM)
  cls 11  flow        : op4 = 0 B imm17 | 1 BL imm17 (r14=pc+1) | 2 BX rn
                        | 3 OUT rn | 4 HALT     (imm17 = signed instr[16:0])
  DP op4: 0 AND 1 EOR 2 SUB 3 RSB 4 ADD 5 ADC 6 SBC 7 ORR
          8 MOV 9 MVN 10 BIC 11 (=MOV) 12 CMP 13 CMN 14 TST 15 TEQ

Deviation from real ARM (documented): r15 is NOT the PC here; the PC is a
separate 8-bit instruction counter. r14 is still the link register.

MODULAR EMISSION (DigitalJS-style hierarchy): <top>_cond / _decode /
_shifter / _alu (instantiating _alu_arith + _alu_logic) / _regfile /
_dmem / _flags submodules; the pc/out/halt sequencing stays in the top.
Every expression is carried over verbatim from the monolithic emitter.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def cond_module(n):
    return f"""\
// --- {n}_cond : ARM condition check (gates EVERY instruction) ---
module {n}_cond(
    input  wire [3:0] cond,
    input  wire       fN,
    input  wire       fZ,
    input  wire       fC,
    input  wire       fV,
    output reg        cond_pass
);
    always @(*) begin case (cond)
        4'd0:  cond_pass = fZ;               // EQ
        4'd1:  cond_pass = ~fZ;              // NE
        4'd2:  cond_pass = fC;               // CS/HS
        4'd3:  cond_pass = ~fC;              // CC/LO
        4'd4:  cond_pass = fN;               // MI
        4'd5:  cond_pass = ~fN;              // PL
        4'd6:  cond_pass = fV;               // VS
        4'd7:  cond_pass = ~fV;              // VC
        4'd8:  cond_pass = fC & ~fZ;         // HI
        4'd9:  cond_pass = ~fC | fZ;         // LS
        4'd10: cond_pass = (fN == fV);       // GE
        4'd11: cond_pass = (fN != fV);       // LT
        4'd12: cond_pass = ~fZ & (fN == fV); // GT
        4'd13: cond_pass = fZ | (fN != fV);  // LE
        4'd14: cond_pass = 1'b1;             // AL
        default: cond_pass = 1'b0;           // NV (never)
    endcase end
endmodule"""


def decode_module(n):
    return f"""\
// --- {n}_decode : field extraction + condition-gated class decode ---
module {n}_decode(
    input  wire [31:0] ir,
    input  wire        cond_pass,
    output wire [3:0]  cond,
    output wire        sbit,
    output wire [1:0]  cls,
    output wire [3:0]  op4,
    output wire [3:0]  rd,
    output wire [3:0]  rn,
    output wire [3:0]  rm,
    output wire [1:0]  shtyp,
    output wire [4:0]  shamt,
    output wire [7:0]  imm8,
    output wire [16:0] imm17,
    output wire        is_dp,
    output wire        is_mem,
    output wire        is_flow,
    output wire        is_test,
    output wire        wr_flag,
    output wire        is_b,
    output wire        is_bl,
    output wire        is_bx,
    output wire        is_outi,
    output wire        is_hlt,
    output wire        is_ldr,
    output wire        is_str,
    output wire        sel_arith,
    output wire        sel_logic,
    output wire        dp_wr
);
    // ---- field extraction ---------------------------------------------
    assign cond  = ir[31:28];
    assign sbit  = ir[27];
    assign cls   = ir[26:25];
    assign op4   = ir[24:21];
    assign rd    = ir[20:17];
    assign rn    = ir[16:13];
    assign rm    = ir[12:9];
    assign shtyp = ir[8:7];
    assign shamt = ir[6:2];
    assign imm8  = ir[12:5];
    assign imm17 = ir[16:0];

    assign is_dp   = cond_pass & (cls[1] == 1'b0);
    assign is_mem  = cond_pass & (cls == 2'b10);
    assign is_flow = cond_pass & (cls == 2'b11);
    assign is_test = (op4 >= 4'd12);               // CMP CMN TST TEQ
    assign wr_flag = is_dp & (sbit | is_test);

    assign sel_arith = is_dp & ((op4 >= 4'd2 & op4 <= 4'd6) |
                              (op4 == 4'd12) | (op4 == 4'd13)); // SUB..SBC CMP CMN
    assign sel_logic = is_dp & ~sel_arith;
    assign dp_wr = is_dp & ~is_test;

    // ---- flow + memory --------------------------------------------------
    assign is_b    = is_flow & (op4 == 4'd0);
    assign is_bl   = is_flow & (op4 == 4'd1);
    assign is_bx   = is_flow & (op4 == 4'd2);
    assign is_outi = is_flow & (op4 == 4'd3);
    assign is_hlt  = is_flow & (op4 == 4'd4);
    assign is_ldr  = is_mem & ~op4[0];
    assign is_str  = is_mem &  op4[0];
endmodule"""


def shifter_module(n, w):
    s = w - 1
    sh_mod = "sh_n[%d:0]" % (max(0, (w - 1).bit_length() - 1)) if w < 32 else "sh_n"
    guard_le = (w < 32)
    L = []
    L.append(f"// --- {n}_shifter : inline barrel shifter on operand 2 ---")
    L.append( "// (operand-isolated: only live for register-form data processing)")
    L.append(f"module {n}_shifter(")
    L.append(f"    input  wire [{w-1}:0] rmv,")
    L.append( "    input  wire [4:0]  shamt,")
    L.append( "    input  wire [1:0]  shtyp,")
    L.append( "    input  wire        sh_en,")
    L.append( "    input  wire        fC,")
    L.append(f"    output reg  [{w-1}:0] sh_out,")
    L.append( "    output reg         sh_cout")
    L.append(");")
    L.append(f"    wire [{w-1}:0] sh_in = rmv & {{{w}{{sh_en}}}};")
    L.append( "    wire [4:0]  sh_n  = shamt & {5{sh_en}};")
    L.append( "    // rotate uses the amount modulo W; shifts saturate naturally")
    L.append( "    always @(*) begin")
    L.append( "        case (shtyp)")
    L.append( "            2'd0: begin                                     // LSL")
    L.append( "                sh_out  = sh_in << sh_n;")
    if guard_le:
        L.append("                sh_cout = (sh_n == 5'd0) ? fC")
        L.append(f"                        : (sh_n <= 5'd{w}) ? sh_in[{w}-sh_n] : 1'b0;")
    else:
        L.append("                sh_cout = (sh_n == 5'd0) ? fC")
        L.append(f"                        : sh_in[{w}-sh_n];")
    L.append( "            end")
    L.append( "            2'd1: begin                                     // LSR")
    L.append( "                sh_out  = sh_in >> sh_n;")
    if guard_le:
        L.append("                sh_cout = (sh_n == 5'd0) ? fC")
        L.append(f"                        : (sh_n <= 5'd{w}) ? sh_in[sh_n-5'd1] : 1'b0;")
    else:
        L.append("                sh_cout = (sh_n == 5'd0) ? fC")
        L.append("                        : sh_in[sh_n-5'd1];")
    L.append( "            end")
    L.append( "            2'd2: begin                                     // ASR")
    L.append( "                sh_out  = $signed(sh_in) >>> sh_n;")
    if guard_le:
        L.append("                sh_cout = (sh_n == 5'd0) ? fC")
        L.append(f"                        : (sh_n <= 5'd{w}) ? sh_in[sh_n-5'd1] : sh_in[{s}];")
    else:
        L.append("                sh_cout = (sh_n == 5'd0) ? fC")
        L.append("                        : sh_in[sh_n-5'd1];")
    L.append( "            end")
    L.append( "            default: begin                                  // ROR")
    L.append(f"                sh_out  = (sh_in >> {sh_mod}) | (sh_in << ({w} - {sh_mod}));")
    L.append(f"                sh_cout = (sh_n == 5'd0) ? fC : sh_out[{s}];")
    L.append( "            end")
    L.append( "        endcase")
    L.append( "    end")
    L.append( "endmodule")
    return "\n".join(L)


def alu_arith_module(n, w):
    s = w - 1
    return f"""\
// --- {n}_alu_arith : unified A+B+cin adder, ARM C/V convention ---
// (leaf of {n}_alu)
module {n}_alu_arith(
    input  wire [{w-1}:0] aa,
    input  wire [{w-1}:0] ab,
    input  wire [3:0]  op4,
    input  wire        fC,
    output wire [{w-1}:0] ar_y,
    output wire        ar_c,
    output wire        ar_v
);
    // unified adder: A + B + cin with operand inversion per op
    //   ADD: A=rn  B=op2  cin=0      ADC: cin=C
    //   SUB/CMP: B=~op2 cin=1        SBC: B=~op2 cin=C
    //   RSB: A=~rn B=op2 cin=1       CMN: like ADD
    wire inv_a = (op4 == 4'd3);                       // RSB
    wire inv_b = (op4 == 4'd2) | (op4 == 4'd6) | (op4 == 4'd12); // SUB SBC CMP
    wire cin   = (op4 == 4'd2) | (op4 == 4'd3) | (op4 == 4'd12) ? 1'b1
               : (op4 == 4'd5) | (op4 == 4'd6)                  ? fC
               : 1'b0;
    wire [{w-1}:0] adA = inv_a ? ~aa : aa;
    wire [{w-1}:0] adB = inv_b ? ~ab : ab;
    wire [{w}:0] adS = {{1'b0, adA}} + {{1'b0, adB}} + {{{{{w}{{1'b0}}}}, cin}};
    assign ar_y = adS[{w-1}:0];
    assign ar_c = adS[{w}];                 // ARM: C = NOT borrow on subtract
    assign ar_v = (adA[{s}] == adB[{s}]) & (ar_y[{s}] != adA[{s}]);
endmodule"""


def alu_logic_module(n, w):
    return f"""\
// --- {n}_alu_logic : AND/EOR/ORR/MOV/MVN/BIC + TST/TEQ (leaf of {n}_alu) ---
module {n}_alu_logic(
    input  wire [{w-1}:0] la,
    input  wire [{w-1}:0] lb,
    input  wire [3:0]  op4,
    output reg  [{w-1}:0] lg_y
);
    always @(*) begin case (op4)
        4'd0, 4'd14: lg_y = la & lb;        // AND TST
        4'd1, 4'd15: lg_y = la ^ lb;        // EOR TEQ
        4'd7:        lg_y = la | lb;        // ORR
        4'd9:        lg_y = ~lb;            // MVN
        4'd10:       lg_y = la & ~lb;       // BIC
        default:     lg_y = lb;             // MOV (8, 11)
    endcase end
endmodule"""


def alu_module(n, w):
    return f"""\
// --- {n}_alu : data-processing ALU (operand-isolated arith + logic) ---
module {n}_alu(
    input  wire [{w-1}:0] rnv,
    input  wire [{w-1}:0] op2,
    input  wire [3:0]  op4,
    input  wire        fC,
    input  wire        sel_arith,
    input  wire        sel_logic,
    output wire [{w-1}:0] dp_y,
    output wire        ar_c,
    output wire        ar_v
);
    wire [{w-1}:0] aa = rnv & {{{w}{{sel_arith}}}};
    wire [{w-1}:0] ab = op2 & {{{w}{{sel_arith}}}};
    wire [{w-1}:0] ar_y;
    {n}_alu_arith u_arith(.aa(aa), .ab(ab), .op4(op4), .fC(fC),
                          .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v));

    wire [{w-1}:0] la = rnv & {{{w}{{sel_logic}}}};
    wire [{w-1}:0] lb = op2 & {{{w}{{sel_logic}}}};
    wire [{w-1}:0] lg_y;
    {n}_alu_logic u_logic(.la(la), .lb(lb), .op4(op4), .lg_y(lg_y));

    assign dp_y = sel_arith ? ar_y : lg_y;
endmodule"""


def regfile_module(n, w):
    return f"""\
// --- {n}_regfile : 16x{w} register file, r14 = LR by convention ---
// single write port: DP result / LDR data / BL link are mutually
// exclusive by instruction class, so one muxed port carries all three.
module {n}_regfile(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  waddr,
    input  wire [{w-1}:0] wdata,
    input  wire [3:0]  rn,
    input  wire [3:0]  rm,
    input  wire [3:0]  rd,
    output wire [{w-1}:0] rnv,
    output wire [{w-1}:0] rmv,
    output wire [{w-1}:0] rdv,
    input  wire [3:0]  dbg_sel,
    output wire [{w-1}:0] dbg_data
);
    reg [{w-1}:0] r [0:15];        // r14 = LR by convention

    assign rnv = r[rn];
    assign rmv = r[rm];
    assign rdv = r[rd];
    assign dbg_data = r[dbg_sel];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) r[waddr] <= wdata;
    end
endmodule"""


def dmem_module(n, w):
    return f"""\
// --- {n}_dmem : 32-word data RAM (sync write, async read) ---
module {n}_dmem(
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  addr,
    input  wire [{w-1}:0] wdata,
    output wire [{w-1}:0] rdata
);
    reg [{w-1}:0] dmem [0:31];

    assign rdata = dmem[addr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dmem[addr] <= wdata;
    end
endmodule"""


def flags_module(n, w):
    s = w - 1
    return f"""\
// --- {n}_flags : NZCV status register (ARM S-bit semantics) ---
module {n}_flags(
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [{w-1}:0] dp_y,
    input  wire        sel_arith,
    input  wire        ar_c,
    input  wire        ar_v,
    input  wire [1:0]  cls,
    input  wire        sh_cout,
    output reg         fN,
    output reg         fZ,
    output reg         fC,
    output reg         fV
);
    always @(posedge clk) begin
        if (rst) begin
            fN <= 1'b0; fZ <= 1'b0; fC <= 1'b0; fV <= 1'b0;
        end else if (we) begin
            fN <= dp_y[{s}];
            fZ <= (dp_y == {{{w}{{1'b0}}}});
            if (sel_arith) begin fC <= ar_c; fV <= ar_v; end
            else if (cls == 2'b00) fC <= sh_cout;   // logical: shifter carry
        end
    end
endmodule"""


def gen(w):
    name = f"cpu_arm{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit ARM-FLAVOURED CPU: full conditional execution (NZCV),",
        "3-operand data processing, inline barrel shifter on operand 2,",
        "S-bit flag writes, ARM carry convention (SUB sets C = no-borrow),",
        "BL/BX subroutine linkage through r14. 32-bit Harvard instructions",
        "on imem_*; 32-word data RAM. See docs/cpus.md for the encoding.",
        "MODULAR: cond / decode / shifter / ALU(arith+logic) / regfile /",
        "dmem / flags submodules give a DigitalJS-style drillable hierarchy.",
    ])

    ports = f"""module {name}(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [31:0] imem_data,
    // OUT instruction port
    output reg  [{w-1}:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    input  wire [3:0]  dbg_sel,
    output wire [{w-1}:0]  dbg_data,
    output wire [7:0]  dbg_pc
);
"""
    defs = define_line([
        ("clk", "input", "clk"), ("rst", "input", "rst"),
        ("imem_addr", "output", "imem_addr"), ("imem_data", "input", "imem_data"),
        ("out_data", "output", "out_data"), ("out_valid", "output", "out_valid"),
        ("halted", "output", "halted"),
        ("dbg_sel", "input", "dbg_sel"), ("dbg_data", "output", "dbg_data"),
        ("dbg_pc", "output", "dbg_pc"),
    ])

    mods = [cond_module(name), decode_module(name), shifter_module(name, w),
            alu_arith_module(name, w), alu_logic_module(name, w),
            alu_module(name, w), regfile_module(name, w),
            dmem_module(name, w), flags_module(name, w)]

    B = []
    B.append("    reg [7:0] pc;")
    B.append("")
    B.append("    // ---- NZCV flags (live in the flags unit below) -------------------")
    B.append("    wire fN, fZ, fC, fV;")
    B.append("")
    B.append("    // ---- decode + condition check ------------------------------------")
    B.append("    wire [3:0]  cond, op4, rd, rn, rm;")
    B.append("    wire        sbit, cond_pass;")
    B.append("    wire [1:0]  cls, shtyp;")
    B.append("    wire [4:0]  shamt;")
    B.append("    wire [7:0]  imm8;")
    B.append("    wire [16:0] imm17;")
    B.append("    wire is_dp, is_mem, is_flow, is_test, wr_flag;")
    B.append("    wire is_b, is_bl, is_bx, is_outi, is_hlt, is_ldr, is_str;")
    B.append("    wire sel_arith, sel_logic, dp_wr;")
    B.append(f"    {name}_cond u_cond(")
    B.append("        .cond(cond), .fN(fN), .fZ(fZ), .fC(fC), .fV(fV),")
    B.append("        .cond_pass(cond_pass)")
    B.append("    );")
    B.append(f"    {name}_decode u_decode(")
    B.append("        .ir(imem_data), .cond_pass(cond_pass),")
    B.append("        .cond(cond), .sbit(sbit), .cls(cls), .op4(op4),")
    B.append("        .rd(rd), .rn(rn), .rm(rm),")
    B.append("        .shtyp(shtyp), .shamt(shamt), .imm8(imm8), .imm17(imm17),")
    B.append("        .is_dp(is_dp), .is_mem(is_mem), .is_flow(is_flow),")
    B.append("        .is_test(is_test), .wr_flag(wr_flag),")
    B.append("        .is_b(is_b), .is_bl(is_bl), .is_bx(is_bx),")
    B.append("        .is_outi(is_outi), .is_hlt(is_hlt),")
    B.append("        .is_ldr(is_ldr), .is_str(is_str),")
    B.append("        .sel_arith(sel_arith), .sel_logic(sel_logic),")
    B.append("        .dp_wr(dp_wr)")
    B.append("    );")
    B.append("")
    B.append("    // write gating: identical condition to the old monolithic block")
    B.append("    // (writes happened only in the `else if (!halted)` branch).")
    B.append("    wire wr_gate = ~rst & ~halted;")
    B.append("")
    B.append("    // ---- register file (single muxed write port) ---------------------")
    B.append(f"    wire [{w-1}:0] rnv, rmv, rdv, dmem_rd, dp_y;")
    if w > 8:
        B.append(f"    wire [{w-1}:0] linkv = {{{{{w-8}{{1'b0}}}}, pc1}};   // BL: r14 <= pc+1")
    else:
        B.append(f"    wire [{w-1}:0] linkv = pc1[{w-1}:0];   // BL: r14 <= pc+1")
    B.append("    wire rf_we = wr_gate & (dp_wr | is_ldr | is_bl);")
    B.append("    wire [3:0] rf_waddr = is_bl ? 4'd14 : rd;")
    B.append(f"    wire [{w-1}:0] rf_wdata = is_bl  ? linkv")
    B.append("                          : is_ldr ? dmem_rd")
    B.append("                          :          dp_y;")
    B.append(f"    {name}_regfile u_regfile(")
    B.append("        .clk(clk),")
    B.append("        .we(rf_we), .waddr(rf_waddr), .wdata(rf_wdata),")
    B.append("        .rn(rn), .rm(rm), .rd(rd),")
    B.append("        .rnv(rnv), .rmv(rmv), .rdv(rdv),")
    B.append("        .dbg_sel(dbg_sel), .dbg_data(dbg_data)")
    B.append("    );")
    B.append("")
    B.append("    // ---- barrel shifter on operand 2 ---------------------------------")
    B.append("    wire sh_en = is_dp & (cls == 2'b00);")
    B.append(f"    wire [{w-1}:0] sh_out;")
    B.append("    wire sh_cout;")
    B.append(f"    {name}_shifter u_shifter(")
    B.append("        .rmv(rmv), .shamt(shamt), .shtyp(shtyp),")
    B.append("        .sh_en(sh_en), .fC(fC),")
    B.append("        .sh_out(sh_out), .sh_cout(sh_cout)")
    B.append("    );")
    B.append("")
    B.append("    // operand 2: shifted register (cls 00) or zero-extended imm8 (cls 01)")
    B.append(f"    wire [{w-1}:0] imm8w = " + (f"{{{{{w-8}{{1'b0}}}}, imm8}};" if w > 8 else f"imm8[{w-1}:0];"))
    B.append(f"    wire [{w-1}:0] op2 = (cls == 2'b00) ? sh_out : imm8w;")
    B.append("")
    B.append("    // ---- data-processing ALU (arith + logic paths inside) ------------")
    B.append("    wire ar_c, ar_v;")
    B.append(f"    {name}_alu u_alu(")
    B.append("        .rnv(rnv), .op2(op2), .op4(op4), .fC(fC),")
    B.append("        .sel_arith(sel_arith), .sel_logic(sel_logic),")
    B.append("        .dp_y(dp_y), .ar_c(ar_c), .ar_v(ar_v)")
    B.append("    );")
    B.append("")
    B.append("    // ---- data RAM -----------------------------------------------------")
    B.append("    wire [4:0] mem_a = rnv[4:0] + imm8[4:0];")
    B.append(f"    {name}_dmem u_dmem(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & is_str),")
    B.append("        .addr(mem_a), .wdata(rdv),")
    B.append("        .rdata(dmem_rd)")
    B.append("    );")
    B.append("")
    B.append("    // ---- NZCV flags unit ----------------------------------------------")
    B.append(f"    {name}_flags u_flags(")
    B.append("        .clk(clk), .rst(rst),")
    B.append("        .we(wr_gate & wr_flag),")
    B.append("        .dp_y(dp_y), .sel_arith(sel_arith),")
    B.append("        .ar_c(ar_c), .ar_v(ar_v),")
    B.append("        .cls(cls), .sh_cout(sh_cout),")
    B.append("        .fN(fN), .fZ(fZ), .fC(fC), .fV(fV)")
    B.append("    );")
    B.append("")
    B.append("    wire [7:0] btgt  = pc + imm17[7:0];         // relative, word units")
    B.append("    wire [7:0] pc1   = pc + 8'd1;")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append("")
    B.append("    // sequencing: identical to the monolithic core; the regfile, dmem")
    B.append("    // and flag writes moved into their modules with the same conditions.")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append("            pc <= 8'd0; halted <= 1'b0;")
    B.append(f"            out_data <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            pc <= (is_b | is_bl) ? btgt")
    B.append("                : is_bx          ? " + ("rnv[7:0]" if w >= 8 else "{4'd0, rnv}"))
    B.append("                : is_hlt         ? pc")
    B.append("                :                  pc1;")
    B.append("            if (is_outi) begin out_data <= rnv; out_valid <= 1'b1; end")
    B.append("            if (is_hlt)  halted <= 1'b1;")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    text = (hdr + "\n" + "\n\n".join(mods) + "\n\n"
            + ports + defs + "\n" + "\n".join(B) + "\n")
    write(os.path.join(OUT, name + ".v"), text)


for w in CPU_WIDTHS:
    gen(w)
print("CPUs: ARM-flavoured family generated (modular)")
