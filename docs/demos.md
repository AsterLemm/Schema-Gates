# Demonstration Circuits

Self-contained worked examples that wire the building blocks into recognizable circuits: adders, a counter with seven-segment output, an ALU, a traffic-light FSM, a tiny accumulator CPU, a stopwatch, and a dice roller.

*Directory:* `src/demos/` -- 10 modules.

| Module | Description |
|--------|-------------|
| `demo_4bit_counter` | Demo: 4-bit counter driving a 7-segment display. |
| `demo_add_rc8` | Demo: 8-bit ripple-carry adder (8 chained full adders). |
| `demo_alu8` | Demo: 8-bit ALU with zero and carry flags. |
| `demo_dice_roller` | Demo: LFSR-based dice roller (faces 1-6). |
| `demo_full_adder` | Demo: a single full adder built from half adders. |
| `demo_half_adder` | Demo: a single half adder. |
| `demo_seven_seg_driver` | Demo: hex-to-7-segment driver with decimal point. |
| `demo_simple_cpu4` | Demo: tiny 4-bit accumulator CPU (8 ops). |
| `demo_stopwatch` | Demo: 2-digit BCD stopwatch (0-59 seconds). |
| `demo_traffic_light` | Demo: traffic-light FSM (green/yellow/red). |
