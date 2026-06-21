"""
build_all.py - regenerate the entire bitfries-logic-layouts library.

Each generator emits fully self-contained .v files (every submodule embedded
down to leaf gates) under src/<family>/. Run from anywhere:

    python3 scripts/build_all.py

Then verify with:

    ./scripts/verify.sh        # bulk Verilog-2001 elaboration (Icarus)
"""
import subprocess, os, sys

here = os.path.dirname(os.path.abspath(__file__))

# Generators in dependency-free build order. Each is independent; order only
# affects console grouping, not correctness (files never cross-reference).
GENERATORS = [
    # §1-3 foundations
    "gen_primitives.py",
    "gen_mux_dec_enc.py",
    "gen_comparators.py",
    # §4 adders (split across 4 scripts: cells/ripple/CLA, prefix+Ling, standard, special)
    "gen_adders.py",
    "gen_adders2.py",
    "gen_adders3.py",
    "gen_adders4.py",
    # §5 subtractors + add/sub units
    "gen_subtractors.py",
    "gen_subtractors2.py",
    # §9 shifters + bit manipulation
    "gen_shifters.py",
    # §10-11 popcount/bit-scan + converters
    "gen_popcount_converters.py",
    # §16 sequential, §17 counters
    "gen_sequential.py",
    "gen_counters.py",
    # §6 multipliers
    "gen_multipliers.py",
    # §19 ALU / datapath
    "gen_alu.py",
    # §7 dividers, §8 sqrt/reciprocal
    "gen_dividers.py",
    "gen_sqrt.py",
    # §12-14 BCD + display
    "gen_bcd.py",
    # §15 LUT / ROM / PLA (uses BITF_LUT / BITF_DECODER directives)
    "gen_lut_rom.py",
    # §18 memory + §20 error detection/correction
    "gen_memory_edac.py",
    # §21 sorting + §22 DSP
    "gen_sorting_dsp.py",
    # §23 floating-point
    "gen_floating_point.py",
    # §24 interfaces
    "gen_interfaces.py",
    # §25 demonstration circuits
    "gen_demos.py",
    # §26 CPUs: six architecture families x widths 4/8/16/32/64
    #   (the flagship src/CPUs/RV32IM_SYSTEM.v is hand-maintained, not generated)
    "gen_cpu_vonneumann.py",
    "gen_cpu_riscv.py",        # emits both single-cycle and 5-stage pipelined
    "gen_cpu_x86.py",
    "gen_cpu_arm.py",
    "gen_cpu_stack.py",
    # §27 GPUs: five designs forming a ladder up to the flagship
    #   (the flagship src/GPUs/GPU.v is hand-maintained, not generated)
    "gen_gpus.py",
]

def main():
    for g in GENERATORS:
        path = os.path.join(here, g)
        if not os.path.exists(path):
            print(f"  SKIP (missing): {g}")
            continue
        print("==>", g)
        subprocess.check_call([sys.executable, path])
    print("\nAll families generated. Run ./scripts/verify.sh to elaborate everything.")

if __name__ == "__main__":
    main()
