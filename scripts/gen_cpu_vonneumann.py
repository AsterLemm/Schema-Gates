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

MODULAR EMISSION (DigitalJS-style hierarchy): <top>_mem (the unified
memory with ONE muxed write port: program-load vs STA) and <top>_alu
(instantiating _alu_arith / _alu_logic / _alu_shift leaf paths); the
fetch/execute FSM stays in the top. Every expression is carried over
verbatim from the monolithic emitter, so behaviour is identical.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def mem_module(n, w, depth, abits):
    return f"""\
// --- {n}_mem : the unified von Neumann memory ({depth}x{w}) ---
// ONE muxed write port carries both program loading (run=0) and STA
// (run=1, EXEC); ONE async read path is time-multiplexed by the FSM.
module {n}_mem(
    input  wire        clk,
    input  wire        we,
    input  wire [{abits-1}:0]  waddr,
    input  wire [{w-1}:0]  wdata,
    input  wire [{abits-1}:0]  raddr,
    output wire [{w-1}:0]  rdata
);
    reg [{w-1}:0] mem [0:{depth-1}];

    assign rdata = mem[raddr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) mem[waddr] <= wdata;
    end
endmodule"""


def alu_arith_module(n, w):
    return f"""\
// --- {n}_alu_arith : ADD / SUB with carry view (leaf of {n}_alu) ---
module {n}_alu_arith(
    input  wire [{w-1}:0] ar_a,
    input  wire [{w-1}:0] ar_b,
    input  wire        is_sub,
    output wire [{w}:0]   ar_sum
);
    assign ar_sum = is_sub ? ({{1'b0, ar_a}} - {{1'b0, ar_b}})
                           : ({{1'b0, ar_a}} + {{1'b0, ar_b}});
endmodule"""


def alu_logic_module(n, w):
    return f"""\
// --- {n}_alu_logic : AND / OR / XOR (leaf of {n}_alu) ---
module {n}_alu_logic(
    input  wire [{w-1}:0] lg_a,
    input  wire [{w-1}:0] lg_b,
    input  wire [3:0]  opcode,
    output wire [{w-1}:0] lg_y
);
    assign lg_y = (opcode == 4'h5) ? (lg_a & lg_b)
                : (opcode == 4'h6) ? (lg_a | lg_b)
                :                    (lg_a ^ lg_b);
endmodule"""


def alu_shift_module(n, w):
    return f"""\
// --- {n}_alu_shift : SHL / SHR with carry-out (leaf of {n}_alu) ---
module {n}_alu_shift(
    input  wire [{w-1}:0] sh_a,
    input  wire [3:0]  opcode,
    output wire [{w-1}:0] sh_y,
    output wire        sh_c
);
    assign sh_y = (opcode == 4'hC) ? {{sh_a[{w-2}:0], 1'b0}}
                :                    {{1'b0, sh_a[{w-1}:1]}};
    assign sh_c = (opcode == 4'hC) ? sh_a[{w-1}] : sh_a[0];
endmodule"""


