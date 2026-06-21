// =====================================================================
//  demo_traffic_light.v
//  Demo: traffic-light FSM (green/yellow/red).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_traffic_light(input clk, input rst, output reg [2:0] lights);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define lights output 120.255.160
    // lights = {red, yellow, green}
    reg [1:0] state; reg [3:0] timer;
    localparam GREEN=0, YELLOW=1, RED=2;
    always @(posedge clk) begin
        if (rst) begin state<=GREEN; timer<=0; end
        else begin timer<=timer+1'b1;
            case (state)
                GREEN:  if (timer==4'd9) begin state<=YELLOW; timer<=0; end
                YELLOW: if (timer==4'd3) begin state<=RED;    timer<=0; end
                RED:    if (timer==4'd9) begin state<=GREEN;  timer<=0; end
            endcase
        end
    end
    always @(*) case(state)
        GREEN:  lights=3'b001;
        YELLOW: lights=3'b010;
        RED:    lights=3'b100;
        default:lights=3'b100;
    endcase
endmodule


