import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL
OUT=os.path.join(os.path.dirname(__file__),"..","src","interfaces")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

# ---- UART transmitter (8N1) ------------------------------------------
emit("uart_tx8",
     "module uart_tx8(input clk, input rst, input tick, input start, input [7:0] data, output reg tx, output reg busy);\n"
     "    // define clk input 255.230.80   // define rst input 255.80.80   // define tick input 255.180.80\n"
     "    // define start input 255.180.80   // define data input 80.160.255   // define tx output 120.255.160   // define busy output 255.255.255\n"
     "    // 8N1 UART transmit: idle high, 1 start bit (0), 8 data LSB-first, 1 stop (1). 'tick' = baud enable.\n"
     "    reg [3:0] state; reg [7:0] shifter;\n"
     "    localparam IDLE=0, START=1, D0=2, STOP=10;\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin tx<=1'b1; busy<=0; state<=IDLE; end\n"
     "        else begin\n"
     "            case (state)\n"
     "                IDLE: begin tx<=1'b1; if (start) begin shifter<=data; busy<=1; state<=START; end else busy<=0; end\n"
     "                default: if (tick) begin\n"
     "                    if (state==START) begin tx<=1'b0; state<=D0; end\n"
     "                    else if (state>=D0 && state<STOP) begin tx<=shifter[0]; shifter<={1'b0,shifter[7:1]}; state<=state+1; end\n"
     "                    else if (state==STOP) begin tx<=1'b1; state<=IDLE; busy<=0; end\n"
     "                end\n"
     "            endcase\n"
     "        end\n"
     "    end\nendmodule\n",
     ["UART transmitter, 8N1, baud-tick enabled."])
emit("uart_rx8",
     "module uart_rx8(input clk, input rst, input tick, input rx, output reg [7:0] data, output reg valid);\n"
     "    // define clk input 255.230.80   // define rst input 255.80.80   // define tick input 255.180.80\n"
     "    // define rx input 80.160.255   // define data output 120.255.160   // define valid output 255.255.255\n"
     "    // 8N1 UART receive (oversampling assumed folded into 'tick').\n"
     "    reg [3:0] state; reg [7:0] shifter; localparam IDLE=0,D0=1,STOP=9;\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin state<=IDLE; valid<=0; end\n"
     "        else begin valid<=0;\n"
     "            case (state)\n"
     "                IDLE: if (!rx) state<=D0;   // start bit detected; sample data on following ticks\n"
     "                default: if (tick) begin\n"
     "                    if (state>=D0 && state<STOP) begin shifter<={rx,shifter[7:1]}; state<=state+1; end\n"
     "                    else if (state==STOP) begin data<=shifter; valid<=1; state<=IDLE; end\n"
     "                end\n"
     "            endcase\n"
     "        end\n"
     "    end\nendmodule\n",
     ["UART receiver, 8N1."])
emit("uart_baud_gen",
     "module uart_baud_gen(input clk, input rst, input [15:0] divisor, output reg tick);\n"
     "    // define clk input 255.230.80   // define rst input 255.80.80   // define divisor input 80.160.255   // define tick output 120.255.160\n"
     "    reg [15:0] cnt;\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin cnt<=0; tick<=0; end\n"
     "        else if (cnt>=divisor) begin cnt<=0; tick<=1; end\n"
     "        else begin cnt<=cnt+1'b1; tick<=0; end\n"
     "    end\nendmodule\n",
     ["UART baud-rate tick generator."])

