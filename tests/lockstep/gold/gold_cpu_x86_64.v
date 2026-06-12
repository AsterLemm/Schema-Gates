// =====================================================================
//  cpu_x86_64.v
//  64-bit x86-FLAVOURED CISC CPU (two-operand destructive ISA).
//  AX/BX/CX/DX + FLAGS(CF ZF SF OF) + SP, descending stack in a
//  32-word unified data/stack RAM. Authentic flag quirks kept:
//  INC/DEC preserve CF, NOT touches no flags, LOOP uses CX.
//  16-bit Harvard instructions on imem_*. See docs/cpus.md.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_cpu_x86_64(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [15:0] imem_data,
    // OUT instruction port
    output reg  [63:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    input  wire [2:0]  dbg_sel,      // 0..3 AX..DX, 4 SP, 5 FLAGS, 6 PC
    output wire [63:0]  dbg_data,
    output wire [7:0]  dbg_pc
);
    // define clk                    input   255.230.80
    // define rst                    input   255.80.80
    // define imem_addr              output  38.15.153
    // define imem_data              input   126.199.90
    // define out_data               output  120.255.160
    // define out_valid              output  97.255.239
    // define halted                 output  255.120.120
    // define dbg_sel                input   200.120.255
    // define dbg_data               output  178.54.0
    // define dbg_pc                 output  255.0.26

    reg [7:0] pc;
    reg [63:0] regs [0:3];      // 0 AX, 1 BX, 2 CX, 3 DX
    reg [63:0] ram  [0:31];     // unified data + descending stack
    reg [5:0] sp;                  // stack pointer (init 32 = empty)
    reg cf, zf, sf, vf;            // FLAGS: carry zero sign overflow

    wire [3:0] op   = imem_data[15:12];
    wire [1:0] rsel = imem_data[11:10];
    wire [1:0] msel = imem_data[9:8];
    wire [7:0] imm8 = imem_data[7:0];
    wire [3:0] cond = {rsel, msel};

    wire [63:0] rv = regs[rsel];   // destination operand (read)
    wire [63:0] mv = regs[msel];   // source operand

    // ---- class decode -------------------------------------------------
    wire is_movrr = (op == 4'h0);
    wire is_movi  = (op == 4'h1);
    wire is_add   = (op == 4'h2);
    wire is_sub   = (op == 4'h3);
    wire is_and   = (op == 4'h4);
    wire is_or    = (op == 4'h5);
    wire is_xor   = (op == 4'h6);
    wire is_cmp   = (op == 4'h7);
    wire is_unary = (op == 4'h8);
    wire is_shift = (op == 4'h9);
    wire is_load  = (op == 4'hA);
    wire is_store = (op == 4'hB);
    wire is_stk   = (op == 4'hC);
    wire is_jcc   = (op == 4'hD);
    wire is_movh  = (op == 4'hE);
    wire is_misc  = (op == 4'hF);

    wire is_push = is_stk & (msel == 2'd0);
    wire is_pop  = is_stk & (msel == 2'd1);
    wire is_call = is_stk & (msel == 2'd2);
    wire is_ret  = is_stk & (msel == 2'd3);
    wire is_hlt  = is_misc & (msel == 2'd1);
    wire is_out  = is_misc & (msel == 2'd2);
    wire is_loop = is_jcc & (cond == 4'd13);

    // ---- ALU (operand-isolated paths, flagship style) -----------------
    wire sel_arith = is_add | is_sub | is_cmp
                   | (is_unary & (msel != 2'd2));   // INC DEC NEG
    wire sel_logic = is_and | is_or | is_xor | (is_unary & (msel == 2'd2));
    wire sel_shift = is_shift;

    // arithmetic path: y = a +/- b (+carry chain view for CF/OF)
    wire [63:0] ar_a = (is_unary ? ((msel == 2'd3) ? {64{1'b0}} : rv) : rv)
                        & {64{sel_arith}};
    wire [63:0] ar_b = (is_unary ? ((msel == 2'd3) ? rv : {{63{1'b0}}, 1'b1}) : mv)
                        & {64{sel_arith}};
    wire ar_subop = is_sub | is_cmp
                  | (is_unary & ((msel == 2'd1) | (msel == 2'd3))); // DEC NEG
    wire [64:0] ar_full = ar_subop ? ({1'b0, ar_a} - {1'b0, ar_b})
                                    : ({1'b0, ar_a} + {1'b0, ar_b});
    wire [63:0] ar_y = ar_full[63:0];
    wire ar_c = ar_full[64];                       // carry / borrow
    wire ar_v = ar_subop ? ((ar_a[63] != ar_b[63]) & (ar_y[63] != ar_a[63]))
                         : ((ar_a[63] == ar_b[63]) & (ar_y[63] != ar_a[63]));

    // logic path
    wire [63:0] lg_a = rv & {64{sel_logic}};
    wire [63:0] lg_b = mv & {64{sel_logic}};
    wire [63:0] lg_y = is_and ? (lg_a & lg_b)
                        : is_or  ? (lg_a | lg_b)
                        : is_xor ? (lg_a ^ lg_b)
                        :          (~lg_a);          // NOT

    // shift path (single position, x86 flag semantics)
    wire [63:0] sh_a = rv & {64{sel_shift}};
    wire [63:0] sh_y = (msel == 2'd0) ? {sh_a[62:0], 1'b0}        // SHL
                        : (msel == 2'd1) ? {1'b0, sh_a[63:1]}        // SHR
                        : (msel == 2'd2) ? {sh_a[63], sh_a[63:1]}    // SAR
                        :                  {sh_a[62:0], sh_a[63]};   // ROL
    wire sh_c = (msel == 2'd0) ? sh_a[63]
              : (msel == 2'd3) ? sh_a[63]
              :                  sh_a[0];
    wire sh_v = (msel == 2'd0) ? (sh_y[63] ^ sh_c)    // SHL: OF = CF^MSB(result)
              : (msel == 2'd1) ? sh_a[63]             // SHR: OF = old MSB
              : (msel == 2'd3) ? (sh_y[63] ^ sh_c)    // ROL
              :                  1'b0;                // SAR: OF = 0

    // ---- condition evaluation (x86 Jcc table) -------------------------
    reg ctaken;
    always @(*) begin case (cond)
        4'd0:  ctaken = 1'b1;            // JMP
        4'd1:  ctaken = zf;              // JZ
        4'd2:  ctaken = ~zf;             // JNZ
        4'd3:  ctaken = cf;              // JC
        4'd4:  ctaken = ~cf;             // JNC
        4'd5:  ctaken = sf;              // JS
        4'd6:  ctaken = ~sf;             // JNS
        4'd7:  ctaken = vf;              // JO
        4'd8:  ctaken = ~vf;             // JNO
        4'd9:  ctaken = sf ^ vf;         // JL  (signed <)
        4'd10: ctaken = ~(sf ^ vf);      // JGE
        4'd11: ctaken = ~zf & ~(sf ^ vf);// JG
        4'd12: ctaken = zf | (sf ^ vf);  // JLE
        4'd13: ctaken = (regs[2] != {64{1'b0}});  // LOOP looks at CX-1... see EXEC
        default: ctaken = 1'b0;          // 14/15 never
    endcase end

    wire [63:0] cx_dec = regs[2] - {{63{1'b0}}, 1'b1};
    wire loop_take = (cx_dec != {64{1'b0}});

    wire [63:0] stk_top = ram[sp[4:0]];
    wire [7:0] pc1w = pc + 8'd1;       // return address (CALL)

    assign imem_addr = pc;
    assign dbg_pc    = pc;
    assign dbg_data  = (dbg_sel < 3'd4) ? regs[dbg_sel[1:0]]
                     : (dbg_sel == 3'd4) ? {{58{1'b0}}, sp}
                     : (dbg_sel == 3'd5) ? {{60{1'b0}}, {vf, sf, zf, cf}}
                     :                    {{56{1'b0}}, pc};

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; sp <= 6'd32; halted <= 1'b0;
            cf <= 1'b0; zf <= 1'b0; sf <= 1'b0; vf <= 1'b0;
            out_data <= {64{1'b0}};
            regs[0] <= {64{1'b0}}; regs[1] <= {64{1'b0}};
            regs[2] <= {64{1'b0}}; regs[3] <= {64{1'b0}};
        end else if (!halted) begin
            pc <= pc + 8'd1;            // default; flow ops override
            case (op)
                4'h0: regs[rsel] <= mv;                       // MOV r,m
                4'h1: regs[rsel] <= {{56{1'b0}}, imm8};         // MOV r,imm8
                4'h2, 4'h3: begin                              // ADD SUB
                    regs[rsel] <= ar_y;
                    cf <= ar_c; zf <= (ar_y == {64{1'b0}});
                    sf <= ar_y[63]; vf <= ar_v;
                end
                4'h4, 4'h5, 4'h6: begin                        // AND OR XOR
                    regs[rsel] <= lg_y;
                    cf <= 1'b0; vf <= 1'b0;                    // x86: logic clears CF/OF
                    zf <= (lg_y == {64{1'b0}}); sf <= lg_y[63];
                end
                4'h7: begin                                    // CMP (flags only)
                    cf <= ar_c; zf <= (ar_y == {64{1'b0}});
                    sf <= ar_y[63]; vf <= ar_v;
                end
                4'h8: case (msel)                              // unary
                    2'd0, 2'd1: begin                          // INC DEC
                        regs[rsel] <= ar_y;                    // CF PRESERVED (x86 quirk)
                        zf <= (ar_y == {64{1'b0}}); sf <= ar_y[63]; vf <= ar_v;
                    end
                    2'd2: regs[rsel] <= lg_y;                  // NOT: no flags (x86 quirk)
                    2'd3: begin                                // NEG = 0 - r
                        regs[rsel] <= ar_y;
                        cf <= (rv != {64{1'b0}});            // x86: CF=0 only if src was 0
                        zf <= (ar_y == {64{1'b0}}); sf <= ar_y[63]; vf <= ar_v;
                    end
                endcase
                4'h9: begin                                    // shifts by 1
                    regs[rsel] <= sh_y;
                    cf <= sh_c; vf <= sh_v;
                    if (msel != 2'd3) begin                    // ROL: ZF/SF untouched
                        zf <= (sh_y == {64{1'b0}}); sf <= sh_y[63];
                    end
                end
                4'hA: regs[rsel] <= ram[imm8[4:0]];            // MOV r,[imm8]
                4'hB: ram[imm8[4:0]] <= rv;                    // MOV [imm8],r
                4'hC: case (msel)
                    2'd0: begin ram[sp[4:0] - 5'd1] <= rv; sp <= sp - 6'd1; end // PUSH
                    2'd1: begin regs[rsel] <= stk_top; sp <= sp + 6'd1; end     // POP
                    2'd2: begin                                                 // CALL
                        ram[sp[4:0] - 5'd1] <= {{56{1'b0}}, pc1w};
                        sp <= sp - 6'd1; pc <= imm8;
                    end
                    2'd3: begin pc <= stk_top[7:0]; sp <= sp + 6'd1; end // RET
                endcase
                4'hD: begin                                    // Jcc / LOOP
                    if (is_loop) begin
                        regs[2] <= cx_dec;                     // CX-- (no flags)
                        if (loop_take) pc <= imm8;
                    end else if (ctaken) pc <= imm8;
                end
                4'hE: regs[rsel] <= {rv[55:0], imm8};     // MOVH (shift-in byte)
                4'hF: case (msel)
                    2'd1: begin halted <= 1'b1; pc <= pc; end      // HLT
                    2'd2: begin out_data <= rv; out_valid <= 1'b1; end // OUT
                    default: ;                                     // NOP
                endcase
                default: ;
            endcase
        end
    end
endmodule


