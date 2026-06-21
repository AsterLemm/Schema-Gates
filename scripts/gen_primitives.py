import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, WIDTHS

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "primitives")

def emit(name, body, desc):
    text = banner(name + ".v", desc) + "\n" + body + "\n"
    write(os.path.join(OUT, name + ".v"), text)

# ---- basic single-output gates -----------------------------------------
def gate(name, ports, expr, desc):
    portdecl = ", ".join("input " + p for p in ports) + ", output y"
    return f"module {name}({portdecl});\n    assign y = {expr};\nendmodule\n"

basic = {
    "buf1":  (["a"], "a"),
    "not1":  (["a"], "~a"),
    "and2":  (["a","b"], "a & b"),
    "and3":  (["a","b","c"], "a & b & c"),
    "and4":  (["a","b","c","d"], "a & b & c & d"),
    "and8":  (["a","b","c","d","e","f","g","h"], "a & b & c & d & e & f & g & h"),
    "or2":   (["a","b"], "a | b"),
    "or3":   (["a","b","c"], "a | b | c"),
    "or4":   (["a","b","c","d"], "a | b | c | d"),
    "or8":   (["a","b","c","d","e","f","g","h"], "a | b | c | d | e | f | g | h"),
    "xor2":  (["a","b"], "a ^ b"),
    "xor3":  (["a","b","c"], "a ^ b ^ c"),
    "xor4":  (["a","b","c","d"], "a ^ b ^ c ^ d"),
    "xnor2": (["a","b"], "~(a ^ b)"),
    "xnor3": (["a","b","c"], "~(a ^ b ^ c)"),
    "xnor4": (["a","b","c","d"], "~(a ^ b ^ c ^ d)"),
    "nand2": (["a","b"], "~(a & b)"),
    "nand3": (["a","b","c"], "~(a & b & c)"),
    "nand4": (["a","b","c","d"], "~(a & b & c & d)"),
    "nor2":  (["a","b"], "~(a | b)"),
    "nor3":  (["a","b","c"], "~(a | b | c)"),
    "nor4":  (["a","b","c","d"], "~(a | b | c | d)"),
}
for name,(ports,expr) in basic.items():
    emit(name, gate(name, ports, expr, []), [f"Basic gate: y = {expr}"])

# ---- constants and utility cells ---------------------------------------
emit("const0", "module const0(output y);\n    assign y = 1'b0;\nendmodule\n", ["Constant logic 0."])
emit("const1", "module const1(output y);\n    assign y = 1'b1;\nendmodule\n", ["Constant logic 1."])
emit("tie_low", "module tie_low(output y);\n    assign y = 1'b0;\nendmodule\n", ["Tie-low cell (drives 0)."])
emit("tie_high","module tie_high(output y);\n    assign y = 1'b1;\nendmodule\n", ["Tie-high cell (drives 1)."])
emit("bit_tap", "module bit_tap(input a, output y);\n    assign y = a;\nendmodule\n", ["Probe/tap a single bit (pass-through)."])

# bus join: N 1-bit inputs -> N-bit bus
def bus_join(n):
    ins = ", ".join(f"input i{k}" for k in range(n))
    body = f"module bus_join{n}({ins}, output [{n-1}:0] y);\n"
    body += "    assign y = {" + ", ".join(f"i{k}" for k in range(n-1, -1, -1)) + "};\n"
    body += "endmodule\n"
    return body
for n in (2,4,8):
    emit(f"bus_join{n}", bus_join(n), [f"Join {n} single bits into a {n}-bit bus (i{n-1}=MSB)."])

# bus split: N-bit bus -> N 1-bit outputs
def bus_split(n):
    outs = ", ".join(f"output o{k}" for k in range(n))
    body = f"module bus_split{n}(input [{n-1}:0] a, {outs});\n"
    for k in range(n):
        body += f"    assign o{k} = a[{k}];\n"
    body += "endmodule\n"
    return body
for n in (2,4,8):
    emit(f"bus_split{n}", bus_split(n), [f"Split a {n}-bit bus into {n} single bits."])

# ---- reduction gates 4/8/16/32 -----------------------------------------
red = {
    "and_reduce":  ("&a",  "AND-reduce: 1 iff all bits set."),
    "or_reduce":   ("|a",  "OR-reduce: 1 iff any bit set."),
    "xor_reduce":  ("^a",  "XOR-reduce: parity of the bus."),
    "nor_reduce":  ("~(|a)","NOR-reduce: 1 iff all bits zero."),
    "nand_reduce": ("~(&a)","NAND-reduce: 0 iff all bits set."),
}
for base,(expr,desc) in red.items():
    for w in WIDTHS:
        name = f"{base}{w}"
        body = f"module {name}(input [{w-1}:0] a, output y);\n    assign y = {expr};\nendmodule\n"
        emit(name, body, [desc])

# ---- gate-only educational variants ------------------------------------
emit("not_using_nand",
     "module not_using_nand(input a, output y);\n    assign y = ~(a & a);\nendmodule\n",
     ["NOT built from one NAND (a NAND a)."])
emit("and_using_nand",
     "module and_using_nand(input a, input b, output y);\n    wire t;\n    assign t = ~(a & b);\n    assign y = ~(t & t);\nendmodule\n",
     ["AND from two NANDs (NAND then invert)."])
