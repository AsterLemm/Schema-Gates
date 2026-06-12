#!/usr/bin/env python3
"""
gen_lockstep.py -- build the lockstep equivalence harness.

For every refactored design this script creates, under tests/lockstep/:

  gold/gold_<name>.v   the PRISTINE pre-refactor file with its (single)
                       module renamed gold_<name>
  tb/tb_ls_<name>.v    a bench that instantiates BOTH the refactored top
                       (from src/) and the gold top, drives them with
                       IDENTICAL pseudo-random stimulus, and compares
                       every output bit every cycle
  run_lockstep.sh      compiles + runs all of them with Icarus Verilog

A PASS means the refactored hierarchy is cycle-exact against the original
for thousands of random input vectors -- on top of the repo's own
tests/run_functional_tests.sh, which still applies unchanged because no
top-level port changed.

Usage:  python3 scripts/gen_lockstep.py <pristine_src_dir>
        (pristine_src_dir = a checkout of src/ from BEFORE the refactor)
"""
import os, re, sys, zlib

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "tests", "lockstep")

# every refactored design, relative to src/
DESIGNS = []
for w in [4, 8, 16, 32, 64]:
    for fam in ["cpu_riscv", "cpu_riscv_pipelined", "cpu_arm",
                "cpu_vonneumann", "cpu_stack"]:
        DESIGNS.append(f"CPUs/{fam}{w}.v")
    DESIGNS.append(f"CPUs/cpu_x86_{w}.v")
DESIGNS += [f"GPUs/{g}.v" for g in
            ["GPU", "gpu_dot8", "gpu_sprite16", "gpu_vector32",
             "gpu_raster64", "gpu_pipelined32", "gpu_mmio_arbiter2",
             "gpu_frame_pacer", "gpu_frame_crc32", "gpu_row_to_pixel",
             "gpu_scene_player"]]
DESIGNS += [f"interpreters/{i}.v" for i in
            ["interp_fetch_switch16", "interp_fetch_switch32",
             "interp_vonneumann_to_x86_16", "interp_riscv_to_arm_16",
             "interp_arm_to_x86_16", "interp_x86_to_arm_16"]]
DESIGNS += [f"multipliers/partial_products{w}.v" for w in [4, 8, 16, 32]]
DESIGNS += [f"sorting/sort{n}_{w}.v" for n in [4, 8] for w in [4, 8]]
DESIGNS += [f"sorting/bitonic_sort{n}_8.v" for n in [4, 8, 16]]
DESIGNS += [f"adders/add_ling{w}.v" for w in [4, 8, 16, 32]]
DESIGNS += [f"dividers/reciprocal_seed{w}.v" for w in [4, 8, 16, 32]]

PORT_RE = re.compile(
    r"(input|output)\s+(wire|reg)?\s*(signed)?\s*(\[[^\]]+\])?\s*(\w+)\s*[,)]")


def parse_ports(text, top):
    m = re.search(r"module\s+" + re.escape(top) + r"\s*\(", text)
    depth, i = 1, m.end()
    while depth:
        if text[i] == "(": depth += 1
        elif text[i] == ")": depth -= 1
        i += 1
    plist = text[m.end()-1:i]
    ports = []
    for pm in PORT_RE.finditer(plist):
        d, _, sgn, rng, nm = pm.groups()
        width = 1
        if rng:
            hi, lo = re.match(r"\[\s*(\d+)\s*:\s*(\d+)\s*\]", rng).groups()
            width = abs(int(hi) - int(lo)) + 1
        ports.append((d, nm, width, (rng or "").strip()))
    return ports


def rand_drive(inputs):
    """Verilog statements assigning fresh $random bits to every input."""
    L = []
    for nm, w in inputs:
        if w <= 32:
            L.append(f"            r = $random(seed); {nm} = r[{w-1}:0];")
        else:
            parts, left = [], w
            n32 = (w + 31) // 32
            for k in range(n32):
                L.append(f"            r = $random(seed); rr[{k*32+31}:{k*32}] = r;")
            L.append(f"            {nm} = rr[{w-1}:0];")
    return "\n".join(L)


