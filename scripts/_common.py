"""
Shared helpers for BITFries generator scripts.

Every generated .v file is FULLY SELF-CONTAINED: it embeds copies of every
submodule it instantiates, down to leaf gates.

Author: BITFries
Synthesizer target: BITF-Synth Engine
"""

import re

WIDTHS = [4, 8, 16, 32]

# ---- colour palette (RGB for // define) ---------------------------------
COL = {
    "a":      "80.160.255",
    "b":      "80.200.255",
    "cin":    "255.230.80",
    "sel":    "200.120.255",
    "clk":    "255.230.80",
    "rst":    "255.80.80",
    "en":     "255.180.80",
    "out":    "120.255.160",
    "flag":   "255.120.120",
    "status": "255.255.255",
}

HEADER_NOTE = (
    "//  Part of schema-gates by BITFries.\n"
    "//  Self-contained: embeds every submodule it uses, down to leaf gates.\n"
    "//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).\n"
)

def banner(title, desc_lines):
    """Return a header comment block."""
    bar = "// " + "=" * 69 + "\n"
    out = bar
    out += f"//  {title}\n"
    for ln in desc_lines:
        out += f"//  {ln}\n"
    out += HEADER_NOTE
    out += bar
    return out

# ---- reusable embedded leaf modules (as text) ---------------------------
# Each returns Verilog source for the named module. Higher modules concatenate
# whichever leaves they need so each file stands alone.

def m_half_adder():
    return (
        "module half_adder(input a, input b, output sum, output carry);\n"
        "    assign sum   = a ^ b;\n"
        "    assign carry = a & b;\n"
        "endmodule\n"
    )

def m_full_adder():
    return (
        "module full_adder(input a, input b, input cin, output sum, output cout);\n"
        "    wire s0, c0, c1;\n"
        "    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));\n"
        "    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));\n"
        "    assign cout = c0 | c1;\n"
        "endmodule\n"
    )

def m_pg_bit():
    return (
        "module pg_bit(input a, input b, output p, output g);\n"
        "    assign p = a ^ b;\n"
        "    assign g = a & b;\n"
        "endmodule\n"
    )

def m_mux2_1():
    return (
        "module mux2_1(input d0, input d1, input sel, output y);\n"
        "    assign y = sel ? d1 : d0;\n"
        "endmodule\n"
    )

def m_full_subtractor():
    return (
        "module full_subtractor(input a, input b, input bin, output diff, output bout);\n"
        "    wire d0, b0, b1;\n"
        "    assign d0   = a ^ b;\n"
        "    assign diff = d0 ^ bin;\n"
        "    assign b0   = (~a) & b;\n"
        "    assign b1   = (~d0) & bin;\n"
        "    assign bout = b0 | b1;\n"
        "endmodule\n"
    )

def m_half_subtractor():
    return (
        "module half_subtractor(input a, input b, output diff, output bout);\n"
        "    assign diff = a ^ b;\n"
        "    assign bout = (~a) & b;\n"
        "endmodule\n"
    )

_PORT_DEFINE = re.compile(r"// define \w+ (?:input|output) \d+\.\d+\.\d+")


def split_port_defines(text):
    # the synth reads one '// define' per line; anything packed onto the same
    # line after the first directive is silently dropped. break them apart.
    nl = "\r\n" if "\r\n" in text else "\n"
    out = []
    for line in text.split("\n"):
        body = line.rstrip("\r")
        bare = body.lstrip()
        directives = _PORT_DEFINE.findall(body)
        if len(directives) > 1 and not _PORT_DEFINE.sub("", bare).strip():
            indent = body[: len(body) - len(bare)]
            out.extend(indent + d for d in directives)
        else:
            out.append(body)
    return nl.join(out)


def write(path, text):
    import os
    os.makedirs(os.path.dirname(path), exist_ok=True)
    text = split_port_defines(text)
    # Library convention: every file ends with exactly two blank lines
    # after the final 'endmodule' (committed files are the contract).
    text = text.rstrip("\n") + "\n\n\n"
    with open(path, "w") as f:
        f.write(text)
