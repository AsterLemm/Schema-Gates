// ############################################################################
// ##  BITFries-RV32IM ,  FULL SYSTEM (CPU + immediate-mode GPU + screen)    ##
// ##  Single-file synthesizable source for the BITF-Synth Engine flow.       ##
// ##  (C) 2026 BITFries / Glad-Note2022                                      ##
// ##  Operand-isolation / process-gating throughout: see ALU sel_*/gate_*,   ##
// ##  Branch_Unit gate_*, and GPU CONFIG/PROCESS front-MUX comments.         ##
// ##  Synthesise RV32IM_SYSTEM as the top.                                   ##
// ############################################################################

// ===== TOP =============================================================
// ============================================================================
//  RV32IM_SYSTEM ,  TOP LEVEL
//  BITFries-RV32IM CPU  +  immediate-mode GPU  +  configurable screen
//  (C) 2026 BITFries / Glad-Note2022
//
//  Wires the CPU's memory-mapped GPU bus into the GPU and brings the GPU's
//  screen interface, the CPU's ROM port, the ALU pipeline strobes (ppln_*),
//  the GPIO and the diagnostic probes out to the build.
//
//  This is the synthesis TOP, the BITF-Synth Engine `// define` colours
//  below are the authoritative ones. The same directives inside RV32IM_CPU / GPU /
//  Memory_And_MMIO are harmless no-ops while those modules are submodules.
// ============================================================================

module RV32IM_SYSTEM (
    input  wire        clk,
    input  wire        reset,

    // ── External instruction ROM (combinational read) ───────────────────────
    output wire [6:0]  rom_addr,
    output wire        rom_cs,
    input  wire [31:0] rom_data,

    // ── ALU / Branch datapath pipeline strobes (drive high for normal run) ───
    input  wire        ppln_add,
    input  wire        ppln_logic,
    input  wire        ppln_shift,
    input  wire        ppln_cmp,
    input  wire        ppln_mul,
    input  wire        ppln_div,
    input  wire        ppln_bcd,
    input  wire        ppln_bcmp,
    input  wire        ppln_badd,

    // ── GPIO ─────────────────────────────────────────────────────────────────
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out,
    output wire [31:0] gpio_dir,
    output wire        gpio_write_trigger,

    // ── Screen handshake ─────────────────────────────────────────────────────
    input  wire        screen_ready,        // tie high to free-run
    output wire        frame_start,
    output wire        frame_done,

    // ── Screen geometry / mode ───────────────────────────────────────────────
    output wire [7:0]  scr_w,               // width  field (actual = scr_w + 1)
    output wire [7:0]  scr_h,               // height field (actual = scr_h + 1)
    output wire [1:0]  scr_ctype,           // 00 mono | 01 MUX | 10 RGB12 | 11 RGB24
    output wire        screen_enable,       // display draws only while high
    output wire        screen_fill,         // flood screen with fill colour

    // ── Monochrome row path (up to 256×256, 256-bit row over 4 slices) ───────
    output wire        mono_valid,
    output wire [7:0]  mono_y,
    output wire [63:0] mono_s0,
    output wire [63:0] mono_s1,
    output wire [63:0] mono_s2,
    output wire [63:0] mono_s3,

    // ── Colour pixel path (up to 32×32, pixel-serial) ────────────────────────
    output wire        px_valid,
    output wire [4:0]  px_x,
    output wire [4:0]  px_y,
    output wire [3:0]  px_mux,              // valid in MUX mode
    output wire [23:0] px_rgb,              // valid in RGB modes (RGB12 expanded)

    // ── Diagnostics ──────────────────────────────────────────────────────────
    output wire [31:0] pc_current,
    output wire [31:0] alu_result,
    output wire        branch_taken
);

    // ── Authoritative BITF-Synth Engine port colours ──────────────────────
    // define clk                  input   97.160.255
    // define reset                input   36.255.145
    // define rom_data             input   126.199.90
    // define rom_addr             output  38.15.153
    // define rom_cs               output  69.97.153
    // define ppln_add             input   90.126.199
    // define ppln_logic           input   255.97.97
    // define ppln_shift           input   0.76.255
    // define ppln_cmp             input   156.68.178
    // define ppln_mul             input   211.235.0
    // define ppln_div             input   0.125.178
    // define ppln_bcd             input   242.153.109
    // define ppln_bcmp            input   160.255.97
    // define ppln_badd            input   68.178.178
    // define gpio_in              input   255.25.140
    // define gpio_out             output  191.0.191
    // define gpio_dir             output  153.51.255
    // define gpio_write_trigger   output  25.255.198
    // define screen_ready         input   153.43.43
    // define frame_start          output  133.242.24
    // define frame_done           output  120.255.180
    // define scr_w                output  61.153.15
    // define scr_h                output  176.109.242
    // define scr_ctype            output  20.20.199
    // define screen_enable        output  90.255.120
    // define screen_fill          output  255.140.60
    // define mono_valid           output  24.133.242
    // define mono_y               output  109.109.242
    // define mono_s0              output  255.255.255
    // define mono_s1              output  56.199.56
    // define mono_s2              output  199.139.20
    // define mono_s3              output  199.56.80
    // define px_valid             output  68.213.242
    // define px_x                 output  24.242.97
    // define px_y                 output  153.15.130
    // define px_mux               output  255.210.120
    // define px_rgb               output  255.60.60
    // define pc_current           output  255.0.26
    // define alu_result           output  178.54.0
    // define branch_taken         output  178.167.68

    // ── internal CPU <-> GPU register bus ─────────────────────────────────
    wire        w_gpu_we;
    wire [3:0]  w_gpu_addr;
    wire [31:0] w_gpu_wdata;
    wire [31:0] w_gpu_rdata;

    // ──────────────────────────────── CPU ────────────────────────────────
    RV32IM_CPU u_cpu (
        .clk                (clk),
        .reset              (reset),
        .rom_addr           (rom_addr),
        .rom_cs             (rom_cs),
        .rom_data           (rom_data),
        .ppln_add           (ppln_add),
        .ppln_logic         (ppln_logic),
        .ppln_shift         (ppln_shift),
        .ppln_cmp           (ppln_cmp),
        .ppln_mul           (ppln_mul),
        .ppln_div           (ppln_div),
        .ppln_bcd           (ppln_bcd),
        .ppln_bcmp          (ppln_bcmp),
        .ppln_badd          (ppln_badd),
        .gpio_in            (gpio_in),
        .gpio_out           (gpio_out),
        .gpio_dir           (gpio_dir),
        .gpio_write_trigger (gpio_write_trigger),
        .gpu_we             (w_gpu_we),
        .gpu_addr           (w_gpu_addr),
        .gpu_wdata          (w_gpu_wdata),
        .gpu_rdata          (w_gpu_rdata),
        .pc_current         (pc_current),
        .alu_result         (alu_result),
        .branch_taken       (branch_taken)
    );

    // ──────────────────────────────── GPU ────────────────────────────────
    GPU u_gpu (
        .clk           (clk),
        .reset         (reset),
        .gpu_we        (w_gpu_we),
        .gpu_addr      (w_gpu_addr),
        .gpu_wdata     (w_gpu_wdata),
        .gpu_rdata     (w_gpu_rdata),
        .screen_ready  (screen_ready),
        .frame_start   (frame_start),
        .frame_done    (frame_done),
        .scr_w         (scr_w),
        .scr_h         (scr_h),
        .scr_ctype     (scr_ctype),
        .enable        (screen_enable),
        .fill          (screen_fill),
        .mono_valid    (mono_valid),
        .mono_y        (mono_y),
        .mono_s0       (mono_s0),
        .mono_s1       (mono_s1),
        .mono_s2       (mono_s2),
        .mono_s3       (mono_s3),
        .px_valid      (px_valid),
        .px_x          (px_x),
        .px_y          (px_y),
        .px_mux        (px_mux),
        .px_rgb        (px_rgb)
    );

endmodule

// ===== CPU CORE ========================================================
module RV32IM_CPU (
    // ── Clock & Reset ───────────────────────────────────────────────────────
    input  wire        clk,
    input  wire        reset,

    // ── External Instruction ROM interface (128 x 32-bit) ──────────────────
    output wire [6:0]  rom_addr,            // word address = pc_current[8:2]
    output wire        rom_cs,              // chip select (constant 1)
    input  wire [31:0] rom_data,            // instruction word returned by ROM

    // ── Pipeline gate controls (HIGH = run normally, LOW = freeze path) ─────
    input  wire        ppln_add,            // ALU adder / subtractor
    input  wire        ppln_logic,          // ALU bitwise logic
    input  wire        ppln_shift,          // ALU barrel shifter
    input  wire        ppln_cmp,            // ALU comparator
    input  wire        ppln_mul,            // ALU tree multiplier
    input  wire        ppln_div,            // ALU LUT divider
    input  wire        ppln_bcd,            // ALU BCD converter
    input  wire        ppln_bcmp,           // Branch comparator
    input  wire        ppln_badd,           // Branch target adder

    // ── 32-bit Arduino-style GPIO ───────────────────────────────────────────
    input  wire [31:0] gpio_in,             // external input sample
    output wire [31:0] gpio_out,            // latched output value
    output wire [31:0] gpio_dir,            // latched direction (1=out, 0=in)
    output wire        gpio_write_trigger,  // pulses on GPIO_OUT / GPIO_DIR write

    // ── GPU command register (MMIO base + 0x00) ────────────────────────────
    output wire        gpu_we,              // GPU register write strobe
    output wire [3:0]  gpu_addr,            // GPU register index (0..15)
    output wire [31:0] gpu_wdata,           // data to GPU register
    input  wire [31:0] gpu_rdata,           // GPU status readback

    // ── Diagnostic probe outputs ────────────────────────────────────────────
    output wire [31:0] pc_current,          // current PC value
    output wire [31:0] alu_result,          // ALU result (before writeback mux)
    output wire        branch_taken         // 1 = branch condition met
);

    // ── Top-level port colours (shared colour == connected net) ─────────────
    // define clk                  input   97.160.255
    // define reset                input   36.255.145
    // define rom_data             input   126.199.90
    // define rom_addr             output  38.15.153
    // define rom_cs               output  69.97.153
    // define ppln_add             input   90.126.199
    // define ppln_logic           input   255.97.97
    // define ppln_shift           input   0.76.255
    // define ppln_cmp             input   156.68.178
    // define ppln_mul             input   211.235.0
    // define ppln_div             input   0.125.178
    // define ppln_bcd             input   242.153.109
    // define ppln_bcmp            input   160.255.97
    // define ppln_badd            input   68.178.178
    // define gpio_in              input   255.25.140
    // define gpio_out             output  191.0.191
    // define gpio_dir             output  153.51.255
    // define gpio_write_trigger   output  25.255.198
    // define gpu_we               output  97.153.69
    // define gpu_addr             output  255.190.70
    // define gpu_wdata            output  68.68.242
    // define gpu_rdata            input   120.200.255
    // define pc_current           output  255.0.26
    // define alu_result           output  178.54.0
    // define branch_taken         output  178.167.68

    // ── Internal datapath nets ──────────────────────────────────────────────
    wire [31:0] inst;            // PC -> Control / Imm_Ext / ALU (+ branch funct3)
    wire [31:0] pc_plus4;        // PC -> Branch
    wire [31:0] pc_next;         // Branch -> PC
    wire [31:0] imm_ext;         // Imm_Ext -> ALU / Branch

    // Control_Unit -> ALU / Branch
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        branch;          // -> Branch_Unit.branch_en
    wire [1:0]  alu_src_a;
    wire        alu_src_b;
    wire [3:0]  alu_control;

    // ALU -> Branch_Unit
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Memory_And_MMIO -> ALU writeback
    wire [31:0] mem_rdata;

    // ── Program Counter + ROM interface ─────────────────────────────────────
    Program_Counter u_pc (
        .clk        (clk),
        .reset      (reset),
        .pc_next    (pc_next),
        .rom_cs     (rom_cs),
        .rom_addr   (rom_addr),
        .rom_data   (rom_data),
        .pc_current (pc_current),
        .pc_plus4   (pc_plus4),
        .inst       (inst)
    );

    // ── Immediate Extender ──────────────────────────────────────────────────
    Immediate_Extender u_imm (
        .inst       (inst),
        .imm_ext    (imm_ext)
    );

    // ── Control Unit ────────────────────────────────────────────────────────
    Control_Unit u_ctrl (
        .opcode     (inst[6:0]),
        .funct3     (inst[14:12]),
        .funct7     (inst[31:25]),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .alu_control(alu_control)
    );

    // ── ALU + Register File ─────────────────────────────────────────────────
    // Legacy direct RAM/GPU outputs left open; Memory_And_MMIO drives the
    // live RAM / GPU / GPIO instead (recommended path).
    ALU u_alu (
        .clk              (clk),
        .reset            (reset),
        .inst             (inst),
        .pc_current       (pc_current),
        .imm_ext          (imm_ext),
        .alu_control      (alu_control),
        .alu_src_a        (alu_src_a),
        .alu_src_b        (alu_src_b),
        .reg_write        (reg_write),
        .mem_read         (mem_read),
        .mem_write        (mem_write),
        .mem_to_reg       (mem_to_reg),
        .ppln_add         (ppln_add),
        .ppln_logic       (ppln_logic),
        .ppln_shift       (ppln_shift),
        .ppln_cmp         (ppln_cmp),
        .ppln_mul         (ppln_mul),
        .ppln_div         (ppln_div),
        .ppln_bcd         (ppln_bcd),
        .ram_rdata        (mem_rdata),       // <- Memory_And_MMIO.read_data
        .ram_cs           (),                // legacy, unused
        .ram_we           (),                // legacy, unused
        .ram_addr         (),                // legacy, unused
        .ram_wdata        (),                // legacy, unused
        .gpu_write_trigger(),                // legacy, unused (use Memory's)
        .gpu_cmd_override (),                // legacy, unused
        .gpu_cmd_fill     (),                // legacy, unused
        .gpu_cmd_enable   (),                // legacy, unused
        .gpu_cmd_x        (),                // legacy, unused
        .gpu_cmd_y        (),                // legacy, unused
        .gpu_cmd_color    (),                // legacy, unused
        .rs1_data         (rs1_data),
        .rs2_data         (rs2_data),
        .alu_result       (alu_result)
    );

    // ── Branch Unit ─────────────────────────────────────────────────────────
    Branch_Unit u_branch (
        .rs1          (rs1_data),
        .rs2          (rs2_data),
        .pc_current   (pc_current),
        .pc_plus4     (pc_plus4),
        .imm_ext      (imm_ext),
        .branch_en    (branch),
        .funct3       (inst[14:12]),
        .ppln_bcmp    (ppln_bcmp),
        .ppln_badd    (ppln_badd),
        .pc_next      (pc_next),
        .branch_taken (branch_taken)
    );

    // ── Memory + MMIO + GPIO  (recommended peripheral) ──────────────────────
    Memory_And_MMIO u_mem (
        .clk               (clk),
        .reset             (reset),
        .mem_write         (mem_write),
        .mem_read          (mem_read),
        .address           (alu_result),     // ALU.alu_result -> address
        .write_data        (rs2_data),       // ALU.rs2_data   -> write_data
        .gpio_in           (gpio_in),
        .read_data         (mem_rdata),      // -> ALU.ram_rdata
        .gpu_we            (gpu_we),
        .gpu_addr          (gpu_addr),
        .gpu_wdata         (gpu_wdata),
        .gpu_rdata         (gpu_rdata),
        .gpio_out          (gpio_out),
        .gpio_dir          (gpio_dir),
        .gpio_write_trigger(gpio_write_trigger)
    );