emit("or_using_nand",
     "module or_using_nand(input a, input b, output y);\n    wire na, nb;\n    assign na = ~(a & a);\n    assign nb = ~(b & b);\n    assign y  = ~(na & nb);\nendmodule\n",
     ["OR from three NANDs (invert inputs, NAND)."])
emit("xor_using_nand",
     "module xor_using_nand(input a, input b, output y);\n"
     "    wire t, t1, t2;\n"
     "    assign t  = ~(a & b);\n"
     "    assign t1 = ~(a & t);\n"
     "    assign t2 = ~(b & t);\n"
     "    assign y  = ~(t1 & t2);\nendmodule\n",
     ["XOR from four NANDs (classic 4-gate form)."])
emit("half_adder_using_nand",
     "module half_adder_using_nand(input a, input b, output sum, output carry);\n"
     "    wire t, t1, t2;\n"
     "    assign t     = ~(a & b);\n"
     "    assign t1    = ~(a & t);\n"
     "    assign t2    = ~(b & t);\n"
     "    assign sum   = ~(t1 & t2);\n"
     "    assign carry = ~t;\nendmodule\n",
     ["Half adder using only NAND gates."])
emit("full_adder_using_nand",
     "module full_adder_using_nand(input a, input b, input cin, output sum, output cout);\n"
     "    // first XOR (a^b)\n"
     "    wire t, ab, x1, x2, axb;\n"
     "    assign t   = ~(a & b);\n"
     "    assign x1  = ~(a & t);\n"
     "    assign x2  = ~(b & t);\n"
     "    assign axb = ~(x1 & x2);     // a ^ b\n"
     "    // second XOR ((a^b)^cin)\n"
     "    wire u, y1, y2;\n"
     "    assign u   = ~(axb & cin);\n"
     "    assign y1  = ~(axb & u);\n"
     "    assign y2  = ~(cin & u);\n"
     "    assign sum = ~(y1 & y2);     // (a^b) ^ cin\n"
     "    // carry = (a&b) | (cin&(a^b))  via NANDs\n"
     "    assign cout = ~(t & u);\nendmodule\n",
     ["Full adder using only NAND gates."])

emit("not_using_nor",
     "module not_using_nor(input a, output y);\n    assign y = ~(a | a);\nendmodule\n",
     ["NOT built from one NOR (a NOR a)."])
emit("or_using_nor",
     "module or_using_nor(input a, input b, output y);\n    wire t;\n    assign t = ~(a | b);\n    assign y = ~(t | t);\nendmodule\n",
     ["OR from two NORs (NOR then invert)."])
emit("and_using_nor",
     "module and_using_nor(input a, input b, output y);\n    wire na, nb;\n    assign na = ~(a | a);\n    assign nb = ~(b | b);\n    assign y  = ~(na | nb);\nendmodule\n",
     ["AND from three NORs (invert inputs, NOR)."])
emit("xor_using_nor",
     "module xor_using_nor(input a, input b, output y);\n"
     "    // verified 5-NOR XOR network\n"
     "    wire na, nab, nb, t;\n"
     "    assign na  = ~(a  | a);   // ~a\n"
     "    assign nab = ~(a  | b);   // ~(a|b)\n"
     "    assign nb  = ~(b  | b);   // ~b\n"
     "    assign t   = ~(na | nb);  // ~(~a|~b) = a&b\n"
     "    assign y   = ~(nab | t);  // a^b\n"
     "endmodule\n",
     ["XOR from five NOR gates (verified network)."])
emit("half_adder_using_nor",
     "module half_adder_using_nor(input a, input b, output sum, output carry);\n"
     "    // sum = a^b (5-NOR), carry = a&b = NOR(~a,~b)\n"
     "    wire na, nab, nb, t;\n"
     "    assign na    = ~(a  | a);\n"
     "    assign nab   = ~(a  | b);\n"
     "    assign nb    = ~(b  | b);\n"
     "    assign t     = ~(na | nb);   // a & b\n"
     "    assign sum   = ~(nab | t);   // a ^ b\n"
     "    assign carry = t;            // a & b\n"
     "endmodule\n",
     ["Half adder using only NOR gates (verified)."])
emit("full_adder_using_nor",
     "module full_adder_using_nor(input a, input b, input cin, output sum, output cout);\n"
     "    // axb = a^b\n"
     "    wire na, nab, nb, ab, axb;\n"
     "    assign na  = ~(a   | a);\n"
     "    assign nab = ~(a   | b);\n"
     "    assign nb  = ~(b   | b);\n"
     "    assign ab  = ~(na  | nb);    // a & b\n"
     "    assign axb = ~(nab | ab);    // a ^ b\n"
     "    // sum = axb ^ cin\n"
     "    wire nx, nxc, nc, xc, sx;\n"
     "    assign nx  = ~(axb | axb);   // ~axb\n"
     "    assign nxc = ~(axb | cin);\n"
     "    assign nc  = ~(cin | cin);   // ~cin\n"
     "    assign xc  = ~(nx  | nc);    // axb & cin\n"
     "    assign sum = ~(nxc | xc);    // axb ^ cin\n"
     "    // cout = (a&b) | (cin & axb) = ab | xc   (OR via double-NOR)\n"
     "    wire nor_oc;\n"
     "    assign nor_oc = ~(ab | xc);  // ab NOR xc\n"
     "    assign cout   = ~(nor_oc | nor_oc);\n"
     "endmodule\n",
     ["Full adder using only NOR gates (verified)."])

print("primitives generated")
