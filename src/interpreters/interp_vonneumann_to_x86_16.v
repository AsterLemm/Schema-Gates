// =====================================================================
//  interp_vonneumann_to_x86_16.v
//  CROSS-ISA INTERPRETER: runs cpu_vonneumann16 binaries on cpu_x86_16.
//
//  Sits on the HOST's instruction-fetch port and BYPASSES its control
//  unit entirely: the host CPU keeps decoding its native x86 ISA; this
//  block translates each fetched address into the right native
//  instruction on the fly. No change to either CPU.
//
//      +-----------+  host_addr   +--------------------+  guest_addr
//      | cpu_x86_16|------------->| interp_vonneumann_ |------------+
//      |   (HOST)  |<-------------|     to_x86_16      |<--------+  |
//      +-----------+  host_instr  +--------------------+  guest  |  |
//                                                       _instr +-+--v-+
//                                                              |GUEST |
//                                                              | ROM  |
//                                                              +------+
//
//  SCHEME: fixed 2-instruction bundles. host_pc = {guest_pc[3:0], slot}.
//  The translator is PURELY COMBINATIONAL - in the schematic it is one
//  decode fan-out, and you can watch each guest opcode light its bundle.
//
//  STATE MAPPING
//    guest acc        -> host AX
//    guest mem[0..15] -> host RAM[0..15]   (absolute MOV r,[imm]/[imm],r)
//    guest carry      -> host CF  (same polarity: SUB carry = borrow,
//                                  SHL/SHR carry = bit shifted out)
//    guest "acc==0"   -> host ZF  (LDA/LDI bundles append OR AX,AX so the
//                                  zero flag always tracks the accumulator)
//    scratch          -> host BX
//
//  BUNDLES (slot 0, slot 1)
//    NOP            NOP            , NOP
//    LDA m          MOV AX,[m]     , OR AX,AX      (refresh ZF)
//    STA m          MOV [m],AX     , NOP
//    ADD m          MOV BX,[m]     , ADD AX,BX
//    SUB m          MOV BX,[m]     , SUB AX,BX
//    AND/OR/XOR m   MOV BX,[m]     , AND/OR/XOR AX,BX
//    LDI i          MOV AX,#i      , OR AX,AX      (refresh ZF)
//    JMP a          JMP {a,0}      , NOP
//    JZ  a          JZ  {a,0}      , NOP
//    JC  a          JC  {a,0}      , NOP
//    SHL / SHR      SHL/SHR AX     , NOP
//    OUT            OUT AX         , NOP
//    HLT            HLT            , HLT
//
//  CAVEATS (documented, by design)
//   * Guest data must be ESTABLISHED BY CODE (LDI/STA): the host data RAM
//     is internal and starts empty, so preloaded guest data images do not
//     carry across. (True of every interpreter in this family.)
//   * The ZF-refresh OR clears the host CF, so JC must follow its
//     arithmetic op without an intervening LDA/LDI (the overwhelmingly
//     common pattern, e.g. ADD; JC).
//
//  trap is tied low: every guest opcode translates (full ISA coverage).
//
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module interp_vonneumann_to_x86_16(
    // host fetch side: connect to cpu_x86_16 imem_addr / imem_data
    input  wire [7:0]  host_addr,
    output reg  [15:0] host_instr,
    // guest program side: connect to the guest binary ROM (16x16)
    output wire [3:0]  guest_addr,
    input  wire [15:0] guest_instr,
    // high while feeding HLT for an untranslatable guest op (never here)
    output wire        trap
);
    // define host_addr    input  255.190.70
    // define host_instr   output 120.200.255
    // define guest_addr   output 255.140.60
    // define guest_instr  input  68.68.242
    // define trap         output 255.80.80

    wire [3:0] gpc  = host_addr[4:1];
    wire       slot = host_addr[0];
    assign guest_addr = gpc;
    assign trap = 1'b0;

    wire [3:0] gop = guest_instr[15:12];
    wire [3:0] m   = guest_instr[3:0];

    // host opcodes used (cpu_x86_16 encoding [15:12]op [11:10]r [9:8]m [7:0]imm8)
    localparam [15:0] H_NOP = 16'hF000;
    localparam [15:0] H_HLT = 16'hF100;

    always @(*) begin
        case (gop)
            4'h0: host_instr = H_NOP;                                  // NOP
            4'h1: host_instr = slot ? 16'h5000                         // OR AX,AX
                                    : (16'hA000 | {12'd0, m});         // MOV AX,[m]
            4'h2: host_instr = slot ? H_NOP
                                    : (16'hB000 | {12'd0, m});         // MOV [m],AX
            4'h3: host_instr = slot ? 16'h2100                         // ADD AX,BX
                                    : (16'hA400 | {12'd0, m});         // MOV BX,[m]
            4'h4: host_instr = slot ? 16'h3100                         // SUB AX,BX
                                    : (16'hA400 | {12'd0, m});
            4'h5: host_instr = slot ? 16'h4100                         // AND AX,BX
                                    : (16'hA400 | {12'd0, m});
            4'h6: host_instr = slot ? 16'h5100                         // OR  AX,BX
                                    : (16'hA400 | {12'd0, m});
            4'h7: host_instr = slot ? 16'h6100                         // XOR AX,BX
                                    : (16'hA400 | {12'd0, m});
            4'h8: host_instr = slot ? 16'h5000                         // OR AX,AX
                                    : (16'h1000 | {12'd0, m});         // MOV AX,#i
            4'h9: host_instr = slot ? H_NOP
                                    : (16'hD000 | {8'd0, m, 1'b0});    // JMP {a,0}
            4'hA: host_instr = slot ? H_NOP
                                    : (16'hD100 | {8'd0, m, 1'b0});    // JZ  {a,0}
            4'hB: host_instr = slot ? H_NOP
                                    : (16'hD300 | {8'd0, m, 1'b0});    // JC  {a,0}
            4'hC: host_instr = slot ? H_NOP : 16'h9000;                // SHL AX
            4'hD: host_instr = slot ? H_NOP : 16'h9100;                // SHR AX
            4'hE: host_instr = slot ? H_NOP : 16'hF200;                // OUT AX
            default: host_instr = H_HLT;                               // HLT
        endcase
    end
endmodule


