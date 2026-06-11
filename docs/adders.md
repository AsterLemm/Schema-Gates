# Adders

The full spectrum of binary adders: structural cells, ripple-carry, carry-lookahead, every classic parallel-prefix topology, Ling, block-CLA, carry-skip/select, conditional-sum, carry-increment, carry-save, bit-serial, plus special adders (increment, modulo, saturating, one's-complement, end-around-carry).

*Directory:* `src/adders/` -- 114 modules.

| Module | Description |
|--------|-------------|
| `add_block_cla16` | 16-bit block CLA: 4 CLA-4 blocks, carries rippled between blocks. |
| `add_block_cla32` | 32-bit block CLA: 8 CLA-4 blocks, carries rippled between blocks. |
| `add_block_cla4` | 4-bit block-CLA (single CLA block). |
| `add_block_cla8` | 8-bit block CLA: 2 CLA-4 blocks, carries rippled between blocks. |
| `add_brent_kung16` | 16-bit prefix adder. |
| `add_brent_kung32` | 32-bit prefix adder. |
| `add_brent_kung4` | 4-bit prefix adder. |
| `add_brent_kung8` | 8-bit prefix adder. |
| `add_carry_increment16` | 16-bit carry-increment adder. |
| `add_carry_increment32` | 32-bit carry-increment adder. |
| `add_carry_increment4` | 4-bit carry-increment adder. |
| `add_carry_increment8` | 8-bit carry-increment adder. |
| `add_carry_save16` | 16-bit carry-save adder (3-input -> sum/carry vectors, no ripple). |
| `add_carry_save32` | 32-bit carry-save adder (3-input -> sum/carry vectors, no ripple). |
| `add_carry_save4` | 4-bit carry-save adder (3-input -> sum/carry vectors, no ripple). |
| `add_carry_save8` | 8-bit carry-save adder (3-input -> sum/carry vectors, no ripple). |
| `add_cla16` | 16-bit CLA: 4 x cla4 blocks + group lookahead. |
| `add_cla32` | 32-bit CLA: 8 x cla4 blocks + group lookahead. |
| `add_cla4` | 4-bit carry-lookahead adder (flat lookahead carries). |
| `add_cla8` | 8-bit CLA: 2 x cla4 blocks + group lookahead. |
| `add_conditional_sum16` | 16-bit conditional-sum adder (recursive-doubling select). |
| `add_conditional_sum32` | 32-bit conditional-sum adder (recursive-doubling select). |
| `add_conditional_sum4` | 4-bit conditional-sum adder (recursive-doubling select). |
| `add_conditional_sum8` | 8-bit conditional-sum adder (recursive-doubling select). |
| `add_const116` | 16-bit add constant 1 (y=a+1). |
| `add_const132` | 32-bit add constant 1 (y=a+1). |
| `add_const14` | 4-bit add constant 1 (y=a+1). |
| `add_const18` | 8-bit add constant 1 (y=a+1). |
| `add_cselect16` | 16-bit carry-select: each 4-bit block computed for cin=0 and 1, then muxed. |
| `add_cselect32` | 32-bit carry-select: each 4-bit block computed for cin=0 and 1, then muxed. |
| `add_cselect4` | 4-bit carry-select (single block; degenerate). |
| `add_cselect8` | 8-bit carry-select: each 4-bit block computed for cin=0 and 1, then muxed. |
| `add_cskip16` | 16-bit carry-skip: 4-bit ripple blocks, carry skips fully-propagating blocks. |
| `add_cskip32` | 32-bit carry-skip: 4-bit ripple blocks, carry skips fully-propagating blocks. |
| `add_cskip4` | 4-bit carry-skip adder (block-propagate skip). |
| `add_cskip8` | 8-bit carry-skip: 4-bit ripple blocks, carry skips fully-propagating blocks. |
| `add_end_around_carry16` | 16-bit end-around-carry adder. |
| `add_end_around_carry32` | 32-bit end-around-carry adder. |
| `add_end_around_carry4` | 4-bit end-around-carry adder. |
| `add_end_around_carry8` | 8-bit end-around-carry adder. |
| `add_han_carlson16` | 16-bit prefix adder. |
| `add_han_carlson32` | 32-bit prefix adder. |
| `add_han_carlson4` | 4-bit prefix adder. |
| `add_han_carlson8` | 8-bit prefix adder. |
| `add_knowles16` | 16-bit prefix adder. |
| `add_knowles32` | 32-bit prefix adder. |
| `add_knowles4` | 4-bit prefix adder. |
| `add_knowles8` | 8-bit prefix adder. |
| `add_kogge_stone16` | 16-bit prefix adder. |
| `add_kogge_stone32` | 32-bit prefix adder. |
| `add_kogge_stone4` | 4-bit prefix adder. |
| `add_kogge_stone8` | 8-bit prefix adder. |
| `add_ladner_fischer16` | 16-bit prefix adder. |
| `add_ladner_fischer32` | 32-bit prefix adder. |
| `add_ladner_fischer4` | 4-bit prefix adder. |
| `add_ladner_fischer8` | 8-bit prefix adder. |
| `add_ling16` | 16-bit Ling-style adder (transmit t=a\|b, carry recurrence). |
| `add_ling32` | 32-bit Ling-style adder (transmit t=a\|b, carry recurrence). |
| `add_ling4` | 4-bit Ling-style adder (transmit t=a\|b, carry recurrence). |
| `add_ling8` | 8-bit Ling-style adder (transmit t=a\|b, carry recurrence). |
| `add_modulo16` | 16-bit modulo-2^16 adder (carry-out discarded). |
| `add_modulo32` | 32-bit modulo-2^32 adder (carry-out discarded). |
| `add_modulo4` | 4-bit modulo-2^4 adder (carry-out discarded). |
| `add_modulo8` | 8-bit modulo-2^8 adder (carry-out discarded). |
| `add_one16` | 16-bit add-one (y=a+1). |
| `add_one32` | 32-bit add-one (y=a+1). |
| `add_one4` | 4-bit add-one (y=a+1). |
| `add_one8` | 8-bit add-one (y=a+1). |
| `add_ones_complement16` | 16-bit one's-complement adder (end-around carry). |
| `add_ones_complement32` | 32-bit one's-complement adder (end-around carry). |
| `add_ones_complement4` | 4-bit one's-complement adder (end-around carry). |
| `add_ones_complement8` | 8-bit one's-complement adder (end-around carry). |
| `add_rc16` | 16-bit ripple-carry adder (two add_rc8 chained on midpoint carry). |
| `add_rc32` | 32-bit ripple-carry adder (two add_rc16 chained on midpoint carry). |
| `add_rc4` | 4-bit ripple-carry adder (4x full_adder). |
| `add_rc8` | 8-bit ripple-carry adder (two add_rc4 chained on midpoint carry). |
| `add_saturating_signed16` | 16-bit signed saturating add (clamps to +max/-min on overflow). |
| `add_saturating_signed32` | 32-bit signed saturating add (clamps to +max/-min on overflow). |
| `add_saturating_signed4` | 4-bit signed saturating add (clamps to +max/-min on overflow). |
| `add_saturating_signed8` | 8-bit signed saturating add (clamps to +max/-min on overflow). |
| `add_saturating_unsigned16` | 16-bit unsigned saturating add (clamps to max). |
| `add_saturating_unsigned32` | 32-bit unsigned saturating add (clamps to max). |
| `add_saturating_unsigned4` | 4-bit unsigned saturating add (clamps to max). |
| `add_saturating_unsigned8` | 8-bit unsigned saturating add (clamps to max). |
| `add_serial16` | 16-bit bit-serial adder (1 full-adder + carry FF, 16 clocks). |
| `add_serial32` | 32-bit bit-serial adder (1 full-adder + carry FF, 32 clocks). |
| `add_serial4` | 4-bit bit-serial adder (1 full-adder + carry FF, 4 clocks). |
| `add_serial8` | 8-bit bit-serial adder (1 full-adder + carry FF, 8 clocks). |
| `add_sklansky16` | 16-bit prefix adder. |
| `add_sklansky32` | 32-bit prefix adder. |
| `add_sklansky4` | 4-bit prefix adder. |
| `add_sklansky8` | 8-bit prefix adder. |
| `add_sparse_kogge_stone16` | 16-bit prefix adder. |
| `add_sparse_kogge_stone32` | 32-bit prefix adder. |
| `add_sparse_kogge_stone4` | 4-bit prefix adder. |
| `add_sparse_kogge_stone8` | 8-bit prefix adder. |
| `black_cell` | Prefix 'black' cell (full carry-merge operator). |
| `carry_generate_cell` | Carry generate g=a&b. |
| `carry_propagate_cell` | Carry propagate p=a^b. |
| `compressor3to2` | 3:2 compressor (full adder counting cell). |
| `compressor4to2` | 4:2 compressor. |
| `compressor5to3` | 5:3 counter (popcount of 5 bits). |
| `dec16` | 16-bit decrementer (y=a-1), borrow chain. |
| `dec32` | 32-bit decrementer (y=a-1), borrow chain. |
| `dec4` | 4-bit decrementer (y=a-1), borrow chain. |
| `dec8` | 8-bit decrementer (y=a-1), borrow chain. |
| `full_adder` | Full adder from two half adders + OR. |
| `full_adder_pg` | Full adder exposing propagate/generate. |
| `gray_cell` | Prefix 'gray' cell (carry-only merge). |
| `half_adder` | Half adder: sum=a^b, carry=a&b. |
| `inc16` | 16-bit incrementer (y=a+1), half-adder carry chain. |
| `inc32` | 32-bit incrementer (y=a+1), half-adder carry chain. |
| `inc4` | 4-bit incrementer (y=a+1), half-adder carry chain. |
| `inc8` | 8-bit incrementer (y=a+1), half-adder carry chain. |
