// =====================================================================
// given.v  --  Provided parts for the CPU lab.   DO NOT MODIFY.
// Known-good models of the built-in registers the Hack CPU sits on:
//   * ARegister -- the address register
//   * DRegister -- the data register
//   * Register  -- the 16-bit load register (used inside your PC)
// The A and D registers are supplied here as built-in chips; they
// behave exactly like the 16-bit load Register you built in the memory lab
// -- a value written when load==1 appears on `out` from the next clock edge
// onward. All three are provided here (as small behavioral models, the same
// Register model the PC lab gave you) so you do NOT implement or copy them.
// You only implement CPU.v.
//
// Everything else the CPU is built from comes from files you completed in
// earlier labs and copy into this folder: adders.v, ALU.v, PC.v (plus the
// bundled primitives.v). You do NOT need to copy your memory.v -- the only
// piece of it the CPU uses is Register, provided above.
// =====================================================================

`default_nettype none

// 16-bit load register: out(t+1) = load ? in : out(t) (matches the memory lab)
module Register(input wire clk, input wire [15:0] in, input wire load,
                output wire [15:0] out);
    reg [15:0] r = 16'd0;
    assign out = r;
    always @(posedge clk)
        if (load) r <= in;
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
