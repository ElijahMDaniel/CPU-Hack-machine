// =====================================================================
// Memory.v  --  Complete Hack address space   (STUDENT STARTER CODE)
// Structural Verilog. Combine the built-in RAM16K, Screen and Keyboard
// chips (provided in given.v) into the single 15-bit address space the CPU
// sees. Depends on: primitives.v, given.v (RAM16K, Screen, Keyboard).
//
// Name of student(s): FIXME
//
// Instructions:
//   * Fill in the body of the module below (marked "// FIXME").
//   * Do NOT rename the module or change its port list.
//   * Name the RAM16K instance exactly ram:   RAM16K ram(...);
//     The Computer testbench reads RAM[0] through that name; any other
//     name is a compile error.
//   * Build the design STRUCTURALLY from the parts in primitives.v (DMux,
//     Mux16, ...) and the built-in chips in given.v (RAM16K, Screen,
//     Keyboard).
//   * This chip is exercised by the Computer testbench in the next part
//     (there is no standalone Memory testbench).
//
// The 15-bit address decodes into three regions:
//   0x0000-0x3FFF (0..16383)     data RAM      -> RAM16K, address[13:0]
//   0x4000-0x5FFF (16384..24575) screen map    -> Screen, address[12:0]
//   0x6000        (24576)        keyboard map  -> Keyboard (read-only)
// It is your job to work out how to decompose the incoming 15-bit address
// (shown as "?" in the handout figure) to select the right chip on both the
// write path (route `load`) and the read path (select `out`).
// =====================================================================

`default_nettype none

module Memory(input wire clk, input wire [15:0] in, input wire load,
              input wire [14:0] address, output wire [15:0] out);

    // FIXME: implement the memory address space structurally. A suggested
    // decomposition that follows the blueprint in the handout:
    //
    //   (a) Write path: RAM (address[14]==0) vs I/O (address[14]==1). Use a
    //       DMux on `load` selected by address[14] to produce loadRAM and
    //       loadScreen. (The keyboard is read-only, so no load is routed to
    //       it. Within the I/O half, address[13] distinguishes screen from
    //       keyboard, but only the screen is writable.)
    //
    //   (b) Instantiate the three chips from given.v:
    //         RAM16K   on address[13:0]
    //         Screen   on address[12:0]
    //         Keyboard (output only)
    //
    //   (c) Read path: select the output with Mux16s. Within the I/O half,
    //       pick screen vs keyboard using address[13]; then pick RAM vs I/O
    //       using address[14].
    //
    // Declare internal wires as needed for the intermediate signals.

    wire loadRAM, loadScreen;
    DMux dmux(.in(load), .sel(address[14]), .a(loadRAM), .b(loadScreen));

    wire [15:0] ramOut, screenOut, keyboardOut, ioOut;
    RAM16K ram(.clk(clk), .in(in), .load(loadRAM), .address(address[13:0]), .out(ramOut));
    Screen screen(.clk(clk), .in(in), .load(loadScreen), .address(address[12:0]), .out(screenOut));
    Keyboard keyboard(.out(keyboardOut));
    Mux16 muxIO(.a(screenOut), .b(keyboardOut), .sel(address[13]), .out(ioOut));
    Mux16 muxOut(.a(ramOut), .b(ioOut), .sel(address[14]), .out(out));

endmodule

`default_nettype wire
