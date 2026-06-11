// =====================================================================
//  uart_rx8.v
//  UART receiver, 8N1.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module uart_rx8(input clk, input rst, input tick, input rx, output reg [7:0] data, output reg valid);
    // define clk input 255.230.80   // define rst input 255.80.80   // define tick input 255.180.80
    // define rx input 80.160.255   // define data output 120.255.160   // define valid output 255.255.255
    // 8N1 UART receive (oversampling assumed folded into 'tick').
    reg [3:0] state; reg [7:0] shifter; localparam IDLE=0,D0=1,STOP=9;
    always @(posedge clk) begin
        if (rst) begin state<=IDLE; valid<=0; end
        else begin valid<=0;
            case (state)
                IDLE: if (!rx) state<=D0;   // start bit detected; sample data on following ticks
                default: if (tick) begin
                    if (state>=D0 && state<STOP) begin shifter<={rx,shifter[7:1]}; state<=state+1; end
                    else if (state==STOP) begin data<=shifter; valid<=1; state<=IDLE; end
                end
            endcase
        end
    end
endmodule


