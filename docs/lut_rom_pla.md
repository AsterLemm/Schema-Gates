# LUT / ROM / PLA / PAL

Lookup tables driven by the BITF_LUT directive, asynchronous and synchronous ROMs, a decoder-based ROM using BITF_DECODER, small synchronous RAMs, and example PLA/PAL sum-of-products arrays.

*Directory:* `src/lut_rom_pla/` -- 29 modules.

| Module | Description |
|--------|-------------|
| `lut2_1` | 2-input 1-bit LUT (BITF_LUT directive). |
| `lut3_1` | 3-input 1-bit LUT (BITF_LUT directive). |
| `lut4_1` | 4-input 1-bit LUT (BITF_LUT directive). |
| `lut4_4` | 4-input 4-bit lookup table. |
| `lut4_8` | 4-input 8-bit lookup table. |
| `lut5_1` | 5-input 1-bit LUT (BITF_LUT directive). |
| `lut6_1` | 6-input 1-bit LUT (BITF_LUT directive). |
| `lut6_8` | 6-input 8-bit lookup table. |
| `lut8_8` | 8-input 8-bit lookup table. |
| `pal_example_4in_2out` | Example PAL: 4-input, 2-output. |
| `pla_example_4in_3out` | Example PLA: 4-input, 3-output sum-of-products. |
| `ram_sync_16x16` | Synchronous RAM, 16x16 bits. |
| `ram_sync_16x8` | Synchronous RAM, 16x8 bits. |
| `ram_sync_32x8` | Synchronous RAM, 32x8 bits. |
| `ram_sync_64x8` | Synchronous RAM, 64x8 bits. |
| `rom_async_128x16` | Asynchronous ROM, 128x16 bits. |
| `rom_async_16x16` | Asynchronous ROM, 16x16 bits. |
| `rom_async_16x8` | Asynchronous ROM, 16x8 bits. |
| `rom_async_256x8` | Asynchronous ROM, 256x8 bits. |
| `rom_async_32x8` | Asynchronous ROM, 32x8 bits. |
| `rom_async_64x8` | Asynchronous ROM, 64x8 bits. |
| `rom_decoder_16x8` | Decoder-based ROM 16x8 (BITF_DECODER directive). |
| `rom_decoder_8x8` | Decoder-based ROM 8x8 (BITF_DECODER directive). |
| `rom_sync_128x16` | Synchronous ROM, 128x16 bits. |
| `rom_sync_16x16` | Synchronous ROM, 16x16 bits. |
| `rom_sync_16x8` | Synchronous ROM, 16x8 bits. |
| `rom_sync_256x8` | Synchronous ROM, 256x8 bits. |
| `rom_sync_32x8` | Synchronous ROM, 32x8 bits. |
| `rom_sync_64x8` | Synchronous ROM, 64x8 bits. |
