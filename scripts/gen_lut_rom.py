import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL
OUT=os.path.join(os.path.dirname(__file__),"..","src","lut_rom_pla")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

# ---- single-bit LUTs using BITF_LUT directive -------------------------
# A k-input 1-bit LUT: the directive tells SchemaGates to realize it as a LUT.
for k in [2,3,4,5,6]:
    n=1<<k
    # example function: parity (XOR reduce), but the LUT is generic via init
    L=[f"module lut{k}_1(input [{k-1}:0] addr, output y);"]
    L.append(f"    // define addr input {COL['a']}   // define y output {COL['out']}")
    L.append(f"    // BITF_LUT k={k} bits=1")
    L.append(f"    // {k}-input 1-bit lookup table. INIT below is the truth table (LSB=addr 0).")
    L.append(f"    parameter [{n-1}:0] INIT = {n}'h0;")
    L.append(f"    assign y = INIT[addr];")
    L.append("endmodule")
    emit(f"lut{k}_1", "\n".join(L)+"\n", [f"{k}-input 1-bit LUT (BITF_LUT directive)."])

# multi-bit LUTs (k-input, m-bit output) -> case ROM if product > LUT bound
for (k,m) in [(4,4),(4,8),(6,8),(8,8)]:
    n=1<<k
    bits=n*m
    L=[f"module lut{k}_{m}(input [{k-1}:0] addr, output [{m-1}:0] y);"]
    L.append(f"    // define addr input {COL['a']}   // define y output {COL['out']}")
    if k<=12 and m==1:
        L.append(f"    // BITF_LUT k={k} bits={m}")
    else:
        L.append(f"    // {k}-input {m}-bit table ({bits} bits <= 2048 ROM cap).")
    L.append(f"    reg [{m-1}:0] mem [0:{n-1}];")
    L.append(f"    integer i; initial for (i=0;i<{n};i=i+1) mem[i]=i[{m-1}:0];   // identity init (edit as needed)")
    L.append(f"    assign y = mem[addr];")
    L.append("endmodule")
    emit(f"lut{k}_{m}", "\n".join(L)+"\n", [f"{k}-input {m}-bit lookup table."])

# ---- ROMs (sync & async), within 2048-bit cap ------------------------
ROM_CONFIGS=[(4,8),(5,8),(6,8),(8,8),(4,16),(7,16)]  # (addr_bits, data_bits): bits=2^a*d
for ab,dw in ROM_CONFIGS:
    depth=1<<ab; bits=depth*dw
    if bits>2048: continue
    emit(f"rom_async_{depth}x{dw}",
         f"module rom_async_{depth}x{dw}(input [{ab-1}:0] addr, output [{dw-1}:0] data);\n"
         f"    // define addr input {COL['a']}   // define data output {COL['out']}\n"
         f"    // Asynchronous ROM {depth}x{dw} = {bits} bits (cap 2048).\n"
         f"    reg [{dw-1}:0] mem [0:{depth-1}];\n"
         f"    integer i; initial for (i=0;i<{depth};i=i+1) mem[i]=i[{dw-1}:0];\n"
         f"    assign data = mem[addr];\nendmodule\n",
         [f"Asynchronous ROM, {depth}x{dw} bits."])
    emit(f"rom_sync_{depth}x{dw}",
         f"module rom_sync_{depth}x{dw}(input clk, input [{ab-1}:0] addr, output reg [{dw-1}:0] data);\n"
         f"    // define clk input {COL['clk']}   // define addr input {COL['a']}   // define data output {COL['out']}\n"
         f"    // Synchronous ROM {depth}x{dw} = {bits} bits (cap 2048).\n"
         f"    reg [{dw-1}:0] mem [0:{depth-1}];\n"
         f"    integer i; initial for (i=0;i<{depth};i=i+1) mem[i]=i[{dw-1}:0];\n"
         f"    always @(posedge clk) data <= mem[addr];\nendmodule\n",
         [f"Synchronous ROM, {depth}x{dw} bits."])

