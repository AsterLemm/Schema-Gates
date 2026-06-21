# CPUs

Complete processors, six architecture families at five data widths each
(4/8/16/32/64), plus the hand-written flagship `RV32IM_SYSTEM`. The point of
the family is architectural contrast: the same kinds of programs run on a
one-accumulator von Neumann machine, a load/store RISC (single-cycle and
5-stage pipelined), a two-operand CISC with flags, a conditionally-executed
ARM-style core, and a zero-address stack machine -- and the differences are
visible in the schematic.

*Directory:* `src/CPUs/` -- 31 modules (30 generated + 1 hand-maintained
flagship).

| Module family | Model | Instruction word | The lesson |
|---------------|-------|------------------|------------|
| `cpu_vonneumann4/8/16/32/64` | accumulator, multicycle | W-bit, unified memory | one memory for code+data = the fetch/execute bottleneck |
| `cpu_riscv4/8/16/32/64` | 16-reg load/store, single-cycle | 32-bit Harvard | RISC datapath at its simplest |
| `cpu_riscv_pipelined4/8/16/32/64` | same ISA, 5-stage pipeline | 32-bit Harvard | forwarding, interlocks, flushes |
| `cpu_x86_4/8/16/32/64` | 4-reg two-operand CISC | 16-bit Harvard | FLAGS, stack in memory, condition-code jumps |
| `cpu_arm4/8/16/32/64` | 16-reg, conditional execution | 32-bit Harvard | predication, barrel shifter, NZCV |
| `cpu_stack4/8/16/32/64` | zero-address dual-stack | 16-bit Harvard | implicit operands, TOS/NOS spill |
| `RV32IM_SYSTEM` | ratified RV32IM + GPU + MMIO | 32-bit | the flagship; hand-maintained, not generated |

Cross-ISA note: the `src/interpreters/` family runs one of these ISAs'
binaries on another family's host by translating the fetch stream - the
host's control unit is never modified. See `docs/interpreters.md`.

## Shared contract

Every generated CPU exposes the same observation surface so one testbench
style fits all of them:

- `out_data[W-1:0]` / `out_valid` -- the OUT instruction writes a value to
  this port and pulses `out_valid` for one cycle.
- `halted` -- sticky; raised by the HALT instruction.
- `dbg_*` -- combinational state peek (register file / accumulator / TOS,
  plus `dbg_pc`). Zero hardware cost in the schematic flow; remove freely.
- Harvard cores fetch through `imem_addr[7:0]` / `imem_data` from an
  external ROM (programs are plain `reg [..] rom [0:255]` arrays in the
  testbenches). The von Neumann core instead has a unified internal memory
  loaded through `prog_we/prog_addr/prog_data` while `run=0` -- by design,
  since the shared memory *is* its lesson.

**Operand isolation** (flagship technique, used in every core): each ALU
path's inputs are ANDed with that path's select, so a path that is not in
use computes on all-zero inputs and its gates do not toggle. In the
schematic viewer this makes the active path visibly light up. The pipelined
RISC cores additionally expose the gates as **pipeline synchronizer** pins
(`ppln_add/ppln_logic/ppln_shift/ppln_cmp`) following `RV32IM_SYSTEM.v` --
AND-combined with the internal selects; tie high for normal operation,
strobe externally to step/observe individual execution classes.

**Width-4 caveat:** on `cpu_x86_4` (CALL/RET) and `cpu_arm4` (BL/BX) return
addresses live in 4-bit storage (the unified RAM word / `r14`), so keep
subroutine return targets below address 16 on those two cores. All other
widths store full 8-bit return addresses.

## cpu_vonneumann -- accumulator machine, unified memory

Multicycle SAP-style core. W=4 uses a 32×4 memory with two-nibble fetch
(`ST_FETCH`/`ST_FETCH2`); W≥8 uses 16×W with single-word fetch
(high nibble = opcode, low nibble = operand address).

| Op | Mnemonic | Action |
|----|----------|--------|
| 0 | NOP | -- |
| 1 | LDA m | acc = mem[m] |
| 2 | STA m | mem[m] = acc |
| 3-7 | ADD/SUB/AND/OR/XOR m | acc = acc op mem[m] |
| 8 | LDI i | acc = zero-extended nibble |
| 9 | JMP a | pc = a |
| A | JZ a | pc = a if acc == 0 |
| B | JC a | pc = a if carry |
| C/D | SHL/SHR | shift acc by one |
| E | OUT | out_data = acc |
| F | HLT | stop |

The FSM serializes fetch and execute through the single memory port -- the
von Neumann bottleneck, visible as the address mux flipping between `pc`
and `operand`.

## cpu_riscv -- RV-lite, single-cycle and 5-stage pipelined

A RISC-V-flavoured teaching ISA (uniform fields; the ratified RV32IM
encoding lives in the flagship). 16 registers, `x0` hardwired to zero.
Fixed 32-bit Harvard instructions:

```
[31:28] op   [27:24] rd   [23:20] rs1   [19:16] rs2   [15:0] imm16
imm = sign-extended imm16 (truncated to W); branch/jump offsets in words
```

| Op | Meaning | Op | Meaning |
|----|---------|----|---------|
| 0 | ALU-R, funct=imm[3:0]: 0 ADD 1 SUB 2 AND 3 OR 4 XOR 5 SLL 6 SRL 7 SRA 8 SLT 9 SLTU | 8 | BEQ |
| 1 | ADDI | 9 | BNE |
| 2 | ANDI | A | BLT (signed) |
| 3 | ORI | B | BGE (signed) |
| 4 | XORI | C | JAL (rd = pc+1) |
| 5 | LUI (imm16 in the TOP 16 bits for W≥16) | D | JALR |
| 6 | LW (16-word data RAM) | E | OUT rs1 |
| 7 | SW | F | HALT |

