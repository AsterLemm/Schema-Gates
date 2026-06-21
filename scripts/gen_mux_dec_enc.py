import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, m_mux2_1

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "mux_decoder_encoder")
def emit(name, body, desc): write(os.path.join(OUT,name+".v"), banner(name+".v",desc)+"\n"+body+"\n")

BIT_WIDTHS=[1,4,8,16,32]
SEL_SIZES=[2,4,8,16,32]   # N:1

def log2(n): return int(math.log2(n))

# ---- N:1 mux, W-bit wide, built as a tree of mux2_1 (embedded) ----------
def mux_tree(nsel, w):
    sb=log2(nsel)
    name=f"mux{nsel}_{w}"
    # base leaf: 2:1, 1-bit -> direct ternary, no submodules
    if nsel==2 and w==1:
        body=(f"module mux2_1(input d0, input d1, input sel, output y);\n"
              f"    // define sel input {COL['sel']}    // define y output {COL['out']}\n"
              f"    assign y = sel ? d1 : d0;\n"
              f"endmodule\n")
        return name, body
    lines=[]
    if w==1:
        din=", ".join(f"input d{i}" for i in range(nsel))
        lines.append(f"module {name}({din}, input [{sb-1}:0] sel, output y);")
    else:
        din=", ".join(f"input [{w-1}:0] d{i}" for i in range(nsel))
        lines.append(f"module {name}({din}, input [{sb-1}:0] sel, output [{w-1}:0] y);")
    lines.append(f"    // define sel input {COL['sel']}    // define y output {COL['out']}")
    # build a reduction tree
    # current layer holds names of nsel data nets
    layer=[f"d{i}" for i in range(nsel)]
    stage=0
    wirecount=0
    # for each select bit, halve
    for s in range(sb):
        newlayer=[]
        for k in range(0,len(layer),2):
            wn=f"w_s{stage}_{k//2}"
            wirecount+=1
            if w==1:
                lines.append(f"    wire {wn};")
                lines.append(f"    mux2_1 m_s{stage}_{k//2}(.d0({layer[k]}), .d1({layer[k+1]}), .sel(sel[{s}]), .y({wn}));")
            else:
                lines.append(f"    wire [{w-1}:0] {wn};")
                # per-bit mux2_1
                for bit in range(w):
                    lines.append(f"    mux2_1 m_s{stage}_{k//2}_b{bit}(.d0({layer[k]}[{bit}]), .d1({layer[k+1]}[{bit}]), .sel(sel[{s}]), .y({wn}[{bit}]));")
            newlayer.append(wn)
        layer=newlayer
        stage+=1
    lines.append(f"    assign y = {layer[0]};")
    lines.append("endmodule")
    if name == "mux2_1":
        body="\n".join(lines)+"\n"   # base cell: don't embed a copy of itself
    else:
        body="\n".join(lines)+"\n\n"+m_mux2_1()
    return name, body

for nsel in SEL_SIZES:
    for w in BIT_WIDTHS:
        name,body=mux_tree(nsel,w)
        emit(name, body, [f"{nsel}:1 multiplexer, {w}-bit data; tree of 2:1 muxes."])

# ---- demux 1->N (1-bit data) -------------------------------------------
def demux(n):
    sb=log2(n)
    name=f"demux1to{n}"
    lines=[f"module {name}(input d, input [{sb-1}:0] sel, output [{n-1}:0] y);"]
    lines.append(f"    // define d input {COL['a']}   // define sel input {COL['sel']}   // define y output {COL['out']}")
    for i in range(n):
        term=" & ".join((f"sel[{b}]" if (i>>b)&1 else f"~sel[{b}]") for b in range(sb))
        lines.append(f"    assign y[{i}] = d & ({term});")
    lines.append("endmodule")
    return name,"\n".join(lines)+"\n"
for n in [2,4,8,16,32]:
    name,body=demux(n); emit(name,body,[f"1-to-{n} demultiplexer (routes d to selected line)."])

# ---- decoders (+ _en) ---------------------------------------------------
def decoder(inb, en=False):
    n=1<<inb
    name=f"decoder{inb}to{n}"+("_en" if en else "")
    enport=", input en" if en else ""
    lines=[f"module {name}(input [{inb-1}:0] a{enport}, output [{n-1}:0] y);"]
    dl=f"    // define a input {COL['a']}   // define y output {COL['out']}"
    if en: dl+=f"   // define en input {COL['en']}"
    lines.append(dl)
    for i in range(n):
        term=" & ".join((f"a[{b}]" if (i>>b)&1 else f"~a[{b}]") for b in range(inb))
        if en:
            lines.append(f"    assign y[{i}] = en & ({term});")
        else:
            lines.append(f"    assign y[{i}] = ({term});")
    lines.append("endmodule")
    return name,"\n".join(lines)+"\n"
for inb in [1,2,3,4,5]:
    name,body=decoder(inb,False); emit(name,body,[f"{inb}-to-{1<<inb} one-hot decoder."])
