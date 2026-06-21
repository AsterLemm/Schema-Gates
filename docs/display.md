# Display Drivers

Binary and BCD to seven-segment decoders (with optional decimal point) and ASCII digit conversion.

*Directory:* `src/display/` -- 5 modules.

| Module | Description |
|--------|-------------|
| `ascii_digit_to_bin` | ASCII hex character to 4-bit nibble (+valid). |
| `bcd_to_7seg` | BCD digit (0-9) to 7-segment decoder (blank if >9). |
| `bin_to_7seg` | 4-bit hex to 7-segment decoder (active-high). |
| `bin_to_ascii_digit` | 4-bit hex nibble to ASCII character code. |
| `seg7_with_dp` | 7-segment hex decoder with decimal point. |
