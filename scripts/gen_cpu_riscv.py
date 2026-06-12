"""
gen_cpu_riscv.py  ->  src/CPUs/cpu_riscv{4,8,16,32,64}.v
                      src/CPUs/cpu_riscv_pipelined{4,8,16,32,64}.v

RV-LITE: a RISC-V-flavoured load/store register machine. 16 registers
(x0 hardwired to zero), fixed 32-bit Harvard instructions, data width W.
The encoding is a teaching simplification (uniform fields, no compressed
formats); the ratified RV32IM encoding lives in the flagship
RV32IM_SYSTEM.v next to these files.

INSTRUCTION WORD  [31:28]=op  [27:24]=rd  [23:20]=rs1  [19:16]=rs2  [15:0]=imm16
  imm value = sign-extended imm16, truncated/extended to W bits.

  op 0  ALU-R  funct=imm[3:0]: 0 ADD 1 SUB 2 AND 3 OR 4 XOR
                               5 SLL 6 SRL 7 SRA 8 SLT 9 SLTU  (shamt = rs2)
  op 1  ADDI   2 ANDI   3 ORI   4 XORI
  op 5  LUI    rd = imm16 placed in the TOP 16 bits (W>=16), else imm[W-1:0]
  op 6  LW     rd = dmem[(rs1+imm)[3:0]]          (16-word data RAM)
  op 7  SW     dmem[(rs1+imm)[3:0]] = rs2
  op 8  BEQ    9 BNE   A BLT(signed)   B BGE(signed)   target = pc + imm
  op C  JAL    rd = pc+1 ; pc = pc + imm
  op D  JALR   rd = pc+1 ; pc = (rs1 + imm)[7:0]
  op E  OUT    out_data <= rs1 (one-cycle out_valid pulse)
  op F  HALT

Both cores use the flagship OPERAND-ISOLATION technique: every ALU path's
inputs are ANDed with a select line so an unused path's gates hold zero.
The pipelined core additionally exposes the gates as PIPELINE SYNCHRONIZER
pins (ppln_add / ppln_logic / ppln_shift / ppln_cmp - drive high for
normal run), exactly as in RV32IM_SYSTEM.v.

cpu_riscv_pipelined* is a classic 5-stage IF/ID/EX/MEM/WB pipeline with
  * full EX forwarding from EX/MEM and MEM/WB,
  * a one-cycle load-use interlock (conservative: stalls on any rd match),
  * branch/jump resolution in EX with a two-slot flush,
  * in-order HALT retirement (fetch stops, pipeline drains, halted goes high).

MODULAR EMISSION (DigitalJS-style hierarchy): each file embeds named
submodules -- <top>_decode, <top>_regfile, <top>_alu (which itself
instantiates _alu_addsub / _alu_logic / _alu_shift / _alu_cmp leaf paths),
<top>_bru / _bcmp, <top>_dmem, plus pipeline-specific <top>_fwd, _exctl,
_hazard -- so a hierarchy-preserving synthesizer shows drillable blocks
instead of one flat gate sea. Sequencing state (pc, pipeline registers,
halted, out_*) stays in the top module; every expression is carried over
verbatim from the previous monolithic emission, so behaviour is identical.
"""
import os, sys, re
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def clog2(n):
    b = 0
    while (1 << b) < n:
        b += 1
    return b


def to_assigns(txt, names):
    """Convert `wire [...] NAME =` declarations into `assign NAME =` for the
    given names (used when an expression's target becomes an output port).
    Continuation lines are untouched, so multi-line expressions survive."""
    out = txt
    for n in names:
        out = re.sub(
            r"wire(\s+signed)?\s*(\[[^\]]*\]\s*)?\b" + re.escape(n) + r"\s*=",
            "assign " + n + " =", out)
    return out


# --------------------------------------------------------------------------
# shared ISA snippets (carried over verbatim from the monolithic emitter)
# --------------------------------------------------------------------------

def imm_value(w):
    if w == 16:
        return "    wire [15:0] immv = imm16;"
    if w < 16:
        return f"    wire [{w-1}:0] immv = imm16[{w-1}:0];   // low bits of the signed imm16"
    return (f"    wire [{w-1}:0] immv = {{{{{w-16}{{imm16[15]}}}}, imm16}};   // sign-extended")


def lui_value(w):
    if w > 16:
        return f"{{imm16, {{{w-16}{{1'b0}}}}}}"
    if w == 16:
        return "imm16"
    return f"imm16[{w-1}:0]"


DECODE_FIELDS = """\
    wire [3:0]  op    = {i}[31:28];
    wire [3:0]  rd    = {i}[27:24];
    wire [3:0]  rs1   = {i}[23:20];
    wire [3:0]  rs2   = {i}[19:16];
    wire [15:0] imm16 = {i}[15:0];
    wire [3:0]  funct = {i}[3:0];          // ALU-R sub-operation
"""

CLASS_DECODE = """\
    wire is_alur   = (op == 4'h0);
    wire is_addi   = (op == 4'h1);
    wire is_andi   = (op == 4'h2);
    wire is_ori    = (op == 4'h3);
    wire is_xori   = (op == 4'h4);
    wire is_lui    = (op == 4'h5);
    wire is_load   = (op == 4'h6);
    wire is_store  = (op == 4'h7);
    wire is_branch = (op[3:2] == 2'b10);   // 8..B
    wire is_jal    = (op == 4'hC);
    wire is_jalr   = (op == 4'hD);
    wire is_out    = (op == 4'hE);
    wire is_halt   = (op == 4'hF);

    // ALU path selects (decoder-style):
    //   add   : ADD/SUB, ADDI, address generation for LW/SW/JALR
    wire sel_add   = (is_alur & ((funct == 4'd0) | (funct == 4'd1)))
                   | is_addi | is_load | is_store | is_jalr;
    wire sel_logic = (is_alur & (funct >= 4'd2) & (funct <= 4'd4))
                   | is_andi | is_ori | is_xori;
    wire sel_shift = is_alur & (funct >= 4'd5) & (funct <= 4'd7);
    wire sel_cmp   = is_alur & ((funct == 4'd8) | (funct == 4'd9));

    // logic sub-select (shared between R-type and I-type)
    wire [1:0] lsel = is_andi ? 2'd0 : is_ori ? 2'd1 : is_xori ? 2'd2
                    : (funct == 4'd2) ? 2'd0 : (funct == 4'd3) ? 2'd1 : 2'd2;

    wire reg_write = is_alur | is_addi | is_andi | is_ori | is_xori
                   | is_lui | is_load | is_jal | is_jalr;
"""

