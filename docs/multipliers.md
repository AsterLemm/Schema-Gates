# Multipliers

Partial-product generation, array/Braun/carry-save multipliers, Wallace and Dadda trees, Booth radix-2/4/8 (signed), Baugh-Wooley, sign-magnitude, two's-complement, squarers, constant multipliers, and multiply-accumulate.

*Directory:* `src/multipliers/` -- 94 modules.

| Module | Description |
|--------|-------------|
| `booth_encoder_radix2` | Radix-2 Booth encoder cell (sel/neg from bit pair). |
| `booth_encoder_radix4` | Radix-4 modified-Booth encoder cell. |
| `mac16` | 16-bit multiply-accumulate (unsigned). |
| `mac32` | 32-bit multiply-accumulate (unsigned). |
| `mac4` | 4-bit multiply-accumulate (unsigned). |
| `mac8` | 8-bit multiply-accumulate (unsigned). |
| `mul_array16` | 16x16 array multiplier (AND partial products + ripple-add reduction chain). |
| `mul_array32` | 32x32 array multiplier (AND partial products + ripple-add reduction chain). |
| `mul_array4` | 4x4 array multiplier (AND partial products + ripple-add reduction chain). |
| `mul_array8` | 8x8 array multiplier (AND partial products + ripple-add reduction chain). |
| `mul_baugh_wooley16` | 16x16 Baugh-Wooley signed multiplier. |
| `mul_baugh_wooley32` | 32x32 Baugh-Wooley signed multiplier. |
| `mul_baugh_wooley4` | 4x4 Baugh-Wooley signed multiplier. |
| `mul_baugh_wooley8` | 8x8 Baugh-Wooley signed multiplier. |
| `mul_booth_radix216` | 16x16 radix-2 Booth multiplier (signed). |
| `mul_booth_radix232` | 32x32 radix-2 Booth multiplier (signed). |
| `mul_booth_radix24` | 4x4 radix-2 Booth multiplier (signed). |
| `mul_booth_radix28` | 8x8 radix-2 Booth multiplier (signed). |
| `mul_booth_radix416` | 16x16 radix-4 Booth multiplier (signed). |
| `mul_booth_radix432` | 32x32 radix-4 Booth multiplier (signed). |
| `mul_booth_radix44` | 4x4 radix-4 Booth multiplier (signed). |
| `mul_booth_radix48` | 8x8 radix-4 Booth multiplier (signed). |
| `mul_booth_radix816` | 16x16 radix-8 Booth multiplier (signed). |
| `mul_booth_radix832` | 32x32 radix-8 Booth multiplier (signed). |
| `mul_booth_radix84` | 4x4 radix-8 Booth multiplier (signed). |
| `mul_booth_radix88` | 8x8 radix-8 Booth multiplier (signed). |
| `mul_braun16` | 16x16 Braun array multiplier (unsigned). |
| `mul_braun32` | 32x32 Braun array multiplier (unsigned). |
| `mul_braun4` | 4x4 Braun array multiplier (unsigned). |
| `mul_braun8` | 8x8 Braun array multiplier (unsigned). |
| `mul_by_power_of_two16` | 16-bit multiply by 2^shift (shift only). |
| `mul_by_power_of_two32` | 32-bit multiply by 2^shift (shift only). |
| `mul_by_power_of_two4` | 4-bit multiply by 2^shift (shift only). |
| `mul_by_power_of_two8` | 8-bit multiply by 2^shift (shift only). |
| `mul_carry_save16` | 16x16 carry-save multiplier (3:2 compressor reduction). |
| `mul_carry_save32` | 32x32 carry-save multiplier (3:2 compressor reduction). |
| `mul_carry_save4` | 4x4 carry-save multiplier (3:2 compressor reduction). |
| `mul_carry_save8` | 8x8 carry-save multiplier (3:2 compressor reduction). |
| `mul_const10_16` | 16-bit multiply-by-10 (a<<3 + a<<1). |
| `mul_const10_32` | 32-bit multiply-by-10 (a<<3 + a<<1). |
| `mul_const10_4` | 4-bit multiply-by-10 (a<<3 + a<<1). |
| `mul_const10_8` | 8-bit multiply-by-10 (a<<3 + a<<1). |
| `mul_const3_16` | 16-bit multiply-by-3 (a<<1 + a). |
| `mul_const3_32` | 32-bit multiply-by-3 (a<<1 + a). |
| `mul_const3_4` | 4-bit multiply-by-3 (a<<1 + a). |
| `mul_const3_8` | 8-bit multiply-by-3 (a<<1 + a). |
| `mul_const5_16` | 16-bit multiply-by-5 (a<<2 + a). |
| `mul_const5_32` | 32-bit multiply-by-5 (a<<2 + a). |
| `mul_const5_4` | 4-bit multiply-by-5 (a<<2 + a). |
| `mul_const5_8` | 8-bit multiply-by-5 (a<<2 + a). |
| `mul_counter_tree16` | 16x16 counter-based reduction-tree multiplier. |
| `mul_counter_tree32` | 32x32 counter-based reduction-tree multiplier. |
| `mul_counter_tree4` | 4x4 counter-based reduction-tree multiplier. |
| `mul_counter_tree8` | 8x8 counter-based reduction-tree multiplier. |
| `mul_dadda16` | 16x16 Dadda-tree multiplier (3:2 compressor reduction). |
| `mul_dadda32` | 32x32 Dadda-tree multiplier (3:2 compressor reduction). |
| `mul_dadda4` | 4x4 Dadda-tree multiplier (3:2 compressor reduction). |
| `mul_dadda8` | 8x8 Dadda-tree multiplier (3:2 compressor reduction). |
| `mul_reduced_wallace16` | 16x16 reduced Wallace-tree multiplier. |
| `mul_reduced_wallace32` | 32x32 reduced Wallace-tree multiplier. |
| `mul_reduced_wallace4` | 4x4 reduced Wallace-tree multiplier. |
| `mul_reduced_wallace8` | 8x8 reduced Wallace-tree multiplier. |
| `mul_shift_add_comb16` | 16x16 combinational shift-and-add multiplier. |
| `mul_shift_add_comb32` | 32x32 combinational shift-and-add multiplier. |
| `mul_shift_add_comb4` | 4x4 combinational shift-and-add multiplier. |
| `mul_shift_add_comb8` | 8x8 combinational shift-and-add multiplier. |
| `mul_shift_add_iter16` | 16x16 iterative shift-add multiplier (16 cycles). |
| `mul_shift_add_iter32` | 32x32 iterative shift-add multiplier (32 cycles). |
| `mul_shift_add_iter4` | 4x4 iterative shift-add multiplier (4 cycles). |
| `mul_shift_add_iter8` | 8x8 iterative shift-add multiplier (8 cycles). |
| `mul_sign_magnitude16` | 16x16 sign-magnitude multiplier. |
| `mul_sign_magnitude32` | 32x32 sign-magnitude multiplier. |
| `mul_sign_magnitude4` | 4x4 sign-magnitude multiplier. |
| `mul_sign_magnitude8` | 8x8 sign-magnitude multiplier. |
| `mul_twos_complement16` | 16x16 two's-complement signed multiplier. |
| `mul_twos_complement32` | 32x32 two's-complement signed multiplier. |
| `mul_twos_complement4` | 4x4 two's-complement signed multiplier. |
| `mul_twos_complement8` | 8x8 two's-complement signed multiplier. |
| `mul_wallace16` | 16x16 Wallace-tree multiplier (3:2 compressor reduction, final CPA). |
| `mul_wallace32` | 32x32 Wallace-tree multiplier (3:2 compressor reduction, final CPA). |
| `mul_wallace4` | 4x4 Wallace-tree multiplier (3:2 compressor reduction, final CPA). |
| `mul_wallace8` | 8x8 Wallace-tree multiplier (3:2 compressor reduction, final CPA). |
| `multiply_accumulate_signed16` | 16-bit signed multiply-accumulate. |
| `multiply_accumulate_signed32` | 32-bit signed multiply-accumulate. |
| `multiply_accumulate_signed4` | 4-bit signed multiply-accumulate. |
| `multiply_accumulate_signed8` | 8-bit signed multiply-accumulate. |
| `partial_products16` | 16x16 partial-product AND matrix. |
| `partial_products32` | 32x32 partial-product AND matrix. |
| `partial_products4` | 4x4 partial-product AND matrix. |
| `partial_products8` | 8x8 partial-product AND matrix. |
| `square16` | 16-bit squarer (a*a). |
| `square32` | 32-bit squarer (a*a). |
| `square4` | 4-bit squarer (a*a). |
| `square8` | 8-bit squarer (a*a). |
