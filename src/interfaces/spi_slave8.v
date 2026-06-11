// =====================================================================
//  spi_slave8.v
//  SPI slave, mode 0, 8-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module spi_slave8(input clk, input rst, input sclk, input mosi, input cs_n, input [7:0] tx_data,
    output miso, output reg [7:0] rx_data, output reg done);
    // define clk input 255.230.80   // define sclk input 255.180.80   // define mosi input 80.160.255   // define rx_data output 120.255.160
    reg [7:0] shrx, shtx; reg [3:0] cnt; reg sclk_d;
    wire sclk_rise = sclk & ~sclk_d;
    assign miso = shtx[7];
    always @(posedge clk) begin
        sclk_d<=sclk; done<=0;
        if (rst || cs_n) begin cnt<=0; shtx<=tx_data; end
        else if (sclk_rise) begin
            shrx<={shrx[6:0],mosi}; shtx<={shtx[6:0],1'b0}; cnt<=cnt+1'b1;
            if (cnt==7) begin rx_data<={shrx[6:0],mosi}; done<=1; cnt<=0; end
        end
    end
endmodule


