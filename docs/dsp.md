# Fixed-Point DSP

Q-format fixed-point add/subtract/multiply with rescaling, rounding and saturation, a 4-tap FIR moving-average filter, and an iterative CORDIC rotator.

*Directory:* `src/dsp/` -- 17 modules.

| Module | Description |
|--------|-------------|
| `cordic_rotate16` | 16-bit iterative CORDIC rotator (12 iterations). |
| `fir4_q8_8` | 4-tap FIR moving-average filter (Q8.8); coefficient multiply is a shift, no * operator. |
| `fixed_add_q16_16` | Q16.16 fixed-point add (32-bit). |
| `fixed_add_q4_4` | Q4.4 fixed-point add (8-bit). |
| `fixed_add_q8_8` | Q8.8 fixed-point add (16-bit). |
| `fixed_mul_q16_16` | Q16.16 fixed-point multiply (32-bit, rescaled). |
| `fixed_mul_q4_4` | Q4.4 fixed-point multiply (8-bit, rescaled). |
| `fixed_mul_q8_8` | Q8.8 fixed-point multiply (16-bit, rescaled). |
| `fixed_round_q16_16` | Q16.16 round-to-nearest integer. |
| `fixed_round_q4_4` | Q4.4 round-to-nearest integer. |
| `fixed_round_q8_8` | Q8.8 round-to-nearest integer. |
| `fixed_saturate_q16_16` | Q16.16 saturate wide accumulator to 32-bit. |
| `fixed_saturate_q4_4` | Q4.4 saturate wide accumulator to 8-bit. |
| `fixed_saturate_q8_8` | Q8.8 saturate wide accumulator to 16-bit. |
| `fixed_sub_q16_16` | Q16.16 fixed-point subtract (32-bit). |
| `fixed_sub_q4_4` | Q4.4 fixed-point subtract (8-bit). |
| `fixed_sub_q8_8` | Q8.8 fixed-point subtract (16-bit). |
