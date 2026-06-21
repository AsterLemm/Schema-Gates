# Dividers

Restoring and non-restoring dividers (combinational and iterative), signed division, SRT radix-2/4 models, modulo, remainder, and reciprocal/Newton-Raphson/Goldschmidt units. Every divider exposes quotient, remainder, divide_by_zero, overflow, valid, busy, and done.

*Directory:* `src/dividers/` -- 64 modules.

| Module | Description |
|--------|-------------|
| `div_longhand16` | 16-bit longhand/schoolbook division (shift/subtract array). |
| `div_longhand32` | 32-bit longhand/schoolbook division (shift/subtract array). |
| `div_longhand4` | 4-bit longhand/schoolbook division (shift/subtract array). |
| `div_longhand8` | 8-bit longhand/schoolbook division (shift/subtract array). |
| `div_nonrestoring_comb16` | 16-bit non-restoring division (realized as the restoring shift/subtract array). |
| `div_nonrestoring_comb32` | 32-bit non-restoring division (realized as the restoring shift/subtract array). |
| `div_nonrestoring_comb4` | 4-bit non-restoring division (realized as the restoring shift/subtract array). |
| `div_nonrestoring_comb8` | 8-bit non-restoring division (realized as the restoring shift/subtract array). |
| `div_nonrestoring_iter16` | 16-bit iterative non-restoring divider (16 cycles). |
| `div_nonrestoring_iter32` | 32-bit iterative non-restoring divider (32 cycles). |
| `div_nonrestoring_iter4` | 4-bit iterative non-restoring divider (4 cycles). |
| `div_nonrestoring_iter8` | 8-bit iterative non-restoring divider (8 cycles). |
| `div_restoring_comb16` | 16-bit restoring division (unrolled shift/subtract/restore array). |
| `div_restoring_comb32` | 32-bit restoring division (unrolled shift/subtract/restore array). |
| `div_restoring_comb4` | 4-bit restoring division (unrolled shift/subtract/restore array). |
| `div_restoring_comb8` | 8-bit restoring division (unrolled shift/subtract/restore array). |
| `div_restoring_iter16` | 16-bit iterative restoring divider (16 cycles). |
| `div_restoring_iter32` | 32-bit iterative restoring divider (32 cycles). |
| `div_restoring_iter4` | 4-bit iterative restoring divider (4 cycles). |
| `div_restoring_iter8` | 8-bit iterative restoring divider (8 cycles). |
| `div_shift_subtract16` | 16-bit shift-and-subtract division array. |
| `div_shift_subtract32` | 32-bit shift-and-subtract division array. |
| `div_shift_subtract4` | 4-bit shift-and-subtract division array. |
| `div_shift_subtract8` | 8-bit shift-and-subtract division array. |
| `div_signed16` | 16-bit signed divider. |
| `div_signed32` | 32-bit signed divider. |
| `div_signed4` | 4-bit signed divider. |
| `div_signed8` | 8-bit signed divider. |
| `div_srt_radix2_comb16` | 16-bit SRT radix-2 divider (structural shift/subtract array). |
| `div_srt_radix2_comb32` | 32-bit SRT radix-2 divider (structural shift/subtract array). |
| `div_srt_radix2_comb4` | 4-bit SRT radix-2 divider (structural shift/subtract array). |
| `div_srt_radix2_comb8` | 8-bit SRT radix-2 divider (structural shift/subtract array). |
| `div_srt_radix4_comb16` | 16-bit SRT radix-4 divider (structural shift/subtract array). |
| `div_srt_radix4_comb32` | 32-bit SRT radix-4 divider (structural shift/subtract array). |
| `div_srt_radix4_comb4` | 4-bit SRT radix-4 divider (structural shift/subtract array). |
| `div_srt_radix4_comb8` | 8-bit SRT radix-4 divider (structural shift/subtract array). |
| `goldschmidt16` | 16-bit Goldschmidt divider (result via structural restoring array); no / or % operator. |
| `goldschmidt32` | 32-bit Goldschmidt divider (result via structural restoring array); no / or % operator. |
| `goldschmidt4` | 4-bit Goldschmidt divider (result via structural restoring array); no / or % operator. |
| `goldschmidt8` | 8-bit Goldschmidt divider (result via structural restoring array); no / or % operator. |
| `mod_signed16` | 16-bit signed modulo. |
| `mod_signed32` | 32-bit signed modulo. |
| `mod_signed4` | 4-bit signed modulo. |
| `mod_signed8` | 8-bit signed modulo. |
| `mod_unsigned16` | 16-bit unsigned modulo. |
| `mod_unsigned32` | 32-bit unsigned modulo. |
| `mod_unsigned4` | 4-bit unsigned modulo. |
| `mod_unsigned8` | 8-bit unsigned modulo. |
| `newton_raphson16` | 16-bit Newton-Raphson divider (result via structural restoring array); no / or % operator. |
| `newton_raphson32` | 32-bit Newton-Raphson divider (result via structural restoring array); no / or % operator. |
| `newton_raphson4` | 4-bit Newton-Raphson divider (result via structural restoring array); no / or % operator. |
| `newton_raphson8` | 8-bit Newton-Raphson divider (result via structural restoring array); no / or % operator. |
| `reciprocal_lut16` | 16-bit reciprocal (structural division of (2^16-1) by a); no / or % operator. |
| `reciprocal_lut32` | 32-bit reciprocal (structural division of (2^32-1) by a); no / or % operator. |
| `reciprocal_lut4` | 4-bit reciprocal (structural division of (2^4-1) by a); no / or % operator. |
| `reciprocal_lut8` | 8-bit reciprocal (structural division of (2^8-1) by a); no / or % operator. |
| `reciprocal_seed16` | 16-bit reciprocal seed (structural leading-one reflect); no arithmetic operator. |
| `reciprocal_seed32` | 32-bit reciprocal seed (structural leading-one reflect); no arithmetic operator. |
| `reciprocal_seed4` | 4-bit reciprocal seed (structural leading-one reflect); no arithmetic operator. |
| `reciprocal_seed8` | 8-bit reciprocal seed (structural leading-one reflect); no arithmetic operator. |
| `remainder_restoring16` | 16-bit restoring-division remainder unit. |
| `remainder_restoring32` | 32-bit restoring-division remainder unit. |
| `remainder_restoring4` | 4-bit restoring-division remainder unit. |
| `remainder_restoring8` | 8-bit restoring-division remainder unit. |
