# Subtractors & Add/Sub Units

Borrow-ripple subtractors and two's-complement subtractors implemented on every adder core, combined add/subtract units with overflow, negation, absolute value, and sign/zero extension.

*Directory:* `src/subtractors/` -- 66 modules.

| Module | Description |
|--------|-------------|
| `abs_twos16` | 16-bit two's-complement absolute value. |
| `abs_twos32` | 32-bit two's-complement absolute value. |
| `abs_twos4` | 4-bit two's-complement absolute value. |
| `abs_twos8` | 8-bit two's-complement absolute value. |
| `addsub_cla16` | 16-bit add/sub on CLA core. |
| `addsub_cla32` | 32-bit add/sub on CLA core. |
| `addsub_cla4` | 4-bit add/sub on CLA core. |
| `addsub_cla8` | 8-bit add/sub on CLA core. |
| `addsub_prefix16` | 16-bit add/sub on Kogge-Stone prefix adder. |
| `addsub_prefix32` | 32-bit add/sub on Kogge-Stone prefix adder. |
| `addsub_prefix4` | 4-bit add/sub on Kogge-Stone prefix adder. |
| `addsub_prefix8` | 8-bit add/sub on Kogge-Stone prefix adder. |
| `addsub_rc16` | 16-bit add/sub on ripple adder (sub=1 -> a-b via b^1,cin=1). |
| `addsub_rc32` | 32-bit add/sub on ripple adder (sub=1 -> a-b via b^1,cin=1). |
| `addsub_rc4` | 4-bit add/sub on ripple adder (sub=1 -> a-b via b^1,cin=1). |
| `addsub_rc8` | 8-bit add/sub on ripple adder (sub=1 -> a-b via b^1,cin=1). |
| `addsub_saturating_signed16` | 16-bit signed saturating add/sub (clamp to +max/-min). |
| `addsub_saturating_signed32` | 32-bit signed saturating add/sub (clamp to +max/-min). |
| `addsub_saturating_signed4` | 4-bit signed saturating add/sub (clamp to +max/-min). |
| `addsub_saturating_signed8` | 8-bit signed saturating add/sub (clamp to +max/-min). |
| `addsub_saturating_unsigned16` | 16-bit unsigned saturating add/sub (clamp 0..max). |
| `addsub_saturating_unsigned32` | 32-bit unsigned saturating add/sub (clamp 0..max). |
| `addsub_saturating_unsigned4` | 4-bit unsigned saturating add/sub (clamp 0..max). |
| `addsub_saturating_unsigned8` | 8-bit unsigned saturating add/sub (clamp 0..max). |
| `borrow_generate_cell` | Borrow generate bg = ~a & b. |
| `borrow_propagate_cell` | Borrow propagate bp = ~(a^b). |
| `full_subtractor` | Full subtractor: diff=a^b^bin, borrow out. |
| `half_subtractor` | Half subtractor: diff=a^b, bout=~a&b. |
| `neg_ones16` | 16-bit one's-complement negate (y = ~a). |
| `neg_ones32` | 32-bit one's-complement negate (y = ~a). |
| `neg_ones4` | 4-bit one's-complement negate (y = ~a). |
| `neg_ones8` | 8-bit one's-complement negate (y = ~a). |
| `neg_twos16` | 16-bit two's-complement negate (y = -a). |
| `neg_twos32` | 32-bit two's-complement negate (y = -a). |
| `neg_twos4` | 4-bit two's-complement negate (y = -a). |
| `neg_twos8` | 8-bit two's-complement negate (y = -a). |
| `sign_extend16_to32` | Sign-extend 16-bit to 32-bit. |
| `sign_extend4_to8` | Sign-extend 4-bit to 8-bit. |
| `sign_extend8_to16` | Sign-extend 8-bit to 16-bit. |
| `sub_borrow_ripple16` | 16-bit borrow-ripple subtractor (full_subtractor chain). |
| `sub_borrow_ripple32` | 32-bit borrow-ripple subtractor (full_subtractor chain). |
| `sub_borrow_ripple4` | 4-bit borrow-ripple subtractor (full_subtractor chain). |
| `sub_borrow_ripple8` | 8-bit borrow-ripple subtractor (full_subtractor chain). |
| `sub_cselect16` | 16-bit subtractor (two's complement on carry-select adder). |
| `sub_cselect32` | 32-bit subtractor (two's complement on carry-select adder). |
| `sub_cselect4` | 4-bit subtractor (two's complement on carry-select adder). |
| `sub_cselect8` | 8-bit subtractor (two's complement on carry-select adder). |
| `sub_cskip16` | 16-bit subtractor (two's complement on carry-skip adder). |
| `sub_cskip32` | 32-bit subtractor (two's complement on carry-skip adder). |
| `sub_cskip4` | 4-bit subtractor (two's complement on carry-skip adder). |
| `sub_cskip8` | 8-bit subtractor (two's complement on carry-skip adder). |
| `sub_prefix_kogge_stone16` | 16-bit subtractor (two's complement on Kogge-Stone prefix adder). |
| `sub_prefix_kogge_stone32` | 32-bit subtractor (two's complement on Kogge-Stone prefix adder). |
| `sub_prefix_kogge_stone4` | 4-bit subtractor (two's complement on Kogge-Stone prefix adder). |
| `sub_prefix_kogge_stone8` | 8-bit subtractor (two's complement on Kogge-Stone prefix adder). |
| `sub_twos_add_cla16` | 16-bit subtractor via two's complement on CLA core. |
| `sub_twos_add_cla32` | 32-bit subtractor via two's complement on CLA core. |
| `sub_twos_add_cla4` | 4-bit subtractor via two's complement on CLA core. |
| `sub_twos_add_cla8` | 8-bit subtractor via two's complement on CLA core. |
| `sub_twos_add_rc16` | 16-bit subtractor via two's complement (a + ~b + 1) on ripple adder. |
| `sub_twos_add_rc32` | 32-bit subtractor via two's complement (a + ~b + 1) on ripple adder. |
| `sub_twos_add_rc4` | 4-bit subtractor via two's complement (a + ~b + 1) on ripple adder. |
| `sub_twos_add_rc8` | 8-bit subtractor via two's complement (a + ~b + 1) on ripple adder. |
| `zero_extend16_to32` | Zero-extend 16-bit to 32-bit. |
| `zero_extend4_to8` | Zero-extend 4-bit to 8-bit. |
| `zero_extend8_to16` | Zero-extend 8-bit to 16-bit. |
