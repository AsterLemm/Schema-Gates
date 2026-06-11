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
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def clog2(n):
    b = 0
    while (1 << b) < n:
        b += 1
    return b


# --------------------------------------------------------------------------
# shared ISA snippets
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


def alu_block(w, gate_prefix, a, b, sh_b, funct, lsel="lsel", indent="    "):
    """Emit the operand-isolated 4-path ALU (flagship technique)."""
    sh = clog2(w)
    L = []
    p = indent
    L.append(p + "// ---- ALU, operand-isolated per path (flagship technique) ---------")
    L.append(p + "// gate_X low -> that path's operands are forced to zero, so its")
    L.append(p + "// internal logic does not toggle while another path computes.")
    L.append(p + f"wire [{w-1}:0] add_a = {a} & {{{w}{{{gate_prefix}add}}}};")
    L.append(p + f"wire [{w-1}:0] add_b = {b} & {{{w}{{{gate_prefix}add}}}};")
    L.append(p + f"wire           add_sub_en = ({funct} == 4'd1);   // R-type SUB")
    L.append(p + f"wire [{w-1}:0] add_y = add_sub_en ? (add_a - add_b) : (add_a + add_b);")
    L.append(p + "")
    L.append(p + f"wire [{w-1}:0] log_a = {a} & {{{w}{{{gate_prefix}logic}}}};")
    L.append(p + f"wire [{w-1}:0] log_b = {b} & {{{w}{{{gate_prefix}logic}}}};")
    L.append(p + f"wire [{w-1}:0] log_y = ({lsel} == 2'd0) ? (log_a & log_b)")
    L.append(p + f"                     : ({lsel} == 2'd1) ? (log_a | log_b)")
    L.append(p + "                     :                  (log_a ^ log_b);")
    L.append(p + "")
    L.append(p + f"wire [{w-1}:0] shf_a = {a} & {{{w}{{{gate_prefix}shift}}}};")
    L.append(p + f"wire [{sh-1}:0] shf_n = {sh_b}[{sh-1}:0] & {{{sh}{{{gate_prefix}shift}}}};")
    L.append(p + "// SRA on its own signed wire: inside a ?: chain with unsigned")
    L.append(p + "// branches, >>> would silently degrade to a logical shift")
    L.append(p + f"wire signed [{w-1}:0] shf_as  = $signed(shf_a);")
    L.append(p + f"wire        [{w-1}:0] shf_sra = shf_as >>> shf_n;")
    L.append(p + f"wire [{w-1}:0] shf_y = ({funct} == 4'd5) ? (shf_a <<  shf_n)")
    L.append(p + f"                     : ({funct} == 4'd6) ? (shf_a >>  shf_n)")
    L.append(p + "                     :                  shf_sra;")
    L.append(p + "")
    L.append(p + f"wire [{w-1}:0] cmp_a = {a} & {{{w}{{{gate_prefix}cmp}}}};")
    L.append(p + f"wire [{w-1}:0] cmp_b = {b} & {{{w}{{{gate_prefix}cmp}}}};")
    L.append(p + f"wire           cmp_lt = ({funct} == 4'd8)")
    L.append(p + "                      ? ($signed(cmp_a) < $signed(cmp_b))")
    L.append(p + "                      : (cmp_a < cmp_b);")
    L.append(p + f"wire [{w-1}:0] cmp_y = {{{{{w-1}{{1'b0}}}}, cmp_lt}};")
    L.append(p + "")
    L.append(p + "// path merge: one-hot by construction (decoder-style front mux)")
    L.append(p + f"wire [{w-1}:0] alu_y = (add_y & {{{w}{{{gate_prefix}add}}}})")
    L.append(p + f"                     | (log_y & {{{w}{{{gate_prefix}logic}}}})")
    L.append(p + f"                     | (shf_y & {{{w}{{{gate_prefix}shift}}}})")
    L.append(p + f"                     | (cmp_y & {{{w}{{{gate_prefix}cmp}}}});")
    return "\n".join(L)


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


# --------------------------------------------------------------------------
# single-cycle core
# --------------------------------------------------------------------------

