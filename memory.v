// =====================================================================
// memory.v  --  Sequential memory chips   (STUDENT STARTER CODE)
// Structural Verilog. Build each chip recursively from the parts in
// primitives.v and from the smaller memory chips you define above it:
//     Bit -> Register -> RAM8 -> RAM64
// Depends on: primitives.v
//
// Name of student(s): Elijah Daniel
//
// Instructions:
//   * Fill in the body of every module marked "// FIXME".
//   * Do NOT rename a module or change its port list -- the testbench
//     (memory_tb.v) connects to these interfaces exactly as written.
//   * Build the design STRUCTURALLY: instantiate gates / sub-chips, e.g.
//         Mux m(.a(out), .b(in), .sel(load), .out(w));
//     The parts available to you (from primitives.v) include:
//         Mux, DFF, DMux8Way, Mux8Way16, ...
//   * primitives.v is already provided in this folder; build and run the
//     self-checking testbench with:
//         iverilog -g2001 -o memory_tb primitives.v memory.v memory_tb.v
//         vvp memory_tb
//     A correct design prints "MEMORY: ALL TESTS PASSED".
//
// Clocking: every chip carries an explicit `clk`. State commits on the
// rising edge -- a value written at cycle t is visible on `out` from
// cycle t+1 onward. (The provided DFF in primitives.v is the 1-bit
// clocked storage element: out(t+1) = in(t).)
// =====================================================================

`default_nettype none

// 1-bit register: out(t+1) = load ? in : out(t)
module Bit(input wire clk, input wire in, input wire load, output wire out);
    wire w;
    // FIXME: select between the held value (out) and the new value (in)
    // with a Mux driven by `load`, and feed the result into a DFF whose
    // output is `out`. (Feeding `out` back into the Mux is what makes the
    // cell hold its value when load == 0.)
    Mux m(.a(out), .b(in), .sel(load), .out(w));
    DFF d(.clk(clk), .in(w), .out(out));
endmodule

// 16-bit register: an array of sixteen 1-bit registers
module Register(input wire clk, input wire [15:0] in, input wire load,
                output wire [15:0] out);
    // FIXME: instantiate sixteen Bit cells, one per bit -- Bit i takes
    // in[i] and drives out[i], all sharing clk and load. (You may write
    // the sixteen instances out explicitly, or use a generate loop.)
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : bit_array
            Bit b(.clk(clk), .in(in[i]), .load(load), .out(out[i]));
        end
    endgenerate
endmodule

// 8 x 16-bit register file, addressed by address[2:0]

module RAM8(input wire clk, input wire [15:0] in, input wire load,
            input wire [2:0] address, output wire [15:0] out);

    wire [15:0] ram_out1, ram_out2, ram_out3, ram_out4, ram_out5, ram_out6, ram_out7, ram_out8;
    wire [7:0] ram_load;

    DMux8Way dmux(.in(load), .sel(address), .a(ram_load[0]), .b(ram_load[1]), .c(ram_load[2]), .d(ram_load[3]), .e(ram_load[4]), .f(ram_load[5]), .g(ram_load[6]), .h(ram_load[7]));

    Mux8Way16 mux(.a(ram_out1), .b(ram_out2), .c(ram_out3), .d(ram_out4),.e(ram_out5), .f(ram_out6), .g(ram_out7), .h(ram_out8), .sel(address), .out(out));

    Register r1(.clk(clk), .in(in), .load(ram_load[0]), .out(ram_out1));
    Register r2(.clk(clk), .in(in), .load(ram_load[1]), .out(ram_out2));
    Register r3(.clk(clk), .in(in), .load(ram_load[2]), .out(ram_out3));
    Register r4(.clk(clk), .in(in), .load(ram_load[3]), .out(ram_out4));
    Register r5(.clk(clk), .in(in), .load(ram_load[4]), .out(ram_out5));
    Register r6(.clk(clk), .in(in), .load(ram_load[5]), .out(ram_out6));
    Register r7(.clk(clk), .in(in), .load(ram_load[6]), .out(ram_out7));
    Register r8(.clk(clk), .in(in), .load(ram_load[7]), .out(ram_out8));

endmodule


// 64 x 16-bit memory: eight RAM8 banks selected by address[5:3]
module RAM64(input wire clk, input wire [15:0] in, input wire load,
             input wire [5:0] address, output wire [15:0] out);

    wire [15:0] ram_out[7:0];
    wire [7:0] ram_load;


    DMux8Way dmux(.in(load), .sel(address[5:3]), .a(ram_load[0]), .b(ram_load[1]), .c(ram_load[2]), .d(ram_load[3]), .e(ram_load[4]), .f(ram_load[5]), .g(ram_load[6]), .h(ram_load[7]));


    Mux8Way16 mux(.a(ram_out[0]), .b(ram_out[1]), .c(ram_out[2]), .d(ram_out[3]), .e(ram_out[4]), .f(ram_out[5]), .g(ram_out[6]), .h(ram_out[7]), .sel(address[5:3]), .out(out));

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ram_array
            RAM8 r(
                .clk(clk),
                .in(in),
                .load(ram_load[i]),
                .address(address[2:0]),
                .out(ram_out[i])
            );
        end
    endgenerate

endmodule

`default_nettype wire