for inb in [2,3,4,5]:
    name,body=decoder(inb,True); emit(name,body,[f"{inb}-to-{1<<inb} decoder with enable."])

# ---- encoders (simple, assume one-hot input) ----------------------------
def encoder(inb):
    n=1<<inb
    name=f"encoder{n}to{inb}"
    lines=[f"module {name}(input [{n-1}:0] a, output [{inb-1}:0] y);"]
    lines.append(f"    // define a input {COL['a']}   // define y output {COL['out']}")
    for b in range(inb):
        terms=[f"a[{i}]" for i in range(n) if (i>>b)&1]
        lines.append(f"    assign y[{b}] = {' | '.join(terms)};")
    lines.append("endmodule")
    return name,"\n".join(lines)+"\n"
for inb in [1,2,3,4,5]:
    n=1<<inb
    name,body=encoder(inb); emit(name,body,[f"{n}-to-{inb} binary encoder (one-hot input assumed)."])

# ---- priority encoders (+ _valid) --------------------------------------
def prio(width, valid=False):
    inb=log2(width)
    name=f"priority_encoder{width}"+("_valid" if valid else "")
    vp=", output valid" if valid else ""
    lines=[f"module {name}(input [{width-1}:0] a, output [{inb-1}:0] y{vp});"]
    dl=f"    // define a input {COL['a']}   // define y output {COL['out']}"
    if valid: dl+=f"   // define valid output {COL['status']}"
    lines.append(dl)
    lines.append("    integer k;")
    lines.append(f"    reg [{inb-1}:0] idx;")
    lines.append("    always @(*) begin")
    lines.append("        idx = 0;")
    lines.append(f"        for (k=0; k<{width}; k=k+1) if (a[k]) idx = k[%d:0];"%(inb-1))
    lines.append("    end")
    lines.append("    assign y = idx;")
    if valid: lines.append("    assign valid = |a;")
    lines.append("endmodule")
    return name,"\n".join(lines)+"\n"
for w in [4,8,16,32]:
    name,body=prio(w,False); emit(name,body,[f"Priority encoder ({w}->index of highest set bit)."])
for w in [4,8,16,32]:
    name,body=prio(w,True); emit(name,body,[f"Priority encoder w/ valid ({w}-bit; valid=|a)."])

# ---- one-hot converters -------------------------------------------------
def bin2onehot(w):
    inb=log2(w); name=f"bin_to_onehot{w}"
    lines=[f"module {name}(input [{inb-1}:0] a, output [{w-1}:0] y);"]
    lines.append(f"    // define a input {COL['a']}   // define y output {COL['out']}")
    for i in range(w):
        term=" & ".join((f"a[{b}]" if (i>>b)&1 else f"~a[{b}]") for b in range(inb))
        lines.append(f"    assign y[{i}] = ({term});")
    lines.append("endmodule")
    return name,"\n".join(lines)+"\n"
def onehot2bin(w):
    inb=log2(w); name=f"onehot_to_bin{w}"
    lines=[f"module {name}(input [{w-1}:0] a, output [{inb-1}:0] y);"]
    lines.append(f"    // define a input {COL['a']}   // define y output {COL['out']}")
    for b in range(inb):
        terms=[f"a[{i}]" for i in range(w) if (i>>b)&1]
        lines.append(f"    assign y[{b}] = {' | '.join(terms)};")
    lines.append("endmodule")
    return name,"\n".join(lines)+"\n"
def onehot_valid(w):
    name=f"onehot_valid{w}"
    lines=[f"module {name}(input [{w-1}:0] a, output valid);"]
    lines.append(f"    // define a input {COL['a']}   // define valid output {COL['status']}")
    # valid iff exactly one bit set
    lines.append(f"    wire any  = |a;")
    # more-than-one: OR of pairwise ANDs is expensive; use reduction trick: a & (a-1) but no '-'.
    # exactly-one = any & ~(any2). Build any2 = OR over i<j of a[i]&a[j] -> use prefix OR.
    lines.append(f"    reg has_lower;")
    lines.append(f"    reg multi;")
    lines.append("    integer k;")
    lines.append("    always @(*) begin")
    lines.append("        has_lower = 1'b0; multi = 1'b0;")
    lines.append(f"        for (k=0;k<{w};k=k+1) begin")
    lines.append("            if (a[k] && has_lower) multi = 1'b1;")
    lines.append("            if (a[k]) has_lower = 1'b1;")
    lines.append("        end")
    lines.append("    end")
    lines.append("    assign valid = any & ~multi;")
    lines.append("endmodule")
    return name,"\n".join(lines)+"\n"
for w in [4,8,16,32]:
    n,b=bin2onehot(w); emit(n,b,[f"Binary->one-hot ({w} lines)."])
    n,b=onehot2bin(w); emit(n,b,[f"One-hot->binary ({w} lines)."])
    n,b=onehot_valid(w); emit(n,b,[f"One-hot validity (exactly-one-bit) {w}-bit."])

print("mux/dec/enc generated")