endmodule

// ===== CPU DATAPATH LEAVES (operand-isolated ALU + Branch_Unit) ========


// ============================================================================
// >>> LEAF MODULE 1/6 : Program_Counter   (source: pc.v, verbatim)
// ============================================================================

// ============================================================================
// PROGRAM COUNTER ,  Standalone Synthesizable Module
// BABFT FULL RV32I+M  /  BIT16 GPU ARCHITECTURE
// (C) 2026 BITFries / Glad-Note2022
//
// Handles: PC register, PC+4 arithmetic, ROM address decode, instruction output.
//
// ── PORT CONNECTIONS TO OTHER MODULES ────────────────────────────────────────
//   pc_next      ← branch_unit : pc_next[31:0]
//   pc_current   → branch_unit : pc_current[31:0]
//   pc_current   → alu         : pc_current[31:0]   (AUIPC operand A)
//   pc_plus4     → branch_unit : pc_plus4[31:0]
//   inst         → control_unit: opcode/funct3/funct7 (slice inst[6:0]/[14:12]/[31:25])
//   inst         → imm_ext     : inst[31:0]
//   inst         → alu         : inst[31:0]          (regfile address decode)
//
// ── ROM INTERFACE ─────────────────────────────────────────────────────────────
//   ROM : 4096 bits  =  128 words × 32-bit
//         Address width : 7 bits [6:0]  (word index = pc_current[8:2])
//         Data width    : 32 bits [31:0]
//
// ── SYNTHESIZER PORT DIRECTIVES (BITF-Synth Engine) ───────────────────────────
// =============================================================================

module Program_Counter (
    // ── Clock & Reset ─────────────────────────────────────────────────────────
    input  wire        clk,
    input  wire        reset,

    // ── From Branch Unit ──────────────────────────────────────────────────────
    input  wire [31:0] pc_next,         // Next PC (branch target or PC+4 from Branch_Unit)

    // ── To ROM (4096-bit / 128 × 32-bit words) ───────────────────────────────
    output wire        rom_cs,          // Chip Select, high every cycle (gate externally if needed)
    output wire [6:0]  rom_addr,        // Word address = pc_current[8:2]

    // ── From ROM ──────────────────────────────────────────────────────────────
    input  wire [31:0] rom_data,        // Instruction word returned by ROM

    // ── To All Other Modules ──────────────────────────────────────────────────
    output reg  [31:0] pc_current,      // Current PC value
    output wire [31:0] pc_plus4,        // PC + 4 (not-taken branch target, to Branch_Unit)
    output wire [31:0] inst             // Instruction word (to Control_Unit / Imm_Ext / ALU)
);


    // ── Port colour defines (v3.9), shared colours = connected ports ─────
    // define clk                    input   97.160.255
    // define reset                  input   36.255.145
    // define pc_next                input   58.255.36
    // define rom_data               input   126.199.90
    // define rom_cs                 output  69.97.153
    // define rom_addr               output  38.15.153
    // define pc_current             output  255.0.26
    // define pc_plus4               output  0.204.255
    // define inst                   output  0.0.255

    // ── PC Register ───────────────────────────────────────────────────────────
    always @(posedge clk or posedge reset) begin
        if (reset) pc_current <= 32'd0;
        else       pc_current <= pc_next;
    end

    // ── PC Arithmetic ─────────────────────────────────────────────────────────
    assign pc_plus4 = pc_current + 32'd4;

    // ── ROM Interface ─────────────────────────────────────────────────────────
    assign rom_cs   = 1'b1;              // Always fetching, gate externally to stall
    assign rom_addr = pc_current[8:2];   // Drop byte-offset bits [1:0], take 7 word-address bits

    // ── Instruction Output ────────────────────────────────────────────────────
    assign inst = rom_data;              // Pass ROM word through as instruction

endmodule

// ============================================================================
// >>> LEAF MODULE 2/6 : Immediate_Extender (source: imm_ext.v, verbatim)
// ============================================================================

// ============================================================================
// IMMEDIATE EXTENDER ,  Standalone Synthesizable Module
// BABFT FULL RV32I+M  /  BIT16 GPU ARCHITECTURE
// (C) 2026 BITFries / Glad-Note2022
//
// Pure combinational sign-extension of the immediate field embedded in the
// 32-bit instruction word. Bit layout varies by instruction type.
// No pipeline needed, this is a pure wire-rearrangement / sign-extend layer.
//
// ── PORT CONNECTIONS TO OTHER MODULES ────────────────────────────────────────
//   inst      ← pc         : inst[31:0]
//   imm_ext   → alu         : imm_ext[31:0]  (B operand when alu_src_b=1)
//   imm_ext   → branch_unit : imm_ext[31:0]  (branch target offset)
//
// ── IMMEDIATE TYPE ENCODING ───────────────────────────────────────────────────
//   S-Type  (Store,  opcode 0100011): {inst[31:25], inst[11:7]}
//   B-Type  (Branch, opcode 1100011): {inst[7], inst[30:25], inst[11:8], 1'b0}
//   U-Type  (LUI/AUIPC, 0110111/0010111): {inst[31:12], 12'b0}
//   I-Type  (default, ADDI, Load, etc.): {inst[31:20]}
//
// ── SYNTHESIZER PORT DIRECTIVES (BITF-Synth Engine) ───────────────────────────
// =============================================================================

