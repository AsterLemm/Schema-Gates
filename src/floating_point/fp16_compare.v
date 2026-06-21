// =====================================================================
//  fp16_compare.v
//  fp16 ordered comparator (sign-magnitude semantics).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_compare(input [15:0] a, input [15:0] b, output lt, output eq, output gt);
    // define a input 80.160.255
    // define b input 80.200.255
    // define lt output 255.255.255
    // define eq output 255.255.255
    // define gt output 255.255.255
    wire sa=a[15], sb=b[15];
    wire [14:0] ma=a[14:0], mb=b[14:0];
    wire azero = ~|ma, bzero = ~|mb;
    wire both_zero = azero & bzero;
    // compare as sign-magnitude
    wire mag_lt = ma < mb;
    wire mag_gt = ma > mb;
    reg rlt, rgt;
    always @(*) begin
        if (both_zero) begin rlt=0; rgt=0; end
        else if (sa & ~sb) begin rlt=1; rgt=0; end        // a neg, b pos
        else if (~sa & sb) begin rlt=0; rgt=1; end        // a pos, b neg
        else if (~sa & ~sb) begin rlt=mag_lt; rgt=mag_gt; end // both pos
        else begin rlt=mag_gt; rgt=mag_lt; end             // both neg: reversed
    end
    assign lt=rlt; assign gt=rgt; assign eq=~rlt & ~rgt;
endmodule


