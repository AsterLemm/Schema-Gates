import os, re, glob

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC=os.path.join(ROOT,"src")
DOCS=os.path.join(ROOT,"docs")
os.makedirs(DOCS, exist_ok=True)

# human-friendly family titles & blurbs
FAM={
 "primitives":("Primitives","Basic logic gates, constants, bus join/split, reduction operators, and educational NAND-only / NOR-only realizations. These are the leaf cells every other family embeds."),
 "mux_decoder_encoder":("Multiplexers, Decoders & Encoders","N:1 multiplexers (built as mux2_1 trees), demultiplexers, binary decoders with enable, encoders, priority encoders with valid flags, and binary<->one-hot converters."),
 "comparators":("Comparators, Detectors & Flags","Equality and magnitude comparison (signed and unsigned), value detectors (zero, all-ones, sign, parity), and condition flags (carry, borrow, overflow, negative, zero)."),
 "adders":("Adders","The full spectrum of binary adders: structural cells, ripple-carry, carry-lookahead, every classic parallel-prefix topology, Ling, block-CLA, carry-skip/select, conditional-sum, carry-increment, carry-save, bit-serial, plus special adders (increment, modulo, saturating, one's-complement, end-around-carry)."),
 "subtractors":("Subtractors & Add/Sub Units","Borrow-ripple subtractors and two's-complement subtractors implemented on every adder core, combined add/subtract units with overflow, negation, absolute value, and sign/zero extension."),
 "shifters":("Shifters & Rotators","Structural log-depth barrel shifters, logical and arithmetic shifts, and rotators (left/right/bidirectional)."),
 "bit_manipulation":("Bit Manipulation","Bit reversal, low/high masks, single-bit set/clear/toggle, bitfield extract/insert, and nibble/byte swaps."),
 "popcount_bitscan":("Population Count & Bit Scan","Population count, leading/trailing zero and one counts, first/last set-bit index with valid, and power-of-two detection."),
 "converters":("Code Converters","Binary<->Gray, one's/two's complement and sign-magnitude conversions, thermometer code, and excess/bias (excess-3/15/127) converters."),
 "sequential":("Sequential Elements","Latches (SR, gated SR, D, JK, T), flip-flops (D edge-triggered with enable/reset variants, JK, T), registers (with enable and reset), and shift registers (SISO/SIPO/PISO/PIPO/universal)."),
 "counters":("Counters & Timing","Up/down/up-down counters, ring, Johnson, and Gray counters, modulo-N counters, LFSRs (Fibonacci and Galois), timers, PWM generators, clock dividers, edge detectors, and a debouncer."),
 "multipliers":("Multipliers","Partial-product generation, array/Braun/carry-save multipliers, Wallace and Dadda trees, Booth radix-2/4/8 (signed), Baugh-Wooley, sign-magnitude, two's-complement, squarers, constant multipliers, and multiply-accumulate."),
 "alu_datapath":("ALU & Datapath","Logic-only, arithmetic-only, and full ALUs with Z/N/C/V flags and shift support, plus datapath building blocks: program counter, branch-target adder, instruction register, stack pointer, accumulator, status register, and a small worked datapath."),
 "dividers":("Dividers","Restoring and non-restoring dividers (combinational and iterative), signed division, SRT radix-2/4 models, modulo, remainder, and reciprocal/Newton-Raphson/Goldschmidt units. Every divider exposes quotient, remainder, divide_by_zero, overflow, valid, busy, and done."),
 "sqrt_reciprocal":("Square Root & Reciprocal","Integer square root (combinational non-restoring, iterative digit-by-digit, and Newton's method) and reciprocal-square-root."),
 "bcd":("Binary-Coded Decimal","Binary<->BCD conversion via double-dabble, BCD addition and subtraction with decimal correction (digit widths 1/2/4/8 plus bit-mapped 4/8/16/32 aliases), validity checking, and nine's complement."),
 "display":("Display Drivers","Binary and BCD to seven-segment decoders (with optional decimal point) and ASCII digit conversion."),
 "lut_rom_pla":("LUT / ROM / PLA / PAL","Lookup tables driven by the BITF_LUT directive, asynchronous and synchronous ROMs, a decoder-based ROM using BITF_DECODER, small synchronous RAMs, and example PLA/PAL sum-of-products arrays."),
 "memory":("Memory","Register files (1-write / 2-read, including a RISC-style file with a hardwired zero register), true dual-port RAM, and a content-addressable memory."),
 "error_detection":("Error Detection & Correction","Even/odd parity generation and checking, Hamming single-error-correcting codes (7,4 and generic 12/8, 21/16, 38/32), CRC (serial and parallel) for several polynomials, and additive / one's-complement checksums."),
 "sorting":("Sorting Networks","Min/max and compare-swap primitives, median-of-three, optimal small sorting networks (4 and 8 inputs), and bitonic sorters."),
 "dsp":("Fixed-Point DSP","Q-format fixed-point add/subtract/multiply with rescaling, rounding and saturation, a 4-tap FIR moving-average filter, and an iterative CORDIC rotator."),
 "floating_point":("Floating Point","Educational fp8 (E4M3) and fp16 (IEEE half) units: field pack/unpack, classification, comparison, add/subtract/multiply/divide, normalization, rounding, and integer<->fp16 conversion."),
 "interfaces":("Interfaces & Communication","UART transmit/receive with a baud generator, SPI master and slave (mode 0), a simplified I2C byte writer, parallel<->serial converters, a req/ack handshake, and synchronous FIFOs."),
 "demos":("Demonstration Circuits","Self-contained worked examples that wire the building blocks into recognizable circuits: adders, a counter with seven-segment output, an ALU, a traffic-light FSM, a tiny accumulator CPU, a stopwatch, and a dice roller."),
}