def alu_module(n, w):
    return f"""\
// --- {n}_alu : operand-isolated accumulator ALU (flagship technique) ---
// Each path's inputs are ANDed with its select so unused paths hold 0.
module {n}_alu(
    input  wire [{w-1}:0] acc,
    input  wire [{w-1}:0] mem_rdata,
    input  wire [3:0]  opcode,
    output wire [{w}:0]   ar_sum,
    output wire [{w-1}:0] lg_y,
    output wire [{w-1}:0] sh_y,
    output wire        sh_c
);
    wire is_add = (opcode == 4'h3);
    wire is_sub = (opcode == 4'h4);
    wire sel_arith = is_add | is_sub;
    wire sel_logic = (opcode == 4'h5) | (opcode == 4'h6) | (opcode == 4'h7);
    wire sel_shift = (opcode == 4'hC) | (opcode == 4'hD);

    wire [{w-1}:0] ar_a = acc       & {{{w}{{sel_arith}}}};
    wire [{w-1}:0] ar_b = mem_rdata & {{{w}{{sel_arith}}}};
    {n}_alu_arith u_arith(.ar_a(ar_a), .ar_b(ar_b), .is_sub(is_sub),
                          .ar_sum(ar_sum));

    wire [{w-1}:0] lg_a = acc       & {{{w}{{sel_logic}}}};
    wire [{w-1}:0] lg_b = mem_rdata & {{{w}{{sel_logic}}}};
    {n}_alu_logic u_logic(.lg_a(lg_a), .lg_b(lg_b), .opcode(opcode),
                          .lg_y(lg_y));

    wire [{w-1}:0] sh_a = acc & {{{w}{{sel_shift}}}};
    {n}_alu_shift u_shift(.sh_a(sh_a), .opcode(opcode),
                          .sh_y(sh_y), .sh_c(sh_c));
endmodule"""


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
        "MODULAR: the unified memory and the operand-isolated ALU (with",
        "arith / logic / shift leaf paths) are drillable submodules; the",
        "fetch/execute FSM stays in the top.",
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

    mods = [mem_module(name, w, depth, abits),
            alu_arith_module(name, w), alu_logic_module(name, w),
            alu_shift_module(name, w), alu_module(name, w)]

    L = []
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
    L.append("")
    L.append("    // ------------------------------------------------------------------")
    L.append("    // UNIFIED MEMORY -- the von Neumann signature. Code and data share")
    L.append("    // this single array and its single read path; the FSM below decides")
    L.append("    // whether the current access is an instruction fetch or a data access.")
    L.append("    // ONE muxed write port: program-load (run=0) or STA (run=1, EXEC).")
    L.append("    // Identical conditions to the old monolithic always block.")
    L.append("    // ------------------------------------------------------------------")
    L.append("    wire mem_we = (~rst & ~run & prog_we)")
    L.append("                | (~rst & run & (state == ST_EXEC) & (cur_opcode == 4'h2));")
    L.append(f"    wire [{abits-1}:0] mem_waddr = (~run) ? prog_addr : mem_raddr;")
    L.append(f"    wire [{w-1}:0] mem_wdata = (~run) ? prog_data : acc;")
    L.append(f"    wire [{w-1}:0] mem_rdata;")
    L.append(f"    {name}_mem u_mem(")
    L.append("        .clk(clk),")
    L.append("        .we(mem_we), .waddr(mem_waddr), .wdata(mem_wdata),")
    L.append("        .raddr(mem_raddr), .rdata(mem_rdata)")
    L.append("    );")
    L.append("")
    L.append("    // ---- ALU (operand-isolated paths inside) -------------------------")
    L.append(f"    wire [{w}:0]   ar_sum;")
    L.append(f"    wire [{w-1}:0] lg_y, sh_y;")
    L.append("    wire sh_c;")
    L.append(f"    {name}_alu u_alu(")
    L.append("        .acc(acc), .mem_rdata(mem_rdata), .opcode(cur_opcode),")
    L.append("        .ar_sum(ar_sum), .lg_y(lg_y), .sh_y(sh_y), .sh_c(sh_c)")
    L.append("    );")
    L.append("")
    L.append("    assign halted  = (state == ST_HALT);")
    L.append("    assign dbg_acc = acc;")
    L.append("    assign dbg_pc  = pc;")
    L.append("")
    L.append("    // sequencing: identical to the monolithic core; the unified-memory")
    L.append("    // writes (program load + STA) moved into u_mem, same conditions.")
    L.append("    always @(posedge clk) begin")
    L.append("        out_valid <= 1'b0;")
    L.append("        if (rst) begin")
    L.append(f"            state <= ST_FETCH; pc <= {abits}'d0; acc <= {{{w}{{1'b0}}}};")
    L.append("            carry <= 1'b0; opcode <= 4'h0;")
    L.append("            operand <= 4'h0;")
    L.append(f"            out_data <= {{{w}{{1'b0}}}};")
    L.append("        end else if (!run) begin")
    L.append("            // program-load mode (the write itself lives in u_mem)")
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
    L.append("                        4'h2: ;       // STA (the write lives in u_mem)")
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
    text = hdr + "\n" + "\n\n".join(mods) + "\n\n" + ports + defs + "\n" + body
    write(os.path.join(OUT, name + ".v"), text)


for w in CPU_WIDTHS:
    gen(w)
print("CPUs: von Neumann family generated (modular)")