def make_tb(name, ports):
    ins  = [(n, w) for d, n, w, _ in ports
            if d == "input" and n not in ("clk", "reset", "rst")]
    outs = [(n, w, r) for d, n, w, r in ports if d == "output"]
    has_clk = any(n == "clk" for d, n, _, _ in ports if d == "input")
    rstname = next((n for d, n, _, _ in ports
                    if d == "input" and n in ("rst", "reset")), None)
    maxw = max([w for _, w in ins] + [32])
    decl_in  = "\n".join(f"    reg {('['+str(w-1)+':0] ') if w > 1 else ''}{n};"
                         for n, w in ins)
    decl_out = "\n".join(
        f"    wire {('['+str(w-1)+':0] ') if w > 1 else ''}d_{n};\n"
        f"    wire {('['+str(w-1)+':0] ') if w > 1 else ''}g_{n};"
        for n, w, _ in outs)
    conn_clk = "        .clk(clk),\n" if has_clk else ""
    conn_rst = f"        .{rstname}({rstname}),\n" if rstname else ""
    conn_in  = "".join(f"        .{n}({n}),\n" for n, _ in ins)

    def inst(mod, pref):
        conn_out = ",\n".join(f"        .{n}({pref}_{n})" for n, _, _ in outs)
        return (f"    {mod} {pref}ut(\n{conn_clk}{conn_rst}{conn_in}"
                f"{conn_out}\n    );")

    dvec = "{" + ", ".join(f"d_{n}" for n, _, _ in outs) + "}"
    gvec = "{" + ", ".join(f"g_{n}" for n, _, _ in outs) + "}"
    zero_ins = "\n".join(f"        {n} = 0;" for n, _ in ins)

    if has_clk:
        body = f"""    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        seed = 32'd{zlib.crc32(name.encode()) % 100000 + 1};
{zero_ins}
{"        " + rstname + " = 1;" if rstname else ""}
        repeat (5) @(posedge clk);
{"        " + rstname + " = 0;" if rstname else ""}
        for (i = 0; i < 2000; i = i + 1) begin
            @(negedge clk);
{rand_drive(ins)}
            @(posedge clk); #1;
            if ({dvec} !== {gvec}) begin
                errors = errors + 1;
                if (errors <= 5)
                    $display("MISMATCH {name} @cycle %0d", i);
            end
        end
        if (errors == 0) $display("PASS {name} lockstep (2000 cycles)");
        else $display("FAIL {name}: %0d mismatching cycles", errors);
        $finish;
    end"""
        clkdecl = "    reg clk;\n" + (f"    reg {rstname};\n" if rstname else "")
    else:
        body = f"""    initial begin
        seed = 32'd{zlib.crc32(name.encode()) % 100000 + 1};
{zero_ins}
        for (i = 0; i < 500; i = i + 1) begin
{rand_drive(ins)}
            #10;
            if ({dvec} !== {gvec}) begin
                errors = errors + 1;
                if (errors <= 5)
                    $display("MISMATCH {name} @vector %0d", i);
            end
        end
        if (errors == 0) $display("PASS {name} lockstep (500 vectors)");
        else $display("FAIL {name}: %0d mismatching vectors", errors);
        $finish;
    end"""
        clkdecl = ""

    return f"""// auto-generated by scripts/gen_lockstep.py -- do not edit
`timescale 1ns/1ps
module tb_ls_{name};
{clkdecl}{decl_in}
{decl_out}
    integer i, errors;
    integer seed;
    reg [31:0] r;
    reg [{max(maxw, 32)*2-1}:0] rr;
    initial errors = 0;

{inst(name, "d")}

{inst("gold_" + name, "g")}

{body}
endmodule
"""


def main():
    if len(sys.argv) < 2:
        print("usage: gen_lockstep.py <pristine_src_dir>"); sys.exit(1)
    GOLD_SRC = sys.argv[1]
    os.makedirs(os.path.join(OUT, "gold"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "tb"), exist_ok=True)
    runner = ["#!/bin/sh", "# auto-generated lockstep equivalence runner",
              "cd \"$(dirname \"$0\")\"", "mkdir -p build", "FAILED=0"]
    for rel in DESIGNS:
        name = os.path.basename(rel)[:-2]
        gold = open(os.path.join(GOLD_SRC, rel)).read()
        gold = re.sub(r"\bmodule\s+" + re.escape(name) + r"\b",
                      "module gold_" + name, gold, count=1)
        open(os.path.join(OUT, "gold", f"gold_{name}.v"), "w").write(gold)
        new = open(os.path.join(SRC, rel)).read()
        ports = parse_ports(new, name)
        open(os.path.join(OUT, "tb", f"tb_ls_{name}.v"), "w").write(
            make_tb(name, ports))
        runner.append(
            f"iverilog -g2005 -o build/ls_{name} tb/tb_ls_{name}.v "
            f"gold/gold_{name}.v ../../src/{rel} && "
            f"vvp build/ls_{name} | tee build/ls_{name}.log | "
            f"grep -q '^PASS' || {{ echo \"FAIL {name}\"; FAILED=1; }}")
    runner += ["if [ $FAILED -eq 0 ]; then echo 'ALL LOCKSTEP TESTS PASS';",
               "else echo 'SOME LOCKSTEP TESTS FAILED'; exit 1; fi"]
    open(os.path.join(OUT, "run_lockstep.sh"), "w").write("\n".join(runner) + "\n")
    os.chmod(os.path.join(OUT, "run_lockstep.sh"), 0o755)
    print(f"lockstep harness: {len(DESIGNS)} designs -> tests/lockstep/")


main()
