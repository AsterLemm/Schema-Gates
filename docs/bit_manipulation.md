# Bit Manipulation

Bit reversal, low/high masks, single-bit set/clear/toggle, bitfield extract/insert, and nibble/byte swaps.

*Directory:* `src/bit_manipulation/` -- 37 modules.

| Module | Description |
|--------|-------------|
| `bit_reverse16` | 16-bit bit-reverse. |
| `bit_reverse32` | 32-bit bit-reverse. |
| `bit_reverse4` | 4-bit bit-reverse. |
| `bit_reverse8` | 8-bit bit-reverse. |
| `byte_swap16` | 16-bit byte swap (endianness reverse). |
| `byte_swap32` | 32-bit byte swap (endianness reverse). |
| `clear_bit16` | 16-bit clear-bit at pos. |
| `clear_bit32` | 32-bit clear-bit at pos. |
| `clear_bit4` | 4-bit clear-bit at pos. |
| `clear_bit8` | 8-bit clear-bit at pos. |
| `extract_field16` | 16-bit extract bitfield (len bits at pos). |
| `extract_field32` | 32-bit extract bitfield (len bits at pos). |
| `extract_field4` | 4-bit extract bitfield (len bits at pos). |
| `extract_field8` | 8-bit extract bitfield (len bits at pos). |
| `insert_field16` | 16-bit insert bitfield. |
| `insert_field32` | 32-bit insert bitfield. |
| `insert_field4` | 4-bit insert bitfield. |
| `insert_field8` | 8-bit insert bitfield. |
| `mask_high16` | 16-bit high-mask (n high bits set). |
| `mask_high32` | 32-bit high-mask (n high bits set). |
| `mask_high4` | 4-bit high-mask (n high bits set). |
| `mask_high8` | 8-bit high-mask (n high bits set). |
| `mask_low16` | 16-bit low-mask (n low bits set). |
| `mask_low32` | 32-bit low-mask (n low bits set). |
| `mask_low4` | 4-bit low-mask (n low bits set). |
| `mask_low8` | 8-bit low-mask (n low bits set). |
| `nibble_swap16` | 16-bit nibble swap (within each byte). |
| `nibble_swap32` | 32-bit nibble swap (within each byte). |
| `nibble_swap8` | 8-bit nibble swap (within each byte). |
| `set_bit16` | 16-bit set-bit at pos. |
| `set_bit32` | 32-bit set-bit at pos. |
| `set_bit4` | 4-bit set-bit at pos. |
| `set_bit8` | 8-bit set-bit at pos. |
| `toggle_bit16` | 16-bit toggle-bit at pos. |
| `toggle_bit32` | 32-bit toggle-bit at pos. |
| `toggle_bit4` | 4-bit toggle-bit at pos. |
| `toggle_bit8` | 8-bit toggle-bit at pos. |
