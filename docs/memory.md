# Memory

Register files (1-write / 2-read, including a RISC-style file with a hardwired zero register), true dual-port RAM, and a content-addressable memory.

*Directory:* `src/memory/` -- 9 modules.

| Module | Description |
|--------|-------------|
| `cam_8x8` | 8x8 content-addressable memory (parallel match). |
| `dpram_16x8` | 16x8 dual-port RAM. |
| `regfile_16x4` | 16x4 register file (1W/2R). |
| `regfile_16x8` | 16x8 register file (1W/2R). |
| `regfile_4x16` | 4x16 register file (1W/2R). |
| `regfile_8x16` | 8x16 register file (1W/2R). |
| `regfile_8x4` | 8x4 register file (1W/2R). |
| `regfile_8x8` | 8x8 register file (1W/2R). |
| `regfile_riscv_8x8` | 8x8 RISC register file (r0 = zero). |
