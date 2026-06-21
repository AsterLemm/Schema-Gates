// =====================================================================
//  spi_master8.v
//  SPI master, mode 0, 8-bit full-duplex.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module spi_master8(input clk, input rst, input start, input [7:0] tx_data, input miso,
    output reg sclk, output reg mosi, output reg cs_n, output reg [7:0] rx_data, output reg done);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define start input 255.180.80
    // define tx_data input 80.160.255
    // define rx_data output 120.255.160
    // define done output 255.255.255
    // SPI mode 0 master, 8-bit, one clk per half-bit.
    reg [4:0] state; reg [7:0] shtx, shrx; reg phase;
    always @(posedge clk) begin
        if (rst) begin state<=0; cs_n<=1; sclk<=0; done<=0; phase<=0; end
        else begin done<=0;
            if (state==0) begin
                if (start) begin shtx<=tx_data; cs_n<=0; state<=1; phase<=0; sclk<=0; end
                else cs_n<=1;
            end else if (state<=16) begin
                if (!phase) begin mosi<=shtx[7]; sclk<=0; phase<=1; end
                else begin sclk<=1; shrx<={shrx[6:0],miso}; shtx<={shtx[6:0],1'b0}; phase<=0; state<=state+1; end
            end else begin sclk<=0; cs_n<=1; rx_data<=shrx; done<=1; state<=0; end
        end
    end
endmodule


