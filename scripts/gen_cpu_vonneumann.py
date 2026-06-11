"""
gen_cpu_vonneumann.py  ->  src/CPUs/cpu_vonneumann{4,8,16,32,64}.v

Classic VON NEUMANN stored-program accumulator machine (SAP lineage).

The defining trait is honoured literally: ONE unified memory holds both
code and data behind ONE port, so fetch and execute are serialized by a
multicycle FSM (the "von Neumann bottleneck" is visible in the state
machine, not just in the docs).

  width 4         : memory 32 x 4.  An instruction is TWO consecutive
                    nibbles {opcode}{operand} fetched in two states.
  width 8..64     : memory 16 x W.  An instruction is ONE word:
                    {opcode[3:0], ... , operand[3:0]} (operand = low nibble).

ISA (4-bit opcode, 4-bit operand a = memory address or immediate):
  0 NOP | 1 LDA a | 2 STA a | 3 ADD a | 4 SUB a | 5 AND a | 6 OR a
  7 XOR a | 8 LDI i | 9 JMP a | A JZ a | B JC a | C SHL | D SHR
  E OUT (latch acc -> out_data, pulse out_valid) | F HLT

Program loading: while run=0, prog_we/prog_addr/prog_data write the
unified memory directly. Raise run to start at PC=0.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def gen(w):
    name = f"cpu_vonneumann{w}"
    two_cell = (w == 4)                       # 4-bit: opcode + operand cells
    depth = 32 if two_cell else 16
    abits = 5 if two_cell else 4
    states = ["ST_FETCH", "ST_FETCH2", "ST_EXEC", "ST_HALT"] if two_cell \
        else ["ST_FETCH", "ST_EXEC", "ST_HALT"]

    hdr = banner(f"{name}.v", [
        f"{w}-bit VON NEUMANN accumulator CPU (multicycle, unified memory).",
        f"One {depth}x{w} memory holds code AND data behind a single port,",
        "so the FSM serializes fetch and execute (the classic bottleneck).",
        "ISA: NOP LDA STA ADD SUB AND OR XOR LDI JMP JZ JC SHL SHR OUT HLT.",
        "Load program via prog_* while run=0, then raise run (PC starts 0).",
    ])

    ports = (
        f"module {name}(\n"
        f"    input  wire        clk,\n"
        f"    input  wire        rst,\n"
        f"    input  wire        run,\n"
        f"    // unified-memory load port (active while run=0)\n"
        f"    input  wire        prog_we,\n"
        f"    input  wire [{abits-1}:0]  prog_addr,\n"
        f"    input  wire [{w-1}:0]  prog_data,\n"
        f"    // OUT instruction port\n"
        f"    output reg  [{w-1}:0]  out_data,\n"
        f"    output reg         out_valid,\n"
        f"    // status / debug\n"
        f"    output wire        halted,\n"
        f"    output wire [{w-1}:0]  dbg_acc,\n"
        f"    output wire [{abits-1}:0]  dbg_pc\n"
        f");\n"
    )

    defs = define_line([
        ("clk", "input", "clk"), ("rst", "input", "rst"),
        ("run", "input", "run"),
        ("prog_we", "input", "prog_we"), ("prog_addr", "input", "prog_addr"),
        ("prog_data", "input", "prog_data"),
        ("out_data", "output", "out_data"), ("out_valid", "output", "out_valid"),
        ("halted", "output", "halted"),
        ("dbg_acc", "output", "dbg_acc"), ("dbg_pc", "output", "dbg_pc"),
    ])

    L = []
    L.append("    // ------------------------------------------------------------------")
    L.append("    // UNIFIED MEMORY -- the von Neumann signature. Code and data share")
    L.append("    // this single array and its single read path; the FSM below decides")
    L.append("    // whether the current access is an instruction fetch or a data access.")
    L.append("    // ------------------------------------------------------------------")
    L.append(f"    reg [{w-1}:0] mem [0:{depth-1}];")
    L.append("")
    st_bits = 2
    for i, s in enumerate(states):
        L.append(f"    localparam {s:<9} = {st_bits}'d{i};")
    L.append(f"    reg [{st_bits-1}:0] state;")
    L.append("")
    L.append(f"    reg [{abits-1}:0] pc;")
    L.append(f"    reg [{w-1}:0] acc;")
    L.append("    reg [3:0] opcode;")
    if two_cell:
        L.append("    reg [3:0] operand;      // fetched in ST_FETCH2 (second cell)")
    L.append("    reg carry;")
    L.append("")
    L.append("    wire zero = (acc == {%d{1'b0}});" % w)
    L.append("")
    L.append("    // single memory read path, time-multiplexed by the FSM:")
    L.append("    //   ST_FETCH/ST_FETCH2 -> mem[pc] (instruction stream)")
    L.append("    //   ST_EXEC            -> mem[operand] (data, for LDA/ADD/...)")
    if not two_cell:
        L.append("    // operand is registered with the opcode at the end of ST_FETCH")
        L.append("    reg  [3:0] operand;")
    L.append("    wire [3:0] cur_opcode  = opcode;")
    L.append("    wire [3:0] cur_operand = operand;")
    if two_cell:
        L.append(f"    wire [{abits-1}:0] mem_raddr = (state == ST_EXEC) ? {{1'b0, cur_operand}} : pc;")
    else:
        L.append("    wire [%d:0] mem_raddr = (state == ST_EXEC) ? cur_operand : pc;" % (abits - 1))
    L.append(f"    wire [{w-1}:0] mem_rdata = mem[mem_raddr];")
    L.append("")
    L.append("    // ---- ALU (operand-isolated, flagship style) ----------------------")
    L.append("    // Each path's inputs are ANDed with its select so unused paths hold 0.")
    L.append("    wire is_add = (opcode == 4'h3);")
    L.append("    wire is_sub = (opcode == 4'h4);")
    L.append("    wire sel_arith = is_add | is_sub;")
    L.append("    wire sel_logic = (opcode == 4'h5) | (opcode == 4'h6) | (opcode == 4'h7);")
    L.append("    wire sel_shift = (opcode == 4'hC) | (opcode == 4'hD);")
    L.append("")
    L.append(f"    wire [{w-1}:0] ar_a = acc       & {{{w}{{sel_arith}}}};")
    L.append(f"    wire [{w-1}:0] ar_b = mem_rdata & {{{w}{{sel_arith}}}};")
    L.append(f"    wire [{w}:0]   ar_sum = is_sub ? ({{1'b0, ar_a}} - {{1'b0, ar_b}})")
    L.append(f"                                   : ({{1'b0, ar_a}} + {{1'b0, ar_b}});")
    L.append("")
    L.append(f"    wire [{w-1}:0] lg_a = acc       & {{{w}{{sel_logic}}}};")
    L.append(f"    wire [{w-1}:0] lg_b = mem_rdata & {{{w}{{sel_logic}}}};")
    L.append(f"    wire [{w-1}:0] lg_y = (opcode == 4'h5) ? (lg_a & lg_b)")
    L.append("                        : (opcode == 4'h6) ? (lg_a | lg_b)")
    L.append("                        :                    (lg_a ^ lg_b);")
    L.append("")
    L.append(f"    wire [{w-1}:0] sh_a = acc & {{{w}{{sel_shift}}}};")
    L.append(f"    wire [{w-1}:0] sh_y = (opcode == 4'hC) ? {{sh_a[{w-2}:0], 1'b0}}")
    L.append(f"                        :                    {{1'b0, sh_a[{w-1}:1]}};")
    L.append(f"    wire sh_c = (opcode == 4'hC) ? sh_a[{w-1}] : sh_a[0];")
    L.append("")
    L.append("    assign halted  = (state == ST_HALT);")
    L.append("    assign dbg_acc = acc;")
    L.append("    assign dbg_pc  = pc;")
    L.append("")
    L.append("    always @(posedge clk) begin")
    L.append("        out_valid <= 1'b0;")
    L.append("        if (rst) begin")
    L.append(f"            state <= ST_FETCH; pc <= {abits}'d0; acc <= {{{w}{{1'b0}}}};")
    L.append("            carry <= 1'b0; opcode <= 4'h0;")
    L.append("            operand <= 4'h0;")
    L.append(f"            out_data <= {{{w}{{1'b0}}}};")
    L.append("        end else if (!run) begin")
    L.append("            // program-load mode: the SAME unified memory is written here")
    L.append("            if (prog_we) mem[prog_addr] <= prog_data;")
    L.append(f"            state <= ST_FETCH; pc <= {abits}'d0;")
    L.append("        end else begin")
    L.append("            case (state)")
    if two_cell:
        L.append("                ST_FETCH: begin                 // cell 1: opcode")
        L.append("                    opcode <= mem_rdata;")
        L.append(f"                    pc     <= pc + {abits}'d1;")
        L.append("                    state  <= ST_FETCH2;")
        L.append("                end")
        L.append("                ST_FETCH2: begin                // cell 2: operand")
        L.append("                    operand <= mem_rdata;")
        L.append(f"                    pc      <= pc + {abits}'d1;")
        L.append("                    state   <= ST_EXEC;")
        L.append("                end")
    else:
        L.append("                ST_FETCH: begin")
        L.append(f"                    opcode  <= mem_rdata[{w-1}:{w-4}];")
        L.append("                    operand <= mem_rdata[3:0];")
        L.append(f"                    pc      <= pc + {abits}'d1;")
        L.append("                    state   <= ST_EXEC;")
        L.append("                end")
    opr5 = "{1'b0, cur_operand}" if two_cell else "cur_operand"
    L.append("                ST_EXEC: begin")
    L.append("                    state <= ST_FETCH;")
    L.append("                    case (cur_opcode)")
    L.append("                        4'h0: ;                                   // NOP")
    L.append("                        4'h1: acc <= mem_rdata;                   // LDA")
    L.append(f"                        4'h2: mem[mem_raddr] <= acc;              // STA")
    L.append(f"                        4'h3: begin acc <= ar_sum[{w-1}:0]; carry <= ar_sum[{w}]; end // ADD")
    L.append(f"                        4'h4: begin acc <= ar_sum[{w-1}:0]; carry <= ar_sum[{w}]; end // SUB (carry = borrow)")
    L.append("                        4'h5, 4'h6, 4'h7: acc <= lg_y;            // AND OR XOR")
    L.append(f"                        4'h8: acc <= {{{{{w-4}{{1'b0}}}}, cur_operand}}; // LDI")
    L.append(f"                        4'h9: pc <= {opr5};                       // JMP")
    L.append(f"                        4'hA: if (zero)  pc <= {opr5};            // JZ")
    L.append(f"                        4'hB: if (carry) pc <= {opr5};            // JC")
    L.append("                        4'hC, 4'hD: begin acc <= sh_y; carry <= sh_c; end // SHL SHR")
    L.append("                        4'hE: begin out_data <= acc; out_valid <= 1'b1; end // OUT")
    L.append("                        4'hF: state <= ST_HALT;                   // HLT")
    L.append("                        default: ;")
    L.append("                    endcase")
    L.append("                end")
    L.append("                ST_HALT: state <= ST_HALT;")
    L.append("                default: state <= ST_FETCH;")
    L.append("            endcase")
    L.append("        end")
    L.append("    end")
    L.append("endmodule")

    body = "\n".join(L) + "\n"
    text = hdr + "\n" + ports + defs + "\n" + body
    write(os.path.join(OUT, name + ".v"), text)


for w in CPU_WIDTHS:
    gen(w)
print("CPUs: von Neumann family generated")