module Immediate_Extender (
    // ── From PC ───────────────────────────────────────────────────────────────
    input  wire [31:0] inst,        // Raw 32-bit instruction word

    // ── To ALU and Branch Unit ────────────────────────────────────────────────
    output reg  [31:0] imm_ext      // Sign-extended immediate value
);


    // ── Port colour defines (v3.9), shared colours = connected ports ─────
    // define inst                   input   0.0.255
    // define imm_ext                output  255.97.208

    wire [6:0] opcode = inst[6:0];

    always @(*) begin
        case (opcode)
            // S-Type: Store , split immediate across inst[31:25] and inst[11:7]
            7'b0100011:
                imm_ext = {{20{inst[31]}}, inst[31:25], inst[11:7]};

            // B-Type: Branch, scrambled immediate with implicit *2 (LSB forced 0)
            7'b1100011:
                imm_ext = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

            // U-Type: LUI / AUIPC, upper 20 bits, lower 12 zeroed
            7'b0110111,
            7'b0010111:
                imm_ext = {inst[31:12], 12'b0};

            // I-Type default: ADDI, XORI, Load, JALR, etc., upper 12 bits
            default:
                imm_ext = {{20{inst[31]}}, inst[31:20]};
        endcase
    end

endmodule

// ============================================================================
// >>> LEAF MODULE 3/6 : Control_Unit       (source: control_unit.v, verbatim)
// ============================================================================

// ============================================================================
// CONTROL UNIT ,  Standalone Synthesizable Module
// BABFT FULL RV32I+M  /  BIT16 GPU ARCHITECTURE
// (C) 2026 BITFries / Glad-Note2022
//
// Pure combinational opcode decoder. Drives all datapath control signals.
//
// Signals that depend ONLY on opcode[6:2] (5-bit, 32 entries) are decoded
// via BITF_LUT, one flat truth table each, no comparator chains.
//
// alu_control depends on opcode + funct3 + funct7[5], so it stays as a
// compact always @(*) block covering only the two relevant opcode cases.
//
// ── PORT CONNECTIONS TO OTHER MODULES ─────────────────────────────────────
//   opcode       ← pc : inst[6:0]
//   funct3       ← pc : inst[14:12]
//   funct7       ← pc : inst[31:25]
//   reg_write    → alu : reg_write
//   mem_write    → alu : mem_write
//   mem_read     → alu : mem_read
//   mem_to_reg   → alu : mem_to_reg
//   alu_src_a    → alu : alu_src_a
//   alu_src_b    → alu : alu_src_b
//   alu_control  → alu : alu_control
//   branch       → branch_unit : branch_en
//
// ── TRUTH TABLE KEY  (input = opcode[6:2]) ────────────────────────────────
//   Index  opcode[6:2]  Type
//     0    00000        Load   (0000011)
//     4    00100        I-type (0010011)
//     5    00101        AUIPC  (0010111)
//     8    01000        Store  (0100011)
//    12    01100        R-type (0110011)
//    13    01101        LUI    (0110111)
//    24    11000        Branch (1100011)
//
// ── SYNTHESIZER PORT DIRECTIVES (BITF-Synth Engine) ───────────────────────
// ============================================================================

module Control_Unit (
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,

    output wire        reg_write,
    output wire        mem_read,
    output wire        mem_write,
    output wire        mem_to_reg,
    output wire        branch,
    output wire [1:0]  alu_src_a,
    output wire        alu_src_b,

    output reg  [3:0]  alu_control
);


    // ══ BITF_LUT, opcode[6:2] → control signals ══════════════════════════
    // 5-bit input, 32-entry truth table (0x hex, 8 digits).
    // Bit i of the table = output when opcode[6:2] == i.
    //
    // reg_write: 1 for Load(0) I-type(4) AUIPC(5) R-type(12) LUI(13)
    // BITF_LUT cu_reg_write  5 = 0x00003031
    //
    // mem_read: 1 for Load(0) only
    // BITF_LUT cu_mem_read   5 = 0x00000001
    //
    // mem_write: 1 for Store(8) only
    // BITF_LUT cu_mem_write  5 = 0x00000100
    //
    // mem_to_reg: 1 for Load(0) only
    // BITF_LUT cu_mem_to_reg 5 = 0x00000001
    //
    // branch: 1 for Branch(24) only
    // BITF_LUT cu_branch     5 = 0x01000000
    //
    // alu_src_b: 1 for Load(0) I-type(4) AUIPC(5) Store(8) LUI(13)
    // BITF_LUT cu_alu_src_b  5 = 0x00002131
    //
    // alu_src_a[0]: 1 for AUIPC(5) only → selects PC (2'b01)
    // BITF_LUT cu_alu_src_a0 5 = 0x00000020
    //
    // alu_src_a[1]: 1 for LUI(13) only  → selects Zero (2'b10)
    // BITF_LUT cu_alu_src_a1 5 = 0x00002000

    // ── Port colour defines (v3.9), shared colours = connected ports ─────
    // define opcode                 input   97.242.68
    // define funct3                 input   80.43.153
    // define funct7                 input   199.90.199
    // define alu_control            output  255.204.0
    // define alu_src_a              output  46.178.112
    // define alu_src_b              output  0.71.178
    // define reg_write              output  178.112.68
    // define mem_read               output  178.0.71
    // define mem_write              output  230.0.255
    // define mem_to_reg             output  125.178.0
    // define branch                 output  255.128.0

    wire src_a0, src_a1;

    cu_reg_write  lut_rw  (.i(opcode[6:2]), .o(reg_write));
    cu_mem_read   lut_mr  (.i(opcode[6:2]), .o(mem_read));
    cu_mem_write  lut_mw  (.i(opcode[6:2]), .o(mem_write));
    cu_mem_to_reg lut_mtr (.i(opcode[6:2]), .o(mem_to_reg));
    cu_branch     lut_br  (.i(opcode[6:2]), .o(branch));
    cu_alu_src_b  lut_asb (.i(opcode[6:2]), .o(alu_src_b));
    cu_alu_src_a0 lut_a0  (.i(opcode[6:2]), .o(src_a0));
    cu_alu_src_a1 lut_a1  (.i(opcode[6:2]), .o(src_a1));

    assign alu_src_a = {src_a1, src_a0};

    // ══ alu_control, depends on opcode + funct3 + funct7[5] ══════════════
    // Default ADD (0010) covers LUI, AUIPC, Load, Store, Branch.
    // Only R-type and I-type override.
    //
    // alu_control encoding:
    //   0000=AND  0001=OR   0010=ADD  0011=XOR
    //   0100=SLL  0101=SRL  0110=SUB  0111=SLT(signed)
    //   1000=SLTU 1001=SRA  1010=MUL  1011=DIV  1100=BCD
    always @(*) begin
        alu_control = 4'b0010;
        case (opcode)
            7'b0110011: begin // R-type
                if (funct7 == 7'b0000001) begin
                    case (funct3)
                        3'b000: alu_control = 4'b1010; // MUL
                        3'b100: alu_control = 4'b1011; // DIV
                        3'b111: alu_control = 4'b1100; // BCD
                        default: alu_control = 4'b0010;
                    endcase
                end else begin
                    case (funct3)
                        3'b000: alu_control = funct7[5] ? 4'b0110 : 4'b0010;
                        3'b001: alu_control = 4'b0100;
                        3'b010: alu_control = 4'b0111;
                        3'b011: alu_control = 4'b1000;
                        3'b100: alu_control = 4'b0011;
                        3'b101: alu_control = funct7[5] ? 4'b1001 : 4'b0101;
                        3'b110: alu_control = 4'b0001;
                        3'b111: alu_control = 4'b0000;
                    endcase
                end
            end
            7'b0010011: begin // I-type math
                case (funct3)
                    3'b000: alu_control = 4'b0010;
                    3'b001: alu_control = 4'b0100;
                    3'b010: alu_control = 4'b0111;
                    3'b011: alu_control = 4'b1000;
                    3'b100: alu_control = 4'b0011;
                    3'b101: alu_control = funct7[5] ? 4'b1001 : 4'b0101;
                    3'b110: alu_control = 4'b0001;
                    3'b111: alu_control = 4'b0000;
                endcase
            end
        endcase
    end

endmodule


// ============================================================================
// >>> LEAF MODULE 4/6 : Branch_Unit        (source: branch_unit.v, verbatim)
// ============================================================================

// ============================================================================
// BRANCH UNIT ,  Standalone Synthesizable Module
// BABFT FULL RV32I+M  /  BIT16 GPU ARCHITECTURE
// (C) 2026 BITFries / Glad-Note2022
//
// Handles: branch condition evaluation, branch target address computation,
// and PC-next mux (branch target vs. PC+4).
// Contains two pipelined logic blocks, each with their own synchronizer port.
//
// ── PORT CONNECTIONS TO OTHER MODULES ────────────────────────────────────────
//   rs1         ← alu         : rs1_data[31:0]   (register file read port 1)
//   rs2         ← alu         : rs2_data[31:0]   (register file read port 2)
//   funct3      ← pc          : inst[14:12]       (branch type selector)
//   branch_en   ← control_unit: branch
//   pc_current  ← pc          : pc_current[31:0]
//   pc_plus4    ← pc          : pc_plus4[31:0]
//   imm_ext     ← imm_ext     : imm_ext[31:0]
//   pc_next     → pc          : pc_next[31:0]
//
// ── PIPELINE PORTS ────────────────────────────────────────────────────────────
//   ppln_bcmp  : synchronizer for the branch comparator block.
//                ANDs with all AND-gate inputs inside the compare logic.
//                Hold LOW to freeze the comparator, HIGH to let it propagate.
//   ppln_badd  : synchronizer for the branch target adder (PC + imm_ext).
//                ANDs with all AND-gate inputs inside the adder carry chain.
//                Hold LOW to freeze the adder (output stays 0), HIGH to run.
//
//
// ── BRANCH CONDITION ENCODING (funct3) ────────────────────────────────────────
//   3'b000 = BEQ   a == b
//   3'b001 = BNE   a != b
//   3'b100 = BLT   signed(a) <  signed(b)
//   3'b101 = BGE   signed(a) >= signed(b)
//   3'b110 = BLTU  a <  b  (unsigned)
//   3'b111 = BGEU  a >= b  (unsigned)
//
// ── SYNTHESIZER PORT DIRECTIVES (BITF-Synth Engine) ───────────────────────────
// =============================================================================

module Branch_Unit (
    // ── From ALU (register file outputs) ──────────────────────────────────────
    input  wire [31:0] rs1,         // Register rs1 value
    input  wire [31:0] rs2,         // Register rs2 value

    // ── From PC ───────────────────────────────────────────────────────────────
    input  wire [31:0] pc_current,  // Current PC (base for branch target)
    input  wire [31:0] pc_plus4,    // PC + 4    (not-taken path)

    // ── From Immediate Extender ───────────────────────────────────────────────
    input  wire [31:0] imm_ext,     // Sign-extended branch offset

    // ── From Control Unit ─────────────────────────────────────────────────────
    input  wire        branch_en,   // 1 = instruction is a branch type

    // ── From PC (instruction slice) ───────────────────────────────────────────
    input  wire [2:0]  funct3,      // inst[14:12], selects BEQ/BNE/BLT/etc.

    // ── Pipeline Synchronizers ────────────────────────────────────────────────
    // Each ppln signal gates the AND-gate inputs of its sub-block.
    // Low = freeze that path to 0, High = normal propagation.
    input  wire        ppln_bcmp,   // Branch comparator pipeline sync
    input  wire        ppln_badd,   // Branch target adder pipeline sync

    // ── To PC ─────────────────────────────────────────────────────────────────
    output wire [31:0] pc_next,     // Next PC to load into Program_Counter
    output wire        branch_taken // 1 = branch condition met (diagnostic output)
);


    // ── Port colour defines (v3.9), shared colours = connected ports ─────
    // define rs1                    input   97.255.239
    // define rs2                    input   107.0.178
    // define pc_current             input   255.0.26
    // define pc_plus4               input   0.204.255
    // define imm_ext                input   255.97.208
    // define branch_en              input   255.128.0
    // define funct3                 input   80.43.153
    // define ppln_bcmp              input   160.255.97
    // define ppln_badd              input   68.178.178
    // define pc_next                output  58.255.36
    // define branch_taken           output  178.167.68

    // ══ DUAL-SIDE GATE SIGNALS ══════════════════════════════════════════════════
    // gate_X = ppln_X AND branch_en
    //
    // branch_en is the front MUX select: if this isn't a branch instruction,
    // neither the comparator nor the adder should activate at all.
    // ppln_X is the pipeline synchronizer.
    // Both must be high before that compute path proceeds, same dual-side
    // gating pattern as the ALU.
    wire gate_bcmp = ppln_bcmp & branch_en;
    wire gate_badd = ppln_badd & branch_en;

    // ══ Pipeline Block 1: Branch Comparator ════════════════════════════════════
    // gate_bcmp = ppln_bcmp AND branch_en
    // When either is low: both operands zero → all comparisons false (no spurious branch).
    wire [31:0] cmp_a = rs1 & {32{gate_bcmp}};
    wire [31:0] cmp_b = rs2 & {32{gate_bcmp}};

    reg branch_cond;
    always @(*) begin
        case (funct3)
            3'b000: branch_cond = (cmp_a == cmp_b);                        // BEQ
            3'b001: branch_cond = (cmp_a != cmp_b);                        // BNE
            3'b100: branch_cond = ($signed(cmp_a) <  $signed(cmp_b));      // BLT
            3'b101: branch_cond = ($signed(cmp_a) >= $signed(cmp_b));      // BGE
            3'b110: branch_cond = (cmp_a <  cmp_b);                        // BLTU
            3'b111: branch_cond = (cmp_a >= cmp_b);                        // BGEU
            default: branch_cond = 1'b0;
        endcase
    end

    // Branch is actually taken only when the CU says it's a branch AND condition true
    assign branch_taken = branch_en & branch_cond;

    // ══ Pipeline Block 2: Branch Target Adder ══════════════════════════════════
    // gate_badd = ppln_badd AND branch_en
    // When either is low: both adder inputs zero → branch_target = 0 (won't be selected).
    wire [31:0] badd_pc  = pc_current & {32{gate_badd}};
    wire [31:0] badd_imm = imm_ext    & {32{gate_badd}};
    wire [31:0] branch_target = badd_pc + badd_imm;

    // ══ PC-Next Mux ════════════════════════════════════════════════════════════
    // Select branch target when taken, otherwise fall through to PC+4.
    assign pc_next = branch_taken ? branch_target : pc_plus4;

endmodule


// ============================================================================
// >>> LEAF MODULE 5/6 : ALU + math helpers (source: alu.v; ONE fix: removed a duplicate sel_* wire block that was declared twice and would not elaborate)
// ============================================================================

// ============================================================================
// ALU ,  Standalone Synthesizable Module
// BABFT FULL RV32I+M  /  BIT16 GPU ARCHITECTURE
// (C) 2026 BITFries / Glad-Note2022
//
// Contains (all inlined, no external file dependencies):
//   - Math helpers : LUT_Divider_4x4, BCD_Adder_Digit, BCD_Adder_32
//   - Math units   : Adder_Tree_Multiplier, Array_LUT_Divider_32, Bin_To_BCD_32
//   - Register File (32 × 32-bit, x0 hardwired 0, synchronous write)
//   - ALU operand muxes (alu_src_a / alu_src_b)
//   - 13-operation ALU with 7 independent pipeline synchronizers
//   - RAM interface (1024-bit / 32 × 32-bit words)
//   - MMIO / GPU command decode (address[31] == 1 → GPU write)
//   - Writeback mux (alu_result vs RAM read data)
//
// ── PORT CONNECTIONS TO OTHER MODULES ────────────────────────────────────────
//   clk         ← external clock (same as PC)
//   reset       ← external reset
//   inst        ← pc          : inst[31:0]    (rs1/rs2/rd address decode)
//   pc_current  ← pc          : pc_current    (AUIPC A-operand)
//   imm_ext     ← imm_ext     : imm_ext[31:0] (B-operand when alu_src_b=1)
//   alu_control ← control_unit: alu_control
//   alu_src_a   ← control_unit: alu_src_a
//   alu_src_b   ← control_unit: alu_src_b
//   reg_write   ← control_unit: reg_write
//   mem_read    ← control_unit: mem_read
//   mem_write   ← control_unit: mem_write
//   mem_to_reg  ← control_unit: mem_to_reg
//   rs1_data    → branch_unit : rs1[31:0]
//   rs2_data    → branch_unit : rs2[31:0]
//
// ── PIPELINE PORTS ────────────────────────────────────────────────────────────
// Each ppln_X signal is ANDed with the INPUT operands of that sub-block,
// gating every AND gate inside that logic path (carry chain, partial products,
// etc.).  LOW = freeze path to 0.  HIGH = normal propagation.
//
//
// ── RAM INTERFACE ─────────────────────────────────────────────────────────────
//   RAM : 1024 bits  =  32 words × 32-bit
//         Address width : 5 bits [4:0]   (word index = alu_result[6:2])
//         Data width    : 32 bits [31:0]
//   MMIO: address[31] == 1 → GPU register space (not RAM)
//         MMIO is write-only; no extra MMIO RAM required.
//         GPU command is decoded from rs2 at Store time (see port list below).
//
// ── SYNTHESIZER PORT DIRECTIVES (BITF-Synth Engine) ───────────────────────────
// =============================================================================


// ============================================================================
// INLINED MATH HELPER: LUT_Divider_4x4
// Single stage of the 8-stage radix LUT divider.
// ============================================================================
module LUT_Divider_4x4 (
    input  wire [3:0] rem_in,       // Remainder from previous stage
    input  wire [3:0] div_nibble,   // 4-bit slice of dividend (MSB-first)
    input  wire [3:0] divisor,      // Divisor[3:0]
    output wire [3:0] rem_out,      // Remainder to next stage
    output wire [3:0] quo_out       // Partial quotient nibble
);
    reg [7:0] lut_data;
    always @(*) begin
        case ({rem_in, div_nibble, divisor})
            // Truth table entries go here (fill with your division lookup table)
            default: lut_data = 8'd0;
        endcase
    end
    assign rem_out = lut_data[7:4];
    assign quo_out = lut_data[3:0];
endmodule


// ============================================================================
// INLINED MATH HELPER: BCD_Adder_Digit
// 1-digit BCD adder with carry-lookahead correction (+6 when sum > 9).
// ============================================================================
module BCD_Adder_Digit (
    input  wire [3:0] a, b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire [4:0] bin_sum  = a + b + cin;
    wire       over_nine = (bin_sum > 5'd9);
    assign cout = over_nine;
    assign sum  = over_nine ? (bin_sum[3:0] + 4'd6) : bin_sum[3:0];
endmodule


// ============================================================================
// INLINED MATH HELPER: BCD_Adder_32
// 8-digit (32-bit) BCD adder array via generate.
// ============================================================================
module BCD_Adder_32 (
    input  wire [31:0] a, b,
    output wire [31:0] sum
);
    wire [8:0] c;
    assign c[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bcd_dig
            BCD_Adder_Digit digit (
                .a(a[i*4 +: 4]), .b(b[i*4 +: 4]),
                .cin(c[i]), .sum(sum[i*4 +: 4]), .cout(c[i+1])
            );
        end
    endgenerate
endmodule


// ============================================================================
// INLINED MATH UNIT: Adder_Tree_Multiplier
// 32×32 Wallace-style tree: 32 partial products reduced in 5 levels.
// Inputs are pre-gated by ppln_mul before reaching this module.
// ============================================================================
module Adder_Tree_Multiplier (
    input  wire [31:0] a, b,
    output wire [31:0] result
);
    wire [31:0] pp [0:31];
    genvar i;
    generate for (i = 0; i < 32; i = i + 1) begin : gen_pp
        assign pp[i] = b[i] ? (a << i) : 32'd0;
    end endgenerate

    wire [31:0] L1 [0:15];
    generate for (i = 0; i < 16; i = i + 1) begin : lv1
        assign L1[i] = pp[i*2] + pp[i*2+1];
    end endgenerate

    wire [31:0] L2 [0:7];
    generate for (i = 0; i < 8; i = i + 1) begin : lv2
        assign L2[i] = L1[i*2] + L1[i*2+1];
    end endgenerate

    wire [31:0] L3 [0:3];
    generate for (i = 0; i < 4; i = i + 1) begin : lv3
        assign L3[i] = L2[i*2] + L2[i*2+1];
    end endgenerate

    wire [31:0] L4a = L3[0] + L3[1];
    wire [31:0] L4b = L3[2] + L3[3];
    assign result = L4a + L4b;
endmodule


// ============================================================================
// INLINED MATH UNIT: Array_LUT_Divider_32
// 8-stage radix LUT divider. Inputs pre-gated by ppln_div before this module.
// ============================================================================
module Array_LUT_Divider_32 (
    input  wire [31:0] dividend, divisor,
    output wire [31:0] quotient
);
    wire [3:0] rem_chain [0:8];
    wire [31:0] quo_chain;
    assign rem_chain[0] = 4'd0;
    genvar stage;
    generate
        for (stage = 0; stage < 8; stage = stage + 1) begin : DIV_STAGES
            LUT_Divider_4x4 lut_block (
                .rem_in    (rem_chain[stage]),
                .div_nibble(dividend[31 - (stage*4) -: 4]),
                .divisor   (divisor[3:0]),
                .rem_out   (rem_chain[stage+1]),
                .quo_out   (quo_chain[31 - (stage*4) -: 4])
            );
        end
    endgenerate
    assign quotient = quo_chain;
endmodule


// ============================================================================
// INLINED MATH UNIT: Bin_To_BCD_32
// Binary → packed BCD tree (5-level BCD adder tree, 32 weight entries).
// Input is pre-gated by ppln_bcd before reaching this module.
// ============================================================================
module Bin_To_BCD_32 (
    input  wire [31:0] bin,
    output wire [31:0] bcd
);
    wire [31:0] bcd_weights [0:31];
    assign bcd_weights[0]  = bin[0]  ? 32'h00000001 : 32'd0;
    assign bcd_weights[1]  = bin[1]  ? 32'h00000002 : 32'd0;
    assign bcd_weights[2]  = bin[2]  ? 32'h00000004 : 32'd0;
    assign bcd_weights[3]  = bin[3]  ? 32'h00000008 : 32'd0;
    assign bcd_weights[4]  = bin[4]  ? 32'h00000016 : 32'd0;
    assign bcd_weights[5]  = bin[5]  ? 32'h00000032 : 32'd0;
    assign bcd_weights[6]  = bin[6]  ? 32'h00000064 : 32'd0;
    assign bcd_weights[7]  = bin[7]  ? 32'h00000128 : 32'd0;
    assign bcd_weights[8]  = bin[8]  ? 32'h00000256 : 32'd0;
    assign bcd_weights[9]  = bin[9]  ? 32'h00000512 : 32'd0;
    assign bcd_weights[10] = bin[10] ? 32'h00001024 : 32'd0;
    assign bcd_weights[11] = bin[11] ? 32'h00002048 : 32'd0;
    assign bcd_weights[12] = bin[12] ? 32'h00004096 : 32'd0;
    assign bcd_weights[13] = bin[13] ? 32'h00008192 : 32'd0;
    assign bcd_weights[14] = bin[14] ? 32'h00016384 : 32'd0;
    assign bcd_weights[15] = bin[15] ? 32'h00032768 : 32'd0;
    assign bcd_weights[16] = bin[16] ? 32'h00065536 : 32'd0;
    assign bcd_weights[17] = bin[17] ? 32'h00131072 : 32'd0;
    assign bcd_weights[18] = bin[18] ? 32'h00262144 : 32'd0;
    assign bcd_weights[19] = bin[19] ? 32'h00524288 : 32'd0;
    assign bcd_weights[20] = bin[20] ? 32'h01048576 : 32'd0;
    assign bcd_weights[21] = bin[21] ? 32'h02097152 : 32'd0;
    assign bcd_weights[22] = bin[22] ? 32'h04194304 : 32'd0;
    assign bcd_weights[23] = bin[23] ? 32'h08388608 : 32'd0;
    assign bcd_weights[24] = bin[24] ? 32'h16777216 : 32'd0;
    assign bcd_weights[25] = bin[25] ? 32'h33554432 : 32'd0;
    assign bcd_weights[26] = bin[26] ? 32'h67108864 : 32'd0;
    // Bits 27-31: truncated to 8-digit BCD limit
    assign bcd_weights[27] = bin[27] ? 32'h34217728 : 32'd0;
    assign bcd_weights[28] = bin[28] ? 32'h68435456 : 32'd0;
    assign bcd_weights[29] = bin[29] ? 32'h36870912 : 32'd0;
    assign bcd_weights[30] = bin[30] ? 32'h73741824 : 32'd0;
    assign bcd_weights[31] = bin[31] ? 32'h47483648 : 32'd0;

    wire [31:0] bL1 [0:15];
    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin : bL1g
        BCD_Adder_32 a1 (.a(bcd_weights[i*2]), .b(bcd_weights[i*2+1]), .sum(bL1[i]));
    end endgenerate

    wire [31:0] bL2 [0:7];
    generate for (i = 0; i < 8; i = i + 1) begin : bL2g
        BCD_Adder_32 a2 (.a(bL1[i*2]), .b(bL1[i*2+1]), .sum(bL2[i]));
    end endgenerate

    wire [31:0] bL3 [0:3];
    generate for (i = 0; i < 4; i = i + 1) begin : bL3g
        BCD_Adder_32 a3 (.a(bL2[i*2]), .b(bL2[i*2+1]), .sum(bL3[i]));
    end endgenerate

    wire [31:0] bL4 [0:1];
    generate for (i = 0; i < 2; i = i + 1) begin : bL4g
        BCD_Adder_32 a4 (.a(bL3[i*2]), .b(bL3[i*2+1]), .sum(bL4[i]));
    end endgenerate

    BCD_Adder_32 afinal (.a(bL4[0]), .b(bL4[1]), .sum(bcd));
endmodule


// BITF_DECODER alu_op_dec 4 13
// 4-bit alu_control → 13 one-hot output lines (codes 0–12).
// y[0]=AND y[1]=OR y[2]=ADD y[3]=XOR y[4]=SLL y[5]=SRL
// y[6]=SUB y[7]=SLT y[8]=SLTU y[9]=SRA y[10]=MUL y[11]=DIV y[12]=BCD

// ============================================================================
// ALU ,  Top Module
// ============================================================================
module ALU (
    // ── Clock & Reset ─────────────────────────────────────────────────────────
    input  wire        clk,
    input  wire        reset,

    // ── From PC ───────────────────────────────────────────────────────────────
    input  wire [31:0] inst,        // Full instruction (for rs1/rs2/rd decode)
    input  wire [31:0] pc_current,  // Current PC (AUIPC A-operand)

    // ── From Immediate Extender ───────────────────────────────────────────────
    input  wire [31:0] imm_ext,     // Sign-extended immediate (B-operand when alu_src_b=1)

    // ── From Control Unit ─────────────────────────────────────────────────────
    input  wire [3:0]  alu_control, // Operation select
    input  wire [1:0]  alu_src_a,   // A-operand mux: 00=rs1, 01=PC, 10=Zero
    input  wire        alu_src_b,   // B-operand mux: 0=rs2, 1=imm_ext
    input  wire        reg_write,   // Register file write enable
    input  wire        mem_read,    // RAM read enable
    input  wire        mem_write,   // RAM write enable
    input  wire        mem_to_reg,  // Writeback mux: 1=RAM rdata, 0=ALU result

    // ── Pipeline Synchronizers ────────────────────────────────────────────────
    // Each port ANDs with the INPUT operands of its sub-block.
    // This gates every AND-gate connection (carry chain, partial products, etc.)
    // inside that path. Low = freeze to 0. High = normal operation.
    input  wire        ppln_add,    // Adder / subtractor path (ADD SUB ADDI LUI AUIPC LW SW)
    input  wire        ppln_logic,  // Bitwise logic path      (AND OR XOR + I-type)
    input  wire        ppln_shift,  // Barrel shifter path     (SLL SRL SRA + I-type)
    input  wire        ppln_cmp,    // Comparator path         (SLT SLTU + I-type)
    input  wire        ppln_mul,    // Tree multiplier path    (MUL)
    input  wire        ppln_div,    // LUT divider path        (DIV)
    input  wire        ppln_bcd,    // BCD converter path      (BCD)

    // ── RAM Interface (1024-bit / 32 × 32-bit, 5-bit address) ────────────────
    output wire        ram_cs,      // Chip Select (high on non-MMIO load or store)
    output wire        ram_we,      // Write Enable
    output wire [4:0]  ram_addr,    // Word address = alu_result[6:2]
    output wire [31:0] ram_wdata,   // Write data   = rs2
    input  wire [31:0] ram_rdata,   // Read data from RAM

    // ── MMIO / GPU Interface (address[31]==1 on Store → GPU write) ────────────
    // MMIO is write-only, no MMIO RAM required.
    // GPU command is decoded from rs2 at Store time:
    //   rs2[15]    = gpu_cmd_override
    //   rs2[14]    = gpu_cmd_fill
    //   rs2[13]    = gpu_cmd_enable
    //   rs2[12:8]  = gpu_cmd_x     (5-bit X coord)
    //   rs2[7:4]   = gpu_cmd_y     (4-bit Y coord)
    //   rs2[3:0]   = gpu_cmd_color (4-bit color)
    output wire        gpu_write_trigger,
    output wire        gpu_cmd_override,
    output wire        gpu_cmd_fill,
    output wire        gpu_cmd_enable,
    output wire [4:0]  gpu_cmd_x,
    output wire [3:0]  gpu_cmd_y,
    output wire [3:0]  gpu_cmd_color,

    // ── To Branch Unit ────────────────────────────────────────────────────────
    output wire [31:0] rs1_data,    // Register file read port 1 (→ branch_unit rs1)
    output wire [31:0] rs2_data,    // Register file read port 2 (→ branch_unit rs2)

    // ── Diagnostic Output ─────────────────────────────────────────────────────
    output wire [31:0] alu_result   // Final ALU output (before writeback mux)
);


    // ══════════════════════════════════════════════════════════════════════════
    // ── Port colour defines (v3.9), shared colours = connected ports ─────
    // define clk                    input   97.160.255
    // define reset                  input   36.255.145
    // define inst                   input   0.0.255
    // define pc_current             input   255.0.26
    // define imm_ext                input   255.97.208
    // define alu_control            input   255.204.0
    // define alu_src_a              input   46.178.112
    // define alu_src_b              input   0.71.178
    // define reg_write              input   178.112.68
    // define mem_read               input   178.0.71
    // define mem_write              input   230.0.255
    // define mem_to_reg             input   125.178.0
    // define ppln_add               input   90.126.199
    // define ppln_logic             input   255.97.97
    // define ppln_shift             input   0.76.255
    // define ppln_cmp               input   156.68.178
    // define ppln_mul               input   211.235.0
    // define ppln_div               input   0.125.178
    // define ppln_bcd               input   242.153.109
    // define ram_rdata              input   0.178.54
    // define rs1_data               output  97.255.239
    // define rs2_data               output  107.0.178
    // define alu_result             output  178.54.0
    // define ram_cs                 output  242.109.153
    // define ram_we                 output  103.56.199
    // define ram_addr               output  153.107.15
    // define ram_wdata              output  20.199.199
    // define gpu_write_trigger      output  242.24.206
    // define gpu_cmd_override       output  213.68.242
    // define gpu_cmd_fill           output  97.24.242
    // define gpu_cmd_enable         output  242.242.68
    // define gpu_cmd_x              output  169.199.20
    // define gpu_cmd_y              output  90.199.126
    // define gpu_cmd_color          output  178.68.134

    // REGISTER FILE  (32 × 32-bit, x0 hardwired to 0, synchronous write)
    // ══════════════════════════════════════════════════════════════════════════
    // Register address fields extracted from instruction word
    wire [4:0] rs1_addr = inst[19:15];
    wire [4:0] rs2_addr = inst[24:20];
    wire [4:0] rd_addr  = inst[11:7];

    reg [31:0] registers [31:1];  // x1–x31; x0 is not stored

    // Asynchronous reads, x0 always returns 0
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : registers[rs2_addr];

    // Writeback mux, select between RAM read data and ALU result
    wire [31:0] mem_read_data  = ram_rdata;
    wire [31:0] write_data_back = mem_to_reg ? mem_read_data : alu_result;

    // Synchronous write, never write to x0
    // BITF memfix (v4.12.1 companion): this write used to sit in an
    // `always @(posedge clk or posedge reset)` block.  An async-reset
    // edge in the sensitivity list of a block that writes a memory
    // makes Yosys replace the whole array with individual registers
    // ("Replacing memory \registers with list of registers").  The
    // reset branch never touched the array, so folding `!reset` into
    // the write enable of a plain sync block is behaviour-preserving.
    always @(posedge clk) begin
        if (!reset && reg_write && rd_addr != 5'd0) begin
            registers[rd_addr] <= write_data_back;
        end
    end

    // ══════════════════════════════════════════════════════════════════════════
    // ALU OPERAND MUXES
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] alu_a = (alu_src_a == 2'b01) ? pc_current :
                        (alu_src_a == 2'b10) ? 32'd0      : rs1_data;
    wire [31:0] alu_b = alu_src_b ? imm_ext : rs2_data;

    // ══════════════════════════════════════════════════════════════════════════
    // OPERATION SELECT DECODE  (front MUX), BITF_DECODER
    //
    // A single 4-to-13 decoder maps alu_control to 13 one-hot lines.
    // OR-reduction groups them into per-path select signals.
    // Gate cost: ~4×13=52 (decoder) + 7 OR gates ≈ 65 total.
    // ══════════════════════════════════════════════════════════════════════════
    wire [12:0] op_dec_y;
    alu_op_dec op_decoder (.addr(alu_control), .y(op_dec_y));

    // OR-reduction: group one-hot lines into operation-select signals
    wire sel_add   = op_dec_y[2]  | op_dec_y[6];                // ADD, SUB
    wire sel_logic = op_dec_y[0]  | op_dec_y[1] | op_dec_y[3];  // AND, OR, XOR
    wire sel_shift = op_dec_y[4]  | op_dec_y[5] | op_dec_y[9];  // SLL, SRL, SRA
    wire sel_cmp   = op_dec_y[7]  | op_dec_y[8];                // SLT, SLTU
    wire sel_mul   = op_dec_y[10];                               // MUL
    wire sel_div   = op_dec_y[11];                               // DIV
    wire sel_bcd   = op_dec_y[12];                               // BCD


    // ══════════════════════════════════════════════════════════════════════════
    // DUAL-SIDE GATE SIGNALS
    // gate_X = ppln_X AND sel_X
    //
    // Both conditions must be true before a compute path activates:
    //   1. ppln_X , pipeline synchronizer allows propagation
    //   2. sel_X  , alu_control has selected this operation (front MUX)
    //
    // This single AND gate per path connects to all AND-gate inputs of that
    // sub-block. Unselected paths stay at zero, no wasted computation.
    // The back MUX (case statement below) then selects the correct result.
    // ══════════════════════════════════════════════════════════════════════════
    wire gate_add   = ppln_add   & sel_add;
    wire gate_logic = ppln_logic & sel_logic;
    wire gate_shift = ppln_shift & sel_shift;
    wire gate_cmp   = ppln_cmp   & sel_cmp;
    wire gate_mul   = ppln_mul   & sel_mul;
    wire gate_div   = ppln_div   & sel_div;
    wire gate_bcd   = ppln_bcd   & sel_bcd;

    // ══════════════════════════════════════════════════════════════════════════
    // PIPELINE BLOCK 1: ADDER / SUBTRACTOR
    // gate_add = ppln_add AND (alu_control is ADD or SUB)
    // Zeros the carry chain when any other operation is selected.
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] add_a   = alu_a & {32{gate_add}};
    wire [31:0] add_b   = alu_b & {32{gate_add}};
    wire [31:0] add_out = add_a + add_b;
    wire [31:0] sub_out = add_a - add_b;

    // ══════════════════════════════════════════════════════════════════════════
    // PIPELINE BLOCK 2: BITWISE LOGIC
    // gate_logic = ppln_logic AND (alu_control is AND, OR, or XOR)
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] log_a    = alu_a & {32{gate_logic}};
    wire [31:0] log_b    = alu_b & {32{gate_logic}};
    wire [31:0] and_out  = log_a & log_b;
    wire [31:0] or_out   = log_a | log_b;
    wire [31:0] xor_out  = log_a ^ log_b;

    // ══════════════════════════════════════════════════════════════════════════
    // PIPELINE BLOCK 3: BARREL SHIFTER
    // gate_shift = ppln_shift AND (alu_control is SLL, SRL, or SRA)
    // Zeroing the shift amount collapses the entire barrel mux to output 0.
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] shf_a   = alu_a      & {32{gate_shift}};
    wire [4:0]  shf_b   = alu_b[4:0] & {5{gate_shift}};
    wire [31:0] sll_out = shf_a << shf_b;
    wire [31:0] srl_out = shf_a >> shf_b;
    wire [31:0] sra_out = $signed(shf_a) >>> shf_b;

    // ══════════════════════════════════════════════════════════════════════════
    // PIPELINE BLOCK 4: COMPARATOR
    // gate_cmp = ppln_cmp AND (alu_control is SLT or SLTU)
    // Zeroed operands → 0 < 0 = false safely when not selected.
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] cmp_a    = alu_a & {32{gate_cmp}};
    wire [31:0] cmp_b    = alu_b & {32{gate_cmp}};
    wire [31:0] slt_out  = ($signed(cmp_a) < $signed(cmp_b)) ? 32'd1 : 32'd0;
    wire [31:0] sltu_out = (cmp_a < cmp_b)                   ? 32'd1 : 32'd0;

    // ══════════════════════════════════════════════════════════════════════════
    // PIPELINE BLOCK 5: TREE MULTIPLIER  (MUL only)
    // gate_mul = ppln_mul AND (alu_control == MUL)
    // All 32 partial products and 5 adder-tree levels see gated inputs.
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] mul_a = alu_a & {32{gate_mul}};
    wire [31:0] mul_b = alu_b & {32{gate_mul}};
    wire [31:0] result_mul;
    Adder_Tree_Multiplier mul_unit (.a(mul_a), .b(mul_b), .result(result_mul));

    // ══════════════════════════════════════════════════════════════════════════
    // PIPELINE BLOCK 6: LUT DIVIDER  (DIV only)
    // gate_div = ppln_div AND (alu_control == DIV)
    // All 8 LUT_Divider_4x4 stages see gated dividend and divisor.
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] div_a = alu_a & {32{gate_div}};
    wire [31:0] div_b = alu_b & {32{gate_div}};
    wire [31:0] result_div;
    Array_LUT_Divider_32 div_unit (.dividend(div_a), .divisor(div_b), .quotient(result_div));

    // ══════════════════════════════════════════════════════════════════════════
    // PIPELINE BLOCK 7: BCD CONVERTER  (BCD only)
    // gate_bcd = ppln_bcd AND (alu_control == BCD)
    // All 32 weight selectors and the 5-level BCD adder tree see gated input.
    // ══════════════════════════════════════════════════════════════════════════
    wire [31:0] bcd_in = alu_a & {32{gate_bcd}};
    wire [31:0] result_bcd;
    Bin_To_BCD_32 bcd_unit (.bin(bcd_in), .bcd(result_bcd));

    // ══════════════════════════════════════════════════════════════════════════
    // OPERATION SELECT MUX  (13 operations)
    // ══════════════════════════════════════════════════════════════════════════
    reg [31:0] result_reg;
    always @(*) begin
        case (alu_control)
            4'b0000: result_reg = and_out;    // AND  / ANDI
            4'b0001: result_reg = or_out;     // OR   / ORI
            4'b0010: result_reg = add_out;    // ADD  / ADDI / LUI / AUIPC / LW addr / SW addr
            4'b0011: result_reg = xor_out;    // XOR  / XORI
            4'b0100: result_reg = sll_out;    // SLL  / SLLI
            4'b0101: result_reg = srl_out;    // SRL  / SRLI
            4'b0110: result_reg = sub_out;    // SUB
            4'b0111: result_reg = slt_out;    // SLT  / SLTI  (signed)
            4'b1000: result_reg = sltu_out;   // SLTU / SLTIU (unsigned)
            4'b1001: result_reg = sra_out;    // SRA  / SRAI
            4'b1010: result_reg = result_mul; // MUL
            4'b1011: result_reg = result_div; // DIV
            4'b1100: result_reg = result_bcd; // BCD
            default: result_reg = 32'd0;
        endcase
    end
    assign alu_result = result_reg;

    // ══════════════════════════════════════════════════════════════════════════
    // RAM INTERFACE  (1024-bit / 32 × 32-bit words, 5-bit word address)
    // ══════════════════════════════════════════════════════════════════════════
    wire is_mmio = alu_result[31];          // Address MSB = 1 → MMIO, not RAM

    assign ram_cs    = (mem_read | mem_write) & ~is_mmio;
    assign ram_we    = mem_write & ~is_mmio;
    assign ram_addr  = alu_result[6:2];     // Drop byte bits [1:0]; take 5 word-address bits
    assign ram_wdata = rs2_data;            // Store data is always rs2

    // ══════════════════════════════════════════════════════════════════════════
    // LEGACY MMIO / GPU DECODE
    // ══════════════════════════════════════════════════════════════════════════
    // Kept for backwards compatibility with older direct-ALU GPU wiring.
    // New builds should prefer Memory_And_MMIO for decoded RAM/GPU/GPIO MMIO.
    // IMPORTANT: only word offset 0 is a GPU command. GPIO offsets must not
    // accidentally pulse the GPU trigger.
    // Command packed into rs2[15:0]:
    //   [15]   override  [14]  fill  [13]  enable
    //   [12:8] x (5-bit) [7:4] y (4-bit) [3:0] color (4-bit)
    wire is_gpu_mmio = is_mmio & (alu_result[7:2] == 6'd0);

    assign gpu_write_trigger = mem_write & is_gpu_mmio;
    assign gpu_cmd_override  = rs2_data[15];
    assign gpu_cmd_fill      = rs2_data[14];
    assign gpu_cmd_enable    = rs2_data[13];
    assign gpu_cmd_x         = rs2_data[12:8];
    assign gpu_cmd_y         = rs2_data[7:4];
    assign gpu_cmd_color     = rs2_data[3:0];

endmodule

// ===== MEMORY / MMIO / GPIO (GPU-bus revision) =========================
// ============================================================================
// MEMORY + MMIO + GPIO ,  Standalone Synthesizable Module  (GPU-bus revision)
// BABFT FULL RV32I+M  /  BITFries-RV32IM
// (C) 2026 BITFries / Glad-Note2022
//
//   • 8 × 32-bit data RAM for normal loads/stores (address[4:2])
//   • Generic GPU register-slave bus (replaces the old fixed gpu_cmd_* pins)
//   • 32 Arduino-style GPIO input bits and 32 GPIO output bits
//
// MMIO map while address[31] == 1  (word = address[7:2]):
//   word 0 .. 15  : GPU registers, forwarded on gpu_we/gpu_addr/gpu_wdata;
//                   reads return gpu_rdata.  (gpu_addr = word[3:0])
//                   See the GPU module header for the register map.
//   word 16 (0x40): GPIO output register  gpio_out[31:0]
//   word 17 (0x44): GPIO direction        gpio_dir[31:0]   (1=output)
//   word 18 (0x48): GPIO input readback    gpio_in[31:0]
// ============================================================================

module Memory_And_MMIO (
    input  wire        clk,
    input  wire        reset,

    // ── From Control / ALU ───────────────────────────────────────────────────
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [31:0] address,
    input  wire [31:0] write_data,

    // ── Simple Arduino-style GPIO inputs ─────────────────────────────────────
    input  wire [31:0] gpio_in,

    // ── To ALU writeback path ────────────────────────────────────────────────
    output reg  [31:0] read_data,

    // ── Generic GPU register-slave bus ───────────────────────────────────────
    output wire        gpu_we,        // 1-cycle write strobe to a GPU register
    output wire [3:0]  gpu_addr,      // GPU register index (0..15)
    output wire [31:0] gpu_wdata,     // data written to the GPU register
    input  wire [31:0] gpu_rdata,     // GPU status readback

    // ── Simple Arduino-style GPIO outputs ────────────────────────────────────
    output reg  [31:0] gpio_out,
    output reg  [31:0] gpio_dir,
    output wire        gpio_write_trigger
);

    // ── Port colour defines (BITF-Synth Engine), shared colours = connected ports ─
    // define clk                    input   97.160.255
    // define reset                  input   36.255.145
    // define mem_read               input   178.0.71
    // define mem_write              input   230.0.255
    // define address                input   178.54.0
    // define write_data             input   107.0.178
    // define gpio_in                input   255.25.140
    // define read_data              output  0.178.54
    // define gpu_we                 output  97.153.69
    // define gpu_addr               output  255.190.70
    // define gpu_wdata              output  68.68.242
    // define gpu_rdata              input   120.200.255
    // define gpio_out               output  191.0.191
    // define gpio_dir               output  153.51.255
    // define gpio_write_trigger     output  25.255.198

    // Small data RAM: 8 words × 32 bits.
    reg [31:0] data_ram [0:7];

    wire        is_mmio   = address[31];
    wire [2:0]  ram_addr  = address[4:2];
    wire [5:0]  mmio_word = address[7:2];

    wire hit_gpu      = is_mmio && (mmio_word <= 6'd15);
    wire hit_gpio_out = is_mmio && (mmio_word == 6'd16);
    wire hit_gpio_dir = is_mmio && (mmio_word == 6'd17);
    wire hit_gpio_in  = is_mmio && (mmio_word == 6'd18);

    // GPU slave bus (the GPU latches writes on its own clock edge)
    assign gpu_we    = mem_write & hit_gpu;
    assign gpu_addr  = mmio_word[3:0];
    assign gpu_wdata = write_data;

    assign gpio_write_trigger = mem_write & (hit_gpio_out | hit_gpio_dir);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            gpio_out <= 32'd0;
            gpio_dir <= 32'd0;
        end else begin
            if (mem_write && hit_gpio_out)  gpio_out <= write_data;
            if (mem_write && hit_gpio_dir)  gpio_dir <= write_data;
        end
    end

    // BITF memfix (v4.12.1 companion): the data_ram write moved out of
    // the async-reset block above so Yosys can keep \data_ram as ONE
    // real memory ($mem) instead of exploding it into registers.  The
    // `!reset` guard reproduces the original behaviour exactly (the
    // old block never wrote the RAM while its reset branch was taken).
    always @(posedge clk) begin
        if (!reset && mem_write && !is_mmio) begin
            data_ram[ram_addr] <= write_data;
        end
    end

    always @(*) begin
        read_data = 32'd0;
        if (mem_read) begin
            if (!is_mmio) begin
                read_data = data_ram[ram_addr];
            end else if (hit_gpu) begin
                read_data = gpu_rdata;
            end else begin
                case (mmio_word)
                    6'd16: read_data = gpio_out;
                    6'd17: read_data = gpio_dir;
                    6'd18: read_data = gpio_in;
                    default: read_data = 32'd0;
                endcase
            end
        end
    end

endmodule

// ===== GPU (immediate-mode; config + process gating) ===================
// ============================================================================
//  GPU ,  IMMEDIATE-MODE RASTER / 2D-3D GRAPHICS PROCESSOR
//  BABFT FULL RV32I+M  /  BITFries-RV32IM  display subsystem
//  (C) 2026 BITFries / Glad-Note2022
//
//  No frame buffer. The GPU keeps only a small bounded SCENE STORE (a handful
//  of primitives, each a short vertex list + flags + colour) and a single
//  monochrome row register. Every pixel / row is RECOMPUTED on the fly from the
//  scene and streamed to the screen ("racing the beam"), so the cost is logic,
//  not RAM.
//
//  ---------------------------------------------------------------------------
//  CPU INTERFACE (memory-mapped slave, driven by Memory_And_MMIO):
//     gpu_we / gpu_addr[3:0] / gpu_wdata[31:0]  -> register writes
//     gpu_rdata[31:0]                           -> status read
//
//  REGISTER MAP (gpu_addr):
//   0  CONFIG     {  -, proj, ctype[1:0], h_field[7:0], w_field[7:0] }
//                 actual_w = w_field+1 (1..256), actual_h = h_field+1 (1..256)
//                 ctype: 00 mono | 01 MUX(4b idx) | 10 RGB12(4b/ch) | 11 RGB24(8b/ch)
//                 proj : 0 ortho | 1 isometric (locked 2:1)        [used for 3D]
//   1  CONTROL    { continuous, wait_for_screen, scene_clear*, commit*,
//                   fill, enable }            (* = self-clearing strobe)
//   2  ROT        { -, az[7:0], ay[7:0], ax[7:0] }   3D rotation, 0..255 = 0..360
//   3  FILLCOLOR  { rgb24 / low4 = mux idx }   colour used by the FILL command
//   4  SEL        { vert_ptr[3:0], slot[3:0] }  selects target slot + vertex ptr
//   5  PRIMHDR    { vcount[3:0], en, fill, is3d, type[1:0] }  -> slot=SEL.slot
//                 type: 00 point | 01 line | 10 polygon (tri/quad/convex n-gon)
//                 fill: polygon only (1 filled, 0 outline/wireframe)
//   6  PRIMCOL    { rgb24 / low4 = mux idx }   colour of slot=SEL.slot
//   7  VERT       { -, z[9:0], y[9:0], x[9:0] } signed; writes vertex at
//                 (SEL.slot, SEL.vert_ptr); vert_ptr auto-increments.
//                 2D prims: x,y are screen coords. 3D prims: x,y,z model space
//                 (centred on 0), rotated then projected and centred on screen.
//   8  read -> STATUS { ..., frame_done, busy }
//
//  Typical CPU flow: write CONFIG; for each shape -> SEL(slot,0), PRIMHDR,
//  PRIMCOL, VERT x N; then CONTROL.commit=1. For animation, update ROT and
//  re-commit each frame (or set CONTROL.continuous=1 to auto re-render).
//
//  ---------------------------------------------------------------------------
//  SCREEN INTERFACE (outputs):
//   scr_w/scr_h/scr_ctype : geometry + colour mode echoed to the display
//   enable                : display only draws while high
//   fill                  : flood the whole screen with FILLCOLOR
//   MONOCHROME (ctype=00, up to 256x256, row-parallel):
//     mono_valid, mono_y[7:0]  + row bitmap on FOUR 64-bit slices
//     mono_s0..mono_s3  (s0 = pixels 0..63 ... s3 = 192..255; low bits used
//     first for narrow screens). One row presented per handshake.
//   COLOUR (ctype=01/10/11, up to 32x32, pixel-serial):
//     px_valid, px_x[4:0], px_y[4:0], px_mux[3:0] (MUX), px_rgb[23:0] (RGB).
//     One pixel presented per handshake (RGB12 nibble-expanded into px_rgb).
//   HANDSHAKE: screen_ready advances the scan when CONTROL.wait_for_screen=1;
//     otherwise the GPU free-runs (one step/clock) and you slow the clock.
//     frame_start / frame_done pulse at the scan boundaries.
// ============================================================================

module GPU (
    input              clk,
    input              reset,

    // ---- CPU memory-mapped slave ----
    input              gpu_we,
    input      [3:0]   gpu_addr,
    input      [31:0]  gpu_wdata,
    output reg [31:0]  gpu_rdata,

    // ---- screen handshake / control ----
    input              screen_ready,
    output reg         frame_start,
    output reg         frame_done,

    // ---- screen geometry / mode ----
    output     [7:0]   scr_w,
    output     [7:0]   scr_h,
    output     [1:0]   scr_ctype,
    output             enable,
    output             fill,

    // ---- monochrome row path ----
    output reg         mono_valid,
    output reg [7:0]   mono_y,
    output reg [63:0]  mono_s0,
    output reg [63:0]  mono_s1,
    output reg [63:0]  mono_s2,
    output reg [63:0]  mono_s3,

    // ---- colour pixel path ----
    output reg         px_valid,
    output reg [4:0]   px_x,
    output reg [4:0]   px_y,
    output reg [3:0]   px_mux,
    output reg [23:0]  px_rgb
);

    // ---- top-level port colours (BITF-Synth Engine; harmless when GPU is a submodule)
    // define clk          input  97.160.255
    // define reset        input  36.255.145
    // define gpu_we       input  97.153.69
    // define gpu_addr     input  255.190.70
    // define gpu_wdata    input  68.68.242
    // define gpu_rdata    output 120.200.255
    // define screen_ready input  153.43.43
    // define frame_start  output 133.242.24
    // define frame_done   output 120.255.180
    // define scr_w        output 61.153.15
    // define scr_h        output 176.109.242
    // define scr_ctype    output 20.20.199
    // define enable       output 90.255.120
    // define fill         output 255.140.60
    // define mono_valid   output 24.133.242
    // define mono_y       output 109.109.242
    // define mono_s0      output 255.255.255
    // define mono_s1      output 56.199.56
    // define mono_s2      output 199.139.20
    // define mono_s3      output 199.56.80
    // define px_valid     output 68.213.242
    // define px_x         output 24.242.97
    // define px_y         output 153.15.130
    // define px_mux       output 255.210.120
    // define px_rgb       output 255.60.60

    // ---------------- parameters (adjustable; cost scales with these) -------
    localparam MAX_PRIM = 4;     // primitive slots (painter priority: high idx on top)
    localparam MAX_VERT = 8;     // max vertices per primitive (convex)
    localparam NV       = MAX_PRIM*MAX_VERT;  // 32 vertex cells
    localparam NE       = MAX_PRIM*MAX_VERT;  // 32 edge cells (1 per vertex)
    localparam CW       = 12;    // signed screen-coord width
    localparam EW       = 32;    // signed edge-accumulator width

    localparam T_POINT = 2'd0, T_LINE = 2'd1, T_POLY = 2'd2;

    // ---------------- configuration / control registers ---------------------
    reg  [7:0] cfg_w, cfg_h;     // width-1 / height-1 fields
    reg  [1:0] cfg_ctype;
    reg        cfg_proj;
    reg        ctl_enable, ctl_fill, ctl_wait, ctl_cont;
    reg  [7:0] rot_ax, rot_ay, rot_az;
    reg [23:0] fill_color;
    reg  [3:0] sel_slot, sel_vert;

    assign scr_w     = cfg_w;
    assign scr_h     = cfg_h;
    assign scr_ctype = cfg_ctype;
    assign enable    = ctl_enable;
    assign fill      = ctl_fill;

    // active resolution (color modes clamp to 32x32)
    wire [8:0] res_w_full = {1'b0,cfg_w} + 9'd1;          // 1..256
    wire [8:0] res_h_full = {1'b0,cfg_h} + 9'd1;
    wire       is_mono    = (cfg_ctype == 2'b00);
    wire [8:0] res_w      = is_mono ? res_w_full : (res_w_full > 9'd32 ? 9'd32 : res_w_full);
    wire [8:0] res_h      = is_mono ? res_h_full : (res_h_full > 9'd32 ? 9'd32 : res_h_full);
    wire signed [CW-1:0] cx = $signed({1'b0,res_w[8:1]});  // screen centre x (W/2)
    wire signed [CW-1:0] cy = $signed({1'b0,res_h[8:1]});  // screen centre y (H/2)

    // ---------------- CONFIG FRONT-MUX (operand isolation by mode) ----------
    // One-hot decode of the colour-type field. Each mode line is broadcast as
    // an AND mask onto the operands of that mode's datapath, so only the
    // selected colour pipeline ever toggles (the others stay frozen at 0).
    // Same idea as the ALU's sel_* lines, applied to the GPU config.
    wire mode_mono  = (cfg_ctype == 2'b00);
    wire mode_mux   = (cfg_ctype == 2'b01);
    wire mode_rgb12 = (cfg_ctype == 2'b10);
    wire mode_rgb24 = (cfg_ctype == 2'b11);
    wire mode_rgb   = mode_rgb12 | mode_rgb24;     // either RGB depth
    wire proj_iso   = cfg_proj;                    // isometric  skew active
    wire proj_ortho = ~cfg_proj;                   // orthographic (no skew)
    reg               p_en   [0:MAX_PRIM-1];   // slot enable (scene store)
    reg  [1:0]        p_type [0:MAX_PRIM-1];
    reg               p_is3d [0:MAX_PRIM-1];
    reg               p_fill [0:MAX_PRIM-1];
    reg  [3:0]        p_vcnt [0:MAX_PRIM-1];
    reg [23:0]        p_col  [0:MAX_PRIM-1];

    reg signed [CW-1:0] vx [0:NV-1];   // raw vertices (model/screen space)
    reg signed [CW-1:0] vy [0:NV-1];
    reg signed [CW-1:0] vz [0:NV-1];
    reg signed [CW-1:0] px2[0:NV-1];   // projected 2D screen coords
    reg signed [CW-1:0] py2[0:NV-1];

    // edge coefficients : E(x,y) = A*x + B*y + C ,  A=dy , B=-dx
    reg signed [CW:0]   e_dy   [0:NE-1];   // A  (and +x step for E)
    reg signed [CW:0]   e_dx   [0:NE-1];   // +x step for dot
    reg signed [CW:0]   e_ndx  [0:NE-1];   // B = -dx
    reg signed [EW-1:0] e_C    [0:NE-1];
    reg signed [EW-1:0] e_Ddot [0:NE-1];
    reg signed [EW-1:0] e_seg2 [0:NE-1];
    reg signed [CW:0]   e_mab  [0:NE-1];   // max(|dx|,|dy|) ~ 1px outline threshold
    reg signed [EW-1:0] e_E    [0:NE-1];   // running edge value at current pixel
    reg signed [EW-1:0] e_dot  [0:NE-1];   // running along-edge dot at current pixel

    integer i;

    // ---------------- sine LUT (Q1.8 ; 256=1.0) -----------------------------
    function signed [10:0] sinv;
        input [7:0] a;
        reg [1:0] q; reg [5:0] p; reg [6:0] idx; reg neg; reg signed [10:0] m;
        begin
            q = a[7:6]; p = a[5:0];
            case (q)
                2'd0: begin idx = {1'b0,p};        neg = 1'b0; end
                2'd1: begin idx = 7'd64-{1'b0,p};  neg = 1'b0; end
                2'd2: begin idx = {1'b0,p};        neg = 1'b1; end
                default: begin idx = 7'd64-{1'b0,p}; neg = 1'b1; end
            endcase
            case (idx)
        7'd0: m = 11'sd0;
        7'd1: m = 11'sd6;
        7'd2: m = 11'sd13;
        7'd3: m = 11'sd19;
        7'd4: m = 11'sd25;
        7'd5: m = 11'sd31;
        7'd6: m = 11'sd38;
        7'd7: m = 11'sd44;
        7'd8: m = 11'sd50;
        7'd9: m = 11'sd56;
        7'd10: m = 11'sd62;
        7'd11: m = 11'sd68;
        7'd12: m = 11'sd74;
        7'd13: m = 11'sd80;
        7'd14: m = 11'sd86;
        7'd15: m = 11'sd92;
        7'd16: m = 11'sd98;
        7'd17: m = 11'sd104;
        7'd18: m = 11'sd109;
        7'd19: m = 11'sd115;
        7'd20: m = 11'sd121;
        7'd21: m = 11'sd126;
        7'd22: m = 11'sd132;
        7'd23: m = 11'sd137;
        7'd24: m = 11'sd142;
        7'd25: m = 11'sd147;
        7'd26: m = 11'sd152;
        7'd27: m = 11'sd157;
        7'd28: m = 11'sd162;
        7'd29: m = 11'sd167;
        7'd30: m = 11'sd172;
        7'd31: m = 11'sd177;
        7'd32: m = 11'sd181;
        7'd33: m = 11'sd185;
        7'd34: m = 11'sd190;
        7'd35: m = 11'sd194;
        7'd36: m = 11'sd198;
        7'd37: m = 11'sd202;
        7'd38: m = 11'sd206;
        7'd39: m = 11'sd209;
        7'd40: m = 11'sd213;
        7'd41: m = 11'sd216;
        7'd42: m = 11'sd220;
        7'd43: m = 11'sd223;
        7'd44: m = 11'sd226;
        7'd45: m = 11'sd229;
        7'd46: m = 11'sd231;
        7'd47: m = 11'sd234;
        7'd48: m = 11'sd237;
        7'd49: m = 11'sd239;
        7'd50: m = 11'sd241;
        7'd51: m = 11'sd243;
        7'd52: m = 11'sd245;
        7'd53: m = 11'sd247;
        7'd54: m = 11'sd248;
        7'd55: m = 11'sd250;
        7'd56: m = 11'sd251;
        7'd57: m = 11'sd252;
        7'd58: m = 11'sd253;
        7'd59: m = 11'sd254;
        7'd60: m = 11'sd255;
        7'd61: m = 11'sd255;
        7'd62: m = 11'sd256;
        7'd63: m = 11'sd256;
        7'd64: m = 11'sd256;
                default: m = 11'sd0;
            endcase
            sinv = neg ? -m : m;
        end
    endfunction

    // trig values latched for the current frame
    reg signed [10:0] sx_, cx_, sy_, cy_, sz_, cz_;

    // ---------------- main FSM ----------------------------------------------
    localparam S_IDLE   = 4'd0,
               S_TRIG   = 4'd1,
               S_XFORM  = 4'd2,
               S_EDGE   = 4'd3,
               S_FRAME  = 4'd4,
               S_ROWINI = 4'd5,
               S_PIXEL  = 4'd6,
               S_ROWEMT = 4'd7,
               S_ROWEND = 4'd8,
               S_DONE   = 4'd9;

    reg [3:0]  state;
    reg [5:0]  idx_v;          // vertex iterator 0..NV
    reg [5:0]  idx_e;          // edge iterator 0..NE

    // ---- PROCESS FRONT-MUX (only the active stage's logic toggles) ---------
    // Exactly one stage runs per cycle, so these one-hot enables gate the
    // operands of each stage. The big per-pixel coverage net in particular is
    // frozen unless pixel_en is high, so it does not toggle during the per-row
    // edge-seed pass or any other state.
    wire xform_en  = (state == S_XFORM);
    wire edge_en   = (state == S_EDGE);
    wire rowini_en = (state == S_ROWINI);
    wire pixel_en  = (state == S_PIXEL);
    reg [1:0]  sub;            // sub-step within transform / edge setup
    reg [8:0]  cur_x, cur_y;   // scan position
    reg        busy;

    // transform scratch
    reg signed [CW-1:0] tx, ty, tz;            // working vertex
    reg signed [CW+12:0] mm0, mm1, mm2, mm3;   // shared products (4 multipliers)
    reg signed [CW-1:0] fx, fy, fz, sxp, syp;  // projection temporaries
    reg signed [CW-1:0] fz_iso, sy_skew;       // iso-only terms (gated by proj_iso)

    // helpers to map an edge index to its slot / vertices
    // slot = idx_e / MAX_VERT ; local e = idx_e % MAX_VERT
    reg [1:0] es;          // edge slot
    reg [3:0] ee;          // edge local index
    reg [3:0] enext;       // next vertex (wrap by vcount)
    reg signed [CW-1:0] x0e, y0e, x1e, y1e, dxe, dye;

    // ----- combinational per-pixel coverage over the scene ------------------
    reg               cov_any;
    reg [23:0]        cov_col;
    reg               s_any; reg [23:0] s_col;
    integer ss, k, base;
    reg allpos, allneg, onedge;
    reg signed [EW-1:0] Ev, av, dv, sg;
    reg signed [CW:0]   mb;
    reg covered;

    always @(*) begin
        cov_any = 1'b0;
        cov_col = 24'd0;
        // PROCESS GATE: this whole evaluator is frozen unless a pixel is being
        // produced, so it does not toggle during edge-seed / setup / idle.
        if (pixel_en) begin
        for (ss = 0; ss < MAX_PRIM; ss = ss + 1) begin
            base   = ss*MAX_VERT;
            allpos = 1'b1; allneg = 1'b1; onedge = 1'b0;
            covered = 1'b0;
            // OPERAND ISOLATION: a disabled slot is skipped entirely, so its
            // comparator chain receives no live data and stays inactive.
            if (p_en[ss]) begin
                for (k = 0; k < MAX_VERT; k = k + 1) begin
                    if (k < p_vcnt[ss]) begin
                        Ev = e_E[base+k];
                        mb = e_mab[base+k];
                        dv = e_dot[base+k];
                        sg = e_seg2[base+k];
                        av = (Ev[EW-1]) ? -Ev : Ev;
                        if (Ev <  0) allpos = 1'b0;
                        if (Ev >  0) allneg = 1'b0;
                        if ((av <= {{(EW-CW-1){1'b0}}, mb}) &&
                            (dv >= 0) && (dv <= sg))
                            onedge = 1'b1;
                    end
                end
                case (p_type[ss])
                    T_POINT: covered = (cur_x == px2[base][8:0]) &&
                                       (cur_y == py2[base][8:0]);
                    T_LINE:  covered = onedge;
                    default: covered = p_fill[ss] ? (allpos | allneg) : onedge;
                endcase
            end
            if (covered) begin           // higher slot index overwrites (painter)
                cov_any = 1'b1;
                cov_col = p_col[ss];
            end
        end
        end
    end

    // expand a stored colour to 24-bit RGB according to colour mode
    function [23:0] rgb_expand;
        input [23:0] c; input [1:0] ct;
        begin
            case (ct)
                2'b10: rgb_expand = {c[11:8],c[11:8], c[7:4],c[7:4], c[3:0],c[3:0]}; // RGB12->24
                default: rgb_expand = c[23:0];                                       // RGB24
            endcase
        end
    endfunction

    wire [23:0] pix_rgb_src  = ctl_fill ? fill_color : cov_col;
    wire [3:0]  pix_mux_src  = ctl_fill ? fill_color[3:0] : cov_col[3:0];
    wire        pix_on_mono  = ctl_fill ? fill_color[0]   : cov_any;

    wire advance = (~ctl_wait) | screen_ready;   // free-run unless waiting

    // ============================ sequential ================================
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE; busy <= 1'b0;
            cfg_w <= 8'd63; cfg_h <= 8'd63; cfg_ctype <= 2'b00; cfg_proj <= 1'b0;
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            rot_ax <= 8'd0; rot_ay <= 8'd0; rot_az <= 8'd0;
            fill_color <= 24'd0; sel_slot <= 4'd0; sel_vert <= 4'd0;
            mono_valid <= 1'b0; px_valid <= 1'b0; frame_start <= 1'b0; frame_done <= 1'b0;
            mono_y <= 8'd0; px_x <= 5'd0; px_y <= 5'd0; px_mux <= 4'd0; px_rgb <= 24'd0;
            mono_s0 <= 64'd0; mono_s1 <= 64'd0; mono_s2 <= 64'd0; mono_s3 <= 64'd0;
            for (i = 0; i < MAX_PRIM; i = i + 1) begin
                p_en[i] <= 1'b0; p_type[i] <= 2'd0; p_is3d[i] <= 1'b0;
                p_fill[i] <= 1'b0; p_vcnt[i] <= 4'd0; p_col[i] <= 24'd0;
            end
        end else begin
            // -------- register writes from the CPU (always serviced) --------
            if (gpu_we) begin
                case (gpu_addr)
                    4'd0: begin cfg_w <= gpu_wdata[7:0]; cfg_h <= gpu_wdata[15:8];
                                cfg_ctype <= gpu_wdata[17:16]; cfg_proj <= gpu_wdata[18]; end
                    4'd1: begin ctl_enable <= gpu_wdata[0]; ctl_fill <= gpu_wdata[1];
                                ctl_wait <= gpu_wdata[3]; ctl_cont <= gpu_wdata[5];
                                if (gpu_wdata[2]) begin                 // scene_clear
                                    for (i = 0; i < MAX_PRIM; i = i + 1) p_en[i] <= 1'b0;
                                end
                                // commit handled below by state machine trigger
                          end
                    4'd2: begin rot_ax <= gpu_wdata[7:0]; rot_ay <= gpu_wdata[15:8];
                                rot_az <= gpu_wdata[23:16]; end
                    4'd3: fill_color <= gpu_wdata[23:0];
                    4'd4: begin sel_slot <= gpu_wdata[3:0]; sel_vert <= gpu_wdata[7:4]; end
                    4'd5: begin p_type[sel_slot[1:0]] <= gpu_wdata[1:0];
                                p_is3d[sel_slot[1:0]] <= gpu_wdata[2];
                                p_fill[sel_slot[1:0]] <= gpu_wdata[3];
                                p_en  [sel_slot[1:0]] <= gpu_wdata[4];
                                p_vcnt[sel_slot[1:0]] <= gpu_wdata[8:5]; end
                    4'd6: p_col[sel_slot[1:0]] <= gpu_wdata[23:0];
                    4'd7: begin
                                vx[{sel_slot[1:0],sel_vert[2:0]}] <= $signed(gpu_wdata[9:0]);
                                vy[{sel_slot[1:0],sel_vert[2:0]}] <= $signed(gpu_wdata[19:10]);
                                vz[{sel_slot[1:0],sel_vert[2:0]}] <= $signed(gpu_wdata[29:20]);
                                sel_vert <= sel_vert + 4'd1;
                          end
                    default: ;
                endcase
            end

            // strobe / valid defaults (asserted only by the presenting states)
            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            mono_valid  <= 1'b0;
            px_valid    <= 1'b0;

            // status read
            gpu_rdata <= {22'd0, frame_done, busy, cur_y[7:0]};

            // -------- the rendering pipeline --------------------------------
            case (state)
            // wait for commit (CONTROL bit4)
            S_IDLE: begin
                busy <= 1'b0;
                if (gpu_we && gpu_addr == 4'd1 && gpu_wdata[4]) begin
                    busy  <= 1'b1;
                    state <= S_TRIG;
                end
            end

            // latch sin/cos for this frame
            S_TRIG: begin
                sx_ <= sinv(rot_ax);  cx_ <= sinv(rot_ax + 8'd64);
                sy_ <= sinv(rot_ay);  cy_ <= sinv(rot_ay + 8'd64);
                sz_ <= sinv(rot_az);  cz_ <= sinv(rot_az + 8'd64);
                idx_v <= 6'd0; sub <= 2'd0;
                state <= S_XFORM;
            end

            // transform + project every vertex (4 shared multipliers, 3 substeps)
            S_XFORM: begin
                if (idx_v == NV) begin
                    idx_e <= 6'd0; sub <= 2'd0; state <= S_EDGE;
                end else if (!p_en[idx_v[4:3]] ||
                             (idx_v[2:0] >= p_vcnt[idx_v[4:3]])) begin
                    idx_v <= idx_v + 6'd1; sub <= 2'd0;          // skip unused cell
                end else if (!p_is3d[idx_v[4:3]]) begin
                    px2[idx_v] <= vx[idx_v];                      // 2D : screen coords
                    py2[idx_v] <= vy[idx_v];
                    idx_v <= idx_v + 6'd1; sub <= 2'd0;
                end else begin
                    case (sub)
                    2'd0: begin                                   // load + rotate X
                        tx <= vx[idx_v];
                        mm0 = vy[idx_v]*cx_; mm1 = vz[idx_v]*sx_;
                        mm2 = vy[idx_v]*sx_; mm3 = vz[idx_v]*cx_;
                        ty <= (mm0 - mm1) >>> 8;
                        tz <= (mm2 + mm3) >>> 8;
                        sub <= 2'd1;
                    end
                    2'd1: begin                                   // rotate Y
                        mm0 = tx*cy_; mm1 = tz*sy_;
                        mm2 = tx*sy_; mm3 = tz*cy_;
                        tx <= (mm0 + mm1) >>> 8;
                        tz <= (mm3 - mm2) >>> 8;
                        sub <= 2'd2;
                    end
                    default: begin                                // rotate Z + project
                        mm0 = tx*cz_; mm1 = ty*sz_;
                        mm2 = tx*sz_; mm3 = ty*cz_;
                        fx = (mm0 - mm1) >>> 8;
                        fy = (mm2 + mm3) >>> 8;
                        fz = tz;
                        // CONFIG GATE: iso skew operands masked by proj_iso.
                        // In ortho mode fz_iso and sy_skew are 0, so the skew
                        // subtractor/adder/shifter inputs are 0 and inactive.
                        fz_iso  = fz & {CW{proj_iso}};
                        sy_skew = ((fx + fz_iso) >>> 1) & {CW{proj_iso}};
                        sxp = fx - fz_iso;          // fx in ortho, fx-fz in iso
                        syp = fy + sy_skew;         // fy in ortho, fy+(fx+fz)/2 in iso
                        px2[idx_v] <= sxp + cx;
                        py2[idx_v] <= syp + cy;
                        idx_v <= idx_v + 6'd1; sub <= 2'd0;
                    end
                    endcase
                end
            end

            // build edge coefficients (2 shared multipliers, 3 substeps/edge)
            S_EDGE: begin
                es    = idx_e[4:3];
                ee    = {1'b0,idx_e[2:0]};
                enext = (ee + 4'd1 >= p_vcnt[es]) ? 4'd0 : (ee + 4'd1);
                x0e   = px2[idx_e];
                y0e   = py2[idx_e];
                x1e   = px2[{es,enext[2:0]}];
                y1e   = py2[{es,enext[2:0]}];
                dxe   = x1e - x0e;
                dye   = y1e - y0e;
                if (idx_e == NE) begin
                    cur_y <= 9'd0; state <= S_FRAME;
                end else if (!p_en[es] || (ee >= p_vcnt[es])) begin
                    e_dy[idx_e]  <= 0; e_dx[idx_e] <= 0; e_ndx[idx_e] <= 0;
                    e_C[idx_e]   <= 0; e_Ddot[idx_e]<= 0; e_seg2[idx_e]<= 0;
                    e_mab[idx_e] <= 0;
                    idx_e <= idx_e + 6'd1; sub <= 2'd0;
                end else begin
                    case (sub)
                    2'd0: begin
                        e_dy [idx_e] <= dye;
                        e_dx [idx_e] <= dxe;
                        e_ndx[idx_e] <= -dxe;
                        e_mab[idx_e] <= ((dye<0?-dye:dye) > (dxe<0?-dxe:dxe))
                                        ? (dye<0?-dye:dye) : (dxe<0?-dxe:dxe);
                        mm0 = dxe*y0e; mm1 = dye*x0e;            // C = dx*y0 - dy*x0
                        e_C[idx_e] <= mm0 - mm1;
                        sub <= 2'd1;
                    end
                    2'd1: begin
                        mm0 = x0e*dxe; mm1 = y0e*dye;            // Ddot = -(x0*dx + y0*dy)
                        e_Ddot[idx_e] <= -(mm0 + mm1);
                        sub <= 2'd2;
                    end
                    default: begin
                        mm0 = dxe*dxe; mm1 = dye*dye;            // seg2 = dx^2 + dy^2
                        e_seg2[idx_e] <= mm0 + mm1;
                        idx_e <= idx_e + 6'd1; sub <= 2'd0;
                    end
                    endcase
                end
            end

            // start of frame
            S_FRAME: begin
                frame_start <= 1'b1;
                cur_y <= 9'd0;
                idx_e <= 6'd0;
                state <= S_ROWINI;
            end

            // per-row: seed each edge accumulator at x=0 (2 shared multipliers)
            S_ROWINI: begin
                if (idx_e == NE) begin
                    cur_x <= 9'd0;
                    mono_s0 <= 64'd0; mono_s1 <= 64'd0;
                    mono_s2 <= 64'd0; mono_s3 <= 64'd0;
                    state <= S_PIXEL;
                end else begin
                    mm0 = e_ndx[idx_e]*$signed({3'b000,cur_y});  // B*y
                    mm1 = e_dy [idx_e]*$signed({3'b000,cur_y});  // dy*y
                    e_E  [idx_e] <= mm0 + e_C[idx_e];
                    e_dot[idx_e] <= mm1 + e_Ddot[idx_e];
                    idx_e <= idx_e + 6'd1;
                end
            end

            // per-pixel: sample coverage, then step every edge accumulator by +x
            S_PIXEL: begin
                if (is_mono) begin
                    // write current bit into the row register
                    if (pix_on_mono) begin
                        case (cur_x[7:6])
                            2'd0: mono_s0[cur_x[5:0]] <= 1'b1;
                            2'd1: mono_s1[cur_x[5:0]] <= 1'b1;
                            2'd2: mono_s2[cur_x[5:0]] <= 1'b1;
                            default: mono_s3[cur_x[5:0]] <= 1'b1;
                        endcase
                    end
                    for (i = 0; i < NE; i = i + 1) begin
                        e_E[i]   <= e_E[i]   + {{(EW-CW-1){e_dy[i][CW]}}, e_dy[i]};
                        e_dot[i] <= e_dot[i] + {{(EW-CW-1){e_dx[i][CW]}}, e_dx[i]};
                    end
                    if (cur_x + 9'd1 >= res_w) begin
                        state <= S_ROWEMT;
                    end else begin
                        cur_x <= cur_x + 9'd1;
                    end
                end else begin
                    // colour: present this pixel, wait for handshake
                    // CONFIG GATE: the MUX index path and the RGB-expand path
                    // are each masked by their mode line, so only the selected
                    // colour pipeline toggles. (rgb_expand sees 0 in MUX mode.)
                    px_valid <= ctl_enable;
                    px_x  <= cur_x[4:0];
                    px_y  <= cur_y[4:0];
                    px_mux<= pix_mux_src & {4{mode_mux}};
                    px_rgb<= rgb_expand(pix_rgb_src & {24{mode_rgb}}, cfg_ctype);
                    if (advance) begin
                        for (i = 0; i < NE; i = i + 1) begin
                            e_E[i]   <= e_E[i]   + {{(EW-CW-1){e_dy[i][CW]}}, e_dy[i]};
                            e_dot[i] <= e_dot[i] + {{(EW-CW-1){e_dx[i][CW]}}, e_dx[i]};
                        end
                        if (cur_x + 9'd1 >= res_w) begin
                            state <= S_ROWEND;
                        end else begin
                            cur_x <= cur_x + 9'd1;
                        end
                    end
                end
            end

            // monochrome: present the completed row, wait for handshake
            S_ROWEMT: begin
                mono_valid <= ctl_enable;
                mono_y <= cur_y[7:0];
                if (advance) begin
                    state <= S_ROWEND;
                end
            end

            // advance to next row / finish frame
            S_ROWEND: begin
                if (cur_y + 9'd1 >= res_h) begin
                    state <= S_DONE;
                end else begin
                    cur_y <= cur_y + 9'd1;
                    idx_e <= 6'd0;
                    state <= S_ROWINI;
                end
            end

            // frame complete
            S_DONE: begin
                frame_done <= 1'b1;
                if (ctl_cont) state <= S_TRIG;     // auto re-render (animation)
                else          state <= S_IDLE;
            end

            default: state <= S_IDLE;
            endcase
        end
    end
endmodule

// ############################################################################
// ##  BITF-SYNTH ENGINE FLOW SHIMS                                          ##
// ##  In the BITF-Synth Engine the eight Control_Unit LUTs and the          ##
// ##  ALU front decoder are materialised from the BITF_LUT /                ##
// ##  BITF_DECODER directives above.  The implementations below are         ##
// ##  bit-exact copies of those tables so the file ALSO elaborates and      ##
// ##  simulates standalone (iverilog -t null -s RV32IM_SYSTEM).             ##
// ##  Keep the directive comments AND these modules in sync.                ##
// ############################################################################

// -- Control_Unit one-bit opcode LUTs (5-bit index = opcode[6:2]) ------------
// Bit i of INIT = output when opcode[6:2] == i.   (BITF_LUT contract)

module cu_reg_write(input [4:0] i, output o);   // Load, I-type, AUIPC, R-type, LUI
    localparam [31:0] INIT = 32'h00003031;
    assign o = INIT[i];
endmodule

module cu_mem_read(input [4:0] i, output o);    // Load only
    localparam [31:0] INIT = 32'h00000001;
    assign o = INIT[i];
endmodule

module cu_mem_write(input [4:0] i, output o);   // Store only
    localparam [31:0] INIT = 32'h00000100;
    assign o = INIT[i];
endmodule

module cu_mem_to_reg(input [4:0] i, output o);  // Load only
    localparam [31:0] INIT = 32'h00000001;
    assign o = INIT[i];
endmodule

module cu_branch(input [4:0] i, output o);      // Branch only
    localparam [31:0] INIT = 32'h01000000;
    assign o = INIT[i];
endmodule

module cu_alu_src_b(input [4:0] i, output o);   // Load, I-type, AUIPC, Store, LUI
    localparam [31:0] INIT = 32'h00002131;
    assign o = INIT[i];
endmodule

module cu_alu_src_a0(input [4:0] i, output o);  // AUIPC only -> A = PC
    localparam [31:0] INIT = 32'h00000020;
    assign o = INIT[i];
endmodule

module cu_alu_src_a1(input [4:0] i, output o);  // LUI only -> A = Zero
    localparam [31:0] INIT = 32'h00002000;
    assign o = INIT[i];
endmodule

// -- ALU operation-select front decoder (BITF_DECODER contract) -------------
// 4-bit alu_control -> 13 one-hot select lines (codes 13..15 idle-low).

module alu_op_dec(input [3:0] addr, output [12:0] y);
    wire [15:0] full = 16'h0001 << addr;
    assign y = full[12:0];
endmodule