# ---- SPI master / slave (mode 0) -------------------------------------
emit("spi_master8",
     "module spi_master8(input clk, input rst, input start, input [7:0] tx_data, input miso,\n"
     "    output reg sclk, output reg mosi, output reg cs_n, output reg [7:0] rx_data, output reg done);\n"
     "    // define clk input 255.230.80   // define rst input 255.80.80   // define start input 255.180.80\n"
     "    // define tx_data input 80.160.255   // define rx_data output 120.255.160   // define done output 255.255.255\n"
     "    // SPI mode 0 master, 8-bit, one clk per half-bit.\n"
     "    reg [4:0] state; reg [7:0] shtx, shrx; reg phase;\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin state<=0; cs_n<=1; sclk<=0; done<=0; phase<=0; end\n"
     "        else begin done<=0;\n"
     "            if (state==0) begin\n"
     "                if (start) begin shtx<=tx_data; cs_n<=0; state<=1; phase<=0; sclk<=0; end\n"
     "                else cs_n<=1;\n"
     "            end else if (state<=16) begin\n"
     "                if (!phase) begin mosi<=shtx[7]; sclk<=0; phase<=1; end\n"
     "                else begin sclk<=1; shrx<={shrx[6:0],miso}; shtx<={shtx[6:0],1'b0}; phase<=0; state<=state+1; end\n"
     "            end else begin sclk<=0; cs_n<=1; rx_data<=shrx; done<=1; state<=0; end\n"
     "        end\n"
     "    end\nendmodule\n",
     ["SPI master, mode 0, 8-bit full-duplex."])
emit("spi_slave8",
     "module spi_slave8(input clk, input rst, input sclk, input mosi, input cs_n, input [7:0] tx_data,\n"
     "    output miso, output reg [7:0] rx_data, output reg done);\n"
     "    // define clk input 255.230.80   // define sclk input 255.180.80   // define mosi input 80.160.255   // define rx_data output 120.255.160\n"
     "    reg [7:0] shrx, shtx; reg [3:0] cnt; reg sclk_d;\n"
     "    wire sclk_rise = sclk & ~sclk_d;\n"
     "    assign miso = shtx[7];\n"
     "    always @(posedge clk) begin\n"
     "        sclk_d<=sclk; done<=0;\n"
     "        if (rst || cs_n) begin cnt<=0; shtx<=tx_data; end\n"
     "        else if (sclk_rise) begin\n"
     "            shrx<={shrx[6:0],mosi}; shtx<={shtx[6:0],1'b0}; cnt<=cnt+1'b1;\n"
     "            if (cnt==7) begin rx_data<={shrx[6:0],mosi}; done<=1; cnt<=0; end\n"
     "        end\n"
     "    end\nendmodule\n",
     ["SPI slave, mode 0, 8-bit."])

# ---- I2C-ish bit controller (educational) ----------------------------
emit("i2c_master_byte",
     "module i2c_master_byte(input clk, input rst, input start, input [7:0] data, \n"
     "    output reg scl, output reg sda, output reg busy, output reg done);\n"
     "    // define clk input 255.230.80   // define start input 255.180.80   // define data input 80.160.255   // define done output 255.255.255\n"
     "    // Simplified I2C byte writer: START, 8 data bits MSB-first, then stop. (Open-drain modeled push-pull.)\n"
     "    reg [4:0] state; reg [7:0] sh;\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin state<=0; scl<=1; sda<=1; busy<=0; done<=0; end\n"
     "        else begin done<=0;\n"
     "            case (state)\n"
     "                0: if (start) begin sh<=data; sda<=0; busy<=1; state<=1; end else busy<=0;  // START: sda 1->0 while scl high\n"
     "                default: begin\n"
     "                    if (state<=16) begin\n"
     "                        if (state[0]) begin scl<=0; sda<=sh[7]; sh<={sh[6:0],1'b0}; end\n"
     "                        else scl<=1;\n"
     "                        state<=state+1;\n"
     "                    end else begin scl<=1; sda<=1; busy<=0; done<=1; state<=0; end  // STOP\n"
     "                end\n"
     "            endcase\n"
     "        end\n"
     "    end\nendmodule\n",
     ["Simplified I2C master byte writer (educational)."])

