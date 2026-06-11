# Multiplexers, Decoders & Encoders

N:1 multiplexers (built as mux2_1 trees), demultiplexers, binary decoders with enable, encoders, priority encoders with valid flags, and binary<->one-hot converters.

*Directory:* `src/mux_decoder_encoder/` -- 64 modules.

| Module | Description |
|--------|-------------|
| `bin_to_onehot16` | Binary->one-hot (16 lines). |
| `bin_to_onehot32` | Binary->one-hot (32 lines). |
| `bin_to_onehot4` | Binary->one-hot (4 lines). |
| `bin_to_onehot8` | Binary->one-hot (8 lines). |
| `decoder1to2` | 1-to-2 one-hot decoder. |
| `decoder2to4` | 2-to-4 one-hot decoder. |
| `decoder2to4_en` | 2-to-4 decoder with enable. |
| `decoder3to8` | 3-to-8 one-hot decoder. |
| `decoder3to8_en` | 3-to-8 decoder with enable. |
| `decoder4to16` | 4-to-16 one-hot decoder. |
| `decoder4to16_en` | 4-to-16 decoder with enable. |
| `decoder5to32` | 5-to-32 one-hot decoder. |
| `decoder5to32_en` | 5-to-32 decoder with enable. |
| `demux1to16` | 1-to-16 demultiplexer (routes d to selected line). |
| `demux1to2` | 1-to-2 demultiplexer (routes d to selected line). |
| `demux1to32` | 1-to-32 demultiplexer (routes d to selected line). |
| `demux1to4` | 1-to-4 demultiplexer (routes d to selected line). |
| `demux1to8` | 1-to-8 demultiplexer (routes d to selected line). |
| `encoder16to4` | 16-to-4 binary encoder (one-hot input assumed). |
| `encoder2to1` | 2-to-1 binary encoder (one-hot input assumed). |
| `encoder32to5` | 32-to-5 binary encoder (one-hot input assumed). |
| `encoder4to2` | 4-to-2 binary encoder (one-hot input assumed). |
| `encoder8to3` | 8-to-3 binary encoder (one-hot input assumed). |
| `mux16_1` | 16:1 multiplexer, 1-bit data; tree of 2:1 muxes. |
| `mux16_16` | 16:1 multiplexer, 16-bit data; tree of 2:1 muxes. |
| `mux16_32` | 16:1 multiplexer, 32-bit data; tree of 2:1 muxes. |
| `mux16_4` | 16:1 multiplexer, 4-bit data; tree of 2:1 muxes. |
| `mux16_8` | 16:1 multiplexer, 8-bit data; tree of 2:1 muxes. |
| `mux2_1` | 2:1 multiplexer, 1-bit data; tree of 2:1 muxes. |
| `mux2_16` | 2:1 multiplexer, 16-bit data; tree of 2:1 muxes. |
| `mux2_32` | 2:1 multiplexer, 32-bit data; tree of 2:1 muxes. |
| `mux2_4` | 2:1 multiplexer, 4-bit data; tree of 2:1 muxes. |
| `mux2_8` | 2:1 multiplexer, 8-bit data; tree of 2:1 muxes. |
| `mux32_1` | 32:1 multiplexer, 1-bit data; tree of 2:1 muxes. |
| `mux32_16` | 32:1 multiplexer, 16-bit data; tree of 2:1 muxes. |
| `mux32_32` | 32:1 multiplexer, 32-bit data; tree of 2:1 muxes. |
| `mux32_4` | 32:1 multiplexer, 4-bit data; tree of 2:1 muxes. |
| `mux32_8` | 32:1 multiplexer, 8-bit data; tree of 2:1 muxes. |
| `mux4_1` | 4:1 multiplexer, 1-bit data; tree of 2:1 muxes. |
| `mux4_16` | 4:1 multiplexer, 16-bit data; tree of 2:1 muxes. |
| `mux4_32` | 4:1 multiplexer, 32-bit data; tree of 2:1 muxes. |
| `mux4_4` | 4:1 multiplexer, 4-bit data; tree of 2:1 muxes. |
| `mux4_8` | 4:1 multiplexer, 8-bit data; tree of 2:1 muxes. |
| `mux8_1` | 8:1 multiplexer, 1-bit data; tree of 2:1 muxes. |
| `mux8_16` | 8:1 multiplexer, 16-bit data; tree of 2:1 muxes. |
| `mux8_32` | 8:1 multiplexer, 32-bit data; tree of 2:1 muxes. |
| `mux8_4` | 8:1 multiplexer, 4-bit data; tree of 2:1 muxes. |
| `mux8_8` | 8:1 multiplexer, 8-bit data; tree of 2:1 muxes. |
| `onehot_to_bin16` | One-hot->binary (16 lines). |
| `onehot_to_bin32` | One-hot->binary (32 lines). |
| `onehot_to_bin4` | One-hot->binary (4 lines). |
| `onehot_to_bin8` | One-hot->binary (8 lines). |
| `onehot_valid16` | One-hot validity (exactly-one-bit) 16-bit. |
| `onehot_valid32` | One-hot validity (exactly-one-bit) 32-bit. |
| `onehot_valid4` | One-hot validity (exactly-one-bit) 4-bit. |
| `onehot_valid8` | One-hot validity (exactly-one-bit) 8-bit. |
| `priority_encoder16` | Priority encoder (16->index of highest set bit). |
| `priority_encoder16_valid` | Priority encoder w/ valid (16-bit; valid=\|a). |
| `priority_encoder32` | Priority encoder (32->index of highest set bit). |
| `priority_encoder32_valid` | Priority encoder w/ valid (32-bit; valid=\|a). |
| `priority_encoder4` | Priority encoder (4->index of highest set bit). |
| `priority_encoder4_valid` | Priority encoder w/ valid (4-bit; valid=\|a). |
| `priority_encoder8` | Priority encoder (8->index of highest set bit). |
| `priority_encoder8_valid` | Priority encoder w/ valid (8-bit; valid=\|a). |
