// =====================================================================
// ALU.v  --  16-bit Hack ALU   (STUDENT STARTER CODE)
// Structural Verilog. Build the ALU up from the gates in primitives.v
// and the Add16 adder you completed in the adder project.
// Depends on: primitives.v, adders.v (for Add16)
//
// Name of student(s): Elijah Daniel
//
// Instructions:
//   * Fill in the body of the module below (marked "// FIXME").
//   * Do NOT rename the module or change its port list -- the testbench
//     (ALU_tb.v) connects to this interface exactly as written.
//   * Build the design STRUCTURALLY: instantiate gates / sub-chips, e.g.
//         Mux16 m(.a(x), .b(16'b0), .sel(zx), .out(w));
//     The parts available to you are the gates in primitives.v
//         (Not, And, Or, Mux, Not16, And16, Mux16, Or8Way, ...)
//     plus Add16 from your completed adders.v.
//   * primitives.v is already provided in this folder; copy your
//     completed adders.v (from the adder project) in as well, then
//     build and run the self-checking testbench with:
//         iverilog -g2001 -o alu_tb primitives.v adders.v ALU.v ALU_tb.v
//         vvp alu_tb
//     A correct design prints "ALU: ALL TESTS PASSED".
//
// The ALU computes out = f(x, y) selected by the six control bits:
//   1. if (zx) x = 0        4. if (ny) y = !y
//   2. if (nx) x = !x       5. out = (f ? x + y : x & y)
//   3. if (zy) y = 0        6. if (no) out = !out
//   and sets the status flags   zr = (out == 0),  ng = (out < 0).
// =====================================================================

`default_nettype none

module ALU(
    input  wire [15:0] x,
    input  wire [15:0] y,
    input  wire        zx,   // zero the x input?
    input  wire        nx,   // negate the x input?
    input  wire        zy,   // zero the y input?
    input  wire        ny,   // negate the y input?
    input  wire        f,    // out = x+y (1) or x&y (0)
    input  wire        no,   // negate the output?
    output wire [15:0] out,
    output wire        zr,   // 1 if out == 0
    output wire        ng    // 1 if out <  0
);
    // FIXME: implement the ALU structurally. A suggested staging that
    // follows the internal-design schematic in the handout:
    //
    //   (a) Preset x: use zx to optionally zero x, then nx to optionally
    //       negate it.  (Mux16 + Not16 + Mux16.)
    //   (b) Preset y: same idea using zy and ny.
    //   (c) Compute both (x & y) and (x + y), then select between them
    //       with f.  (And16 + Add16 + Mux16.)
    //   (d) Post-set: use no to optionally negate the result to form out.
    //   (e) ng is the sign bit of out (its most-significant bit).
    //   (f) zr is 1 when out == 0: OR all 16 bits of out together (two
    //       Or8Way chips + an Or), then invert.
    //
    // Declare internal wires as needed for the intermediate signals.
    wire [15:0] x0, xbar, xfinal;
    wire [15:0] y0, ybar, yfinal;
    wire [15:0] and_out, add_out, f_out;
    wire [15:0] outbar;
    wire or8way_out1, or8way_out2, or_out;
    wire orLower, orUpper;

    // preset x
    Mux16 mux_x0(.a(x), .b(16'b0), .sel(zx), .out(x0));

    Not16 not_x(.in(x0), .out(xbar));
    Mux16 mux_xfinal(.a(x0), .b(xbar), .sel(nx), .out(xfinal));

    // preset y
    Mux16 mux_y0(.a(y), .b(16'b0), .sel(zy), .out(y0));

    Not16 not_y(.in(y0), .out(ybar));
    Mux16 mux_yfinal(.a(y0), .b(ybar), .sel(ny), .out(yfinal));

    // compute and16 and add16 and select with f
    Add16 add1(.x(xfinal), .y(yfinal), .z(add_out));
    And16 and1(.a(xfinal), .b(yfinal), .out(and_out));
    Mux16 mux_f(.a(and_out), .b(add_out), .sel(f), .out(f_out));

    // post-set
    Not16 not_out(.in(f_out), .out(outbar));
    Mux16 mux_out(.a(f_out), .b(outbar), .sel(no), .out(out));

    // compute ng and zr
    assign ng = out[15];
    Or8Way orLow(.in(out[7:0]), .out(orLower));
    Or8Way orHigh(.in(out[15:8]), .out(orUpper));
    Or orFinal(.a(orLower), .b(orUpper), .out(or_out));
    Not not_zr(.in(or_out), .out(zr));

    

endmodule

`default_nettype wire
