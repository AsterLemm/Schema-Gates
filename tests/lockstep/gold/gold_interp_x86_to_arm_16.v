// =====================================================================
//  interp_x86_to_arm_16.v
//  CROSS-ISA INTERPRETER: runs cpu_x86_16 binaries on cpu_arm16.
//
//  Sits on the HOST's instruction-fetch port and BYPASSES its control
//  unit: the ARM host keeps decoding native ARM; this block expands each
//  x86 instruction into a fixed 4-instruction native bundle on the fly.
//  Purely combinational - host_pc = {guest_pc[5:0], slot[1:0]}, so a
//  guest program of up to 64 instructions runs unmodified.
//
//  This direction is the EASY one and the schematic shows why: the ARM
//  host is a near-superset (3-operand ALU covers 2-operand ops, the
//  barrel shifter covers the shifts, LDR/STR [rn+imm] covers absolute
//  AND stack addressing, BX covers RET's indirect jump). FULL guest ISA
//  coverage - the only trap is a 4-op guest instruction at address 0.
//
//  STATE MAPPING
//    guest AX BX CX DX -> host r0 r1 r2 r3
//    guest SP          -> host r13  (initialized to 32 by a one-slot
//                          PREAMBLE injected into bundle 0, slot 0; guest
//                          instruction 0 therefore gets 3 payload slots)
//    guest RAM[0..31]  -> host dmem[0..31]  (stack descends inside it)
//    guest FLAGS       -> host NZCV via S-suffixed ops. CARRY POLARITY
//                          differs (x86 CF = borrow, ARM C = NOT borrow):
//                          handled in the Jcc condition map (JC<->CC).
//    scratch           -> host r11
//
//  TRANSLATION (bundle slots, filler = cond-NV NOP)
//    MOV r,m / r,imm   MOV rd,rm / MOV rd,#imm
//    ADD/SUB/AND/OR/XOR ADDS/SUBS/ANDS/ORRS/EORS rd,rd,rm
//    CMP               CMP rn,rm
//    INC / DEC         ADDS/SUBS rd,rd,#1   (CF-preserve quirk NOT kept:
//                                             host updates C - documented)
//    NOT               MVN rd,rd            (no flags - quirk PRESERVED)
//    NEG               RSBS rd,rd,#0
//    SHL/SHR/SAR       MOVS rd, rd LSL/LSR/ASR #1
//    ROL               MOVS rd, rd ROR #15  (CF = MSB of result, not the
//                                             rotated-in bit - documented)
//    MOV r,[i]/[i],r   MOV r11,#i ; LDR/STR rd,[r11+0]
//    PUSH / POP        SUB sp,#1; STR r,[sp]  /  LDR r,[sp]; ADD sp,#1
//    CALL i            MOV r11,#(pc+1); SUB sp,#1; STR r11,[sp]; B i*4
//    RET               LDR r11,[sp]; ADD sp,#1; MOV r11,r11 LSL #2; BX r11
//                      ^^^ the host BARREL SHIFTER rescales the guest
//                      return address into bundle space at runtime
//    Jcc i             B<cond> (relative)   JZ->EQ JNZ->NE JC->CC JNC->CS
//                      JS->MI JNS->PL JO->VS JNO->VC JL->LT JGE->GE
//                      JG->GT JLE->LE
//    LOOP i            SUBS r2,r2,#1 ; BNE  (clobbers host flags, unlike
//                                            the guest LOOP - documented)
//    MOVH r,i          MOV rd, rd LSL #8 ; ORR rd,rd,#i
//    OUT r / HLT       OUT rn / HALT
//
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_interp_x86_to_arm_16(
    // host fetch side: connect to cpu_arm16 imem_addr / imem_data
    input  wire [7:0]  host_addr,
    output reg  [31:0] host_instr,
    // guest program side: connect to the guest binary ROM (64 x 16-bit)
    output wire [5:0]  guest_addr,
    input  wire [15:0] guest_instr,
    // high while feeding HALT for an untranslatable guest instruction
    output reg         trap
);
    // define host_addr    input  255.190.70
    // define host_instr   output 120.200.255
    // define guest_addr   output 255.140.60
    // define guest_instr  input  68.68.242
    // define trap         output 255.80.80

    wire [5:0] gpc  = host_addr[7:2];
    wire [1:0] slot = host_addr[1:0];
    assign guest_addr = gpc;

    // ---- guest field extraction (cpu_x86_16 encoding) -------------------
    wire [3:0] gop  = guest_instr[15:12];
    wire [1:0] r    = guest_instr[11:10];
    wire [1:0] m    = guest_instr[9:8];
    wire [7:0] imm8 = guest_instr[7:0];
    wire [3:0] cond = {r, m};
    wire [3:0] rr   = {2'd0, r};                  // guest reg -> host r0..r3
    wire [3:0] rm   = {2'd0, m};

    // ---- host word builders (cpu_arm16 encoding) -------------------------
    localparam [3:0] AL = 4'd14;
    localparam [31:0] NOPW = 32'hF0000000;        // cond NV: executes never
    function [31:0] dpi;   // data processing, immediate op2
        input [3:0] c, op, d, n; input s; input [7:0] i;
        dpi = {c, s, 2'b01, op, d, n, i, 5'b00000};
    endfunction
    function [31:0] dpr;   // data processing, shifted-register op2
        input [3:0] c, op, d, n, rmf; input s; input [1:0] sht; input [4:0] sha;
        dpr = {c, s, 2'b00, op, d, n, rmf, sht, sha, 2'b00};
    endfunction
    function [31:0] memw;  // LDR/STR rd,[rn+imm8]
        input st; input [3:0] d, n; input [7:0] i;
        memw = {AL, 1'b0, 2'b10, 3'b000, st, d, n, i, 5'b00000};
    endfunction
    function [31:0] flw;   // B / HALT (pc-relative imm17)
        input [3:0] c, op; input [16:0] i;
        flw = {c, 1'b0, 2'b11, op, 4'd0, i};
    endfunction
    function [31:0] flr;   // BX / OUT (register rn)
        input [3:0] c, op, n;
        flr = {c, 1'b0, 2'b11, op, 4'd0, n, 13'd0};
    endfunction

    // pc-relative branch offset: host target = guest_imm8*4
    wire [16:0] rel = {9'd0, imm8, 2'b00} - {9'd0, host_addr};

    // guest Jcc condition -> host cond (CS/CC swapped for carry polarity)
    reg [3:0] hcond; reg cond_ok;
    always @(*) begin
        cond_ok = 1'b1;
        case (cond)
            4'd0:  hcond = 4'd14;  // JMP -> AL
            4'd1:  hcond = 4'd0;   // JZ  -> EQ
            4'd2:  hcond = 4'd1;   // JNZ -> NE
            4'd3:  hcond = 4'd3;   // JC  -> CC  (guest borrow == host !C)
            4'd4:  hcond = 4'd2;   // JNC -> CS
            4'd5:  hcond = 4'd4;   // JS  -> MI
            4'd6:  hcond = 4'd5;   // JNS -> PL
            4'd7:  hcond = 4'd6;   // JO  -> VS
            4'd8:  hcond = 4'd7;   // JNO -> VC
            4'd9:  hcond = 4'd11;  // JL  -> LT
            4'd10: hcond = 4'd10;  // JGE -> GE
            4'd11: hcond = 4'd12;  // JG  -> GT
            4'd12: hcond = 4'd13;  // JLE -> LE
            default: begin hcond = 4'd15; cond_ok = 1'b0; end // LOOP/never
        endcase
    end

    // ---- payload: up to 4 ops per guest instruction ----------------------
    // ps = payload slot index; bundle 0 reserves slot 0 for the preamble
    // (MOV r13,#32), so guest instruction 0 has payload slots 0..2 only.
    wire preamble = (gpc == 6'd0) && (slot == 2'd0);
    wire [1:0] ps = (gpc == 6'd0) ? (slot - 2'd1) : slot;
    wire       g0 = (gpc == 6'd0);

    reg [31:0] pay; reg need4;
    always @(*) begin
        pay = NOPW; need4 = 1'b0;
        case (gop)
            4'h0: if (ps == 2'd0) pay = dpr(AL, 4'd8, rr, 4'd0, rm, 1'b0, 2'd0, 5'd0); // MOV r,m
            4'h1: if (ps == 2'd0) pay = dpi(AL, 4'd8, rr, 4'd0, 1'b0, imm8);           // MOV r,#i
            4'h2: if (ps == 2'd0) pay = dpr(AL, 4'd4, rr, rr, rm, 1'b1, 2'd0, 5'd0);   // ADDS
            4'h3: if (ps == 2'd0) pay = dpr(AL, 4'd2, rr, rr, rm, 1'b1, 2'd0, 5'd0);   // SUBS
            4'h4: if (ps == 2'd0) pay = dpr(AL, 4'd0, rr, rr, rm, 1'b1, 2'd0, 5'd0);   // ANDS
            4'h5: if (ps == 2'd0) pay = dpr(AL, 4'd7, rr, rr, rm, 1'b1, 2'd0, 5'd0);   // ORRS
            4'h6: if (ps == 2'd0) pay = dpr(AL, 4'd1, rr, rr, rm, 1'b1, 2'd0, 5'd0);   // EORS
            4'h7: if (ps == 2'd0) pay = dpr(AL, 4'd12, 4'd0, rr, rm, 1'b1, 2'd0, 5'd0);// CMP
            4'h8: if (ps == 2'd0) case (m)                                              // unary
                2'd0: pay = dpi(AL, 4'd4, rr, rr, 1'b1, 8'd1);          // INC
                2'd1: pay = dpi(AL, 4'd2, rr, rr, 1'b1, 8'd1);          // DEC
                2'd2: pay = dpr(AL, 4'd9, rr, 4'd0, rr, 1'b0, 2'd0, 5'd0); // NOT (no flags)
                2'd3: pay = dpi(AL, 4'd3, rr, rr, 1'b1, 8'd0);          // NEG = RSBS #0
            endcase
            4'h9: if (ps == 2'd0) case (m)                                              // shift by 1
                2'd0: pay = dpr(AL, 4'd8, rr, 4'd0, rr, 1'b1, 2'd0, 5'd1);  // SHL
                2'd1: pay = dpr(AL, 4'd8, rr, 4'd0, rr, 1'b1, 2'd1, 5'd1);  // SHR
                2'd2: pay = dpr(AL, 4'd8, rr, 4'd0, rr, 1'b1, 2'd2, 5'd1);  // SAR
                2'd3: pay = dpr(AL, 4'd8, rr, 4'd0, rr, 1'b1, 2'd3, 5'd15); // ROL
            endcase
            4'hA: case (ps)                                                              // MOV r,[i]
                2'd0: pay = dpi(AL, 4'd8, 4'd11, 4'd0, 1'b0, imm8);
                2'd1: pay = memw(1'b0, rr, 4'd11, 8'd0);
                default: pay = NOPW;
            endcase
            4'hB: case (ps)                                                              // MOV [i],r
                2'd0: pay = dpi(AL, 4'd8, 4'd11, 4'd0, 1'b0, imm8);
                2'd1: pay = memw(1'b1, rr, 4'd11, 8'd0);
                default: pay = NOPW;
            endcase
            4'hC: case (m)
                2'd0: case (ps)                                                          // PUSH
                    2'd0: pay = dpi(AL, 4'd2, 4'd13, 4'd13, 1'b0, 8'd1);
                    2'd1: pay = memw(1'b1, rr, 4'd13, 8'd0);
                    default: pay = NOPW;
                endcase
                2'd1: case (ps)                                                          // POP
                    2'd0: pay = memw(1'b0, rr, 4'd13, 8'd0);
                    2'd1: pay = dpi(AL, 4'd4, 4'd13, 4'd13, 1'b0, 8'd1);
                    default: pay = NOPW;
                endcase
                2'd2: begin need4 = 1'b1; case (ps)                                      // CALL
                    2'd0: pay = dpi(AL, 4'd8, 4'd11, 4'd0, 1'b0, {2'd0, gpc} + 8'd1);
                    2'd1: pay = dpi(AL, 4'd2, 4'd13, 4'd13, 1'b0, 8'd1);
                    2'd2: pay = memw(1'b1, 4'd11, 4'd13, 8'd0);
                    2'd3: pay = flw(AL, 4'd0, rel);
                endcase end
                2'd3: begin need4 = 1'b1; case (ps)                                      // RET
                    2'd0: pay = memw(1'b0, 4'd11, 4'd13, 8'd0);
                    2'd1: pay = dpi(AL, 4'd4, 4'd13, 4'd13, 1'b0, 8'd1);
                    2'd2: pay = dpr(AL, 4'd8, 4'd11, 4'd0, 4'd11, 1'b0, 2'd0, 5'd2);
                    2'd3: pay = flr(AL, 4'd2, 4'd11);                    // BX r11
                endcase end
            endcase
            4'hD: begin                                                                  // Jcc / LOOP
                if (cond == 4'd13) begin                                 // LOOP
                    if (ps == 2'd0) pay = dpi(AL, 4'd2, 4'd2, 4'd2, 1'b1, 8'd1);
                    if (ps == 2'd1) pay = flw(4'd1, 4'd0, rel);          // BNE
                end else if (cond_ok) begin
                    if (ps == 2'd0) pay = flw(hcond, 4'd0, rel);
                end                                                       // 14/15: NOPs
            end
            4'hE: case (ps)                                                              // MOVH
                2'd0: pay = dpr(AL, 4'd8, rr, 4'd0, rr, 1'b0, 2'd0, 5'd8);
                2'd1: pay = dpi(AL, 4'd7, rr, rr, 1'b0, imm8);           // ORR
                default: pay = NOPW;
            endcase
            4'hF: if (ps == 2'd0) case (m)                                               // misc
                2'd1: pay = flw(AL, 4'd4, 17'd0);                        // HLT -> HALT
                2'd2: pay = flr(AL, 4'd3, rr);                           // OUT r
                default: pay = NOPW;                                     // NOP
            endcase
            default: pay = NOPW;
        endcase
    end

    always @(*) begin
        trap = 1'b0;
        if (preamble) begin
            host_instr = dpi(AL, 4'd8, 4'd13, 4'd0, 1'b0, 8'd32);        // r13 = 32
        end else if (g0 && need4) begin
            // a 4-op guest instruction cannot fit beside the preamble
            host_instr = (ps == 2'd0) ? flw(AL, 4'd4, 17'd0) : NOPW;     // trap
            trap = (ps == 2'd0);
        end else begin
            host_instr = pay;
        end
    end
endmodule


