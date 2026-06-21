# Counters & Timing

Up/down/up-down counters, ring, Johnson, and Gray counters, modulo-N counters, LFSRs (Fibonacci and Galois), timers, PWM generators, clock dividers, edge detectors, and a debouncer.

*Directory:* `src/counters/` -- 61 modules.

| Module | Description |
|--------|-------------|
| `clock_divider16` | Clock divider by 16. |
| `clock_divider2` | Clock divider by 2. |
| `clock_divider32` | Clock divider by 32. |
| `clock_divider4` | Clock divider by 4. |
| `clock_divider8` | Clock divider by 8. |
| `counter_down16` | 16-bit down counter. |
| `counter_down32` | 32-bit down counter. |
| `counter_down4` | 4-bit down counter. |
| `counter_down8` | 8-bit down counter. |
| `counter_up16` | 16-bit up counter. |
| `counter_up32` | 32-bit up counter. |
| `counter_up4` | 4-bit up counter. |
| `counter_up8` | 8-bit up counter. |
| `counter_updown16` | 16-bit up/down counter. |
| `counter_updown32` | 32-bit up/down counter. |
| `counter_updown4` | 4-bit up/down counter. |
| `counter_updown8` | 8-bit up/down counter. |
| `debouncer` | Switch debouncer (counter-based). |
| `edge_detector_both` | Any-edge detector. |
| `edge_detector_falling` | Falling-edge detector. |
| `edge_detector_rising` | Rising-edge detector. |
| `fibonacci_lfsr16` | 16-bit Fibonacci LFSR. |
| `fibonacci_lfsr32` | 32-bit Fibonacci LFSR. |
| `fibonacci_lfsr4` | 4-bit Fibonacci LFSR. |
| `fibonacci_lfsr8` | 8-bit Fibonacci LFSR. |
| `galois_lfsr16` | 16-bit Galois LFSR. |
| `galois_lfsr32` | 32-bit Galois LFSR. |
| `galois_lfsr4` | 4-bit Galois LFSR. |
| `galois_lfsr8` | 8-bit Galois LFSR. |
| `gray_counter16` | 16-bit Gray-code counter. |
| `gray_counter32` | 32-bit Gray-code counter. |
| `gray_counter4` | 4-bit Gray-code counter. |
| `gray_counter8` | 8-bit Gray-code counter. |
| `johnson_counter16` | 16-bit Johnson (twisted-ring) counter. |
| `johnson_counter32` | 32-bit Johnson (twisted-ring) counter. |
| `johnson_counter4` | 4-bit Johnson (twisted-ring) counter. |
| `johnson_counter8` | 8-bit Johnson (twisted-ring) counter. |
| `lfsr16` | 16-bit Fibonacci LFSR (maximal-length taps). |
| `lfsr32` | 32-bit Fibonacci LFSR (maximal-length taps). |
| `lfsr4` | 4-bit Fibonacci LFSR (maximal-length taps). |
| `lfsr8` | 8-bit Fibonacci LFSR (maximal-length taps). |
| `mod10_counter` | Modulo-10 counter (0..9), tc at terminal count. |
| `mod12_counter` | Modulo-12 counter (0..11), tc at terminal count. |
| `mod16_counter` | Modulo-16 counter (0..15), tc at terminal count. |
| `mod3_counter` | Modulo-3 counter (0..2), tc at terminal count. |
| `mod5_counter` | Modulo-5 counter (0..4), tc at terminal count. |
| `mod60_counter` | Modulo-60 counter (0..59), tc at terminal count. |
| `mod6_counter` | Modulo-6 counter (0..5), tc at terminal count. |
| `one_pulse` | Single-cycle pulse on rising trigger. |
| `pwm16` | 16-bit PWM generator (duty/2^16). |
| `pwm32` | 32-bit PWM generator (duty/2^32). |
| `pwm4` | 4-bit PWM generator (duty/2^4). |
| `pwm8` | 8-bit PWM generator (duty/2^8). |
| `ring_counter16` | 16-bit ring counter (one-hot rotate). |
| `ring_counter32` | 32-bit ring counter (one-hot rotate). |
| `ring_counter4` | 4-bit ring counter (one-hot rotate). |
| `ring_counter8` | 8-bit ring counter (one-hot rotate). |
| `timer16` | 16-bit programmable timer. |
| `timer32` | 32-bit programmable timer. |
| `timer4` | 4-bit programmable timer. |
| `timer8` | 8-bit programmable timer. |