def gen_single(w):
    name = f"cpu_riscv{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit RV-LITE single-cycle CPU (RISC-V-flavoured load/store ISA).",
        "16 registers (x0=0), Harvard: 32-bit instructions on imem_* ports,",
        "16-word internal data RAM. ALU uses flagship operand isolation",
        "(sel_* gated inputs). See docs/cpus.md for the full encoding.",
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

    B = []
    B.append("    reg [7:0] pc;")
    B.append(f"    reg [{w-1}:0] x [0:15];        // x0 reads as zero")
    B.append(f"    reg [{w-1}:0] dmem [0:15];")
    B.append("")
    B.append(DECODE_FIELDS.format(i="imem_data").rstrip())
    B.append("")
    B.append(imm_value(w))
    B.append("")
    B.append(CLASS_DECODE.rstrip())
    B.append("")
    B.append(f"    wire [{w-1}:0] rs1v = (rs1 == 4'd0) ? {{{w}{{1'b0}}}} : x[rs1];")
    B.append(f"    wire [{w-1}:0] rs2v = (rs2 == 4'd0) ? {{{w}{{1'b0}}}} : x[rs2];")
    B.append("")
    B.append("    // single-cycle core: the path selects ARE the gates")
    B.append("    wire gate_add   = sel_add;")
    B.append("    wire gate_logic = sel_logic;")
    B.append("    wire gate_shift = sel_shift;")
    B.append("    wire gate_cmp   = sel_cmp;")
    B.append("")
    B.append(f"    wire [{w-1}:0] alu_b = is_alur ? rs2v : immv;")
    B.append("")
    B.append(alu_block(w, "gate_", "rs1v", "alu_b", "rs2v", "funct"))
    B.append("")
    B.append("    // ---- branch comparator (separately gated, flagship style) ---------")
    B.append(f"    wire [{w-1}:0] bcm_a = rs1v & {{{w}{{is_branch}}}};")
    B.append(f"    wire [{w-1}:0] bcm_b = rs2v & {{{w}{{is_branch}}}};")
    B.append("    wire beq  = (bcm_a == bcm_b);")
    B.append("    wire blt  = ($signed(bcm_a) < $signed(bcm_b));")
    B.append("    wire btaken = is_branch & ( (op == 4'h8) ?  beq")
    B.append("                              : (op == 4'h9) ? ~beq")
    B.append("                              : (op == 4'hA) ?  blt")
    B.append("                              :                ~blt );   // BGE")
    B.append("")
    B.append("    wire [7:0] pc1     = pc + 8'd1;")
    B.append("    wire [7:0] pc_imm  = pc + imm16[7:0];           // word offset")
    B.append("    wire [7:0] jalr_t  = alu_y[7:0];                // rs1 + imm")
    B.append("    wire [7:0] next_pc = (btaken | is_jal) ? pc_imm")
    B.append("                       : is_jalr           ? jalr_t")
    B.append("                       : is_halt           ? pc")
    B.append("                       :                     pc1;")
    B.append("")
    B.append(f"    wire [{w-1}:0] load_v = dmem[alu_y[3:0]];")
    if w > 8:
        B.append(f"    wire [{w-1}:0] pcret  = {{{{{w-8}{{1'b0}}}}, pc1}};")
    else:
        B.append(f"    wire [{w-1}:0] pcret  = pc1[{w-1}:0];")
    B.append(f"    wire [{w-1}:0] wb_val = is_lui          ? {lui_value(w)}")
    B.append("                          : is_load          ? load_v")
    B.append("                          : (is_jal|is_jalr) ? pcret")
    B.append("                          :                    alu_y;")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append(f"    assign dbg_data  = (dbg_sel == 4'd0) ? {{{w}{{1'b0}}}} : x[dbg_sel];")
    B.append("")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append(f"            pc <= 8'd0; halted <= 1'b0; out_data <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            pc <= next_pc;")
    B.append("            if (reg_write && rd != 4'd0) x[rd] <= wb_val;")
    B.append("            if (is_store) dmem[alu_y[3:0]] <= rs2v;")
    B.append("            if (is_out) begin out_data <= rs1v; out_valid <= 1'b1; end")
    B.append("            if (is_halt) halted <= 1'b1;")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    write(os.path.join(OUT, name + ".v"),
          hdr + "\n" + ports + defs + "\n" + "\n".join(B) + "\n")