DECODE_OUTS = ["op", "rd", "rs1", "rs2", "imm16", "funct", "immv",
               "is_alur", "is_addi", "is_andi", "is_ori", "is_xori",
               "is_lui", "is_load", "is_store", "is_branch", "is_jal",
               "is_jalr", "is_out", "is_halt",
               "sel_add", "sel_logic", "sel_shift", "sel_cmp",
               "lsel", "reg_write"]


def decode_module(top, w):
    """<top>_decode : instruction word -> fields, class flags, ALU selects."""
    L = []
    L.append(f"// --- {top}_decode : fields, instruction classes, ALU path selects ---")
    L.append(f"module {top}_decode(")
    L.append( "    input  wire [31:0] ir,")
    L.append( "    output wire [3:0]  op,")
    L.append( "    output wire [3:0]  rd,")
    L.append( "    output wire [3:0]  rs1,")
    L.append( "    output wire [3:0]  rs2,")
    L.append( "    output wire [15:0] imm16,")
    L.append( "    output wire [3:0]  funct,")
    L.append(f"    output wire [{w-1}:0] immv,")
    for f in ["is_alur", "is_addi", "is_andi", "is_ori", "is_xori", "is_lui",
              "is_load", "is_store", "is_branch", "is_jal", "is_jalr",
              "is_out", "is_halt", "sel_add", "sel_logic", "sel_shift",
              "sel_cmp"]:
        L.append(f"    output wire        {f},")
    L.append( "    output wire [1:0]  lsel,")
    L.append( "    output wire        reg_write")
    L.append(");")
    body = (DECODE_FIELDS.format(i="ir").rstrip() + "\n\n"
            + imm_value(w) + "\n\n" + CLASS_DECODE.rstrip())
    L.append(to_assigns(body, DECODE_OUTS))
    L.append("endmodule")
    return "\n".join(L)


# ---- operand-isolated ALU: parent + four leaf path modules ----------------

def alu_path_modules(top, w):
    """The four ALU leaf paths (sub-submodules of <top>_alu)."""
    sh = clog2(w)
    M = []

    M.append(f"""\
// --- {top}_alu_addsub : ADD / SUB path (leaf of {top}_alu) ---
module {top}_alu_addsub(
    input  wire [{w-1}:0] a,
    input  wire [{w-1}:0] b,
    input  wire        sub_en,
    output wire [{w-1}:0] y
);
    assign y = sub_en ? (a - b) : (a + b);
endmodule""")

    M.append(f"""\
// --- {top}_alu_logic : AND / OR / XOR path (leaf of {top}_alu) ---
module {top}_alu_logic(
    input  wire [{w-1}:0] a,
    input  wire [{w-1}:0] b,
    input  wire [1:0]  lsel,
    output wire [{w-1}:0] y
);
    assign y = (lsel == 2'd0) ? (a & b)
             : (lsel == 2'd1) ? (a | b)
             :                  (a ^ b);
endmodule""")

    M.append(f"""\
// --- {top}_alu_shift : SLL / SRL / SRA path (leaf of {top}_alu) ---
module {top}_alu_shift(
    input  wire [{w-1}:0] a,
    input  wire [{sh-1}:0] n,
    input  wire [3:0]  funct,
    output wire [{w-1}:0] y
);
    // SRA on its own signed wire: inside a ?: chain with unsigned
    // branches, >>> would silently degrade to a logical shift
    wire signed [{w-1}:0] sra_a = $signed(a);
    wire        [{w-1}:0] sra_y = sra_a >>> n;
    assign y = (funct == 4'd5) ? (a <<  n)
             : (funct == 4'd6) ? (a >>  n)
             :                  sra_y;
endmodule""")

    M.append(f"""\
// --- {top}_alu_cmp : SLT / SLTU path (leaf of {top}_alu) ---
module {top}_alu_cmp(
    input  wire [{w-1}:0] a,
    input  wire [{w-1}:0] b,
    input  wire [3:0]  funct,
    output wire [{w-1}:0] y
);
    wire lt = (funct == 4'd8)
            ? ($signed(a) < $signed(b))
            : (a < b);
    assign y = {{{{{w-1}{{1'b0}}}}, lt}};
endmodule""")

    return M


