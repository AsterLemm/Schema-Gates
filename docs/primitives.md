# Primitives

Basic logic gates, constants, bus join/split, reduction operators, and educational NAND-only / NOR-only realizations. These are the leaf cells every other family embeds.

*Directory:* `src/primitives/` -- 65 modules.

| Module | Description |
|--------|-------------|
| `and2` | Basic gate: y = a & b |
| `and3` | Basic gate: y = a & b & c |
| `and4` | Basic gate: y = a & b & c & d |
| `and8` | Basic gate: y = a & b & c & d & e & f & g & h |
| `and_reduce16` | AND-reduce: 1 iff all bits set. |
| `and_reduce32` | AND-reduce: 1 iff all bits set. |
| `and_reduce4` | AND-reduce: 1 iff all bits set. |
| `and_reduce8` | AND-reduce: 1 iff all bits set. |
| `and_using_nand` | AND from two NANDs (NAND then invert). |
| `and_using_nor` | AND from three NORs (invert inputs, NOR). |
| `bit_tap` | Probe/tap a single bit (pass-through). |
| `buf1` | Basic gate: y = a |
| `bus_join2` | Join 2 single bits into a 2-bit bus (i1=MSB). |
| `bus_join4` | Join 4 single bits into a 4-bit bus (i3=MSB). |
| `bus_join8` | Join 8 single bits into a 8-bit bus (i7=MSB). |
| `bus_split2` | Split a 2-bit bus into 2 single bits. |
| `bus_split4` | Split a 4-bit bus into 4 single bits. |
| `bus_split8` | Split a 8-bit bus into 8 single bits. |
| `const0` | Constant logic 0. |
| `const1` | Constant logic 1. |
| `full_adder_using_nand` | Full adder using only NAND gates. |
| `full_adder_using_nor` | Full adder using only NOR gates (verified). |
| `half_adder_using_nand` | Half adder using only NAND gates. |
| `half_adder_using_nor` | Half adder using only NOR gates (verified). |
| `nand2` | Basic gate: y = ~(a & b) |
| `nand3` | Basic gate: y = ~(a & b & c) |
| `nand4` | Basic gate: y = ~(a & b & c & d) |
| `nand_reduce16` | NAND-reduce: 0 iff all bits set. |
| `nand_reduce32` | NAND-reduce: 0 iff all bits set. |
| `nand_reduce4` | NAND-reduce: 0 iff all bits set. |
| `nand_reduce8` | NAND-reduce: 0 iff all bits set. |
| `nor2` | Basic gate: y = ~(a \| b) |
| `nor3` | Basic gate: y = ~(a \| b \| c) |
| `nor4` | Basic gate: y = ~(a \| b \| c \| d) |
| `nor_reduce16` | NOR-reduce: 1 iff all bits zero. |
| `nor_reduce32` | NOR-reduce: 1 iff all bits zero. |
| `nor_reduce4` | NOR-reduce: 1 iff all bits zero. |
| `nor_reduce8` | NOR-reduce: 1 iff all bits zero. |
| `not1` | Basic gate: y = ~a |
| `not_using_nand` | NOT built from one NAND (a NAND a). |
| `not_using_nor` | NOT built from one NOR (a NOR a). |
| `or2` | Basic gate: y = a \| b |
| `or3` | Basic gate: y = a \| b \| c |
| `or4` | Basic gate: y = a \| b \| c \| d |
| `or8` | Basic gate: y = a \| b \| c \| d \| e \| f \| g \| h |
| `or_reduce16` | OR-reduce: 1 iff any bit set. |
| `or_reduce32` | OR-reduce: 1 iff any bit set. |
| `or_reduce4` | OR-reduce: 1 iff any bit set. |
| `or_reduce8` | OR-reduce: 1 iff any bit set. |
| `or_using_nand` | OR from three NANDs (invert inputs, NAND). |
| `or_using_nor` | OR from two NORs (NOR then invert). |
| `tie_high` | Tie-high cell (drives 1). |
| `tie_low` | Tie-low cell (drives 0). |
| `xnor2` | Basic gate: y = ~(a ^ b) |
| `xnor3` | Basic gate: y = ~(a ^ b ^ c) |
| `xnor4` | Basic gate: y = ~(a ^ b ^ c ^ d) |
| `xor2` | Basic gate: y = a ^ b |
| `xor3` | Basic gate: y = a ^ b ^ c |
| `xor4` | Basic gate: y = a ^ b ^ c ^ d |
| `xor_reduce16` | XOR-reduce: parity of the bus. |
| `xor_reduce32` | XOR-reduce: parity of the bus. |
| `xor_reduce4` | XOR-reduce: parity of the bus. |
| `xor_reduce8` | XOR-reduce: parity of the bus. |
| `xor_using_nand` | XOR from four NANDs (classic 4-gate form). |
| `xor_using_nor` | XOR from five NOR gates (verified network). |
