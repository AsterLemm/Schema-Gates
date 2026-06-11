// =====================================================================
//  interp_arm_to_x86_16.v
//  CROSS-ISA INTERPRETER: runs cpu_arm16 binaries on cpu_x86_16.
//
//  Sits on the HOST's instruction-fetch port and BYPASSES its control
//  unit: the x86 host keeps decoding native x86; this block expands each
//  ARM instruction into a fixed 8-instruction native bundle on the fly.
//  Purely combinational - host_pc = {guest_pc[4:0], slot[2:0]}, so a
//  guest program of up to 32 instructions runs unmodified.
//
//  STATE MAPPING
//    guest r0..r15     -> host RAM[16..31]  (memory-mapped register file;
//                                            host RAM[0..15] stays free)
//    guest NZCV        -> host SF/ZF/CF/OF after each arith/logic op.
//                         CARRY POLARITY differs (ARM C = NOT borrow,
//                         x86 CF = borrow): handled by swapping JC/JNC in
//                         the condition guards, never by extra ops.
//    scratch           -> host AX (working value), BX (operand 2)
//
//  BUNDLE LAYOUT (slots 0..7); slot 7 is ALWAYS a NOP landing pad
//    0,1  CONDITION GUARD: a host Jcc on the INVERSE guest condition
//         jumps to slot 7, skipping the body -- ARM's "every instruction
//         is conditional" rebuilt from x86 conditional jumps. HI and LS
//         (which x86 cannot test in one jump) use both slots.
//    2    load AX  <- RAM[16+rn]            (or #imm for RSB-immediate)
//    3    load BX  <- RAM[16+rm] / #imm8
//    4    pre-op   NOT BX (MVN, BIC)  /  OR AX,AX (flag fix for MOVS)
//    5    ALU      ADD/SUB/AND/OR/XOR/CMP AX,BX  /  MOV AX,BX
//    6    writeback RAM[16+rd] <- AX         (omitted for CMP/CMN/TST/TEQ)
//    7    NOP      (guard target)
//
//  OP TRANSLATION
//    AND->AND  EOR->XOR  SUB->SUB  RSB->SUB(operands pre-swapped)
//    ADD->ADD  ORR->OR   MOV->MOV  MVN->NOT BX;MOV  BIC->NOT BX;AND
//    CMP->CMP  CMN->ADD(no WB)  TST->AND(no WB)  TEQ->XOR(no WB)
//    B  -> JMP target*8        BL -> MOV AX,#(pc+1); MOV [30],AX; JMP
//    OUT rn -> MOV AX,[16+rn]; OUT AX          HALT -> HLT
//
//  TRAPS (host fed HLT, trap output high) - each is a real architectural
//  lesson about what the host LACKS:
//    * shifted register operands (shamt != 0)  - x86_16 has no barrel
//      shifter (only shift-by-1 instructions)
//    * ADC / SBC                               - host ALU has no carry-in
//    * LDR / STR                               - host has no base+offset
//      addressing (absolute [imm] only); keep guest data in r4..r12
//    * BX                                      - host has no indirect jump
//
//  FLAG CAVEATS: the host updates flags on every arith/logic op, so an
//  S=0 guest data op still refreshes them (sequence S-dependent code
//  accordingly); MOVS gets Z/N via an OR AX,AX fix-up which clears CF.
//
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module interp_arm_to_x86_16(
    // host fetch side: connect to cpu_x86_16 imem_addr / imem_data
    input  wire [7:0]  host_addr,
    output reg  [15:0] host_instr,
    // guest program side: connect to the guest binary ROM (32 x 32-bit)
    output wire [4:0]  guest_addr,
    input  wire [31:0] guest_instr,
    // high while feeding HLT for an untranslatable guest instruction
    output reg         trap
);
    // define host_addr    input  255.190.70
    // define host_instr   output 120.200.255
    // define guest_addr   output 255.140.60
    // define guest_instr  input  68.68.242
    // define trap         output 255.80.80

    wire [4:0] gpc  = host_addr[7:3];
    wire [2:0] slot = host_addr[2:0];
    assign guest_addr = gpc;

    // ---- guest field extraction (cpu_arm16 encoding) -------------------
    wire [3:0]  cond  = guest_instr[31:28];
    wire        sbit  = guest_instr[27];
    wire [1:0]  cls   = guest_instr[26:25];
    wire [3:0]  op4   = guest_instr[24:21];
    wire [3:0]  rd    = guest_instr[20:17];
    wire [3:0]  rn    = guest_instr[16:13];
    wire [3:0]  rm    = guest_instr[12:9];
    wire [1:0]  shtyp = guest_instr[8:7];
    wire [4:0]  shamt = guest_instr[6:2];
    wire [7:0]  imm8  = guest_instr[12:5];
    wire [16:0] imm17 = guest_instr[16:0];

    wire is_dp   = (cls[1] == 1'b0);
    wire is_imm  = (cls == 2'b01);
    wire is_mem  = (cls == 2'b10);
    wire is_flow = (cls == 2'b11);
    wire is_test = is_dp && (op4 >= 4'd12);          // CMP CMN TST TEQ
    wire is_mov  = is_dp && ((op4 == 4'd8) || (op4 == 4'd11));
    wire is_mvn  = is_dp && (op4 == 4'd9);
    wire is_bic  = is_dp && (op4 == 4'd10);
    wire is_rsb  = is_dp && (op4 == 4'd3);
    wire bad_sh  = is_dp && (cls == 2'b00) && ((shtyp != 2'd0) || (shamt != 5'd0));
    wire bad_op  = is_dp && ((op4 == 4'd5) || (op4 == 4'd6)); // ADC SBC

    // ---- bundle landmarks ----------------------------------------------
    wire [7:0] b_end  = {gpc, 3'd7};                 // guard skip target
    wire [7:0] b_cont = {gpc, 3'd2};                 // LS guard continue

    // host helpers (cpu_x86_16 encoding)
    localparam [15:0] H_NOP = 16'hF000;
    localparam [15:0] H_HLT = 16'hF100;
    function [15:0] h_jcc;            // Jcc <cond> to absolute target
        input [3:0] cc; input [7:0] tgt;
        h_jcc = {4'hD, cc, tgt};
    endfunction
    function [15:0] h_ldax;  input [4:0] a; h_ldax = {4'hA, 2'd0, 2'd0, 3'd0, a}; endfunction
    function [15:0] h_ldbx;  input [4:0] a; h_ldbx = {4'hA, 2'd1, 2'd0, 3'd0, a}; endfunction
    function [15:0] h_stax;  input [4:0] a; h_stax = {4'hB, 2'd0, 2'd0, 3'd0, a}; endfunction
    function [15:0] h_movi;  input [7:0] i; h_movi = {4'h1, 2'd0, 2'd0, i};       endfunction

    // inverse-condition guard: host Jcc code that SKIPS when the guest
    // condition is FALSE (note the CS/CC swap for carry polarity)
    reg [3:0] inv_cc; reg guard_simple;
    always @(*) begin
        guard_simple = 1'b1;
        case (cond)
            4'd0:  inv_cc = 4'd2;    // EQ : skip on JNZ
            4'd1:  inv_cc = 4'd1;    // NE : skip on JZ
            4'd2:  inv_cc = 4'd3;    // CS : guest C ~ host !CF -> skip on JC
            4'd3:  inv_cc = 4'd4;    // CC : skip on JNC
            4'd4:  inv_cc = 4'd6;    // MI : skip on JNS
            4'd5:  inv_cc = 4'd5;    // PL : skip on JS
            4'd6:  inv_cc = 4'd8;    // VS : skip on JNO
            4'd7:  inv_cc = 4'd7;    // VC : skip on JO
            4'd10: inv_cc = 4'd9;    // GE : skip on JL
            4'd11: inv_cc = 4'd10;   // LT : skip on JGE
            4'd12: inv_cc = 4'd12;   // GT : skip on JLE
            4'd13: inv_cc = 4'd11;   // LE : skip on JG
            default: begin inv_cc = 4'd0; guard_simple = 1'b0; end // AL NV HI LS
        endcase
    end

    // ---- the ALU bundle body (slots 2..6) --------------------------------
    reg [15:0] body;
    always @(*) begin
        body = H_NOP;
        case (slot)
            3'd2: body = is_rsb ? (is_imm ? h_movi(imm8) : h_ldax({1'b1, rm}))
                 : (is_mov | is_mvn) ? H_NOP
                 :                     h_ldax({1'b1, rn});
            3'd3: body = is_rsb ? h_ldbx({1'b1, rn})
                 : is_imm       ? {4'h1, 2'd1, 2'd0, imm8}      // MOV BX,#imm
                 :                h_ldbx({1'b1, rm});
            3'd4: body = (is_mvn | is_bic) ? 16'h8600           // NOT BX
                 : (is_mov & sbit)         ? 16'h0100           // MOV AX,BX early
                 :                           H_NOP;
            3'd5: begin
                case (op4)
                    4'd0, 4'd14: body = 16'h4100;               // AND  / TST
                    4'd1, 4'd15: body = 16'h6100;               // XOR  / TEQ
                    4'd2, 4'd3:  body = 16'h3100;               // SUB  / RSB
                    4'd4, 4'd13: body = 16'h2100;               // ADD  / CMN
                    4'd7:        body = 16'h5100;               // OR
                    4'd10:       body = 16'h4100;               // BIC (BX pre-NOTed)
                    4'd12:       body = 16'h7100;               // CMP
                    default:     body = (is_mov & sbit) ? 16'h5000  // OR AX,AX: Z/N
                                                        : 16'h0100; // MOV AX,BX
                endcase
            end
            3'd6: body = is_test ? H_NOP : h_stax({1'b1, rd});
            default: body = H_NOP;
        endcase
        // (MVNS Z/N follow the next flag-writing host op - documented caveat)
    end

    // ---- flow bundle body -------------------------------------------------
    wire [4:0] b_tgt = gpc + imm17[4:0];                  // word-relative
    reg [15:0] fbody;
    always @(*) begin
        fbody = H_NOP;
        case (op4)
            4'd0: if (slot == 3'd2) fbody = h_jcc(4'd0, {b_tgt, 3'd0});   // B
            4'd1: case (slot)                                              // BL
                3'd2: fbody = h_movi({3'd0, gpc} + 8'd1);
                3'd3: fbody = h_stax(5'd30);                               // r14
                3'd4: fbody = h_jcc(4'd0, {b_tgt, 3'd0});
                default: fbody = H_NOP;
            endcase
            4'd3: case (slot)                                              // OUT rn
                3'd2: fbody = h_ldax({1'b1, rn});
                3'd3: fbody = 16'hF200;
                default: fbody = H_NOP;
            endcase
            4'd4: if (slot == 3'd2) fbody = H_HLT;                         // HALT
            default: if (slot == 3'd2) fbody = H_HLT;                      // BX -> trap
        endcase
    end

    // ---- final mux ----------------------------------------------------------
    wire body_trap = bad_sh | bad_op | is_mem | (is_flow && (op4 == 4'd2));

    always @(*) begin
        trap = 1'b0;
        if (slot == 3'd7) begin
            host_instr = H_NOP;                          // landing pad
        end else if (slot <= 3'd1) begin
            // ---- condition guard ----
            host_instr = H_NOP;
            case (cond)
                4'd14: host_instr = H_NOP;                                   // AL
                4'd15: if (slot == 3'd0) host_instr = h_jcc(4'd0, b_end);    // NV
                4'd8:  host_instr = (slot == 3'd0) ? h_jcc(4'd3, b_end)      // HI:
                                                   : h_jcc(4'd1, b_end);     //  CF|ZF skips
                4'd9:  host_instr = (slot == 3'd0) ? h_jcc(4'd3, b_cont)     // LS:
                                                   : h_jcc(4'd2, b_end);     //  !CF&!ZF skips
                default: if (slot == 3'd0) host_instr = h_jcc(inv_cc, b_end);
            endcase
        end else if (body_trap) begin
            host_instr = (slot == 3'd2) ? H_HLT : H_NOP;
            trap = (slot == 3'd2);
        end else if (is_flow) begin
            host_instr = fbody;
        end else begin
            host_instr = body;                           // data processing
        end
    end
endmodule


