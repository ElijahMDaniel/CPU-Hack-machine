// =====================================================================
// adders_tb.v  --  Self-checking testbench for the adder family
// Sweeps each chip and compares against arithmetic golden values
// (the FullAdder cases mirror alu/solutions/FullAdder.cmp exactly).
//
// Do NOT modify this file -- it defines how your design is graded.
// Build and run from this folder:
//   iverilog -g2001 -o adders_tb primitives.v adders.v adders_tb.v
//   vvp adders_tb
// =====================================================================

`default_nettype none
`timescale 1ns/1ps

module adders_tb;
    integer errors = 0;
    integer i, j, k;

    // ---- HalfAdder ----
    reg ha_x, ha_y;
    wire ha_z, ha_cout;
    HalfAdder ha(.x(ha_x), .y(ha_y), .z(ha_z), .cout(ha_cout));

    // ---- FullAdder ----
    reg fa_x, fa_y, fa_cin;
    wire fa_z, fa_cout;
    FullAdder fa(.x(fa_x), .y(fa_y), .cin(fa_cin), .z(fa_z), .cout(fa_cout));

    // ---- RippleCarryAdder4 ----
    reg [3:0] r4_x, r4_y; reg r4_cin;
    wire [3:0] r4_z; wire r4_cout;
    RippleCarryAdder4 r4(.x(r4_x), .y(r4_y), .cin(r4_cin), .z(r4_z), .cout(r4_cout));

    // ---- CLA4 ----
    reg [3:0] cl_x, cl_y; reg cl_cin;
    wire [3:0] cl_z; wire cl_cout;
    CLA4 cl(.x(cl_x), .y(cl_y), .cin(cl_cin), .z(cl_z), .cout(cl_cout));

    // ---- Add16 / Inc16 ----
    reg [15:0] a16_x, a16_y;
    wire [15:0] a16_z;
    Add16 a16(.x(a16_x), .y(a16_y), .z(a16_z));
    reg [15:0] inc_in;
    wire [15:0] inc_out;
    Inc16 inc(.in(inc_in), .out(inc_out));

    // ---- CarrySelectAdder16 ----
    reg [15:0] cs_x, cs_y;
    wire [15:0] cs_z;
    CarrySelectAdder16 cs(.x(cs_x), .y(cs_y), .z(cs_z));

    initial begin
        // HalfAdder: {cout,z} == x + y
        for (i = 0; i < 2; i = i + 1)
        for (j = 0; j < 2; j = j + 1) begin
            ha_x = i[0]; ha_y = j[0]; #1;
            if ({ha_cout, ha_z} !== (i + j)) begin
                errors = errors + 1;
                $display("FAIL HalfAdder x=%b y=%b -> z=%b cout=%b", ha_x, ha_y, ha_z, ha_cout);
            end
        end

        // FullAdder: {cout,z} == x + y + cin
        for (i = 0; i < 2; i = i + 1)
        for (j = 0; j < 2; j = j + 1)
        for (k = 0; k < 2; k = k + 1) begin
            fa_x = i[0]; fa_y = j[0]; fa_cin = k[0]; #1;
            if ({fa_cout, fa_z} !== (i + j + k)) begin
                errors = errors + 1;
                $display("FAIL FullAdder x=%b y=%b cin=%b -> z=%b cout=%b", fa_x, fa_y, fa_cin, fa_z, fa_cout);
            end
        end

        // RippleCarryAdder4 and CLA4: {cout,z} == x + y + cin  (full 4-bit sweep)
        for (i = 0; i < 16; i = i + 1)
        for (j = 0; j < 16; j = j + 1)
        for (k = 0; k < 2; k = k + 1) begin
            r4_x = i[3:0]; r4_y = j[3:0]; r4_cin = k[0];
            cl_x = i[3:0]; cl_y = j[3:0]; cl_cin = k[0]; #1;
            if ({r4_cout, r4_z} !== (i + j + k)) begin
                errors = errors + 1;
                $display("FAIL RCA4 x=%0d y=%0d cin=%0d -> got %0d", i, j, k, {r4_cout, r4_z});
            end
            if ({cl_cout, cl_z} !== (i + j + k)) begin
                errors = errors + 1;
                $display("FAIL CLA4 x=%0d y=%0d cin=%0d -> got %0d", i, j, k, {cl_cout, cl_z});
            end
        end

        // Add16: z == (x + y) mod 2^16 ; Inc16: out == (in + 1) mod 2^16 ;
        // CarrySelectAdder16: z == (x + y) mod 2^16  (same operands as Add16).
        for (i = 0; i < 400; i = i + 1) begin
            a16_x = (i * 211) & 16'hFFFF;
            a16_y = (i * 397) & 16'hFFFF;
            inc_in = (i * 521) & 16'hFFFF;
            cs_x = a16_x; cs_y = a16_y; #1;
            if (a16_z !== ((a16_x + a16_y) & 16'hFFFF)) begin
                errors = errors + 1;
                $display("FAIL Add16 x=%h y=%h -> z=%h", a16_x, a16_y, a16_z);
            end
            if (inc_out !== ((inc_in + 1) & 16'hFFFF)) begin
                errors = errors + 1;
                $display("FAIL Inc16 in=%h -> out=%h", inc_in, inc_out);
            end
            if (cs_z !== ((cs_x + cs_y) & 16'hFFFF)) begin
                errors = errors + 1;
                $display("FAIL CarrySelectAdder16 x=%h y=%h -> z=%h", cs_x, cs_y, cs_z);
            end
        end

        if (errors == 0) $display("ADDERS: ALL TESTS PASSED");
        else             $display("ADDERS: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule

`default_nettype wire
