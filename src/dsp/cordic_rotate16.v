// =====================================================================
//  cordic_rotate16.v
//  16-bit iterative CORDIC rotator (12 iterations).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module cordic_rotate16(input clk, input rst, input start, input signed [15:0] x0, input signed [15:0] y0, input signed [15:0] angle,
    output reg signed [15:0] x_out, output reg signed [15:0] y_out, output reg done);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define start input 255.180.80
    // Iterative CORDIC rotation mode (16-bit, 12 iterations).
    reg signed [15:0] x, y, z; reg [3:0] i; reg busy;
    reg signed [15:0] atan [0:11];
    initial begin
        atan[0]=16'sd12867; atan[1]=16'sd7596; atan[2]=16'sd4014; atan[3]=16'sd2037;
        atan[4]=16'sd1023;  atan[5]=16'sd512;  atan[6]=16'sd256;  atan[7]=16'sd128;
        atan[8]=16'sd64;    atan[9]=16'sd32;   atan[10]=16'sd16;  atan[11]=16'sd8;
    end
    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; end
        else if (start) begin x<=x0; y<=y0; z<=angle; i<=0; busy<=1; done<=0; end
        else if (busy) begin
            if (i==12) begin busy<=0; done<=1; x_out<=x; y_out<=y; end
            else begin
                if (z[15]==1'b0) begin x<=x-(y>>>i); y<=y+(x>>>i); z<=z-atan[i]; end
                else begin x<=x+(y>>>i); y<=y-(x>>>i); z<=z+atan[i]; end
                i<=i+1;
            end
        end else done<=0;
    end
endmodule