# --------------------------------------------------------------------------
# 5-stage pipelined core
# --------------------------------------------------------------------------

def gen_pipelined(w):
    name = f"cpu_riscv_pipelined{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit RV-LITE 5-STAGE PIPELINED CPU (IF / ID / EX / MEM / WB).",
        "Same ISA as cpu_riscv* (programs port over unchanged). Features:",
        "EX forwarding from EX/MEM + MEM/WB, one-cycle load-use interlock,",
        "branch/jump resolution in EX with a two-slot flush, in-order HALT",
        "drain. ppln_* pins are PIPELINE SYNCHRONIZER strobes (flagship",
        "operand isolation): gate_X = ppln_X & sel_X; drive high to run.",
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
    B.append(f"    reg [{w-1}:0] x [0:15];")
    B.append("")
    B.append(DECODE_FIELDS.format(i="ifid_ir").rstrip())
    B.append("")
    B.append(imm_value(w))
    B.append("")
    B.append(CLASS_DECODE.rstrip())
    B.append("")
    B.append("    // MEM/WB write-back (declared early: ID reads the file it writes)")
    B.append("    reg         memwb_v, memwb_rw;")
    B.append("    reg  [3:0]  memwb_rd;")
    B.append(f"    reg [{w-1}:0] memwb_val;")
    B.append("")
    B.append("    // transparent regfile: WB value bypasses to ID in the same cycle")
    B.append(f"    wire [{w-1}:0] rf1 = (rs1 == 4'd0) ? {{{w}{{1'b0}}}}")
    B.append("                      : (memwb_v && memwb_rw && memwb_rd == rs1) ? memwb_val")
    B.append("                      : x[rs1];")
    B.append(f"    wire [{w-1}:0] rf2 = (rs2 == 4'd0) ? {{{w}{{1'b0}}}}")
    B.append("                      : (memwb_v && memwb_rw && memwb_rd == rs2) ? memwb_val")
    B.append("                      : x[rs2];")
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
    B.append("    // forwarding unit: newest result wins (EX/MEM over MEM/WB)")
    B.append(f"    wire [{w-1}:0] fwd1 = (exmem_v && exmem_rw && exmem_rd != 4'd0")
    B.append("                        && exmem_rd == idex_rs1) ? exmem_val")
    B.append("                      : (memwb_v && memwb_rw && memwb_rd != 4'd0")
    B.append("                        && memwb_rd == idex_rs1) ? memwb_val")
    B.append("                      : idex_rs1v;")
    B.append(f"    wire [{w-1}:0] fwd2 = (exmem_v && exmem_rw && exmem_rd != 4'd0")
    B.append("                        && exmem_rd == idex_rs2) ? exmem_val")
    B.append("                      : (memwb_v && memwb_rw && memwb_rd != 4'd0")
    B.append("                        && memwb_rd == idex_rs2) ? memwb_val")
    B.append("                      : idex_rs2v;")
    B.append("")
    B.append("    // pipeline synchronizer gating: external strobe AND internal select")
    B.append("    wire gate_add   = ppln_add   & idex_sadd  & idex_v;")
    B.append("    wire gate_logic = ppln_logic & idex_slog  & idex_v;")
    B.append("    wire gate_shift = ppln_shift & idex_sshf  & idex_v;")
    B.append("    wire gate_cmp   = ppln_cmp   & idex_scmp  & idex_v;")
    B.append("")
    B.append(f"    wire [{w-1}:0] ex_b = idex_alur ? fwd2 : idex_imm;")
    B.append("")
    B.append(alu_block(w, "gate_", "fwd1", "ex_b", "fwd2", "idex_funct",
                       lsel="idex_lsel"))
    B.append("")
    B.append("    // branch comparator -- gated like the flagship Branch_Unit")
    B.append("    wire gate_bcmp = idex_branch & idex_v;")
    B.append(f"    wire [{w-1}:0] bcm_a = fwd1 & {{{w}{{gate_bcmp}}}};")
    B.append(f"    wire [{w-1}:0] bcm_b = fwd2 & {{{w}{{gate_bcmp}}}};")
    B.append("    wire beq = (bcm_a == bcm_b);")
    B.append("    wire blt = ($signed(bcm_a) < $signed(bcm_b));")
    B.append("    wire btaken = gate_bcmp & ( (idex_op == 4'h8) ?  beq")
    B.append("                              : (idex_op == 4'h9) ? ~beq")
    B.append("                              : (idex_op == 4'hA) ?  blt")
    B.append("                              :                    ~blt );")
    B.append("")
    B.append("    wire [7:0] ex_pc1   = idex_pc + 8'd1;")
    B.append("    wire [7:0] ex_pcimm = idex_pc + idex_imm16[7:0];")
    B.append("    assign redirect    = idex_v & (btaken | idex_jal | idex_jalr | idex_halt);")
    B.append("    assign redirect_pc = idex_halt ? idex_pc")
    B.append("                       : idex_jalr ? alu_y[7:0]")
    B.append("                       :             ex_pcimm;")
    B.append("")
    if w > 8:
        B.append(f"    wire [{w-1}:0] ex_pcret = {{{{{w-8}{{1'b0}}}}, ex_pc1}};")
    else:
        B.append(f"    wire [{w-1}:0] ex_pcret = ex_pc1[{w-1}:0];")
    B.append(f"    wire [{w-1}:0] ex_wbv = idex_lui              ? {lui_value(w).replace('imm16','idex_imm16')}")
    B.append("                          : (idex_jal | idex_jalr) ? ex_pcret")
    B.append("                          : idex_outi              ? fwd1")
    B.append("                          :                          alu_y;")
    B.append("")
    B.append("    // load-use interlock: the ID instruction may need a value the load")
    B.append("    // in EX has not produced yet -> hold IF/ID one cycle, bubble EX.")
    B.append("    // (conservative: any rd/rs match stalls; no per-class read masks)")
    B.append("    assign stall = idex_v & idex_load & ifid_v & (idex_rd != 4'd0)")
    B.append("                 & ((idex_rd == rs1) | (idex_rd == rs2));")
    B.append("")
    B.append("    // =================================================================")
    B.append("    //  MEM  --  data RAM access, OUT port")
    B.append("    // =================================================================")
    B.append(f"    reg [{w-1}:0] dmem [0:15];")
    B.append(f"    wire [{w-1}:0] mem_rd = dmem[exmem_val[3:0]];")
    B.append("")
    B.append("    // =================================================================")
    B.append("    //  WB  --  register write (transparent: see rf1/rf2 bypass in ID)")
    B.append("    // =================================================================")
    B.append(f"    assign dbg_data = (dbg_sel == 4'd0) ? {{{w}{{1'b0}}}} : x[dbg_sel];")
    B.append("")
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
    B.append("            if (exmem_v & exmem_store) dmem[exmem_val[3:0]] <= exmem_sval;")
    B.append("            if (exmem_v & exmem_outi) begin")
    B.append("                out_data <= exmem_val; out_valid <= 1'b1;")
    B.append("            end")
    B.append("            memwb_v    <= exmem_v;")
    B.append("            memwb_rw   <= exmem_rw;")
    B.append("            memwb_rd   <= exmem_rd;")
    B.append("            memwb_val  <= exmem_load ? mem_rd : exmem_val;")
    B.append("            memwb_halt <= exmem_halt & exmem_v;")
    B.append("            // ---------------- WB ----------------")
    B.append("            if (memwb_v && memwb_rw && memwb_rd != 4'd0)")
    B.append("                x[memwb_rd] <= memwb_val;")
    B.append("            if (memwb_v && memwb_halt) halted <= 1'b1;   // in-order retire")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    write(os.path.join(OUT, name + ".v"),
          hdr + "\n" + ports + defs + "\n" + "\n".join(B) + "\n")


for w in CPU_WIDTHS:
    gen_single(w)
    gen_pipelined(w)
print("CPUs: RV-lite single-cycle + 5-stage pipelined families generated")
