# Cross-ISA Interpreters

Fetch-path translation units: run one architecture's binary on another
family's CPU **without touching either design**. The interpreter sits on
the HOST CPU's instruction-fetch port and bypasses its control unit -
the host keeps decoding its native ISA; the interpreter rewrites the
fetch stream on the fly.

*Directory:* `src/interpreters/` -- 6 modules (4 interpreters + 2 fetch
switches), all purely combinational.

```
 +----------+ imem_addr  +---------------+ guest_addr  +-----------+
 | host CPU |----------->| interp_X_to_Y |------------>| guest ROM |
 | (native  |<-----------|  (pure comb.  |<------------| (the other |
 |  CU!)    | imem_data  |    logic)     | guest_instr |  ISA's bin)|
 +----------+            +-------+-------+             +-----------+
                                 | trap : high while feeding HALT for
                                 |        an untranslatable guest op
```

## The bundle scheme

Each guest instruction expands into a fixed-size bundle of N native host
instructions; the host PC simply indexes into bundle space:

```
host_pc = { guest_pc, slot }        (slot = log2(N) low bits)
```

Branch targets scale by N at translate time, so guest control flow works
unchanged. Because the mapping is pure combinational decode, each guest
opcode visibly lights its bundle's gates in the schematic viewer.

Shared port shape: `host_addr[7:0]` in / `host_instr` out on the host
side, `guest_addr` out / `guest_instr` in on the guest-ROM side, plus
`trap`. Shared constraint (all four): guest DATA must be established by
code (loads of constants, stores), not by a preloaded data image - the
host's data RAM is internal and starts empty.

| Module | Guest -> Host | N | Guest capacity |
|--------|---------------|---|----------------|
| `interp_vonneumann_to_x86_16` | accumulator vN -> x86 | 2 | 16 instrs (the guest's full space) |
| `interp_arm_to_x86_16` | ARM -> x86 | 8 | 32 instrs |
| `interp_x86_to_arm_16` | x86 -> ARM | 4 | 64 instrs |
| `interp_riscv_to_arm_16` | RV-lite -> ARM | 8 | 32 instrs |

## interp_vonneumann_to_x86_16

acc -> AX, guest mem[0..15] -> host RAM[0..15] (absolute MOVs), carry
polarity matches natively (both treat SUB carry as borrow; shifts carry
the bit out). LDA/LDI bundles append `OR AX,AX` so ZF always tracks the
accumulator - which clears CF, so guest `JC` must directly follow its
arithmetic op (the overwhelmingly common idiom). Full guest ISA
coverage; `trap` is tied low.

## interp_arm_to_x86_16

Guest r0..r15 live in host RAM[16..31] - a memory-mapped register file.
Bundle layout: slots 0-1 are a CONDITION GUARD (a host Jcc on the
*inverse* guest condition jumps to the slot-7 landing pad), rebuilding
ARM's "every instruction is conditional" from x86 conditional jumps.
The CS/CC conditions swap JC/JNC because ARM C = NOT borrow while x86
CF = borrow; HI and LS, which x86 cannot test in one jump, use both
guard slots. Slots 2-6: load AX/BX, optional pre-op (`NOT BX` for
MVN/BIC, operand swap for RSB), the ALU op, writeback. BL writes the
link (guest pc+1) to RAM[30] and jumps.

TRAPS - each names something the host LACKS: shifted register operands
(no barrel shifter; x86 shifts only by 1), ADC/SBC (no carry-in on the
host ALU), LDR/STR (no base+offset addressing, absolute only), BX (no
indirect jump). Flag caveats are documented in the header (host updates
flags on every arith/logic op regardless of S; MOVS gets Z/N via an
`OR AX,AX` fix-up that clears C).

## interp_x86_to_arm_16

The easy direction, and the schematic shows why - the ARM host is a
near-superset. AX..DX -> r0..r3, SP -> r13 (initialised to 32 by a
PREAMBLE slot stolen from bundle 0; guest instruction 0 therefore gets
3 payload slots), guest RAM[0..31] -> host dmem 1:1, scratch r11.
Two-operand ALU ops become S-suffixed three-operand ops; absolute
loads/stores become `MOV r11,#i ; LDR/STR [r11+0]`; PUSH/POP/CALL run
through r13; **RET pops the guest return address and rescales it into
bundle space at runtime with `MOV r11,r11 LSL #2 ; BX r11`** - the
barrel shifter doing what no static translation could. Jcc maps with
the same carry swap (JC->CC, JNC->CS). FULL guest ISA coverage; the
only trap is a 4-op guest instruction (CALL/RET) at address 0, where
the preamble leaves just 3 slots.

Kept quirks: NOT translates to flag-less MVN (matching x86's
"NOT touches no flags"). Documented deviations: INC/DEC update C on the
host (the CF-preserve quirk is not emulated), LOOP clobbers host flags,
ROL's carry is the result MSB rather than the rotated-in bit.

## interp_riscv_to_arm_16

x0..x15 -> r0..r15 one-to-one, with the **x0 invariant**: slot 0 of
EVERY bundle is `MOV r0,#0`, so r0 reads as zero at each guest
instruction boundary even if a JAL/ALU wrote rd=x0 a bundle earlier -
architecturally invisible, exactly like the guest. The guest has no
flags, so branches expand to `CMP + B<cond>` pairs and the host NZCV is
the translator's private scratch. SLT/SLTU become CMP plus a MOVLT/MOVCC
+ MOVGE/MOVCS pair. Negative ADDI immediates become SUB; LUI assembles
through r11 and an `LSL #8`; JALR rescales through the barrel shifter
like RET above. TRAPS: register-amount shifts (the host shifter takes
immediates only) and I-type/offset immediates outside 0..255.

## interp_fetch_switch16 / interp_fetch_switch32

A/B glue: mux a host's fetch port between its native ROM and an
interpreter at runtime, with the interpreter's trap gated so it is only
believed while selected. Flip `mode` and the same silicon becomes
"another CPU". The _16 variant suits the x86 family hosts, _32 the ARM
family.

## Verification

Golden tests in `tests/` run real guest programs through real host CPUs
(via the runner's `// FT_ALSO:` mechanism, which pulls the host CPU file
into the build):

- vN-on-x86: straight-line ISA sweep -> outs 15, 7, 0xFFFE, halted.
- ARM-on-x86: SUBS loop -> 55; cond-exec picks 7 and skips a poison
  ADDNE; MOVS Z-refresh feeds ADDEQ -> 30; BL writes its link; BX traps.
- x86-on-ARM: fib(10)=55 through LOOP, PUSH/POP across a clobber, and
  CALL/RET (the runtime BX rescale).
- RV-on-ARM: sum loop -> 55 (negative ADDI), SW/LW round-trip, SLT,
  write-to-x0 reads back 0, SLL-by-register traps.
- switch32: one cpu_arm16 outputs 11 from its native program, then 22
  from a RISC-V binary after flipping `mode`.
