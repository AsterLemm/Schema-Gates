# Binary-Coded Decimal

Binary<->BCD conversion via double-dabble, BCD addition and subtraction with decimal correction (digit widths 1/2/4/8 plus bit-mapped 4/8/16/32 aliases), validity checking, and nine's complement.

*Directory:* `src/bcd/` -- 32 modules.

| Module | Description |
|--------|-------------|
| `bcd_add1` | 1-digit BCD adder (+6 decimal correction). |
| `bcd_add2` | 2-digit BCD adder (+6 decimal correction). |
| `bcd_add4` | 4-digit BCD adder (+6 decimal correction). |
| `bcd_add8` | 8-digit BCD adder (+6 decimal correction). |
| `bcd_add_bits16` | 16-bit (4-digit) BCD adder. |
| `bcd_add_bits32` | 32-bit (8-digit) BCD adder. |
| `bcd_add_bits4` | 4-bit (1-digit) BCD adder. |
| `bcd_add_bits8` | 8-bit (2-digit) BCD adder. |
| `bcd_nines_complement1` | 1-digit BCD nine's complement. |
| `bcd_nines_complement2` | 2-digit BCD nine's complement. |
| `bcd_nines_complement4` | 4-digit BCD nine's complement. |
| `bcd_nines_complement8` | 8-digit BCD nine's complement. |
| `bcd_sub1` | 1-digit BCD subtractor (-6 decimal correction). |
| `bcd_sub2` | 2-digit BCD subtractor (-6 decimal correction). |
| `bcd_sub4` | 4-digit BCD subtractor (-6 decimal correction). |
| `bcd_sub8` | 8-digit BCD subtractor (-6 decimal correction). |
| `bcd_sub_bits16` | 16-bit (4-digit) BCD subtractor. |
| `bcd_sub_bits32` | 32-bit (8-digit) BCD subtractor. |
| `bcd_sub_bits4` | 4-bit (1-digit) BCD subtractor. |
| `bcd_sub_bits8` | 8-bit (2-digit) BCD subtractor. |
| `bcd_to_bin16` | 5-digit BCD -> 16-bit binary. |
| `bcd_to_bin32` | 10-digit BCD -> 32-bit binary. |
| `bcd_to_bin4` | 2-digit BCD -> 4-bit binary. |
| `bcd_to_bin8` | 3-digit BCD -> 8-bit binary. |
| `bcd_valid1` | 1-digit BCD validity (each nibble <= 9). |
| `bcd_valid2` | 2-digit BCD validity (each nibble <= 9). |
| `bcd_valid4` | 4-digit BCD validity (each nibble <= 9). |
| `bcd_valid8` | 8-digit BCD validity (each nibble <= 9). |
| `bin_to_bcd16` | 16-bit binary -> 5-digit BCD (double-dabble). |
| `bin_to_bcd32` | 32-bit binary -> 10-digit BCD (double-dabble). |
| `bin_to_bcd4` | 4-bit binary -> 2-digit BCD (double-dabble). |
| `bin_to_bcd8` | 8-bit binary -> 3-digit BCD (double-dabble). |
