// =====================================================================
//  interp_fetch_switch32.v
//  INTERPRETER GLUE: A/B switch on a 32-bit host instruction-fetch port.
//
//  Lets one host CPU run either its NATIVE program ROM or a cross-ISA
//  interpreter's output, selected at runtime by `mode` - flip a switch
//  in the schematic and the same silicon becomes "another CPU".
//
//      host imem_addr -> host_addr -> (fans out to both sources)
//      native_instr   -> from the native program ROM     (mode 0)
//      xlat_instr     -> from interp_*  host_instr       (mode 1)
//      xlat_trap      -> from interp_*  trap; gated to trap_out so the
//                        flag is only believed while the interpreter is
//                        actually the one driving the CPU
//
//  For 16-bit-instruction hosts (x86 family) use the _16 variant.
//
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module interp_fetch_switch32(
    input  wire        mode,          // 0 = native ROM, 1 = interpreter
    input  wire [31:0] native_instr,
    input  wire [31:0] xlat_instr,
    input  wire        xlat_trap,
    output wire [31:0] host_instr,
    output wire        trap_out
);
    // define mode         input  255.190.70
    // define native_instr input  68.68.242
    // define xlat_instr   input  68.68.242
    // define xlat_trap    input  255.80.80
    // define host_instr   output 120.200.255
    // define trap_out     output 255.80.80

    assign host_instr = mode ? xlat_instr : native_instr;
    assign trap_out   = mode & xlat_trap;
endmodule


