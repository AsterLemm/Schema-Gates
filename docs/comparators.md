# Comparators, Detectors & Flags

Equality and magnitude comparison (signed and unsigned), value detectors (zero, all-ones, sign, parity), and condition flags (carry, borrow, overflow, negative, zero).

*Directory:* `src/comparators/` -- 88 modules.

| Module | Description |
|--------|-------------|
| `all_ones_detect16` | All-ones detect, 16-bit. |
| `all_ones_detect32` | All-ones detect, 32-bit. |
| `all_ones_detect4` | All-ones detect, 4-bit. |
| `all_ones_detect8` | All-ones detect, 8-bit. |
| `borrow_flag16` | Borrow flag for a-b-bin, 16-bit. |
| `borrow_flag32` | Borrow flag for a-b-bin, 32-bit. |
| `borrow_flag4` | Borrow flag for a-b-bin, 4-bit. |
| `borrow_flag8` | Borrow flag for a-b-bin, 8-bit. |
| `carry_flag16` | Carry flag for a+b+cin, 16-bit. |
| `carry_flag32` | Carry flag for a+b+cin, 32-bit. |
| `carry_flag4` | Carry flag for a+b+cin, 4-bit. |
| `carry_flag8` | Carry flag for a+b+cin, 8-bit. |
| `eq16` | Equality, 16-bit (eq=1 iff a==b). |
| `eq32` | Equality, 32-bit (eq=1 iff a==b). |
| `eq4` | Equality, 4-bit (eq=1 iff a==b). |
| `eq8` | Equality, 8-bit (eq=1 iff a==b). |
| `even_detect16` | Even detect, 16-bit (LSB==0). |
| `even_detect32` | Even detect, 32-bit (LSB==0). |
| `even_detect4` | Even detect, 4-bit (LSB==0). |
| `even_detect8` | Even detect, 8-bit (LSB==0). |
| `gt_signed16` | Signed greater-than, 16-bit (two's complement). |
| `gt_signed32` | Signed greater-than, 32-bit (two's complement). |
| `gt_signed4` | Signed greater-than, 4-bit (two's complement). |
| `gt_signed8` | Signed greater-than, 8-bit (two's complement). |
| `gt_unsigned16` | Unsigned greater-than, 16-bit. |
| `gt_unsigned32` | Unsigned greater-than, 32-bit. |
| `gt_unsigned4` | Unsigned greater-than, 4-bit. |
| `gt_unsigned8` | Unsigned greater-than, 8-bit. |
| `gte_signed16` | Signed greater-or-equal, 16-bit (two's complement). |
| `gte_signed32` | Signed greater-or-equal, 32-bit (two's complement). |
| `gte_signed4` | Signed greater-or-equal, 4-bit (two's complement). |
| `gte_signed8` | Signed greater-or-equal, 8-bit (two's complement). |
| `gte_unsigned16` | Unsigned greater-or-equal, 16-bit. |
| `gte_unsigned32` | Unsigned greater-or-equal, 32-bit. |
| `gte_unsigned4` | Unsigned greater-or-equal, 4-bit. |
| `gte_unsigned8` | Unsigned greater-or-equal, 8-bit. |
| `lt_signed16` | Signed less-than, 16-bit (two's complement). |
| `lt_signed32` | Signed less-than, 32-bit (two's complement). |
| `lt_signed4` | Signed less-than, 4-bit (two's complement). |
| `lt_signed8` | Signed less-than, 8-bit (two's complement). |
| `lt_unsigned16` | Unsigned less-than, 16-bit. |
| `lt_unsigned32` | Unsigned less-than, 32-bit. |
| `lt_unsigned4` | Unsigned less-than, 4-bit. |
| `lt_unsigned8` | Unsigned less-than, 8-bit. |
| `lte_signed16` | Signed less-or-equal, 16-bit (two's complement). |
| `lte_signed32` | Signed less-or-equal, 32-bit (two's complement). |
| `lte_signed4` | Signed less-or-equal, 4-bit (two's complement). |
| `lte_signed8` | Signed less-or-equal, 8-bit (two's complement). |
| `lte_unsigned16` | Unsigned less-or-equal, 16-bit. |
| `lte_unsigned32` | Unsigned less-or-equal, 32-bit. |
| `lte_unsigned4` | Unsigned less-or-equal, 4-bit. |
| `lte_unsigned8` | Unsigned less-or-equal, 8-bit. |
| `negative_flag16` | Negative flag, 16-bit (result MSB). |
| `negative_flag32` | Negative flag, 32-bit (result MSB). |
| `negative_flag4` | Negative flag, 4-bit (result MSB). |
| `negative_flag8` | Negative flag, 8-bit (result MSB). |
| `neq16` | Inequality, 16-bit. |
| `neq32` | Inequality, 32-bit. |
| `neq4` | Inequality, 4-bit. |
| `neq8` | Inequality, 8-bit. |
| `nonzero_detect16` | Non-zero detect, 16-bit. |
| `nonzero_detect32` | Non-zero detect, 32-bit. |
| `nonzero_detect4` | Non-zero detect, 4-bit. |
| `nonzero_detect8` | Non-zero detect, 8-bit. |
| `odd_detect16` | Odd detect, 16-bit (LSB==1). |
| `odd_detect32` | Odd detect, 32-bit (LSB==1). |
| `odd_detect4` | Odd detect, 4-bit (LSB==1). |
| `odd_detect8` | Odd detect, 8-bit (LSB==1). |
| `overflow_add16` | Signed add overflow, 16-bit. |
| `overflow_add32` | Signed add overflow, 32-bit. |
| `overflow_add4` | Signed add overflow, 4-bit. |
| `overflow_add8` | Signed add overflow, 8-bit. |
| `overflow_sub16` | Signed sub overflow, 16-bit. |
| `overflow_sub32` | Signed sub overflow, 32-bit. |
| `overflow_sub4` | Signed sub overflow, 4-bit. |
| `overflow_sub8` | Signed sub overflow, 8-bit. |
| `sign_detect16` | Sign detect, 16-bit (MSB). |
| `sign_detect32` | Sign detect, 32-bit (MSB). |
| `sign_detect4` | Sign detect, 4-bit (MSB). |
| `sign_detect8` | Sign detect, 8-bit (MSB). |
| `zero_detect16` | Zero detect, 16-bit (1 iff a==0). |
| `zero_detect32` | Zero detect, 32-bit (1 iff a==0). |
| `zero_detect4` | Zero detect, 4-bit (1 iff a==0). |
| `zero_detect8` | Zero detect, 8-bit (1 iff a==0). |
| `zero_flag16` | Zero flag, 16-bit (result==0). |
| `zero_flag32` | Zero flag, 32-bit (result==0). |
| `zero_flag4` | Zero flag, 4-bit (result==0). |
| `zero_flag8` | Zero flag, 8-bit (result==0). |
