// =====================================================================
//  demo_dice_roller.v
//  Demo: LFSR-based dice roller (faces 1-6).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_dice_roller(input clk, input rst, input roll, output reg [2:0] face);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define roll input 255.180.80
    // define face output 120.255.160
    reg [3:0] lfsr;
    wire fb = lfsr[3]^lfsr[2];
    always @(posedge clk) begin
        if (rst) begin lfsr<=4'b1; face<=3'd1; end
        else begin lfsr<={lfsr[2:0],fb};
            if (roll) begin
                // map 4-bit lfsr to 1..6
                if (lfsr[2:0]==3'd0 || lfsr[2:0] > 3'd6) face<=3'd1; else face<=lfsr[2:0];
            end
        end
    end
endmodule


