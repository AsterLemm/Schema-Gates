# Error Detection & Correction

Even/odd parity generation and checking, Hamming single-error-correcting codes (7,4 and generic 12/8, 21/16, 38/32), CRC (serial and parallel) for several polynomials, and additive / one's-complement checksums.

*Directory:* `src/error_detection/` -- 34 modules.

| Module | Description |
|--------|-------------|
| `checksum_add16` | 16-bit additive checksum step. |
| `checksum_add32` | 32-bit additive checksum step. |
| `checksum_add8` | 8-bit additive checksum step. |
| `checksum_ones_complement16` | 16-bit one's-complement checksum add. |
| `checksum_ones_complement32` | 32-bit one's-complement checksum add. |
| `checksum_ones_complement8` | 8-bit one's-complement checksum add. |
| `crc16_parallel` | CRC-16 parallel (whole word), poly 0x1021. |
| `crc16_serial` | CRC-16 serial (LFSR), poly 0x1021. |
| `crc32_parallel` | CRC-32 parallel (whole word), poly 0x4C11DB7. |
| `crc32_serial` | CRC-32 serial (LFSR), poly 0x4C11DB7. |
| `crc4_parallel` | CRC-4 parallel (whole word), poly 0x3. |
| `crc4_serial` | CRC-4 serial (LFSR), poly 0x3. |
| `crc8_parallel` | CRC-8 parallel (whole word), poly 0x7. |
| `crc8_serial` | CRC-8 serial (LFSR), poly 0x7. |
| `hamming_decode_12_8` | Hamming SEC decoder (12 bits -> 8 data, 1-bit correct). |
| `hamming_decode_21_16` | Hamming SEC decoder (21 bits -> 16 data, 1-bit correct). |
| `hamming_decode_38_32` | Hamming SEC decoder (38 bits -> 32 data, 1-bit correct). |
| `hamming_decode_7_4` | Hamming (7,4) decoder with single-error correction. |
| `hamming_encode_12_8` | Hamming SEC encoder (8 data -> 12 bits). |
| `hamming_encode_21_16` | Hamming SEC encoder (16 data -> 21 bits). |
| `hamming_encode_38_32` | Hamming SEC encoder (32 data -> 38 bits). |
| `hamming_encode_7_4` | Hamming (7,4) encoder. |
| `parity_check16` | 16-bit even-parity checker. |
| `parity_check32` | 32-bit even-parity checker. |
| `parity_check4` | 4-bit even-parity checker. |
| `parity_check8` | 8-bit even-parity checker. |
| `parity_even16` | 16-bit even-parity generator. |
| `parity_even32` | 32-bit even-parity generator. |
| `parity_even4` | 4-bit even-parity generator. |
| `parity_even8` | 8-bit even-parity generator. |
| `parity_odd16` | 16-bit odd-parity generator. |
| `parity_odd32` | 32-bit odd-parity generator. |
| `parity_odd4` | 4-bit odd-parity generator. |
| `parity_odd8` | 8-bit odd-parity generator. |
