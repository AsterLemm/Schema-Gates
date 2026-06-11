# Floating Point

Educational fp8 (E4M3) and fp16 (IEEE half) units: field pack/unpack, classification, comparison, add/subtract/multiply/divide, normalization, rounding, and integer<->fp16 conversion.

*Directory:* `src/floating_point/` -- 18 modules.

| Module | Description |
|--------|-------------|
| `fp16_add` | fp16 (IEEE half) adder, round-toward-zero, educational. |
| `fp16_classify` | fp16 value classifier (zero/inf/nan/denormal). |
| `fp16_compare` | fp16 ordered comparator (sign-magnitude semantics). |
| `fp16_div` | fp16 divider (structural 22/11 restoring mantissa divide); no / operator. |
| `fp16_mul` | fp16 multiplier (structural 11x11 mantissa multiply); no * operator. |
| `fp16_normalize` | fp16 mantissa normalizer (leading-1 alignment). |
| `fp16_pack` | fp16 field packer. |
| `fp16_round_nearest` | fp16 round-to-nearest-even unit. |
| `fp16_sub` | fp16 (IEEE half) subtractor. |
| `fp16_to_int` | fp16 -> signed int16 (truncating). |
| `fp16_unpack` | fp16 field unpacker (sign/exp/mantissa). |
| `fp8_add` | fp8 (E4M3) adder, educational. |
| `fp8_classify` | fp8 value classifier (zero/inf/nan/denormal). |
| `fp8_compare` | fp8 ordered comparator (sign-magnitude semantics). |
| `fp8_mul` | fp8 (E4M3) multiplier (structural 4x4 mantissa multiply); no * operator. |
| `fp8_pack` | fp8 field packer. |
| `fp8_unpack` | fp8 field unpacker (sign/exp/mantissa). |
| `int_to_fp16` | signed int16 -> fp16 conversion. |
