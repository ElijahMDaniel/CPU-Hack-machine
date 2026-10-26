// =====================================================================
// adders.v  --  Adder family for the Hack ALU   (STUDENT STARTER CODE)
// Structural Verilog. Build each chip up from the gates in
// primitives.v and from the smaller adders you define above it.
// Depends on: primitives.v
//
// Name of student(s): Elijah Daniel
//
// Instructions:
//   * Fill in the body of every module marked "// FIXME".
//   * Do NOT rename a module or change its port list -- the testbench
//     (adders_tb.v) connects to these interfaces exactly as written.
//   * Build the design STRUCTURALLY: instantiate gates/sub-adders, e.g.
//         Xor g1(.a(x), .b(y), .out(z));
//     The gates available to you (from primitives.v) are:
//         Nand, Not, And, Or, Xor, Mux, DMux, ... and the 16-bit / wide
//         versions Not16, And16, Or16, Mux16, Mux4Way16, ...
//   * Build and run the self-checking testbench from this folder with:
//         iverilog -g2001 -o adders_tb primitives.v adders.v adders_tb.v
//         vvp adders_tb
//     A correct design prints "ADDERS: ALL TESTS PASSED".
// =====================================================================

`default_nettype none

// Half-adder: z = x ^ y, cout = x & y
module HalfAdder(input wire x, input wire y, output wire z, output wire cout);
    // FIXME: drive z and cout using Xor and And gates.
    Xor g1(.a(x), .b(y), .out(z));
    And g2(.a(x), .b(y), .out(cout));
endmodule

// Full-adder: sum of three bits.  {cout, z} == x + y + cin
module FullAdder(input wire x, input wire y, input wire cin,
                 output wire z, output wire cout);
    // FIXME: build from basic gates (Xor / And / Or). You may declare
    // internal wires for the intermediate signals.
    wire t1,t2,t3;
    Xor g1(.a(x),.b(y), .out(t1));
    Xor g2(.a(t1), .b(cin), .out(z));
    And g3(.a(t1), .b(cin), .out(t2));
    And g4(.a(x), .b(y), .out(t3));
    Or g5(.a(t2), .b(t3), .out(cout));
endmodule

// 4-bit ripple-carry adder: chain four FullAdders, carry rippling 0 -> 3.
module RippleCarryAdder4(input wire [3:0] x, input wire [3:0] y, input wire cin,
                         output wire [3:0] z, output wire cout);
    // FIXME: instantiate four FullAdder stages and connect the carries.
    wire c1, c2, c3;
    FullAdder fa0(.x(x[0]), .y(y[0]), .cin(cin), .z(z[0]), .cout(c1));
    FullAdder fa1(.x(x[1]), .y(y[1]), .cin(c1), .z(z[1]), .cout(c2));
    FullAdder fa2(.x(x[2]), .y(y[2]), .cin(c2), .z(z[2]), .cout(c3));
    FullAdder fa3(.x(x[3]), .y(y[3]), .cin(c3), .z(z[3]), .cout(cout));
endmodule

// 16-bit ripple-carry adder from four 4-bit ripple-carry adders.
module RippleCarryAdder16(input wire [15:0] x, input wire [15:0] y,
                          output wire [15:0] z);
    // FIXME: instantiate four RippleCarryAdder4 stages (cin of stage 0 is
    // 0). The final carry-out is unused -- assign it to a dummy wire.
    wire c1, c2, c3, dummy;
    RippleCarryAdder4 rca0(.x(x[3:0]), .y(y[3:0]), .cin(1'b0), .z(z[3:0]), .cout(c1));
    RippleCarryAdder4 rca1(.x(x[7:4]), .y(y[7:4]), .cin(c1), .z(z[7:4]), .cout(c2));
    RippleCarryAdder4 rca2(.x(x[11:8]), .y(y[11:8]), .cin(c2), .z(z[11:8]), .cout(c3));
    RippleCarryAdder4 rca3(.x(x[15:12]), .y(y[15:12]), .cin(c3), .z(z[15:12]), .cout(dummy));
endmodule

// Add16: 16-bit adder, most-significant carry ignored.
module Add16(input wire [15:0] x, input wire [15:0] y, output wire [15:0] z);
    // FIXME: same structure as RippleCarryAdder16 (cin = 0, carry-out
    // discarded). This is the adder the ALU uses.
    wire c1, c2, c3, dummy;
    RippleCarryAdder4 rca0(.x(x[3:0]), .y(y[3:0]), .cin(1'b0), .z(z[3:0]), .cout(c1));
    RippleCarryAdder4 rca1(.x(x[7:4]), .y(y[7:4]), .cin(c1), .z(z[7:4]), .cout(c2));
    RippleCarryAdder4 rca2(.x(x[11:8]), .y(y[11:8]), .cin(c2), .z(z[11:8]), .cout(c3));
    RippleCarryAdder4 rca3(.x(x[15:12]), .y(y[15:12]), .cin(c3), .z(z[15:12]), .cout(dummy));
endmodule

// Inc16: out = in + 1
module Inc16(input wire [15:0] in, output wire [15:0] out);
    // FIXME: implement using one Add16 with the constant 1.
    Add16 adder(.x(in), .y(16'b0000000000000001), .z(out));
endmodule

// ---------------------------------------------------------------------
// CLA4: 4-bit carry-lookahead adder.
// Hint (from the handout): build the per-bit propagate p_i = x_i ^ y_i and
// generate g_i = x_i & y_i signals, then expand the carries
//     c1 = g0 + p0.cin
//     c2 = g1 + p1.g0 + p1.p0.cin
//     c3 = g2 + p2.g1 + p2.p1.g0 + p2.p1.p0.cin
//     cout = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0 + p3.p2.p1.p0.cin
// and form the sum bits z_i = p_i ^ (carry into bit i).
// ---------------------------------------------------------------------
module CLA4(input wire [3:0] x, input wire [3:0] y, input wire cin,
            output wire [3:0] z, output wire cout);
    // FIXME: implement the carry-lookahead adder described above.
    wire [3:0] p, g;
    wire t1, t2, t3,t4,t5,t6,t7,t8,t9,t10,t11,t12, t13,t14,t15,t16,t17,t18,t19;
    wire c1, c2, c3;

    //Calculate propogates
    Xor g0(.a(x[0]), .b(y[0]), .out(p[0]));
    Xor g1(.a(x[1]), .b(y[1]), .out(p[1]));
    Xor g2(.a(x[2]), .b(y[2]), .out(p[2]));
    Xor g3(.a(x[3]), .b(y[3]), .out(p[3]));

    //calculate generates
    And g4(.a(x[0]), .b(y[0]), .out(g[0]));
    And g5(.a(x[1]), .b(y[1]), .out(g[1]));
    And g6(.a(x[2]), .b(y[2]), .out(g[2]));
    And g7(.a(x[3]), .b(y[3]), .out(g[3]));

    // Calculating C1
    And g8(.a(p[0]), .b(cin), .out(t1)); //p0.cin
    Or g9(.a(g[0]), .b(t1), .out(c1)); //c1 = g0 + p0.cin
    
    // Calculating C2
    And g10(.a(p[1]), .b(t1), .out(t2)); //p1.p0.cin
    And g11(.a(p[1]), .b(g[0]), .out(t3)); //p1.g0
    Or g12(.a(g[1]), .b(t2), .out(t4)); //g1 + p1.p0.cin
    Or g13(.a(t4), .b(t3), .out(c2)); //c2 = g1 + p1.g0 + p1.p0.cin

    // Calculating C3
    And g14(.a(t2), .b(p[2]), .out(t5)); //p2.p1.p0.cin
    And g15(.a(p[2]), .b(p[1]), .out(t6)); //p2.p1
    And g16(.a(t6), .b(g[0]), .out(t7)); //p2.p1.g0
    And g17(.a(p[2]), .b(g[1]), .out(t8)); //p2.g1
    Or g18(.a(g[2]), .b(t5), .out(t9)); //g2 + p2.p1.p0.cin
    Or g19(.a(t9), .b(t7), .out(t10)); //g2 + p2.p1.g0 + p2.p1.p0.cin
    Or g20(.a(t10), .b(t8), .out(c3)); //c3 = g2 + p2.g1 + p2.p1.g0 + p2.p1.p0.cin

    // Calculating Cout
    And g21(.a(p[3]), .b(t5), .out(t11)); //p3.p2.p1.p0.cin
    And g22(.a(p[3]), .b(t6), .out(t12)); //p3.p2.p1
    And g23(.a(t12), .b(g[0]), .out(t13)); //p3.p2.p1.g0
    And g24(.a(p[3]), .b(p[2]), .out(t14)); //p3.p2
    And g25(.a(t14), .b(g[1]), .out(t15)); //p3.p2.g1
    And g26(.a(p[3]), .b(g[2]), .out(t16)); //p3.g2
    Or g27(.a(g[3]), .b(t11), .out(t17)); //g3 + p3.p2.p1.p0.cin
    Or g28(.a(t17), .b(t13), .out(t18)); //g3 + p3.p2.p1.g0 + p3.p2.p1.p0.cin
    Or g29(.a(t18), .b(t15), .out(t19)); //g3 + p3.p2.g1
    Or g30(.a(t19), .b(t16), .out(cout)); //cout = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0 + p3.p2.p1.p0.cin

    //Calculating sum bits
    Xor g31(.a(p[0]), .b(cin), .out(z[0]));
    Xor g32(.a(p[1]), .b(c1), .out(z[1]));
    Xor g33(.a(p[2]), .b(c2), .out(z[2]));
    Xor g34(.a(p[3]), .b(c3), .out(z[3]));
endmodule

// ---------------------------------------------------------------------
// CarrySelectAdder16: 16-bit carry-select adder from four 4-bit
// ripple-carry adders and multiplexers.  Most-significant carry ignored.
// Idea: block 0's carry-in is 0 (one RCA4). For each higher 4-bit block,
// compute the sum TWICE in parallel -- once with carry-in 0, once with
// carry-in 1 -- then use muxes to select the right sum and the right
// block carry-out once the true carry from the block below is known.
// (Mux from primitives.v: out = (sel==0) ? a : b.)
// ---------------------------------------------------------------------
module CarrySelectAdder16(input wire [15:0] x, input wire [15:0] y,
                          output wire [15:0] z);
    // FIXME: implement the carry-select adder described above. Instantiate
    // RippleCarryAdder4 blocks (two per higher block) and Mux gates; the
    // final block's carry-out is unused -- assign it to a dummy wire.
    wire c0, c1, c2, dummy;
    wire [3:0] z1_0, z1_1, z2_0, z2_1, z3_0, z3_1;
    wire c1_0, c1_1, c2_0, c2_1, c3_0, c3_1;

    //Block 0
    RippleCarryAdder4 rca0(.x(x[3:0]), .y(y[3:0]), .cin(1'b0), .z(z[3:0]), .cout(c0));

    //Block 1
    RippleCarryAdder4 rca1_0(.x(x[7:4]), .y(y[7:4]), .cin(1'b0), .z(z1_0), .cout(c1_0));
    RippleCarryAdder4 rca1_1(.x(x[7:4]), .y(y[7:4]), .cin(1'b1), .z(z1_1), .cout(c1_1));
    Mux m1_0(.a(z1_0[0]), .b(z1_1[0]), .sel(c0), .out(z[4]));
    Mux m1_1(.a(z1_0[1]), .b(z1_1[1]), .sel(c0), .out(z[5]));
    Mux m1_2(.a(z1_0[2]), .b(z1_1[2]), .sel(c0), .out(z[6]));
    Mux m1_3(.a(z1_0[3]), .b(z1_1[3]), .sel(c0), .out(z[7]));
    Mux m1_cout(.a(c1_0), .b(c1_1), .sel(c0), .out(c1));

    //Block 2
    RippleCarryAdder4 rca2_0(.x(x[11:8]), .y(y[11:8]), .cin(1'b0), .z(z2_0), .cout(c2_0));
    RippleCarryAdder4 rca2_1(.x(x[11:8]), .y(y[11:8]), .cin(1'b1), .z(z2_1), .cout(c2_1));
    Mux m2_0(.a(z2_0[0]), .b(z2_1[0]), .sel(c1), .out(z[8]));
    Mux m2_1(.a(z2_0[1]), .b(z2_1[1]), .sel(c1), .out(z[9]));
    Mux m2_2(.a(z2_0[2]), .b(z2_1[2]), .sel(c1), .out(z[10]));
    Mux m2_3(.a(z2_0[3]), .b(z2_1[3]), .sel(c1), .out(z[11]));
    Mux m2_cout(.a(c2_0), .b(c2_1), .sel(c1), .out(c2));

    //Block 3
    RippleCarryAdder4 rca3_0(.x(x[15:12]), .y(y[15:12]), .cin(1'b0), .z(z3_0), .cout(c3_0));
    RippleCarryAdder4 rca3_1(.x(x[15:12]), .y(y[15:12]), .cin(1'b1), .z(z3_1), .cout(c3_1));
    Mux m3_0(.a(z3_0[0]), .b(z3_1[0]), .sel(c2), .out(z[12]));
    Mux m3_1(.a(z3_0[1]), .b(z3_1[1]), .sel(c2), .out(z[13]));
    Mux m3_2(.a(z3_0[2]), .b(z3_1[2]), .sel(c2), .out(z[14]));
    Mux m3_3(.a(z3_0[3]), .b(z3_1[3]), .sel(c2), .out(z[15]));
    Mux m3_cout(.a(c3_0), .b(c3_1), .sel(c2), .out(dummy));
endmodule

`default_nettype wire
