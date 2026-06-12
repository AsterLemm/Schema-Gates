// =====================================================================
//  interp_riscv_to_arm_16.v
//  CROSS-ISA INTERPRETER: runs cpu_riscv16 (RV-lite) binaries on cpu_arm16.
//
//  Sits on the HOST's instruction-fetch port and BYPASSES its control
//  unit: the ARM host keeps decoding native ARM; this block expands each
//  RV-lite instruction into a fixed 8-instruction native bundle on the
//  fly. Purely combinational - host_pc = {guest_pc[4:0], slot[2:0]}, so a
//  guest program of up to 32 instructions runs unmodified.
//
//  STATE MAPPING
//    guest x0..x15  -> host r0..r15 one-to-one.
//    THE x0 INVARIANT: slot 0 of EVERY bundle is "MOV r0,#0", so r0 reads
//    as zero at every guest instruction boundary exactly like x0 - even
//    if a guest JAL/ALU wrote rd=x0 a bundle earlier (the write lands,
//    then is erased; architecturally invisible, just like the guest).
//    guest dmem     -> host dmem (LDR/STR [rn+imm] maps 1:1)
//    guest has NO flags; branches expand to CMP + B<cond> pairs, so the
//    host NZCV is a private scratch resource of the translator.
//    scratch        -> host r11 (LUI assembly, JALR target math)
//
//  TRANSLATION (bundle slots 1..7, filler = cond-NV NOP)
//    ALU-R ADD/SUB/AND/OR/XOR  ADD/SUB/AND/ORR/EOR rd,rs1,rs2 (3-op, 1:1)
//    SLT  / SLTU               CMP rs1,rs2 ; MOVLT/MOVCC rd,#1 ; MOVGE/MOVCS rd,#0
//    ADDI #pos / #neg          ADD rd,rs1,#i  /  SUB rd,rs1,#(-i)
//    ANDI/ORI/XORI             AND/ORR/EOR rd,rs1,#i      (i in 0..255)
//    LUI (W=16: rd = imm16)    MOV r11,#hi ; MOV rd,r11 LSL #8 ; ORR rd,rd,#lo
//    LW / SW                   LDR rd,[rs1+i] / STR rs2,[rs1+i]
//    BEQ/BNE/BLT/BGE           CMP rs1,rs2 ; B EQ/NE/LT/GE target
//    JAL                       MOV rd,#(pc+1) ; B target
//    JALR                      MOV rd,#(pc+1) ; ADD r11,rs1,#i ;
//                              MOV r11,r11 LSL #3 ; BX r11
//                              (the barrel shifter rescales the guest
//                               address into bundle space at runtime)
//    OUT / HALT                OUT rs1 / HALT
//
//  TRAPS (host fed HALT, trap output high):
//    * ALU-R funct 5/6/7 (SLL/SRL/SRA by register) - the host barrel
//      shifter takes IMMEDIATE amounts only
//    * I-type immediates outside 0..255 (except negative ADDI, which
//      becomes SUB), and LW/SW/JALR offsets outside 0..255
//
//  MODULAR: guest-field decode + the translate cloud are drillable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- interp_riscv_to_arm_16_gdec : guest field extraction + class decode ---
// (verbatim from the monolithic body; wire = -> assign =)
module interp_riscv_to_arm_16_gdec(
    input  wire [31:0] guest_instr,
    output wire [3:0] gop,
    output wire [3:0] rd,
    output wire [3:0] rs1,
    output wire [3:0] rs2,
    output wire [15:0] imm16,
    output wire [3:0] funct,
    output wire [7:0] immlo,
    output wire immneg,
    output wire [15:0] immabs,
    output wire imm_ok,
    output wire nimm_ok
);
    // ---- guest field extraction (RV-lite encoding) -----------------------
    assign gop = guest_instr[31:28];
    assign rd = guest_instr[27:24];
    assign rs1 = guest_instr[23:20];
    assign rs2 = guest_instr[19:16];
    assign imm16 = guest_instr[15:0];
    assign funct = guest_instr[3:0];
    assign immlo = imm16[7:0];
    assign immneg = imm16[15];
    assign immabs = (~imm16) + 16'd1;        // |imm| for negative ADDI
    assign imm_ok = (imm16[15:8] == 8'd0);
    assign nimm_ok = immneg && (immabs[15:8] == 8'd0);

endmodule

// --- interp_riscv_to_arm_16_xlat : the bundle translator (guest -> host words) ---
// the entire translate cloud of the old monolithic body, carried
// over verbatim; guest fields come from interp_riscv_to_arm_16_gdec inside.
module interp_riscv_to_arm_16_xlat(
    input  wire [7:0]  host_addr,
    input  wire [4:0]  gpc,
    input  wire [2:0]  slot,
    input  wire [31:0] guest_instr,
    output reg  [31:0] host_instr,
    output reg         trap
);
    wire [3:0] gop;
    wire [3:0] rd;
    wire [3:0] rs1;
    wire [3:0] rs2;
    wire [15:0] imm16;
    wire [3:0] funct;
    wire [7:0] immlo;
    wire immneg;
    wire [15:0] immabs;
    wire imm_ok;
    wire nimm_ok;

    interp_riscv_to_arm_16_gdec u_gdec(
        .guest_instr(guest_instr),
        .gop(gop),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm16(imm16),
        .funct(funct),
        .immlo(immlo),
        .immneg(immneg),
        .immabs(immabs),
        .imm_ok(imm_ok),
        .nimm_ok(nimm_ok)
    );

    // ---- host word builders (cpu_arm16 encoding) -------------------------
    localparam [3:0] AL = 4'd14;
    localparam [31:0] NOPW = 32'hF0000000;        // cond NV: executes never
    function [31:0] dpi;
        input [3:0] c, op, d, n; input s; input [7:0] i;
        dpi = {c, s, 2'b01, op, d, n, i, 5'b00000};
    endfunction
    function [31:0] dpr;
        input [3:0] c, op, d, n, rmf; input s; input [1:0] sht; input [4:0] sha;
        dpr = {c, s, 2'b00, op, d, n, rmf, sht, sha, 2'b00};
    endfunction
    function [31:0] memw;
        input st; input [3:0] d, n; input [7:0] i;
        memw = {AL, 1'b0, 2'b10, 3'b000, st, d, n, i, 5'b00000};
    endfunction
    function [31:0] flw;
        input [3:0] c, op; input [16:0] i;
        flw = {c, 1'b0, 2'b11, op, 4'd0, i};
    endfunction
    function [31:0] flr;
        input [3:0] c, op, n;
        flr = {c, 1'b0, 2'b11, op, 4'd0, n, 13'd0};
    endfunction
    localparam [31:0] HALTW = {4'd14, 1'b0, 2'b11, 4'd4, 4'd0, 17'd0};

    // branch / jump target: guest pc arithmetic is 8-bit, masked into the
    // 32-instruction window, scaled by 8, made pc-relative for the host B
    wire [7:0]  tgt_g  = {3'd0, gpc} + immlo;
    wire [16:0] rel    = {9'd0, tgt_g[4:0], 3'b000} - {9'd0, host_addr};
    wire [7:0]  retval = {3'd0, gpc} + 8'd1;

    // ---- per-class payload (slots 1..7) ------------------------------------
    reg [31:0] pay; reg bad;
    always @(*) begin
        pay = NOPW; bad = 1'b0;
        case (gop)
            4'h0: begin                                            // ALU-R
                case (funct)
                    4'd0: if (slot == 3'd1) pay = dpr(AL, 4'd4, rd, rs1, rs2, 1'b0, 2'd0, 5'd0);
                    4'd1: if (slot == 3'd1) pay = dpr(AL, 4'd2, rd, rs1, rs2, 1'b0, 2'd0, 5'd0);
                    4'd2: if (slot == 3'd1) pay = dpr(AL, 4'd0, rd, rs1, rs2, 1'b0, 2'd0, 5'd0);
                    4'd3: if (slot == 3'd1) pay = dpr(AL, 4'd7, rd, rs1, rs2, 1'b0, 2'd0, 5'd0);
                    4'd4: if (slot == 3'd1) pay = dpr(AL, 4'd1, rd, rs1, rs2, 1'b0, 2'd0, 5'd0);
                    4'd8: case (slot)                              // SLT
                        3'd1: pay = dpr(AL, 4'd12, 4'd0, rs1, rs2, 1'b1, 2'd0, 5'd0);
                        3'd2: pay = dpi(4'd11, 4'd8, rd, 4'd0, 1'b0, 8'd1);  // MOVLT
                        3'd3: pay = dpi(4'd10, 4'd8, rd, 4'd0, 1'b0, 8'd0);  // MOVGE
                        default: pay = NOPW;
                    endcase
                    4'd9: case (slot)                              // SLTU
                        3'd1: pay = dpr(AL, 4'd12, 4'd0, rs1, rs2, 1'b1, 2'd0, 5'd0);
                        3'd2: pay = dpi(4'd3, 4'd8, rd, 4'd0, 1'b0, 8'd1);   // MOVCC
                        3'd3: pay = dpi(4'd2, 4'd8, rd, 4'd0, 1'b0, 8'd0);   // MOVCS
                        default: pay = NOPW;
                    endcase
                    default: bad = 1'b1;                           // var shifts
                endcase
            end
            4'h1: begin                                            // ADDI
                if (imm_ok)       begin if (slot == 3'd1) pay = dpi(AL, 4'd4, rd, rs1, 1'b0, immlo); end
                else if (nimm_ok) begin if (slot == 3'd1) pay = dpi(AL, 4'd2, rd, rs1, 1'b0, immabs[7:0]); end
                else bad = 1'b1;
            end
            4'h2: if (imm_ok) begin if (slot == 3'd1) pay = dpi(AL, 4'd0, rd, rs1, 1'b0, immlo); end
                  else bad = 1'b1;                                 // ANDI
            4'h3: if (imm_ok) begin if (slot == 3'd1) pay = dpi(AL, 4'd7, rd, rs1, 1'b0, immlo); end
                  else bad = 1'b1;                                 // ORI
            4'h4: if (imm_ok) begin if (slot == 3'd1) pay = dpi(AL, 4'd1, rd, rs1, 1'b0, immlo); end
                  else bad = 1'b1;                                 // XORI
            4'h5: case (slot)                                      // LUI: rd = imm16
                3'd1: pay = dpi(AL, 4'd8, 4'd11, 4'd0, 1'b0, imm16[15:8]);
                3'd2: pay = dpr(AL, 4'd8, rd, 4'd0, 4'd11, 1'b0, 2'd0, 5'd8);
                3'd3: pay = dpi(AL, 4'd7, rd, rd, 1'b0, immlo);
                default: pay = NOPW;
            endcase
            4'h6: if (imm_ok) begin if (slot == 3'd1) pay = memw(1'b0, rd,  rs1, immlo); end
                  else bad = 1'b1;                                 // LW
            4'h7: if (imm_ok) begin if (slot == 3'd1) pay = memw(1'b1, rs2, rs1, immlo); end
                  else bad = 1'b1;                                 // SW
            4'h8, 4'h9, 4'hA, 4'hB: case (slot)                    // branches
                3'd1: pay = dpr(AL, 4'd12, 4'd0, rs1, rs2, 1'b1, 2'd0, 5'd0);  // CMP
                3'd2: pay = flw((gop == 4'h8) ? 4'd0                // BEQ -> EQ
                              : (gop == 4'h9) ? 4'd1                // BNE -> NE
                              : (gop == 4'hA) ? 4'd11               // BLT -> LT
                              :                 4'd10,              // BGE -> GE
                              4'd0, rel);
                default: pay = NOPW;
            endcase
            4'hC: case (slot)                                      // JAL
                3'd1: pay = dpi(AL, 4'd8, rd, 4'd0, 1'b0, retval);
                3'd2: pay = flw(AL, 4'd0, rel);
                default: pay = NOPW;
            endcase
            4'hD: begin                                            // JALR
                if (!imm_ok) bad = 1'b1;
                else case (slot)
                    3'd1: pay = dpi(AL, 4'd8, rd, 4'd0, 1'b0, retval);
                    3'd2: pay = dpi(AL, 4'd4, 4'd11, rs1, 1'b0, immlo);
                    3'd3: pay = dpr(AL, 4'd8, 4'd11, 4'd0, 4'd11, 1'b0, 2'd0, 5'd3);
                    3'd4: pay = flr(AL, 4'd2, 4'd11);              // BX r11
                    default: pay = NOPW;
                endcase
            end
            4'hE: if (slot == 3'd1) pay = flr(AL, 4'd3, rs1);      // OUT
            default: if (slot == 3'd1) pay = HALTW;                // HALT
        endcase
    end

    always @(*) begin
        trap = 1'b0;
        if (slot == 3'd0) begin
            host_instr = dpi(AL, 4'd8, 4'd0, 4'd0, 1'b0, 8'd0);    // r0 <= 0
        end else if (bad) begin
            host_instr = (slot == 3'd1) ? HALTW : NOPW;
            trap = (slot == 3'd1);
        end else begin
            host_instr = pay;
        end
    end
endmodule

module interp_riscv_to_arm_16(
    // host fetch side: connect to cpu_arm16 imem_addr / imem_data
    input  wire [7:0]  host_addr,
    output wire [31:0] host_instr,
    // guest program side: connect to the guest binary ROM (32 x 32-bit)
    output wire [4:0]  guest_addr,
    input  wire [31:0] guest_instr,
    // high while feeding HALT for an untranslatable guest instruction
    output wire        trap
);
    // define host_addr    input  255.190.70
    // define host_instr   output 120.200.255
    // define guest_addr   output 255.140.60
    // define guest_instr  input  68.68.242
    // define trap         output 255.80.80

    wire [4:0] gpc  = host_addr[7:3];
    wire [2:0] slot = host_addr[2:0];
    assign guest_addr = gpc;

    // the entire translator lives in interp_riscv_to_arm_16_xlat above
    interp_riscv_to_arm_16_xlat u_xlat(
        .host_addr(host_addr), .gpc(gpc), .slot(slot),
        .guest_instr(guest_instr),
        .host_instr(host_instr), .trap(trap)
    );
endmodule