def alu_parent_module(top, w):
    """<top>_alu : operand isolation gating + path mux around the leaves.
    Port names mirror the single-cycle core's signal names; the pipelined
    core wires its own signals onto the same shape."""
    sh = clog2(w)
    return f"""\
// --- {top}_alu : operand-isolated 4-path ALU (flagship technique) ---
// gate_X low -> that path's operands are forced to zero, so its
// internal logic does not toggle while another path computes.
module {top}_alu(
    input  wire [{w-1}:0] rs1v,
    input  wire [{w-1}:0] rs2v,
    input  wire [{w-1}:0] immv,
    input  wire        is_alur,
    input  wire [3:0]  funct,
    input  wire [1:0]  lsel,
    input  wire        gate_add,
    input  wire        gate_logic,
    input  wire        gate_shift,
    input  wire        gate_cmp,
    output wire [{w-1}:0] alu_y
);
    wire [{w-1}:0] alu_b = is_alur ? rs2v : immv;

    wire [{w-1}:0] add_a = rs1v & {{{w}{{gate_add}}}};
    wire [{w-1}:0] add_b = alu_b & {{{w}{{gate_add}}}};
    wire           add_sub_en = (funct == 4'd1);   // R-type SUB
    wire [{w-1}:0] add_y;
    {top}_alu_addsub u_path_add(.a(add_a), .b(add_b), .sub_en(add_sub_en), .y(add_y));

    wire [{w-1}:0] log_a = rs1v & {{{w}{{gate_logic}}}};
    wire [{w-1}:0] log_b = alu_b & {{{w}{{gate_logic}}}};
    wire [{w-1}:0] log_y;
    {top}_alu_logic u_path_log(.a(log_a), .b(log_b), .lsel(lsel), .y(log_y));

    wire [{w-1}:0] shf_a = rs1v & {{{w}{{gate_shift}}}};
    wire [{sh-1}:0] shf_n = rs2v[{sh-1}:0] & {{{sh}{{gate_shift}}}};
    wire [{w-1}:0] shf_y;
    {top}_alu_shift u_path_shf(.a(shf_a), .n(shf_n), .funct(funct), .y(shf_y));

    wire [{w-1}:0] cmp_a = rs1v & {{{w}{{gate_cmp}}}};
    wire [{w-1}:0] cmp_b = alu_b & {{{w}{{gate_cmp}}}};
    wire [{w-1}:0] cmp_y;
    {top}_alu_cmp u_path_cmp(.a(cmp_a), .b(cmp_b), .funct(funct), .y(cmp_y));

    // path merge: one-hot by construction (decoder-style front mux)
    assign alu_y = (add_y & {{{w}{{gate_add}}}})
                 | (log_y & {{{w}{{gate_logic}}}})
                 | (shf_y & {{{w}{{gate_shift}}}})
                 | (cmp_y & {{{w}{{gate_cmp}}}});
endmodule"""


def regfile_module(top, w, transparent):
    """<top>_regfile : 16 x W, x0 hardwired to zero, sync write port.
    transparent=True adds the MEM/WB same-cycle bypass used by the pipeline."""
    L = []
    L.append(f"// --- {top}_regfile : 16x{w} register file, x0 reads as zero ---")
    if transparent:
        L.append("// transparent: the WB value bypasses to the read ports in the")
        L.append("// same cycle (wb_v/wb_rw/wb_rd/wb_val), exactly as before.")
    L.append(f"module {top}_regfile(")
    L.append( "    input  wire        clk,")
    L.append( "    input  wire        we,")
    L.append( "    input  wire [3:0]  waddr,")
    L.append(f"    input  wire [{w-1}:0] wdata,")
    L.append( "    input  wire [3:0]  raddr1,")
    L.append( "    input  wire [3:0]  raddr2,")
    if transparent:
        L.append( "    input  wire        wb_v,")
        L.append( "    input  wire        wb_rw,")
        L.append( "    input  wire [3:0]  wb_rd,")
        L.append(f"    input  wire [{w-1}:0] wb_val,")
    L.append(f"    output wire [{w-1}:0] rdata1,")
    L.append(f"    output wire [{w-1}:0] rdata2,")
    L.append( "    input  wire [3:0]  dbg_sel,")
    L.append(f"    output wire [{w-1}:0] dbg_data")
    L.append(");")
    L.append(f"    reg [{w-1}:0] x [0:15];        // x0 reads as zero")
    L.append("")
    if transparent:
        L.append(f"    assign rdata1 = (raddr1 == 4'd0) ? {{{w}{{1'b0}}}}")
        L.append( "                  : (wb_v && wb_rw && wb_rd == raddr1) ? wb_val")
        L.append( "                  : x[raddr1];")
        L.append(f"    assign rdata2 = (raddr2 == 4'd0) ? {{{w}{{1'b0}}}}")
        L.append( "                  : (wb_v && wb_rw && wb_rd == raddr2) ? wb_val")
        L.append( "                  : x[raddr2];")
    else:
        L.append(f"    assign rdata1 = (raddr1 == 4'd0) ? {{{w}{{1'b0}}}} : x[raddr1];")
        L.append(f"    assign rdata2 = (raddr2 == 4'd0) ? {{{w}{{1'b0}}}} : x[raddr2];")
    L.append(f"    assign dbg_data = (dbg_sel == 4'd0) ? {{{w}{{1'b0}}}} : x[dbg_sel];")
    L.append("")
    L.append("    // sync write only (no async edge: keeps the array ONE $mem cell)")
    L.append("    always @(posedge clk) begin")
    L.append("        if (we && waddr != 4'd0) x[waddr] <= wdata;")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L)


def dmem_module(top, w):
    return f"""\
// --- {top}_dmem : 16-word data RAM (sync write, async read) ---
module {top}_dmem(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  addr,
    input  wire [{w-1}:0] wdata,
    output wire [{w-1}:0] rdata
);
    reg [{w-1}:0] dmem [0:15];

    assign rdata = dmem[addr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dmem[addr] <= wdata;
    end
endmodule"""


# --------------------------------------------------------------------------
# single-cycle core
# --------------------------------------------------------------------------