`cpu_riscv_pipelined*` runs the identical ISA through IF/ID/EX/MEM/WB with:
full EX forwarding from EX/MEM and MEM/WB; a transparent register file
(WB bypasses to ID in the same cycle); a conservative one-cycle load-use
interlock (any rd/rs match after a load stalls); branch/jump resolution in
EX with a two-slot flush; and in-order HALT retirement (fetch stops, the
pipe drains, then `halted` rises). `tests/tb_cpu_riscv_pipelined32.v`
demonstrates each mechanism, including poison instructions in a branch
shadow that must never retire.

## cpu_x86 -- two-operand CISC with FLAGS

8086-lineage teaching subset. Registers AX BX CX DX, a FLAGS register
(CF ZF SF OF), and SP into a 32-word unified data/stack RAM (descending,
init 32). 16-bit Harvard instructions:

```
[15:12] op   [11:10] r   [9:8] m   [7:0] imm8
```

| Op | Meaning | Op | Meaning |
|----|---------|----|---------|
| 0 | MOV r,m | 8 | unary (m: 0 INC 1 DEC 2 NOT 3 NEG) |
| 1 | MOV r,imm8 | 9 | shift by 1 (m: 0 SHL 1 SHR 2 SAR 3 ROL) |
| 2 | ADD r,m | A | MOV r,[imm8] |
| 3 | SUB r,m | B | MOV [imm8],r |
| 4 | AND r,m | C | stack (m: 0 PUSH r 1 POP r 2 CALL imm8 3 RET) |
| 5 | OR r,m | D | Jcc imm8, cond = {r,m} |
| 6 | XOR r,m | E | MOVH r,imm8 -- r = (r<<8)\|imm8 |
| 7 | CMP r,m | F | misc (m: 0 NOP 1 HLT 2 OUT r) |

Jcc conditions: 0 JMP 1 JZ 2 JNZ 3 JC 4 JNC 5 JS 6 JNS 7 JO 8 JNO
9 JL 10 JGE 11 JG 12 JLE **13 LOOP** (decrement CX, jump while CX≠0,
flags untouched) 14/15 never.

Authentic flag quirks are kept on purpose and tested in
`tests/tb_cpu_x86_16.v`: **INC/DEC preserve CF**; **NOT touches no flags
at all**; logic ops clear CF/OF; ROL updates only CF/OF; NEG sets
CF = (src ≠ 0).

## cpu_arm -- conditional execution and the barrel shifter

Classic-ARM data-processing model. Every instruction carries a 4-bit
condition read against NZCV; `r14` is the link register. Deviation from
real ARM (documented in the file header): `r15` is *not* the PC -- the PC is
a separate 8-bit counter.

```
[31:28] cond  [27] S  [26:25] cls  [24:21] op4  [20:17] rd  [16:13] rn
[12:9] rm  [8:7] shtyp  [6:2] shamt5  [1:0] 00
cls: 00 DP-register (op2 = barrel(rm))   01 DP-immediate (imm8 = [12:5])
     10 memory (op4[0]: LDR/STR rd,[rn+imm8])
     11 flow (op4: 0 B imm17  1 BL  2 BX rn  3 OUT rn  4 HALT;
              imm17 = signed [16:0], pc-relative)
DP op4: 0 AND 1 EOR 2 SUB 3 RSB 4 ADD 5 ADC 6 SBC 7 ORR
        8 MOV 9 MVN 10 BIC 11(=MOV) 12 CMP 13 CMN 14 TST 15 TEQ
```

Conditions: EQ NE CS CC MI PL VS VC HI LS GE LT GT LE AL NV.
The op2 barrel shifter (LSL/LSR/ASR/ROR by imm5) feeds its carry-out into
C on logical S-ops (shift amount 0 leaves C unchanged). Subtraction sets
C = NOT borrow (the ARM convention), and ADC/SBC chain it through a single
unified adder with operand inversion. CMP/CMN/TST/TEQ always write flags
and never write `rd`.

## cpu_stack -- zero-address dual-stack machine

Forth/Burroughs lineage. No register operands: binary ops consume the top
two cells (`tos = nos OP tos`). The two top cells live in registers
(TOS/NOS) with a 16-deep spill RAM beneath them -- the classic optimisation
that makes every instruction single-cycle. CALL/RET use a **separate**
8-deep return stack.

```
[15:12] op   [11:0] imm12 (sign-extended where used)
```

| Op | Meaning | Op | Meaning |
|----|---------|----|---------|
| 0 | PUSHI imm | 8 | DUP |
| 1 | LOAD [imm[4:0]] | 9 | DROP |
| 2 | STORE [imm[4:0]] | A | SWAP |
| 3 | ADD | B | OVER |
| 4 | SUB (nos − tos) | C | JMP |
| 5 | AND | D | JZ (pops) |
| 6 | OR | E | CALL |
| 7 | XOR | F | imm[1:0]: 0 RET 1 OUT (pops) 2 HALT 3 NOP |

`dbg_depth` exposes the live cell count; `tests/tb_cpu_stack16.v` pushes
five items (three spill) and collapses them to prove the refill path.

## Flagship: RV32IM_SYSTEM

`src/CPUs/RV32IM_SYSTEM.v` is the hand-written BITFries-RV32IM system --
ratified RV32IM encodings, M-extension, MMIO bridge to the flagship GPU,
and the full pipeline-synchronizer / operand-isolation discipline the
generated cores are modelled on. It is **not** produced by a generator;
edit it directly. The eight `cu_*` control LUTs and the `alu_op_dec`
decoder at the end of the file are BITF-Synth Engine flow shims with their INIT
tables documented inline.
