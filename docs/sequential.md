# Sequential Elements

Latches (SR, gated SR, D, JK, T), flip-flops (D edge-triggered with enable/reset variants, JK, T), registers (with enable and reset), and shift registers (SISO/SIPO/PISO/PIPO/universal).

*Directory:* `src/sequential/` -- 56 modules.

| Module | Description |
|--------|-------------|
| `d_latch` | D latch (transparent when en=1). |
| `d_latch_en` | D latch with explicit enable. |
| `dff_en` | D flip-flop with enable. |
| `dff_negedge` | Negative-edge D flip-flop. |
| `dff_posedge` | Positive-edge D flip-flop. |
| `dff_reset_async` | D flip-flop, asynchronous reset. |
| `dff_reset_sync` | D flip-flop, synchronous reset. |
| `dff_set_reset` | D flip-flop with sync set & reset. |
| `gated_sr_latch` | Gated SR latch (level-sensitive). |
| `jk_latch` | JK latch. |
| `jkff` | JK flip-flop. |
| `pipo16` | 16-bit parallel-in parallel-out register. |
| `pipo32` | 32-bit parallel-in parallel-out register. |
| `pipo4` | 4-bit parallel-in parallel-out register. |
| `pipo8` | 8-bit parallel-in parallel-out register. |
| `piso16` | 16-bit parallel-in serial-out shift register. |
| `piso32` | 32-bit parallel-in serial-out shift register. |
| `piso4` | 4-bit parallel-in serial-out shift register. |
| `piso8` | 8-bit parallel-in serial-out shift register. |
| `reg12` | 12-bit register. |
| `reg16` | 16-bit register. |
| `reg20` | 20-bit register. |
| `reg32` | 32-bit register. |
| `reg4` | 4-bit register. |
| `reg40` | 40-bit register. |
| `reg8` | 8-bit register. |
| `reg_en12` | 12-bit register with enable. |
| `reg_en16` | 16-bit register with enable. |
| `reg_en20` | 20-bit register with enable. |
| `reg_en32` | 32-bit register with enable. |
| `reg_en4` | 4-bit register with enable. |
| `reg_en40` | 40-bit register with enable. |
| `reg_en8` | 8-bit register with enable. |
| `reg_reset12` | 12-bit register, sync reset + enable. |
| `reg_reset16` | 16-bit register, sync reset + enable. |
| `reg_reset20` | 20-bit register, sync reset + enable. |
| `reg_reset32` | 32-bit register, sync reset + enable. |
| `reg_reset4` | 4-bit register, sync reset + enable. |
| `reg_reset40` | 40-bit register, sync reset + enable. |
| `reg_reset8` | 8-bit register, sync reset + enable. |
| `sipo16` | 16-bit serial-in parallel-out shift register. |
| `sipo32` | 32-bit serial-in parallel-out shift register. |
| `sipo4` | 4-bit serial-in parallel-out shift register. |
| `sipo8` | 8-bit serial-in parallel-out shift register. |
| `siso16` | 16-bit serial-in serial-out shift register. |
| `siso32` | 32-bit serial-in serial-out shift register. |
| `siso4` | 4-bit serial-in serial-out shift register. |
| `siso8` | 8-bit serial-in serial-out shift register. |
| `sr_latch_nand` | SR latch (cross-coupled NAND, active-low). |
| `sr_latch_nor` | SR latch (cross-coupled NOR). |
| `t_latch` | T (toggle) latch. |
| `tff` | T (toggle) flip-flop. |
| `universal_shift_reg16` | 16-bit universal shift register (hold/L/R/load). |
| `universal_shift_reg32` | 32-bit universal shift register (hold/L/R/load). |
| `universal_shift_reg4` | 4-bit universal shift register (hold/L/R/load). |
| `universal_shift_reg8` | 8-bit universal shift register (hold/L/R/load). |