# ---- parallel<->serial ----------------------------------------------
for w in [8,16,32]:
    cb=max(1,int(math.ceil(math.log2(w+1))))
    emit(f"parallel_to_serial{w}",
         f"module parallel_to_serial{w}(input clk, input rst, input load, input [{w-1}:0] din, output sout, output done);\n"
         f"    // define clk input {COL['clk']}   // define load input {COL['en']}   // define din input {COL['a']}   // define sout output {COL['out']}\n"
         f"    reg [{w-1}:0] sh; reg [{cb-1}:0] cnt; reg active;\n"
         f"    always @(posedge clk) begin\n"
         f"        if (rst) begin active<=0; cnt<=0; end\n"
         f"        else if (load) begin sh<=din; cnt<={w}; active<=1; end\n"
         f"        else if (active) begin sh<={{1'b0,sh[{w-1}:1]}}; cnt<=cnt-1'b1; if (cnt=={cb}'d1) active<=0; end\n"
         f"    end\n"
         f"    assign sout = sh[0];\n"
         f"    assign done = (cnt=={cb}'d0);\nendmodule\n",
         [f"{w}-bit parallel-in to serial-out converter."])
    emit(f"serial_to_parallel{w}",
         f"module serial_to_parallel{w}(input clk, input rst, input en, input sin, output reg [{w-1}:0] dout, output reg valid);\n"
         f"    // define clk input {COL['clk']}   // define en input {COL['en']}   // define sin input {COL['a']}   // define dout output {COL['out']}\n"
         f"    reg [{cb-1}:0] cnt;\n"
         f"    always @(posedge clk) begin\n"
         f"        if (rst) begin cnt<=0; valid<=0; end\n"
         f"        else if (en) begin dout<={{sin,dout[{w-1}:1]}}; cnt<=cnt+1'b1;\n"
         f"            if (cnt=={cb}'d{w-1}) begin valid<=1; cnt<=0; end else valid<=0;\n"
         f"        end else valid<=0;\n"
         f"    end\nendmodule\n",
         [f"{w}-bit serial-in to parallel-out converter."])

# ---- handshake (req/ack) --------------------------------------------
emit("handshake_sync",
     "module handshake_sync(input clk, input rst, input req, output reg ack, output reg data_taken);\n"
     "    // define clk input 255.230.80   // define req input 255.180.80   // define ack output 120.255.160\n"
     "    // 4-phase req/ack handshake receiver.\n"
     "    reg state;\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin ack<=0; data_taken<=0; state<=0; end\n"
     "        else begin data_taken<=0;\n"
     "            case (state)\n"
     "                0: if (req) begin ack<=1; data_taken<=1; state<=1; end\n"
     "                1: if (!req) begin ack<=0; state<=0; end\n"
     "            endcase\n"
     "        end\n"
     "    end\nendmodule\n",
     ["4-phase req/ack handshake synchronizer."])

# ---- synchronous FIFO ------------------------------------------------
for depth,dw in [(8,8),(16,8),(16,16)]:
    ab=int(math.ceil(math.log2(depth)))
    emit(f"fifo_sync_{depth}x{dw}",
         f"module fifo_sync_{depth}x{dw}(input clk, input rst, input wr, input rd, input [{dw-1}:0] din,\n"
         f"    output reg [{dw-1}:0] dout, output empty, output full, output [{ab}:0] count);\n"
         f"    // define clk input {COL['clk']}   // define wr input {COL['en']}   // define rd input {COL['en']}\n"
         f"    // define din input {COL['a']}   // define dout output {COL['out']}   // define empty output {COL['status']}   // define full output {COL['flag']}\n"
         f"    reg [{dw-1}:0] mem [0:{depth-1}];\n"
         f"    reg [{ab-1}:0] wptr, rptr; reg [{ab}:0] cnt;\n"
         f"    assign empty = (cnt==0);\n"
         f"    assign full  = (cnt=={depth});\n"
         f"    assign count = cnt;\n"
         f"    always @(posedge clk) begin\n"
         f"        if (rst) begin wptr<=0; rptr<=0; cnt<=0; end\n"
         f"        else begin\n"
         f"            if (wr && !full) begin mem[wptr]<=din; wptr<=wptr+1'b1; end\n"
         f"            if (rd && !empty) begin dout<=mem[rptr]; rptr<=rptr+1'b1; end\n"
         f"            case ({{wr && !full, rd && !empty}})\n"
         f"                2'b10: cnt<=cnt+1'b1;\n"
         f"                2'b01: cnt<=cnt-1'b1;\n"
         f"                default: cnt<=cnt;\n"
         f"            endcase\n"
         f"        end\n"
         f"    end\nendmodule\n",
         [f"Synchronous FIFO, {depth} deep x {dw}-bit."])

print("interfaces generated")