def bru_module(top, w):
    """<top>_bru : branch comparator + next-PC select (single-cycle)."""
    body = f"""\
    // ---- branch comparator (separately gated, flagship style) ---------
    wire [{w-1}:0] bcm_a = rs1v & {{{w}{{is_branch}}}};
    wire [{w-1}:0] bcm_b = rs2v & {{{w}{{is_branch}}}};
    wire beq  = (bcm_a == bcm_b);
    wire blt  = ($signed(bcm_a) < $signed(bcm_b));
    wire btaken = is_branch & ( (op == 4'h8) ?  beq
                              : (op == 4'h9) ? ~beq
                              : (op == 4'hA) ?  blt
                              :                ~blt );   // BGE

    wire [7:0] pc1     = pc + 8'd1;
    wire [7:0] pc_imm  = pc + imm16[7:0];           // word offset
    wire [7:0] jalr_t  = alu_y[7:0];                // rs1 + imm
    wire [7:0] next_pc = (btaken | is_jal) ? pc_imm
                       : is_jalr           ? jalr_t
                       : is_halt           ? pc
                       :                     pc1;"""
    body = to_assigns(body, ["btaken", "pc1", "next_pc"])
    return f"""\
// --- {top}_bru : branch resolve + next-PC select ---
module {top}_bru(
    input  wire [7:0]  pc,
    input  wire [15:0] imm16,
    input  wire [3:0]  op,
    input  wire        is_branch,
    input  wire        is_jal,
    input  wire        is_jalr,
    input  wire        is_halt,
    input  wire [{w-1}:0] rs1v,
    input  wire [{w-1}:0] rs2v,
    input  wire [{w-1}:0] alu_y,
    output wire        btaken,
    output wire [7:0]  pc1,
    output wire [7:0]  next_pc
);
{body}
endmodule"""


def wbsel_module(top, w):
    if w > 8:
        pcret = f"    wire [{w-1}:0] pcret  = {{{{{w-8}{{1'b0}}}}, pc1}};"
    else:
        pcret = f"    wire [{w-1}:0] pcret  = pc1[{w-1}:0];"
    body = f"""\
{pcret}
    wire [{w-1}:0] wb_val = is_lui          ? {lui_value(w)}
                          : is_load          ? load_v
                          : (is_jal|is_jalr) ? pcret
                          :                    alu_y;"""
    body = to_assigns(body, ["wb_val"])
    return f"""\
// --- {top}_wbsel : write-back value select ---
module {top}_wbsel(
    input  wire        is_lui,
    input  wire        is_load,
    input  wire        is_jal,
    input  wire        is_jalr,
    input  wire [15:0] imm16,
    input  wire [{w-1}:0] load_v,
    input  wire [7:0]  pc1,
    input  wire [{w-1}:0] alu_y,
    output wire [{w-1}:0] wb_val
);
{body}
endmodule"""


def gen_single(w):
    name = f"cpu_riscv{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit RV-LITE single-cycle CPU (RISC-V-flavoured load/store ISA).",
        "16 registers (x0=0), Harvard: 32-bit instructions on imem_* ports,",
        "16-word internal data RAM. ALU uses flagship operand isolation",
        "(sel_* gated inputs). See docs/cpus.md for the full encoding.",
        "MODULAR: decode / regfile / ALU(+4 leaf paths) / bru / wbsel /",
        "dmem submodules give a DigitalJS-style drillable hierarchy.",
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

    # ---- leaf + unit modules (emitted before the top, flagship style) ----
    mods = []
    mods.append(decode_module(name, w))
    mods.append(regfile_module(name, w, transparent=False))
    mods += alu_path_modules(name, w)
    mods.append(alu_parent_module(name, w))
    mods.append(bru_module(name, w))
    mods.append(wbsel_module(name, w))
    mods.append(dmem_module(name, w))

    # ---- top: structural netlist + the original sequencing block --------
    B = []
    B.append("    reg [7:0] pc;")
    B.append("")
    B.append("    // ---- decode ------------------------------------------------------")
    B.append("    wire [3:0]  op, rd, rs1, rs2, funct;")
    B.append("    wire [15:0] imm16;")
    B.append(f"    wire [{w-1}:0] immv;")
    B.append("    wire is_alur, is_addi, is_andi, is_ori, is_xori, is_lui;")
    B.append("    wire is_load, is_store, is_branch, is_jal, is_jalr, is_out, is_halt;")
    B.append("    wire sel_add, sel_logic, sel_shift, sel_cmp;")
    B.append("    wire [1:0] lsel;")
    B.append("    wire reg_write;")
    B.append(f"    {name}_decode u_decode(")
    B.append("        .ir(imem_data),")
    B.append("        .op(op), .rd(rd), .rs1(rs1), .rs2(rs2),")
    B.append("        .imm16(imm16), .funct(funct), .immv(immv),")
    B.append("        .is_alur(is_alur), .is_addi(is_addi), .is_andi(is_andi),")
    B.append("        .is_ori(is_ori), .is_xori(is_xori), .is_lui(is_lui),")
    B.append("        .is_load(is_load), .is_store(is_store), .is_branch(is_branch),")
    B.append("        .is_jal(is_jal), .is_jalr(is_jalr), .is_out(is_out),")
    B.append("        .is_halt(is_halt),")
    B.append("        .sel_add(sel_add), .sel_logic(sel_logic),")
    B.append("        .sel_shift(sel_shift), .sel_cmp(sel_cmp),")
    B.append("        .lsel(lsel), .reg_write(reg_write)")
    B.append("    );")
    B.append("")
    B.append("    // write gating: identical condition to the old monolithic block")
    B.append("    // (writes happened only in the `else if (!halted)` branch).")
    B.append("    wire wr_gate = ~rst & ~halted;")
    B.append("")
    B.append("    // ---- register file ----------------------------------------------")
    B.append(f"    wire [{w-1}:0] rs1v, rs2v, wb_val;")
    B.append(f"    {name}_regfile u_regfile(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & reg_write),")
    B.append("        .waddr(rd), .wdata(wb_val),")
    B.append("        .raddr1(rs1), .raddr2(rs2),")
    B.append("        .rdata1(rs1v), .rdata2(rs2v),")
    B.append("        .dbg_sel(dbg_sel), .dbg_data(dbg_data)")
    B.append("    );")
    B.append("")
    B.append("    // single-cycle core: the path selects ARE the gates")
    B.append("    wire gate_add   = sel_add;")
    B.append("    wire gate_logic = sel_logic;")
    B.append("    wire gate_shift = sel_shift;")
    B.append("    wire gate_cmp   = sel_cmp;")
    B.append("")
    B.append("    // ---- ALU (operand-isolated paths inside) ------------------------")
    B.append(f"    wire [{w-1}:0] alu_y;")
    B.append(f"    {name}_alu u_alu(")
    B.append("        .rs1v(rs1v), .rs2v(rs2v), .immv(immv),")
    B.append("        .is_alur(is_alur), .funct(funct), .lsel(lsel),")
    B.append("        .gate_add(gate_add), .gate_logic(gate_logic),")
    B.append("        .gate_shift(gate_shift), .gate_cmp(gate_cmp),")
    B.append("        .alu_y(alu_y)")
    B.append("    );")
    B.append("")
    B.append("    // ---- branch resolve + next PC -----------------------------------")
    B.append("    wire btaken;")
    B.append("    wire [7:0] pc1, next_pc;")
    B.append(f"    {name}_bru u_bru(")
    B.append("        .pc(pc), .imm16(imm16), .op(op),")
    B.append("        .is_branch(is_branch), .is_jal(is_jal),")
    B.append("        .is_jalr(is_jalr), .is_halt(is_halt),")
    B.append("        .rs1v(rs1v), .rs2v(rs2v), .alu_y(alu_y),")
    B.append("        .btaken(btaken), .pc1(pc1), .next_pc(next_pc)")
    B.append("    );")
    B.append("")
    B.append("    // ---- data RAM ----------------------------------------------------")
    B.append(f"    wire [{w-1}:0] load_v;")
    B.append(f"    {name}_dmem u_dmem(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & is_store),")
    B.append("        .addr(alu_y[3:0]), .wdata(rs2v),")
    B.append("        .rdata(load_v)")
    B.append("    );")
    B.append("")
    B.append("    // ---- write-back select ------------------------------------------")
    B.append(f"    {name}_wbsel u_wbsel(")
    B.append("        .is_lui(is_lui), .is_load(is_load),")
    B.append("        .is_jal(is_jal), .is_jalr(is_jalr),")
    B.append("        .imm16(imm16), .load_v(load_v),")
    B.append("        .pc1(pc1), .alu_y(alu_y),")
    B.append("        .wb_val(wb_val)")
    B.append("    );")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append("")
    B.append("    // sequencing: identical to the monolithic core; the regfile and")
    B.append("    // dmem writes moved into their modules with the same conditions.")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append(f"            pc <= 8'd0; halted <= 1'b0; out_data <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            pc <= next_pc;")
    B.append("            if (is_out) begin out_data <= rs1v; out_valid <= 1'b1; end")
    B.append("            if (is_halt) halted <= 1'b1;")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    text = (hdr + "\n" + "\n\n".join(mods) + "\n\n"
            + ports + defs + "\n" + "\n".join(B) + "\n")
    write(os.path.join(OUT, name + ".v"), text)


