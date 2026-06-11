// =====================================================================
//  uart_tx8.v
//  UART transmitter, 8N1, baud-tick enabled.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module uart_tx8(input clk, input rst, input tick, input start, input [7:0] data, output reg tx, output reg busy);
    // define clk input 255.230.80   // define rst input 255.80.80   // define tick input 255.180.80
    // define start input 255.180.80   // define data input 80.160.255   // define tx output 120.255.160   // define busy output 255.255.255
    // 8N1 UART transmit: idle high, 1 start bit (0), 8 data LSB-first, 1 stop (1). 'tick' = baud enable.
    reg [3:0] state; reg [7:0] shifter;
    localparam IDLE=0, START=1, D0=2, STOP=10;
    always @(posedge clk) begin
        if (rst) begin tx<=1'b1; busy<=0; state<=IDLE; end
        else begin
            case (state)
                IDLE: begin tx<=1'b1; if (start) begin shifter<=data; busy<=1; state<=START; end else busy<=0; end
                default: if (tick) begin
                    if (state==START) begin tx<=1'b0; state<=D0; end
                    else if (state>=D0 && state<STOP) begin tx<=shifter[0]; shifter<={1'b0,shifter[7:1]}; state<=state+1; end
                    else if (state==STOP) begin tx<=1'b1; state<=IDLE; busy<=0; end
                end
            endcase
        end
    end
endmodule


