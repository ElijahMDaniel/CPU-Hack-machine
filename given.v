// =====================================================================
// given.v  --  Provided parts for the Computer lab.   DO NOT MODIFY.
// Known-good models of the built-in chips the Memory and
// Computer are built on top of:
//   * RAM16K    -- 16K x 16-bit data RAM
//   * Screen    -- 8K-word screen framebuffer (memory-mapped output)
//   * Keyboard  -- read-only keyboard register (memory-mapped input)
//   * ROM32K    -- instruction memory (the program is loaded here)
//   * ARegister -- the CPU's address register
//   * DRegister -- the CPU's data register
//   * Register  -- the 16-bit load register (used inside your PC)
// These are supplied (as small behavioral models) so that you can focus on
// the two chips you implement in this lab: Memory.v and Computer.v.
//
// Everything else comes from files you completed in earlier labs and copy
// into this folder: adders.v, ALU.v, PC.v, and CPU.v (the CPU you finished
// in the previous part), plus the bundled primitives.v. You do NOT need to
// copy your memory.v -- the only piece of it the upper chips use is Register,
// provided below.
//
// Scope note: the Screen is modeled as its 8K-word framebuffer (writable and
// readable). The Keyboard is a read-only stub that always returns 0 -- the
// supplied test program (Add.hack) never reads it. To inject a keypress in a
// simulation, force `Keyboard.out` hierarchically.
// =====================================================================

`default_nettype none

// 16K x 16-bit RAM. out = mem[address]; a write (load==1) commits on the edge.
module RAM16K(input wire clk, input wire [15:0] in, input wire load,
              input wire [13:0] address, output wire [15:0] out);
    reg [15:0] mem [0:16383];
    assign out = mem[address];
    always @(posedge clk)
        if (load) mem[address] <= in;
endmodule

// 8192-word screen framebuffer (256 x 512, 1 bit/pixel)
module Screen(input wire clk, input wire [15:0] in, input wire load,
              input wire [12:0] address, output wire [15:0] out);
    reg [15:0] mem [0:8191];
    assign out = mem[address];
    always @(posedge clk)
        if (load) mem[address] <= in;
endmodule

// Read-only keyboard register (stub: no key pressed)
module Keyboard(output wire [15:0] out);
    assign out = 16'b0;
endmodule

// 16-bit load register: out(t+1) = load ? in : out(t) (matches the memory lab)
module Register(input wire clk, input wire [15:0] in, input wire load,
                output wire [15:0] out);
    reg [15:0] r = 16'd0;
    assign out = r;
    always @(posedge clk)
        if (load) r <= in;
endmodule

// ROM32K instruction memory. Read-only, asynchronous: out = ROM[address].
// The program is loaded into `mem` from a .hack file by the testbench, e.g.
//     $readmemb("Add.hack", uut.rom.mem);
module ROM32K(input wire [14:0] address, output wire [15:0] out);
    reg [15:0] mem [0:32767];
    assign out = mem[address];
endmodule

// 16-bit address register: out(t+1) = load ? in : out(t)
module ARegister(input wire clk, input wire [15:0] in, input wire load,
                 output wire [15:0] out);
    reg [15:0] r = 16'd0;
    assign out = r;
    always @(posedge clk)
        if (load) r <= in;
endmodule

// 16-bit data register: out(t+1) = load ? in : out(t)
module DRegister(input wire clk, input wire [15:0] in, input wire load,
                 output wire [15:0] out);
    reg [15:0] r = 16'd0;
    assign out = r;
    always @(posedge clk)
        if (load) r <= in;
endmodule

`default_nettype wire