# --------------------------------------------------------------------------
# 5-stage pipelined core
# --------------------------------------------------------------------------

def fwd_module(top, w):
    body = f"""\
    // forwarding unit: newest result wins (EX/MEM over MEM/WB)
    wire [{w-1}:0] fwd1 = (exmem_v && exmem_rw && exmem_rd != 4'd0
                        && exmem_rd == idex_rs1) ? exmem_val
                      : (memwb_v && memwb_rw && memwb_rd != 4'd0
                        && memwb_rd == idex_rs1) ? memwb_val
                      : idex_rs1v;
    wire [{w-1}:0] fwd2 = (exmem_v && exmem_rw && exmem_rd != 4'd0
                        && exmem_rd == idex_rs2) ? exmem_val
                      : (memwb_v && memwb_rw && memwb_rd != 4'd0
                        && memwb_rd == idex_rs2) ? memwb_val
                      : idex_rs2v;"""
    body = to_assigns(body, ["fwd1", "fwd2"])
    return f"""\
// --- {top}_fwd : EX forwarding (EX/MEM and MEM/WB sources) ---
module {top}_fwd(
    input  wire [{w-1}:0] idex_rs1v,
    input  wire [{w-1}:0] idex_rs2v,
    input  wire [3:0]  idex_rs1,
    input  wire [3:0]  idex_rs2,
    input  wire        exmem_v,
    input  wire        exmem_rw,
    input  wire [3:0]  exmem_rd,
    input  wire [{w-1}:0] exmem_val,
    input  wire        memwb_v,
    input  wire        memwb_rw,
    input  wire [3:0]  memwb_rd,
    input  wire [{w-1}:0] memwb_val,
    output wire [{w-1}:0] fwd1,
    output wire [{w-1}:0] fwd2
);
{body}
endmodule"""


def bcmp_module(top, w):
    body = f"""\
    // branch comparator -- gated like the flagship Branch_Unit
    wire gate_bcmp = idex_branch & idex_v;
    wire [{w-1}:0] bcm_a = fwd1 & {{{w}{{gate_bcmp}}}};
    wire [{w-1}:0] bcm_b = fwd2 & {{{w}{{gate_bcmp}}}};
    wire beq = (bcm_a == bcm_b);
    wire blt = ($signed(bcm_a) < $signed(bcm_b));
    wire btaken = gate_bcmp & ( (idex_op == 4'h8) ?  beq
                              : (idex_op == 4'h9) ? ~beq
                              : (idex_op == 4'hA) ?  blt
                              :                    ~blt );"""
    body = to_assigns(body, ["btaken"])
    return f"""\
// --- {top}_bcmp : gated branch comparator ---
module {top}_bcmp(
    input  wire [{w-1}:0] fwd1,
    input  wire [{w-1}:0] fwd2,
    input  wire [3:0]  idex_op,
    input  wire        idex_branch,
    input  wire        idex_v,
    output wire        btaken
);
{body}
endmodule"""


