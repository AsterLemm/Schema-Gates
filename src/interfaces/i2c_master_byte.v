// =====================================================================
//  i2c_master_byte.v
//  Simplified I2C master byte writer (educational).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module i2c_master_byte(input clk, input rst, input start, input [7:0] data, 
    output reg scl, output reg sda, output reg busy, output reg done);
    // define clk input 255.230.80   // define start input 255.180.80   // define data input 80.160.255   // define done output 255.255.255
    // Simplified I2C byte writer: START, 8 data bits MSB-first, then stop. (Open-drain modeled push-pull.)
    reg [4:0] state; reg [7:0] sh;
    always @(posedge clk) begin
        if (rst) begin state<=0; scl<=1; sda<=1; busy<=0; done<=0; end
        else begin done<=0;
            case (state)
                0: if (start) begin sh<=data; sda<=0; busy<=1; state<=1; end else busy<=0;  // START: sda 1->0 while scl high
                default: begin
                    if (state<=16) begin
                        if (state[0]) begin scl<=0; sda<=sh[7]; sh<={sh[6:0],1'b0}; end
                        else scl<=1;
                        state<=state+1;
                    end else begin scl<=1; sda<=1; busy<=0; done<=1; state<=0; end  // STOP
                end
            endcase
        end
    end
endmodule


