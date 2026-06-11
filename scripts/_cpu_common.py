"""
Shared helpers for the CPU / GPU generator scripts.

All processor families follow the library conventions (one self-contained
module per file, concrete widths, filename == top module) plus the two
flagship techniques from RV32IM_SYSTEM / GPU:

  * OPERAND ISOLATION ("process gating"): every functional unit's input
    operands are ANDed with a select/strobe line, so an unused unit's
    internal gates receive constant zeros and do not toggle.
        gate_add = ppln_add & sel_add;
        add_a    = alu_a & {W{gate_add}};
  * PIPELINE SYNCHRONIZER STROBES (ppln_*): pipelined cores expose the
    gates as input pins, "drive high for normal run".

CPU debug/observability contract (uniform across families so the same
testbench skeleton works everywhere):
    out_data / out_valid : OUT-instruction port (latched data + 1-cycle pulse)
    halted               : sticky high after HALT retires
"""

CPU_WIDTHS = [4, 8, 16, 32, 64]

# colour palette for // define lines (extends _common.COL with CPU signals)
CPU_COL = {
    "clk":        "255.230.80",
    "rst":        "255.80.80",
    "run":        "255.180.80",
    "prog_we":    "200.120.255",
    "prog_addr":  "160.120.255",
    "prog_data":  "120.120.255",
    "imem_addr":  "38.15.153",
    "imem_data":  "126.199.90",
    "out_data":   "120.255.160",
    "out_valid":  "97.255.239",
    "halted":     "255.120.120",
    "dbg_pc":     "255.0.26",
    "dbg_acc":    "178.54.0",
    "dbg_sel":    "200.120.255",
    "dbg_data":   "178.54.0",
    "ppln":       "90.126.199",
}


def define_line(pairs):
    """pairs = [(port, 'input'|'output', colour_key_or_rgb)] -> comment lines.

    Mirrors the flagship files: one '// define' per port, aligned columns.
    """
    out = []
    for port, direction, col in pairs:
        rgb = CPU_COL.get(col, col)
        out.append(f"    // define {port:<22} {direction:<7} {rgb}")
    return "\n".join(out) + "\n"


def sext(expr_bits, frm, to):
    """Verilog sign-extension snippet from `frm` bits to `to` bits."""
    if to == frm:
        return expr_bits
    return "{{%d{%s[%d]}}, %s}" % (to - frm, expr_bits, frm - 1, expr_bits)