def exctl_module(top, w):
    if w > 8:
        pcret = f"    wire [{w-1}:0] ex_pcret = {{{{{w-8}{{1'b0}}}}, ex_pc1}};"
    else:
        pcret = f"    wire [{w-1}:0] ex_pcret = ex_pc1[{w-1}:0];"
    body = f"""\
    wire [7:0] ex_pc1   = idex_pc + 8'd1;
    wire [7:0] ex_pcimm = idex_pc + idex_imm16[7:0];
    assign redirect    = idex_v & (btaken | idex_jal | idex_jalr | idex_halt);
    assign redirect_pc = idex_halt ? idex_pc
                       : idex_jalr ? alu_y[7:0]
                       :             ex_pcimm;

{pcret}
    wire [{w-1}:0] ex_wbv = idex_lui              ? {lui_value(w).replace('imm16','idex_imm16')}
                          : (idex_jal | idex_jalr) ? ex_pcret
                          : idex_outi              ? fwd1
                          :                          alu_y;"""
    body = to_assigns(body, ["ex_wbv"])
    return f"""\
// --- {top}_exctl : branch/jump redirect + WB value select (EX stage) ---
module {top}_exctl(
    input  wire        idex_v,
    input  wire [7:0]  idex_pc,
    input  wire [15:0] idex_imm16,
    input  wire        idex_halt,
    input  wire        idex_jal,
    input  wire        idex_jalr,
    input  wire        idex_lui,
    input  wire        idex_outi,
    input  wire [{w-1}:0] alu_y,
    input  wire        btaken,
    input  wire [{w-1}:0] fwd1,
    output wire        redirect,
    output wire [7:0]  redirect_pc,
    output wire [{w-1}:0] ex_wbv
);
{body}
endmodule"""


def hazard_module(top, w):
    body = """\
    // load-use interlock: the ID instruction may need a value the load
    // in EX has not produced yet -> hold IF/ID one cycle, bubble EX.
    // (conservative: any rd/rs match stalls; no per-class read masks)
    assign stall = idex_v & idex_load & ifid_v & (idex_rd != 4'd0)
                 & ((idex_rd == rs1) | (idex_rd == rs2));"""
    return f"""\
// --- {top}_hazard : load-use interlock detect ---
module {top}_hazard(
    input  wire        idex_v,
    input  wire        idex_load,
    input  wire [3:0]  idex_rd,
    input  wire        ifid_v,
    input  wire [3:0]  rs1,
    input  wire [3:0]  rs2,
    output wire        stall
);
{body}
endmodule"""


