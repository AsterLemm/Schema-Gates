import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
OUTM=os.path.join(os.path.dirname(__file__),"..","src","memory")
OUTE=os.path.join(os.path.dirname(__file__),"..","src","error_detection")
def emitm(name,body,desc): write(os.path.join(OUTM,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
def emite(name,body,desc): write(os.path.join(OUTE,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

# ---- register files (depth x width, <=512 bits), 1W/2R typical -------
RF=[(8,4),(8,8),(16,8),(4,16),(8,16),(16,4)]  # (regs, width): regs*width<=... keep <=512
for regs,w in RF:
    if regs*w>512: continue
    ab=int(math.ceil(math.log2(regs)))
    emitm(f"regfile_{regs}x{w}",
          f"module regfile_{regs}x{w}(input clk, input we, input [{ab-1}:0] waddr, input [{w-1}:0] wdata,\n"
          f"    input [{ab-1}:0] raddr_a, input [{ab-1}:0] raddr_b, output [{w-1}:0] rdata_a, output [{w-1}:0] rdata_b);\n"
          f"    // define clk input {COL['clk']}   // define we input {COL['en']}   // define waddr input {COL['sel']}\n"
          f"    // define wdata input {COL['b']}   // define rdata_a output {COL['out']}   // define rdata_b output {COL['out']}\n"
          f"    // {regs}x{w} register file, 1 write / 2 read ports ({regs*w} bits).\n"
          f"    reg [{w-1}:0] regs [0:{regs-1}];\n"
          f"    always @(posedge clk) if (we) regs[waddr] <= wdata;\n"
          f"    assign rdata_a = regs[raddr_a];\n"
          f"    assign rdata_b = regs[raddr_b];\nendmodule\n",
          [f"{regs}x{w} register file (1W/2R)."])

# ---- register file with zero-register r0 (RISC-style) ----------------
emitm("regfile_riscv_8x8",
      "module regfile_riscv_8x8(input clk, input we, input [2:0] waddr, input [7:0] wdata,\n"
      "    input [2:0] raddr_a, input [2:0] raddr_b, output [7:0] rdata_a, output [7:0] rdata_b);\n"
      "    // define clk input 255.230.80   // define we input 255.180.80\n"
      "    // 8x8 register file; register 0 hardwired to zero (RISC convention).\n"
      "    reg [7:0] regs [1:7];\n"
      "    always @(posedge clk) if (we && waddr!=3'b0) regs[waddr] <= wdata;\n"
      "    assign rdata_a = (raddr_a==3'b0) ? 8'b0 : regs[raddr_a];\n"
      "    assign rdata_b = (raddr_b==3'b0) ? 8'b0 : regs[raddr_b];\nendmodule\n",
      ["8x8 RISC register file (r0 = zero)."])

# ---- small memories: dual-port, fifo-backing ------------------------
emitm("dpram_16x8",
      "module dpram_16x8(input clk, input we_a, input [3:0] addr_a, input [7:0] din_a, output reg [7:0] dout_a,\n"
      "    input [3:0] addr_b, output reg [7:0] dout_b);\n"
      "    // define clk input 255.230.80   // define we_a input 255.180.80\n"
      "    // True dual-port RAM 16x8 (128 bits).\n"
      "    reg [7:0] mem [0:15];\n"
      "    always @(posedge clk) begin if (we_a) mem[addr_a]<=din_a; dout_a<=mem[addr_a]; dout_b<=mem[addr_b]; end\nendmodule\n",
      ["16x8 dual-port RAM."])

# ---- content-addressable memory (small) ------------------------------
emitm("cam_8x8",
      "module cam_8x8(input clk, input we, input [2:0] waddr, input [7:0] wdata,\n"
      "    input [7:0] search, output [7:0] match, output hit);\n"
      "    // define clk input 255.230.80   // define search input 80.160.255   // define match output 120.255.160\n"
      "    // 8-entry x 8-bit content-addressable memory.\n"
      "    reg [7:0] mem [0:7];\n"
      "    always @(posedge clk) if (we) mem[waddr]<=wdata;\n"
      "    genvar i;\n"
      "    generate for (i=0;i<8;i=i+1) begin : cmp\n"
      "        assign match[i] = (mem[i]==search);\n"
      "    end endgenerate\n"
      "    assign hit = |match;\nendmodule\n",
      ["8x8 content-addressable memory (parallel match)."])

# ---- §20 parity ------------------------------------------------------
for w in WIDTHS:
    emite(f"parity_even{w}",
          f"module parity_even{w}(input [{w-1}:0] a, output p);\n"
          f"    // define a input {COL['a']}   // define p output {COL['status']}\n"
          f"    assign p = ^a;   // even parity bit (1 if odd # of ones)\nendmodule\n",
          [f"{w}-bit even-parity generator."])
    emite(f"parity_odd{w}",
          f"module parity_odd{w}(input [{w-1}:0] a, output p);\n"
          f"    // define a input {COL['a']}   // define p output {COL['status']}\n"
          f"    assign p = ~(^a);  // odd parity bit\nendmodule\n",
          [f"{w}-bit odd-parity generator."])
    emite(f"parity_check{w}",
          f"module parity_check{w}(input [{w-1}:0] a, input p, output error);\n"
          f"    // define a input {COL['a']}   // define p input {COL['cin']}   // define error output {COL['flag']}\n"
          f"    assign error = (^a) ^ p;   // even-parity check\nendmodule\n",
          [f"{w}-bit even-parity checker."])

# ---- Hamming codes ---------------------------------------------------
# (7,4)
emite("hamming_encode_7_4",
      "module hamming_encode_7_4(input [3:0] d, output [6:0] code);\n"
      "    // define d input 80.160.255   // define code output 120.255.160\n"
      "    // bits: p1 p2 d1 p4 d2 d3 d4  (positions 1..7)\n"
      "    wire p1 = d[0]^d[1]^d[3];\n"
      "    wire p2 = d[0]^d[2]^d[3];\n"
      "    wire p4 = d[1]^d[2]^d[3];\n"
      "    assign code = {d[3],d[2],d[1],p4,d[0],p2,p1};\nendmodule\n",
      ["Hamming (7,4) encoder."])
emite("hamming_decode_7_4",
      "module hamming_decode_7_4(input [6:0] code, output [3:0] d, output [2:0] syndrome, output error);\n"
      "    // define code input 80.160.255   // define d output 120.255.160   // define error output 255.120.120\n"
      "    wire c1=code[0], c2=code[1], dd1=code[2], c4=code[3], dd2=code[4], dd3=code[5], dd4=code[6];\n"
      "    wire s1 = c1 ^ dd1 ^ dd2 ^ dd4;\n"
      "    wire s2 = c2 ^ dd1 ^ dd3 ^ dd4;\n"
      "    wire s4 = c4 ^ dd2 ^ dd3 ^ dd4;\n"
      "    wire [6:0] corr;\n"
      "    wire [2:0] syn = {s4,s2,s1};\n"
      "    assign corr = (syn==3'd0) ? code : (code ^ (7'b1 << (syn-1)));\n"
      "    assign d = {corr[6],corr[5],corr[4],corr[2]};\n"
      "    assign syndrome = syn;\n"
      "    assign error = |syn;\nendmodule\n",
      ["Hamming (7,4) decoder with single-error correction."])
# wider SECDED-style encoders (data widths 8/16/32) - parity-based, named
HAM={8:(12,"12_8"),16:(21,"21_16"),32:(38,"38_32")}
for dw,(cw,tag) in HAM.items():
    # number of parity bits
    pb=cw-dw
    emite(f"hamming_encode_{tag}",
          f"module hamming_encode_{tag}(input [{dw-1}:0] d, output [{cw-1}:0] code);\n"
          f"    // define d input {COL['a']}   // define code output {COL['out']}\n"
          f"    // Hamming SEC code: {dw} data + {pb} parity = {cw} bits.\n"
          f"    integer i, pos, pi; reg [{cw-1}:0] c; reg [{dw-1}:0] dd;\n"
          f"    always @(*) begin\n"
          f"        c = 0; dd = d; pos = 0;\n"
          f"        // place data bits into non-power-of-two positions (1-indexed)\n"
          f"        for (i=1;i<={cw};i=i+1) begin\n"
          f"            if ((i & (i-1)) != 0) begin c[i-1] = dd[pos]; pos = pos+1; end\n"
          f"        end\n"
          f"        // compute parity bits at power-of-two positions\n"
          f"        for (pi=0;pi<{pb};pi=pi+1) begin : pgen\n"
          f"            integer mask; reg par; integer j;\n"
          f"            mask = (1<<pi); par=0;\n"
          f"            for (j=1;j<={cw};j=j+1) if ((j & mask)!=0 && j!=mask) par = par ^ c[j-1];\n"
          f"            c[mask-1] = par;\n"
          f"        end\n"
          f"    end\n"
          f"    assign code = c;\nendmodule\n",
          [f"Hamming SEC encoder ({dw} data -> {cw} bits)."])
    emite(f"hamming_decode_{tag}",
          f"module hamming_decode_{tag}(input [{cw-1}:0] code, output [{dw-1}:0] d, output error);\n"
          f"    // define code input {COL['a']}   // define d output {COL['out']}   // define error output {COL['flag']}\n"
          f"    integer pi, j, pos, i; reg [{pb}:0] syn; reg [{cw-1}:0] corr; reg [{dw-1}:0] dd;\n"
          f"    always @(*) begin\n"
          f"        syn=0;\n"
          f"        for (pi=0;pi<{pb};pi=pi+1) begin : sgen\n"
          f"            integer mask; reg par;\n"
          f"            mask=(1<<pi); par=0;\n"
          f"            for (j=1;j<={cw};j=j+1) if ((j & mask)!=0) par = par ^ code[j-1];\n"
          f"            syn[pi]=par;\n"
          f"        end\n"
          f"        corr = code;\n"
          f"        if (syn!=0 && syn<={cw}) corr[syn-1] = ~corr[syn-1];\n"
          f"        dd=0; pos=0;\n"
          f"        for (i=1;i<={cw};i=i+1) if ((i & (i-1))!=0) begin dd[pos]=corr[i-1]; pos=pos+1; end\n"
          f"    end\n"
          f"    assign d = dd; assign error = |syn;\nendmodule\n",
          [f"Hamming SEC decoder ({cw} bits -> {dw} data, 1-bit correct)."])

# ---- CRC (serial + parallel) -----------------------------------------
CRC_POLY={4:0x3, 8:0x07, 16:0x1021, 32:0x04C11DB7}
for w,poly in CRC_POLY.items():
    emite(f"crc{w}_serial",
          f"module crc{w}_serial(input clk, input rst, input en, input bit_in, output [{w-1}:0] crc);\n"
          f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define en input {COL['en']}\n"
          f"    // define bit_in input {COL['a']}   // define crc output {COL['out']}\n"
          f"    // CRC-{w}, polynomial 0x{poly:X}\n"
          f"    reg [{w-1}:0] reg_crc;\n"
          f"    wire fb = reg_crc[{w-1}] ^ bit_in;\n"
          f"    always @(posedge clk) begin\n"
          f"        if (rst) reg_crc <= {w}'b0;\n"
          f"        else if (en) reg_crc <= ({{reg_crc[{w-2}:0],1'b0}}) ^ (fb ? {w}'h{poly:x} : {w}'b0);\n"
          f"    end\n"
          f"    assign crc = reg_crc;\nendmodule\n",
          [f"CRC-{w} serial (LFSR), poly 0x{poly:X}."])
    emite(f"crc{w}_parallel",
          f"module crc{w}_parallel(input [{w-1}:0] data, input [{w-1}:0] crc_in, output [{w-1}:0] crc_out);\n"
          f"    // define data input {COL['a']}   // define crc_in input {COL['b']}   // define crc_out output {COL['out']}\n"
          f"    // CRC-{w} parallel update over {w} data bits, poly 0x{poly:X}\n"
          f"    integer i; reg [{w-1}:0] c; reg fb;\n"
          f"    always @(*) begin\n"
          f"        c = crc_in;\n"
          f"        for (i={w-1}; i>=0; i=i-1) begin\n"
          f"            fb = c[{w-1}] ^ data[i];\n"
          f"            c = {{c[{w-2}:0],1'b0}} ^ (fb ? {w}'h{poly:x} : {w}'b0);\n"
          f"        end\n"
          f"    end\n"
          f"    assign crc_out = c;\nendmodule\n",
          [f"CRC-{w} parallel (whole word), poly 0x{poly:X}."])

# ---- checksums -------------------------------------------------------
for w in [8,16,32]:
    emite(f"checksum_add{w}",
          f"module checksum_add{w}(input [{w-1}:0] a, input [{w-1}:0] b, input [{w-1}:0] acc_in, output [{w-1}:0] acc_out, output carry);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define acc_out output {COL['out']}\n"
          f"    wire [{w}:0] s = a + b + acc_in;\n"
          f"    assign acc_out = s[{w-1}:0]; assign carry = s[{w}];\nendmodule\n",
          [f"{w}-bit additive checksum step."])
    emite(f"checksum_ones_complement{w}",
          f"module checksum_ones_complement{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] sum);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sum output {COL['out']}\n"
          f"    wire [{w}:0] t = a + b;\n"
          f"    assign sum = t[{w-1}:0] + t[{w}];   // end-around carry (internet checksum style)\nendmodule\n",
          [f"{w}-bit one's-complement checksum add."])

print("memory + edac generated")
