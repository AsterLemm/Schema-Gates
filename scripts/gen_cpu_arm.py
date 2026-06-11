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
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def gen(w):
    name = f"cpu_arm{w}"
    s = w - 1
    hdr = banner(f"{name}.v", [
        f"{w}-bit ARM-FLAVOURED CPU: full conditional execution (NZCV),",
        "3-operand data processing, inline barrel shifter on operand 2,",
        "S-bit flag writes, ARM carry convention (SUB sets C = no-borrow),",
        "BL/BX subroutine linkage through r14. 32-bit Harvard instructions",
        "on imem_*; 32-word data RAM. See docs/cpus.md for the encoding.",
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
    B.append(f"    reg [{w-1}:0] r [0:15];        // r14 = LR by convention")
    B.append(f"    reg [{w-1}:0] dmem [0:31];")
    B.append("    reg fN, fZ, fC, fV;            // NZCV")
    B.append("")
    B.append("    // ---- field extraction ---------------------------------------------")
    B.append("    wire [3:0] cond  = imem_data[31:28];")
    B.append("    wire       sbit  = imem_data[27];")
    B.append("    wire [1:0] cls   = imem_data[26:25];")
    B.append("    wire [3:0] op4   = imem_data[24:21];")
    B.append("    wire [3:0] rd    = imem_data[20:17];")
    B.append("    wire [3:0] rn    = imem_data[16:13];")
    B.append("    wire [3:0] rm    = imem_data[12:9];")
    B.append("    wire [1:0] shtyp = imem_data[8:7];")
    B.append("    wire [4:0] shamt = imem_data[6:2];")
    B.append("    wire [7:0] imm8  = imem_data[12:5];")
    B.append("    wire [16:0] imm17 = imem_data[16:0];")
    B.append("")
    B.append("    // =====================================================================")
    B.append("    //  CONDITION CHECK -- the ARM signature: gates EVERY instruction")
    B.append("    // =====================================================================")
    B.append("    reg cond_pass;")
    B.append("    always @(*) begin case (cond)")
    B.append("        4'd0:  cond_pass = fZ;               // EQ")
    B.append("        4'd1:  cond_pass = ~fZ;              // NE")
    B.append("        4'd2:  cond_pass = fC;               // CS/HS")
    B.append("        4'd3:  cond_pass = ~fC;              // CC/LO")
    B.append("        4'd4:  cond_pass = fN;               // MI")
    B.append("        4'd5:  cond_pass = ~fN;              // PL")
    B.append("        4'd6:  cond_pass = fV;               // VS")
    B.append("        4'd7:  cond_pass = ~fV;              // VC")
    B.append("        4'd8:  cond_pass = fC & ~fZ;         // HI")
    B.append("        4'd9:  cond_pass = ~fC | fZ;         // LS")
    B.append("        4'd10: cond_pass = (fN == fV);       // GE")
    B.append("        4'd11: cond_pass = (fN != fV);       // LT")
    B.append("        4'd12: cond_pass = ~fZ & (fN == fV); // GT")
    B.append("        4'd13: cond_pass = fZ | (fN != fV);  // LE")
    B.append("        4'd14: cond_pass = 1'b1;             // AL")
    B.append("        default: cond_pass = 1'b0;           // NV (never)")
    B.append("    endcase end")
    B.append("")
    B.append("    wire is_dp   = cond_pass & (cls[1] == 1'b0);")
    B.append("    wire is_mem  = cond_pass & (cls == 2'b10);")
    B.append("    wire is_flow = cond_pass & (cls == 2'b11);")
    B.append("    wire is_test = (op4 >= 4'd12);               // CMP CMN TST TEQ")
    B.append("    wire wr_flag = is_dp & (sbit | is_test);")
    B.append("")
    B.append(f"    wire [{w-1}:0] rnv = r[rn];")
    B.append(f"    wire [{w-1}:0] rmv = r[rm];")
    B.append("")
    B.append("    // =====================================================================")
    B.append("    //  BARREL SHIFTER on operand 2 (operand-isolated: only live for")
    B.append("    //  register-form data processing, flagship gating style)")
    B.append("    // =====================================================================")
    B.append("    wire sh_en = is_dp & (cls == 2'b00);")
    B.append(f"    wire [{w-1}:0] sh_in = rmv & {{{w}{{sh_en}}}};")
    B.append("    wire [4:0]  sh_n  = shamt & {5{sh_en}};")
    sh_mod = "sh_n[%d:0]" % (max(0, (w - 1).bit_length() - 1)) if w < 32 else "sh_n"
    B.append(f"    // rotate uses the amount modulo W; shifts saturate naturally")
    B.append(f"    reg [{w-1}:0] sh_out; reg sh_cout;")
    guard_le = (w < 32)
    B.append("    always @(*) begin")
    B.append("        case (shtyp)")
    B.append("            2'd0: begin                                     // LSL")
    B.append("                sh_out  = sh_in << sh_n;")
    if guard_le:
        B.append("                sh_cout = (sh_n == 5'd0) ? fC")
        B.append(f"                        : (sh_n <= 5'd{w}) ? sh_in[{w}-sh_n] : 1'b0;")
    else:
        B.append("                sh_cout = (sh_n == 5'd0) ? fC")
        B.append(f"                        : sh_in[{w}-sh_n];")
    B.append("            end")
    B.append("            2'd1: begin                                     // LSR")
    B.append("                sh_out  = sh_in >> sh_n;")
    if guard_le:
        B.append("                sh_cout = (sh_n == 5'd0) ? fC")
        B.append(f"                        : (sh_n <= 5'd{w}) ? sh_in[sh_n-5'd1] : 1'b0;")
    else:
        B.append("                sh_cout = (sh_n == 5'd0) ? fC")
        B.append("                        : sh_in[sh_n-5'd1];")
    B.append("            end")
    B.append("            2'd2: begin                                     // ASR")
    B.append("                sh_out  = $signed(sh_in) >>> sh_n;")
    if guard_le:
        B.append("                sh_cout = (sh_n == 5'd0) ? fC")
        B.append(f"                        : (sh_n <= 5'd{w}) ? sh_in[sh_n-5'd1] : sh_in[{s}];")
    else:
        B.append("                sh_cout = (sh_n == 5'd0) ? fC")
        B.append("                        : sh_in[sh_n-5'd1];")
    B.append("            end")
    B.append("            default: begin                                  // ROR")
    B.append(f"                sh_out  = (sh_in >> {sh_mod}) | (sh_in << ({w} - {sh_mod}));")
    B.append(f"                sh_cout = (sh_n == 5'd0) ? fC : sh_out[{s}];")
    B.append("            end")
    B.append("        endcase")
    B.append("    end")
    B.append("")
    B.append("    // operand 2: shifted register (cls 00) or zero-extended imm8 (cls 01)")
    B.append(f"    wire [{w-1}:0] imm8w = " + (f"{{{{{w-8}{{1'b0}}}}, imm8}};" if w > 8 else f"imm8[{w-1}:0];"))
    B.append(f"    wire [{w-1}:0] op2 = (cls == 2'b00) ? sh_out : imm8w;")
    B.append("")
    B.append("    // =====================================================================")
    B.append("    //  DATA-PROCESSING ALU (arith carry-chained, ARM C convention)")
    B.append("    // =====================================================================")
    B.append("    wire sel_arith = is_dp & ((op4 >= 4'd2 & op4 <= 4'd6) |")
    B.append("                              (op4 == 4'd12) | (op4 == 4'd13)); // SUB..SBC CMP CMN")
    B.append("    wire sel_logic = is_dp & ~sel_arith;")
    B.append("")
    B.append(f"    wire [{w-1}:0] aa = rnv & {{{w}{{sel_arith}}}};")
    B.append(f"    wire [{w-1}:0] ab = op2 & {{{w}{{sel_arith}}}};")
    B.append("    // unified adder: A + B + cin with operand inversion per op")
    B.append("    //   ADD: A=rn  B=op2  cin=0      ADC: cin=C")
    B.append("    //   SUB/CMP: B=~op2 cin=1        SBC: B=~op2 cin=C")
    B.append("    //   RSB: A=~rn B=op2 cin=1       CMN: like ADD")
    B.append("    wire inv_a = (op4 == 4'd3);                       // RSB")
    B.append("    wire inv_b = (op4 == 4'd2) | (op4 == 4'd6) | (op4 == 4'd12); // SUB SBC CMP")
    B.append("    wire cin   = (op4 == 4'd2) | (op4 == 4'd3) | (op4 == 4'd12) ? 1'b1")
    B.append("               : (op4 == 4'd5) | (op4 == 4'd6)                  ? fC")
    B.append("               : 1'b0;")
    B.append(f"    wire [{w-1}:0] adA = inv_a ? ~aa : aa;")
    B.append(f"    wire [{w-1}:0] adB = inv_b ? ~ab : ab;")
    B.append(f"    wire [{w}:0] adS = {{1'b0, adA}} + {{1'b0, adB}} + {{{{{w}{{1'b0}}}}, cin}};")
    B.append(f"    wire [{w-1}:0] ar_y = adS[{w-1}:0];")
    B.append(f"    wire ar_c = adS[{w}];                 // ARM: C = NOT borrow on subtract")
    B.append(f"    wire ar_v = (adA[{s}] == adB[{s}]) & (ar_y[{s}] != adA[{s}]);")
    B.append("")
    B.append(f"    wire [{w-1}:0] la = rnv & {{{w}{{sel_logic}}}};")
    B.append(f"    wire [{w-1}:0] lb = op2 & {{{w}{{sel_logic}}}};")
    B.append(f"    reg  [{w-1}:0] lg_y;")
    B.append("    always @(*) begin case (op4)")
    B.append("        4'd0, 4'd14: lg_y = la & lb;        // AND TST")
    B.append("        4'd1, 4'd15: lg_y = la ^ lb;        // EOR TEQ")
    B.append("        4'd7:        lg_y = la | lb;        // ORR")
    B.append("        4'd9:        lg_y = ~lb;            // MVN")
    B.append("        4'd10:       lg_y = la & ~lb;       // BIC")
    B.append("        default:     lg_y = lb;             // MOV (8, 11)")
    B.append("    endcase end")
    B.append("")
    B.append(f"    wire [{w-1}:0] dp_y = sel_arith ? ar_y : lg_y;")
    B.append("    wire dp_wr = is_dp & ~is_test;")
    B.append("")
    B.append("    // ---- flow + memory --------------------------------------------------")
    B.append("    wire is_b    = is_flow & (op4 == 4'd0);")
    B.append("    wire is_bl   = is_flow & (op4 == 4'd1);")
    B.append("    wire is_bx   = is_flow & (op4 == 4'd2);")
    B.append("    wire is_outi = is_flow & (op4 == 4'd3);")
    B.append("    wire is_hlt  = is_flow & (op4 == 4'd4);")
    B.append("    wire is_ldr  = is_mem & ~op4[0];")
    B.append("    wire is_str  = is_mem &  op4[0];")
    B.append("")
    B.append("    wire [4:0] mem_a = rnv[4:0] + imm8[4:0];")
    B.append("    wire [7:0] btgt  = pc + imm17[7:0];         // relative, word units")
    B.append("    wire [7:0] pc1   = pc + 8'd1;")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append("    assign dbg_data  = r[dbg_sel];")
    B.append("")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append("            pc <= 8'd0; halted <= 1'b0;")
    B.append("            fN <= 1'b0; fZ <= 1'b0; fC <= 1'b0; fV <= 1'b0;")
    B.append(f"            out_data <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            pc <= (is_b | is_bl) ? btgt")
    B.append("                : is_bx          ? " + ("rnv[7:0]" if w >= 8 else "{4'd0, rnv}"))
    B.append("                : is_hlt         ? pc")
    B.append("                :                  pc1;")
    B.append("            if (dp_wr)  r[rd] <= dp_y;")
    B.append("            if (is_ldr) r[rd] <= dmem[mem_a];")
    B.append("            if (is_str) dmem[mem_a] <= r[rd];")
    B.append("            if (is_bl)  r[14] <= " + (f"{{{{{w-8}{{1'b0}}}}, pc1}};" if w > 8 else f"pc1[{w-1}:0];"))
    B.append("            if (is_outi) begin out_data <= rnv; out_valid <= 1'b1; end")
    B.append("            if (is_hlt)  halted <= 1'b1;")
    B.append("            if (wr_flag) begin")
    B.append(f"                fN <= dp_y[{s}];")
    B.append(f"                fZ <= (dp_y == {{{w}{{1'b0}}}});")
    B.append("                if (sel_arith) begin fC <= ar_c; fV <= ar_v; end")
    B.append("                else if (cls == 2'b00) fC <= sh_cout;   // logical: shifter carry")
    B.append("            end")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    write(os.path.join(OUT, name + ".v"),
          hdr + "\n" + ports + defs + "\n" + "\n".join(B) + "\n")


for w in CPU_WIDTHS:
    gen(w)
print("CPUs: ARM-flavoured family generated")
