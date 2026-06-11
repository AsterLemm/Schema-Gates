# Code Converters

Binary<->Gray, one's/two's complement and sign-magnitude conversions, thermometer code, and excess/bias (excess-3/15/127) converters.

*Directory:* `src/converters/` -- 42 modules.

| Module | Description |
|--------|-------------|
| `bin_to_gray16` | 16-bit binary->Gray. |
| `bin_to_gray32` | 32-bit binary->Gray. |
| `bin_to_gray4` | 4-bit binary->Gray. |
| `bin_to_gray8` | 8-bit binary->Gray. |
| `bin_to_thermometer16` | 16-bit binary->thermometer code. |
| `bin_to_thermometer32` | 32-bit binary->thermometer code. |
| `bin_to_thermometer4` | 4-bit binary->thermometer code. |
| `bin_to_thermometer8` | 8-bit binary->thermometer code. |
| `binary_to_excess127_8` | 8-bit value -> excess-127 (float-exponent style bias). |
| `binary_to_excess15_4` | 4-bit value -> excess-15 (bias 15). |
| `binary_to_excess3_digit` | BCD digit (0..9) -> excess-3 code. |
| `excess127_to_binary8` | Excess-127 -> 8-bit value. |
| `excess15_to_binary4` | Excess-15 -> 4-bit value. |
| `excess3_to_binary_digit` | Excess-3 -> BCD digit. |
| `gray_to_bin16` | 16-bit Gray->binary (prefix XOR). |
| `gray_to_bin32` | 32-bit Gray->binary (prefix XOR). |
| `gray_to_bin4` | 4-bit Gray->binary (prefix XOR). |
| `gray_to_bin8` | 8-bit Gray->binary (prefix XOR). |
| `ones_to_twos16` | 16-bit one's->two's complement. |
| `ones_to_twos32` | 32-bit one's->two's complement. |
| `ones_to_twos4` | 4-bit one's->two's complement. |
| `ones_to_twos8` | 8-bit one's->two's complement. |
| `signmag_to_twos16` | 16-bit sign-magnitude->two's complement. |
| `signmag_to_twos32` | 32-bit sign-magnitude->two's complement. |
| `signmag_to_twos4` | 4-bit sign-magnitude->two's complement. |
| `signmag_to_twos8` | 8-bit sign-magnitude->two's complement. |
| `thermometer_to_bin16` | 16-bit thermometer->binary (popcount). |
| `thermometer_to_bin32` | 32-bit thermometer->binary (popcount). |
| `thermometer_to_bin4` | 4-bit thermometer->binary (popcount). |
| `thermometer_to_bin8` | 8-bit thermometer->binary (popcount). |
| `thermometer_valid16` | 16-bit thermometer-code validity check. |
| `thermometer_valid32` | 32-bit thermometer-code validity check. |
| `thermometer_valid4` | 4-bit thermometer-code validity check. |
| `thermometer_valid8` | 8-bit thermometer-code validity check. |
| `twos_to_ones16` | 16-bit two's->one's complement. |
| `twos_to_ones32` | 32-bit two's->one's complement. |
| `twos_to_ones4` | 4-bit two's->one's complement. |
| `twos_to_ones8` | 8-bit two's->one's complement. |
| `twos_to_signmag16` | 16-bit two's complement->sign-magnitude. |
| `twos_to_signmag32` | 32-bit two's complement->sign-magnitude. |
| `twos_to_signmag4` | 4-bit two's complement->sign-magnitude. |
| `twos_to_signmag8` | 8-bit two's complement->sign-magnitude. |
