// =====================================================================
// primitives.v  --  Built-in chip library for the Hack computer
// ECE 350 Computer Organization
//
// These are the chips treated as primitive building blocks: the one true
// gate (Nand), the elementary 1-bit gates built from it, and a small
// library of muxes, demuxes, and wide (16-bit / multi-way) gates.
// Everything above the adder is assembled structurally from these parts.
//
// Style (hybrid): the leaf primitives here are written behaviorally;
// the elementary logic gates are built up from a single Nand to preserve
// the bottom-up pedagogy. The wide (16-bit / multi-way) gates are written
// behaviorally for readability -- they are part of the assumed library.
//
// Clocking note: a hardware simulator threads a clock to every flip-flop
// implicitly. Verilog has no such mechanism, so every sequential chip
// (DFF, Bit, Register, RAM*, PC, CPU, Computer) takes an explicit `clk`
// port. State updates on the rising edge: out(t+1) = in(t).
// =====================================================================

`default_nettype none

// ---------------------------------------------------------------------
// The one true primitive
// ---------------------------------------------------------------------
module Nand(input wire a, input wire b, output wire out);
    assign out = ~(a & b);
endmodule

// ---------------------------------------------------------------------
// Elementary 1-bit gates, built from Nand
// ---------------------------------------------------------------------
module Not(input wire in, output wire out);
    Nand g(.a(in), .b(in), .out(out));
endmodule

module And(input wire a, input wire b, output wire out);
    wire t;
    Nand g1(.a(a), .b(b), .out(t));
    Not  g2(.in(t), .out(out));
endmodule

module Or(input wire a, input wire b, output wire out);
    wire na, nb;
    Not  g1(.in(a), .out(na));
    Not  g2(.in(b), .out(nb));
    Nand g3(.a(na), .b(nb), .out(out));
endmodule

module Xor(input wire a, input wire b, output wire out);
    // classic 4-NAND XOR
    wire t, u, v;
    Nand g1(.a(a), .b(b), .out(t));
    Nand g2(.a(a), .b(t), .out(u));
    Nand g3(.a(t), .b(b), .out(v));
    Nand g4(.a(u), .b(v), .out(out));
endmodule

// out = (sel == 0) ? a : b
module Mux(input wire a, input wire b, input wire sel, output wire out);
    wire nsel, t1, t2;
    Not g1(.in(sel), .out(nsel));
    And g2(.a(a), .b(nsel), .out(t1));
    And g3(.a(b), .b(sel),  .out(t2));
    Or  g4(.a(t1), .b(t2),  .out(out));
endmodule

// sel == 0 -> {a=in, b=0} ;  sel == 1 -> {a=0, b=in}
module DMux(input wire in, input wire sel, output wire a, output wire b);
    wire nsel;
    Not g1(.in(sel), .out(nsel));
    And g2(.a(in), .b(nsel), .out(a));
    And g3(.a(in), .b(sel),  .out(b));
endmodule

// ---------------------------------------------------------------------
// Wide / multi-way gates (assumed library; written behaviorally)
// Bit 0 is the LSB (little-endian), the conventional Verilog ordering.
// ---------------------------------------------------------------------
module Not16(input wire [15:0] in, output wire [15:0] out);
    assign out = ~in;
endmodule

module And16(input wire [15:0] a, input wire [15:0] b, output wire [15:0] out);
    assign out = a & b;
endmodule

module Or16(input wire [15:0] a, input wire [15:0] b, output wire [15:0] out);
    assign out = a | b;
endmodule

// out = (sel == 0) ? a : b
module Mux16(input wire [15:0] a, input wire [15:0] b, input wire sel,
             output wire [15:0] out);
    assign out = sel ? b : a;
endmodule

module Or8Way(input wire [7:0] in, output wire out);
    assign out = |in;
endmodule

module Mux4Way16(input wire [15:0] a, input wire [15:0] b,
                 input wire [15:0] c, input wire [15:0] d,
                 input wire [1:0] sel, output wire [15:0] out);
    assign out = sel[1] ? (sel[0] ? d : c) : (sel[0] ? b : a);
endmodule

module Mux8Way16(input wire [15:0] a, input wire [15:0] b,
                 input wire [15:0] c, input wire [15:0] d,
                 input wire [15:0] e, input wire [15:0] f,
                 input wire [15:0] g, input wire [15:0] h,
                 input wire [2:0] sel, output wire [15:0] out);
    assign out = sel[2] ? (sel[1] ? (sel[0] ? h : g) : (sel[0] ? f : e))
                        : (sel[1] ? (sel[0] ? d : c) : (sel[0] ? b : a));
endmodule

module DMux4Way(input wire in, input wire [1:0] sel,
                output wire a, output wire b, output wire c, output wire d);
    assign a = in & (sel == 2'd0);
    assign b = in & (sel == 2'd1);
    assign c = in & (sel == 2'd2);
    assign d = in & (sel == 2'd3);
endmodule

module DMux8Way(input wire in, input wire [2:0] sel,
                output wire a, output wire b, output wire c, output wire d,
                output wire e, output wire f, output wire g, output wire h);
    assign a = in & (sel == 3'd0);
    assign b = in & (sel == 3'd1);
    assign c = in & (sel == 3'd2);
    assign d = in & (sel == 3'd3);
    assign e = in & (sel == 3'd4);
    assign f = in & (sel == 3'd5);
    assign g = in & (sel == 3'd6);
    assign h = in & (sel == 3'd7);
endmodule

// ---------------------------------------------------------------------
// The sequential primitive: data flip-flop  (out(t+1) = in(t))
// ---------------------------------------------------------------------
module DFF(input wire clk, input wire in, output reg out);
    initial out = 1'b0;
    always @(posedge clk) out <= in;
endmodule

`default_nettype wire