# ---- decoder-based ROM using BITF_DECODER -----------------------------
for ab in [3,4]:
    depth=1<<ab; dw=8
    emit(f"rom_decoder_{depth}x{dw}",
         f"module rom_decoder_{depth}x{dw}(input [{ab-1}:0] addr, output [{dw-1}:0] data);\n"
         f"    // define addr input {COL['a']}   // define data output {COL['out']}\n"
         f"    // BITF_DECODER addr_bits={ab}\n"
         f"    // Decoder-driven ROM: one-hot address selects a hardwired word.\n"
         f"    wire [{depth-1}:0] sel;\n"
         + "".join(f"    assign sel[{i}] = (addr == {ab}'d{i});\n" for i in range(depth))
         + f"    reg [{dw-1}:0] word [0:{depth-1}];\n"
         f"    integer k; initial for (k=0;k<{depth};k=k+1) word[k]=k[{dw-1}:0];\n"
         f"    integer j; reg [{dw-1}:0] acc;\n"
         f"    always @(*) begin acc={dw}'b0; for (j=0;j<{depth};j=j+1) if (sel[j]) acc=word[j]; end\n"
         f"    assign data = acc;\nendmodule\n",
         [f"Decoder-based ROM {depth}x{dw} (BITF_DECODER directive)."])

# ---- RAM (<=512 bit cap) ---------------------------------------------
RAM_CONFIGS=[(4,8),(5,8),(4,16),(6,8)]  # 2^a*d <= 512
for ab,dw in RAM_CONFIGS:
    depth=1<<ab; bits=depth*dw
    if bits>512: continue
    emit(f"ram_sync_{depth}x{dw}",
         f"module ram_sync_{depth}x{dw}(input clk, input we, input [{ab-1}:0] addr, input [{dw-1}:0] din, output reg [{dw-1}:0] dout);\n"
         f"    // define clk input {COL['clk']}   // define we input {COL['en']}   // define addr input {COL['a']}\n"
         f"    // define din input {COL['b']}   // define dout output {COL['out']}\n"
         f"    // Synchronous RAM {depth}x{dw} = {bits} bits (cap 512).\n"
         f"    reg [{dw-1}:0] mem [0:{depth-1}];\n"
         f"    always @(posedge clk) begin if (we) mem[addr]<=din; dout<=mem[addr]; end\nendmodule\n",
         [f"Synchronous RAM, {depth}x{dw} bits."])

# ---- PLA / PAL --------------------------------------------------------
emit("pla_example_4in_3out",
     "module pla_example_4in_3out(input [3:0] in, output [2:0] out);\n"
     "    // define in input 80.160.255   // define out output 120.255.160\n"
     "    // Programmable Logic Array: AND-plane then OR-plane (sum of products).\n"
     "    wire p0 =  in[0] & in[1];\n"
     "    wire p1 =  in[2] & ~in[3];\n"
     "    wire p2 = ~in[0] & in[3];\n"
     "    wire p3 =  in[1] & in[2] & in[3];\n"
     "    assign out[0] = p0 | p2;\n"
     "    assign out[1] = p1 | p3;\n"
     "    assign out[2] = p0 | p1 | p3;\nendmodule\n",
     ["Example PLA: 4-input, 3-output sum-of-products."])
emit("pal_example_4in_2out",
     "module pal_example_4in_2out(input [3:0] in, output [1:0] out);\n"
     "    // define in input 80.160.255   // define out output 120.255.160\n"
     "    // PAL: fixed OR-plane, programmable AND-plane.\n"
     "    wire p0 = in[0] & in[1] & ~in[2];\n"
     "    wire p1 = in[2] & in[3];\n"
     "    wire p2 = ~in[0] & ~in[1];\n"
     "    assign out[0] = p0 | p1;\n"
     "    assign out[1] = p1 | p2;\nendmodule\n",
     ["Example PAL: 4-input, 2-output."])

print("lut/rom/pla generated")