# explicit catalog order
ORDER=["primitives","mux_decoder_encoder","comparators","adders","subtractors",
 "shifters","bit_manipulation","popcount_bitscan","converters","sequential",
 "counters","multipliers","alu_datapath","dividers","sqrt_reciprocal","bcd",
 "display","lut_rom_pla","memory","error_detection","sorting","dsp",
 "floating_point","interfaces","demos"]

def first_desc(path):
    """Pull the first non-boilerplate banner comment line as the module description."""
    with open(path) as f:
        lines=f.readlines()
    for ln in lines:
        s=ln.strip()
        if s.startswith("//"):
            txt=s.lstrip("/").strip()
            if not txt: continue
            if txt.startswith("="): continue
            if "bitfries-logic-layouts" in txt: continue
            if "Self-contained" in txt: continue
            if "Target synthesizer" in txt: continue
            if txt.endswith(".v"): continue
            return txt
    return ""

index=["# schema-gates, Documentation (formerly bitfries-logic-layouts)","",
       "Reference notes for each module family. Every module listed here lives in a",
       "single self-contained `.v` file under `src/<family>/` and elaborates cleanly",
       "under Icarus Verilog.","",
       "## Families",""]

for fam in ORDER:
    d=os.path.join(SRC,fam)
    if not os.path.isdir(d): continue
    files=sorted(glob.glob(os.path.join(d,"*.v")))
    title,blurb=FAM.get(fam,(fam,""))
    index.append(f"- [{title}](./{fam}.md), {len(files)} modules")
    # per-family doc
    doc=[f"# {title}","",blurb,"",f"*Directory:* `src/{fam}/`, {len(files)} modules.","",
         "| Module | Description |","|--------|-------------|"]
    for fp in files:
        name=os.path.basename(fp)[:-2]
        desc=first_desc(fp).replace("|","\\|")
        doc.append(f"| `{name}` | {desc} |")
    doc.append("")
    with open(os.path.join(DOCS,f"{fam}.md"),"w") as f:
        f.write("\n".join(doc))

index.append("")

# Hand-maintained family pages: indexed here with live module counts, but the
# generator never (re)writes their .md files.
EXTRA=[("CPUs","cpus"),("GPUs","gpus"),
       ("Cross-ISA Interpreters","interpreters"),("Games","games")]
for title,fam in EXTRA:
    # directory names: src/CPUs, src/GPUs, src/interpreters, src/games
    d=os.path.join(SRC,{"cpus":"CPUs","gpus":"GPUs"}.get(fam,fam))
    if not os.path.isdir(d): continue
    n=len(glob.glob(os.path.join(d,"*.v")))
    index.append(f"- [{title}](./{fam}.md), {n} modules")

def _famdir(fam):
    return os.path.join(SRC,{"cpus":"CPUs","gpus":"GPUs"}.get(fam,fam))
ALL=[f for f in ORDER+[e[1] for e in EXTRA] if os.path.isdir(_famdir(f))]
total=sum(len(glob.glob(os.path.join(_famdir(f),"*.v"))) for f in ALL)
index.append("")
index.append(f"_Total: {total} modules across {len(ALL)} families._")
with open(os.path.join(DOCS,"README.md"),"w") as f:
    f.write("\n".join(index)+"\n")

print(f"docs generated: {len(ORDER)} family pages + index")
