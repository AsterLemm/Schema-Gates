// =====================================================================
//  handshake_sync.v
//  4-phase req/ack handshake synchronizer.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module handshake_sync(input clk, input rst, input req, output reg ack, output reg data_taken);
    // define clk input 255.230.80   // define req input 255.180.80   // define ack output 120.255.160
    // 4-phase req/ack handshake receiver.
    reg state;
    always @(posedge clk) begin
        if (rst) begin ack<=0; data_taken<=0; state<=0; end
        else begin data_taken<=0;
            case (state)
                0: if (req) begin ack<=1; data_taken<=1; state<=1; end
                1: if (!req) begin ack<=0; state<=0; end
            endcase
        end
    end
endmodule


