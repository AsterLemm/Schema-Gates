# ALU & Datapath

Logic-only, arithmetic-only, and full ALUs with Z/N/C/V flags and shift support, plus datapath building blocks: program counter, branch-target adder, instruction register, stack pointer, accumulator, status register, and a small worked datapath.

*Directory:* `src/alu_datapath/` -- 52 modules.

| Module | Description |
|--------|-------------|
| `accumulator16` | 16-bit accumulator register. |
| `accumulator32` | 32-bit accumulator register. |
| `accumulator4` | 4-bit accumulator register. |
| `accumulator8` | 8-bit accumulator register. |
| `alu_arithmetic16` | 16-bit arithmetic ALU (add/sub/inc/dec). |
| `alu_arithmetic32` | 32-bit arithmetic ALU (add/sub/inc/dec). |
| `alu_arithmetic4` | 4-bit arithmetic ALU (add/sub/inc/dec). |
| `alu_arithmetic8` | 8-bit arithmetic ALU (add/sub/inc/dec). |
| `alu_basic16` | 16-bit basic ALU (8 ops). |
| `alu_basic32` | 32-bit basic ALU (8 ops). |
| `alu_basic4` | 4-bit basic ALU (8 ops). |
| `alu_basic8` | 8-bit basic ALU (8 ops). |
| `alu_flags16` | 16-bit ALU with Z/N/C/V flags. |
| `alu_flags32` | 32-bit ALU with Z/N/C/V flags. |
| `alu_flags4` | 4-bit ALU with Z/N/C/V flags. |
| `alu_flags8` | 8-bit ALU with Z/N/C/V flags. |
| `alu_full16` | 16-bit full ALU (16 ops + flags). |
| `alu_full32` | 32-bit full ALU (16 ops + flags). |
| `alu_full4` | 4-bit full ALU (16 ops + flags). |
| `alu_full8` | 8-bit full ALU (16 ops + flags). |
| `alu_logic16` | 16-bit logic ALU (AND/OR/XOR/NOT). |
| `alu_logic32` | 32-bit logic ALU (AND/OR/XOR/NOT). |
| `alu_logic4` | 4-bit logic ALU (AND/OR/XOR/NOT). |
| `alu_logic8` | 8-bit logic ALU (AND/OR/XOR/NOT). |
| `alu_shift16` | 16-bit shift ALU (shl/shr/sar/rol). |
| `alu_shift32` | 32-bit shift ALU (shl/shr/sar/rol). |
| `alu_shift4` | 4-bit shift ALU (shl/shr/sar/rol). |
| `alu_shift8` | 8-bit shift ALU (shl/shr/sar/rol). |
| `branch_target_adder16` | 16-bit branch-target adder (pc+offset). |
| `branch_target_adder32` | 32-bit branch-target adder (pc+offset). |
| `branch_target_adder4` | 4-bit branch-target adder (pc+offset). |
| `branch_target_adder8` | 8-bit branch-target adder (pc+offset). |
| `instruction_register16` | 16-bit instruction register. |
| `instruction_register32` | 32-bit instruction register. |
| `instruction_register4` | 4-bit instruction register. |
| `instruction_register8` | 8-bit instruction register. |
| `program_counter16` | 16-bit program counter (inc/load/reset). |
| `program_counter32` | 32-bit program counter (inc/load/reset). |
| `program_counter4` | 4-bit program counter (inc/load/reset). |
| `program_counter8` | 8-bit program counter (inc/load/reset). |
| `simple_datapath16` | 16-bit simple accumulator datapath (ALU + accumulator). |
| `simple_datapath32` | 32-bit simple accumulator datapath (ALU + accumulator). |
| `simple_datapath4` | 4-bit simple accumulator datapath (ALU + accumulator). |
| `simple_datapath8` | 8-bit simple accumulator datapath (ALU + accumulator). |
| `stack_pointer16` | 16-bit stack pointer (push dec / pop inc). |
| `stack_pointer32` | 32-bit stack pointer (push dec / pop inc). |
| `stack_pointer4` | 4-bit stack pointer (push dec / pop inc). |
| `stack_pointer8` | 8-bit stack pointer (push dec / pop inc). |
| `status_register16` | 16-bit status/flags register. |
| `status_register32` | 32-bit status/flags register. |
| `status_register4` | 4-bit status/flags register. |
| `status_register8` | 8-bit status/flags register. |