def gen_pipelined(w):
    name = f"cpu_riscv_pipelined{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit RV-LITE 5-STAGE PIPELINED CPU (IF / ID / EX / MEM / WB).",
        "Same ISA as cpu_riscv* (programs port over unchanged). Features:",
        "EX forwarding from EX/MEM + MEM/WB, one-cycle load-use interlock,",
        "branch/jump resolution in EX with a two-slot flush, in-order HALT",
        "drain. ppln_* pins are PIPELINE SYNCHRONIZER strobes (flagship",
        "operand isolation): gate_X = ppln_X & sel_X; drive high to run.",
        "MODULAR: decode / regfile / fwd / ALU(+4 leaf paths) / bcmp /",
        "exctl / hazard / dmem submodules; pipeline registers stay in the",
        "top so the sequencing is bit-identical to the monolithic core.",
    ])

    ports = f"""module {name}(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [31:0] imem_data,
    // pipeline synchronizer strobes -- drive high for normal run
    input  wire        ppln_add,
    input  wire        ppln_logic,
    input  wire        ppln_shift,
    input  wire        ppln_cmp,
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
        ("ppln_add", "input", "ppln"), ("ppln_logic", "input", "ppln"),
        ("ppln_shift", "input", "ppln"), ("ppln_cmp", "input", "ppln"),
        ("out_data", "output", "out_data"), ("out_valid", "output", "out_valid"),
        ("halted", "output", "halted"),
        ("dbg_sel", "input", "dbg_sel"), ("dbg_data", "output", "dbg_data"),
        ("dbg_pc", "output", "dbg_pc"),
    ])

    mods = []
    mods.append(decode_module(name, w))
    mods.append(regfile_module(name, w, transparent=True))
    mods.append(fwd_module(name, w))
    mods += alu_path_modules(name, w)
    mods.append(alu_parent_module(name, w))
    mods.append(bcmp_module(name, w))
    mods.append(exctl_module(name, w))
    mods.append(hazard_module(name, w))
    mods.append(dmem_module(name, w))

    B = []
    B.append("    // =================================================================")
    B.append("    //  IF  --  instruction fetch")
    B.append("    // =================================================================")
    B.append("    reg  [7:0]  pc;")
    B.append("    wire        stall;        // load-use interlock (holds IF + ID)")
    B.append("    wire        redirect;     // taken branch / jump / halt (from EX)")
    B.append("    wire [7:0]  redirect_pc;")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append("")
    B.append("    reg  [7:0]  ifid_pc;")
    B.append("    reg  [31:0] ifid_ir;")
    B.append("    reg         ifid_v;")
    B.append("")
    B.append("    // =================================================================")
    B.append("    //  ID  --  decode + register read")
    B.append("    // =================================================================")
    B.append("    wire [3:0]  op, rd, rs1, rs2, funct;")
    B.append("    wire [15:0] imm16;")
    B.append(f"    wire [{w-1}:0] immv;")
    B.append("    wire is_alur, is_addi, is_andi, is_ori, is_xori, is_lui;")
    B.append("    wire is_load, is_store, is_branch, is_jal, is_jalr, is_out, is_halt;")
    B.append("    wire sel_add, sel_logic, sel_shift, sel_cmp;")
    B.append("    wire [1:0] lsel;")
    B.append("    wire reg_write;")
    B.append(f"    {name}_decode u_decode(")
    B.append("        .ir(ifid_ir),")
    B.append("        .op(op), .rd(rd), .rs1(rs1), .rs2(rs2),")
    B.append("        .imm16(imm16), .funct(funct), .immv(immv),")
    B.append("        .is_alur(is_alur), .is_addi(is_addi), .is_andi(is_andi),")
    B.append("        .is_ori(is_ori), .is_xori(is_xori), .is_lui(is_lui),")
    B.append("        .is_load(is_load), .is_store(is_store), .is_branch(is_branch),")
    B.append("        .is_jal(is_jal), .is_jalr(is_jalr), .is_out(is_out),")
    B.append("        .is_halt(is_halt),")
    B.append("        .sel_add(sel_add), .sel_logic(sel_logic),")
    B.append("        .sel_shift(sel_shift), .sel_cmp(sel_cmp),")
    B.append("        .lsel(lsel), .reg_write(reg_write)")
    B.append("    );")
    B.append("")
    B.append("    // MEM/WB write-back (declared early: ID reads the file it writes)")
    B.append("    reg         memwb_v, memwb_rw;")
    B.append("    reg  [3:0]  memwb_rd;")
    B.append(f"    reg [{w-1}:0] memwb_val;")
    B.append("")
    B.append("    // write gating: identical condition to the old monolithic block")
    B.append("    // (writes happened only in the `else if (!halted)` branch).")
    B.append("    wire wr_gate = ~rst & ~halted;")
    B.append("")
    B.append("    // transparent regfile: WB value bypasses to ID in the same cycle")
    B.append(f"    wire [{w-1}:0] rf1, rf2;")
    B.append(f"    {name}_regfile u_regfile(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & memwb_v & memwb_rw),")
    B.append("        .waddr(memwb_rd), .wdata(memwb_val),")
    B.append("        .raddr1(rs1), .raddr2(rs2),")
    B.append("        .wb_v(memwb_v), .wb_rw(memwb_rw),")
    B.append("        .wb_rd(memwb_rd), .wb_val(memwb_val),")
    B.append("        .rdata1(rf1), .rdata2(rf2),")
    B.append("        .dbg_sel(dbg_sel), .dbg_data(dbg_data)")
    B.append("    );")
    B.append("")
    B.append("    // ID/EX pipeline register")
    B.append("    reg         idex_v;")
    B.append("    reg  [7:0]  idex_pc;")
    B.append(f"    reg [{w-1}:0] idex_rs1v, idex_rs2v, idex_imm;")
    B.append("    reg  [3:0]  idex_rd, idex_rs1, idex_rs2, idex_op, idex_funct;")
    B.append("    reg  [1:0]  idex_lsel;")
    B.append("    reg         idex_alur, idex_lui, idex_load, idex_store, idex_branch;")
    B.append("    reg         idex_jal, idex_jalr, idex_outi, idex_halt, idex_rw;")
    B.append("    reg         idex_sadd, idex_slog, idex_sshf, idex_scmp;")
    B.append("    reg  [15:0] idex_imm16;")
    B.append("")
    B.append("    // =================================================================")
    B.append("    //  EX  --  forwarding, operand-isolated ALU, branch resolve")
    B.append("    // =================================================================")
    B.append("    reg         exmem_v, exmem_rw, exmem_load, exmem_store;")
    B.append("    reg         exmem_outi, exmem_halt;")
    B.append("    reg  [3:0]  exmem_rd;")
    B.append(f"    reg [{w-1}:0] exmem_val, exmem_sval;   // ALU/wb value, store data")
    B.append("")
    B.append(f"    wire [{w-1}:0] fwd1, fwd2;")
    B.append(f"    {name}_fwd u_fwd(")
    B.append("        .idex_rs1v(idex_rs1v), .idex_rs2v(idex_rs2v),")
    B.append("        .idex_rs1(idex_rs1), .idex_rs2(idex_rs2),")
    B.append("        .exmem_v(exmem_v), .exmem_rw(exmem_rw),")
    B.append("        .exmem_rd(exmem_rd), .exmem_val(exmem_val),")
    B.append("        .memwb_v(memwb_v), .memwb_rw(memwb_rw),")
    B.append("        .memwb_rd(memwb_rd), .memwb_val(memwb_val),")
    B.append("        .fwd1(fwd1), .fwd2(fwd2)")
    B.append("    );")
    B.append("")
    B.append("    // pipeline synchronizer gating: external strobe AND internal select")
    B.append("    wire gate_add   = ppln_add   & idex_sadd  & idex_v;")
    B.append("    wire gate_logic = ppln_logic & idex_slog  & idex_v;")
    B.append("    wire gate_shift = ppln_shift & idex_sshf  & idex_v;")
    B.append("    wire gate_cmp   = ppln_cmp   & idex_scmp  & idex_v;")
    B.append("")
    B.append("    // ---- ALU (operand-isolated paths inside) ------------------------")
    B.append(f"    wire [{w-1}:0] alu_y;")
    B.append(f"    {name}_alu u_alu(")
    B.append("        .rs1v(fwd1), .rs2v(fwd2), .immv(idex_imm),")
    B.append("        .is_alur(idex_alur), .funct(idex_funct), .lsel(idex_lsel),")
    B.append("        .gate_add(gate_add), .gate_logic(gate_logic),")
    B.append("        .gate_shift(gate_shift), .gate_cmp(gate_cmp),")
    B.append("        .alu_y(alu_y)")
    B.append("    );")
    B.append("")
    B.append("    wire btaken;")
    B.append(f"    {name}_bcmp u_bcmp(")
    B.append("        .fwd1(fwd1), .fwd2(fwd2), .idex_op(idex_op),")
    B.append("        .idex_branch(idex_branch), .idex_v(idex_v),")
    B.append("        .btaken(btaken)")
    B.append("    );")
    B.append("")
    B.append(f"    wire [{w-1}:0] ex_wbv;")
    B.append(f"    {name}_exctl u_exctl(")
    B.append("        .idex_v(idex_v), .idex_pc(idex_pc), .idex_imm16(idex_imm16),")
    B.append("        .idex_halt(idex_halt), .idex_jal(idex_jal),")
    B.append("        .idex_jalr(idex_jalr), .idex_lui(idex_lui),")
    B.append("        .idex_outi(idex_outi),")
    B.append("        .alu_y(alu_y), .btaken(btaken), .fwd1(fwd1),")
    B.append("        .redirect(redirect), .redirect_pc(redirect_pc),")
    B.append("        .ex_wbv(ex_wbv)")
    B.append("    );")
    B.append("")
    B.append(f"    {name}_hazard u_hazard(")
    B.append("        .idex_v(idex_v), .idex_load(idex_load), .idex_rd(idex_rd),")
    B.append("        .ifid_v(ifid_v), .rs1(rs1), .rs2(rs2),")
    B.append("        .stall(stall)")
    B.append("    );")
    B.append("")
    B.append("    // =================================================================")
    B.append("    //  MEM  --  data RAM access, OUT port")
    B.append("    // =================================================================")
    B.append(f"    wire [{w-1}:0] mem_rd;")
    B.append(f"    {name}_dmem u_dmem(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & exmem_v & exmem_store),")
    B.append("        .addr(exmem_val[3:0]), .wdata(exmem_sval),")
    B.append("        .rdata(mem_rd)")
    B.append("    );")
    B.append("")
    B.append("    // =================================================================")
    B.append("    //  WB  --  register write (transparent: see rf1/rf2 bypass in ID)")
    B.append("    // =================================================================")
    B.append("    reg memwb_halt;")
    B.append("")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append("            pc <= 8'd0;")
    B.append("            ifid_v <= 1'b0; idex_v <= 1'b0; exmem_v <= 1'b0; memwb_v <= 1'b0;")
    B.append("            ifid_pc <= 8'd0; ifid_ir <= 32'd0;")
    B.append("            memwb_halt <= 1'b0; halted <= 1'b0;")
    B.append(f"            out_data <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            // ---------------- IF ----------------")
    B.append("            if (redirect) begin")
    B.append("                pc      <= redirect_pc;")
    B.append("                ifid_v  <= 1'b0;                  // flush slot 1")
    B.append("            end else if (!stall) begin")
    B.append("                pc      <= pc + 8'd1;")
    B.append("                ifid_pc <= pc;")
    B.append("                ifid_ir <= imem_data;")
    B.append("                ifid_v  <= 1'b1;")
    B.append("            end")
    B.append("            // ---------------- ID -> ID/EX ----------------")
    B.append("            if (redirect) begin")
    B.append("                idex_v <= 1'b0;                   // flush slot 2")
    B.append("            end else if (stall) begin")
    B.append("                idex_v <= 1'b0;                   // interlock bubble")
    B.append("            end else begin")
    B.append("                idex_v     <= ifid_v;")
    B.append("                idex_pc    <= ifid_pc;")
    B.append("                idex_rs1v  <= rf1;   idex_rs2v <= rf2;   idex_imm <= immv;")
    B.append("                idex_rd    <= rd;    idex_rs1  <= rs1;   idex_rs2 <= rs2;")
    B.append("                idex_op    <= op;    idex_funct <= funct; idex_lsel <= lsel;")
    B.append("                idex_imm16 <= imm16;")
    B.append("                idex_alur  <= is_alur;   idex_lui  <= is_lui;")
    B.append("                idex_load  <= is_load;   idex_store <= is_store;")
    B.append("                idex_branch<= is_branch; idex_jal  <= is_jal;")
    B.append("                idex_jalr  <= is_jalr;   idex_outi <= is_out;")
    B.append("                idex_halt  <= is_halt;   idex_rw   <= reg_write;")
    B.append("                idex_sadd  <= sel_add;   idex_slog <= sel_logic;")
    B.append("                idex_sshf  <= sel_shift; idex_scmp <= sel_cmp;")
    B.append("            end")
    B.append("            // ---------------- EX -> EX/MEM ----------------")
    B.append("            exmem_v    <= idex_v;")
    B.append("            exmem_rw   <= idex_rw   & idex_v;")
    B.append("            exmem_load <= idex_load & idex_v;")
    B.append("            exmem_store<= idex_store& idex_v;")
    B.append("            exmem_outi <= idex_outi & idex_v;")
    B.append("            exmem_halt <= idex_halt & idex_v;")
    B.append("            exmem_rd   <= idex_rd;")
    B.append("            exmem_val  <= ex_wbv;")
    B.append("            exmem_sval <= fwd2;")
    B.append("            // ---------------- MEM -> MEM/WB ----------------")
    B.append("            // (the dmem write itself lives in u_dmem, same condition)")
    B.append("            if (exmem_v & exmem_outi) begin")
    B.append("                out_data <= exmem_val; out_valid <= 1'b1;")
    B.append("            end")
    B.append("            memwb_v    <= exmem_v;")
    B.append("            memwb_rw   <= exmem_rw;")
    B.append("            memwb_rd   <= exmem_rd;")
    B.append("            memwb_val  <= exmem_load ? mem_rd : exmem_val;")
    B.append("            memwb_halt <= exmem_halt & exmem_v;")
    B.append("            // ---------------- WB ----------------")
    B.append("            // (the x[] write itself lives in u_regfile, same condition)")
    B.append("            if (memwb_v && memwb_halt) halted <= 1'b1;   // in-order retire")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    text = (hdr + "\n" + "\n\n".join(mods) + "\n\n"
            + ports + defs + "\n" + "\n".join(B) + "\n")
    write(os.path.join(OUT, name + ".v"), text)


for w in CPU_WIDTHS:
    gen_single(w)
    gen_pipelined(w)
print("CPUs: RV-lite single-cycle + 5-stage pipelined families generated (modular)")
