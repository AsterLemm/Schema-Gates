// =====================================================================
//  gpu_mmio_arbiter2.v
//  GPU COMPANION: two write masters on one GPU register bus.
//
//  Lets a CPU (port A) and an autonomous driver like gpu_scene_player
//  (port B) share a single GPU: the CPU sets a scene up or intervenes
//  at any time, the player animates in the background.
//
//  POLICY: fixed priority, A wins. Writes are combinationally forwarded
//  (zero added latency). If both masters assert *_we in the same cycle,
//  B's write is LOST and b_dropped pulses so the loss is observable -
//  either design the drivers not to overlap, or have B hold its write
//  until b_dropped stays low (gpu_scene_player writes are sparse:
//  one-cycle bursts around frame_done, easy to keep clear of).
//
//  The read path is shared verbatim: both masters may sample gpu_rdata
//  (STATUS reads are side-effect-free in the whole GPU family).
//
//  MODULAR: grant policy + bus steering are drillable leaf units.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- gpu_mmio_arbiter2_grant : fixed-priority grant (A wins) ---
module gpu_mmio_arbiter2_grant(
    input  wire a_we,
    input  wire b_we,
    output wire gpu_we,
    output wire b_dropped,
    output wire grant_b
);
    assign grant_b   = b_we & ~a_we;
    assign gpu_we    = a_we | b_we;
    assign b_dropped = a_we & b_we;
endmodule

// --- gpu_mmio_arbiter2_mux : address/data steering for the winner ---
module gpu_mmio_arbiter2_mux(
    input  wire        a_we,
    input  wire [3:0]  a_addr,
    input  wire [31:0] a_wdata,
    input  wire [3:0]  b_addr,
    input  wire [31:0] b_wdata,
    output wire [3:0]  gpu_addr,
    output wire [31:0] gpu_wdata
);
    assign gpu_addr  = a_we ? a_addr  : b_addr;
    assign gpu_wdata = a_we ? a_wdata : b_wdata;
endmodule

module gpu_mmio_arbiter2(
    // master A (priority - typically the CPU)
    input  wire        a_we,
    input  wire [3:0]  a_addr,
    input  wire [31:0] a_wdata,
    // master B (typically gpu_scene_player)
    input  wire        b_we,
    input  wire [3:0]  b_addr,
    input  wire [31:0] b_wdata,
    // to the GPU
    output wire        gpu_we,
    output wire [3:0]  gpu_addr,
    output wire [31:0] gpu_wdata,
    // observability
    output wire        b_dropped,     // high when A displaced a B write
    output wire        grant_b        // high when B is on the bus
);
    // define a_we      input  255.190.70
    // define a_addr    input  255.190.70
    // define a_wdata   input  255.190.70
    // define b_we      input  68.68.242
    // define b_addr    input  68.68.242
    // define b_wdata   input  68.68.242
    // define gpu_we    output 120.200.255
    // define gpu_addr  output 120.200.255
    // define gpu_wdata output 120.200.255
    // define b_dropped output 255.80.80
    // define grant_b   output 255.255.120

    // grant + steering live in the two leaf units above (same equations)
    gpu_mmio_arbiter2_grant u_grant(
        .a_we(a_we), .b_we(b_we),
        .gpu_we(gpu_we), .b_dropped(b_dropped), .grant_b(grant_b)
    );
    gpu_mmio_arbiter2_mux u_mux(
        .a_we(a_we), .a_addr(a_addr), .a_wdata(a_wdata),
        .b_addr(b_addr), .b_wdata(b_wdata),
        .gpu_addr(gpu_addr), .gpu_wdata(gpu_wdata)
    );
endmodule


