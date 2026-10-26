// =====================================================================
// given.v  --  Provided parts for the PC lab.   DO NOT MODIFY.
// Known-good models of the two chips the PC is built on top of:
//   * Inc16    -- the incrementer you built in the adder lab
//   * Register -- the 16-bit load register you built in the memory lab
// They are supplied here (as small behavioral models) so that the program
// counter can be exercised on its own -- you only implement PC.v.
// =====================================================================

`default_nettype none

// out = in + 1
module Inc16(input wire [15:0] in, output wire [15:0] out);
    assign out = in + 16'd1;
endmodule

// 16-bit register: out(t+1) = load ? in : out(t), committed on the rising
// clock edge (matches the Register from the memory lab).
module Register(input wire clk, input wire [15:0] in, input wire load,
                output wire [15:0] out);
    reg [15:0] r = 16'd0;
    assign out = r;
    always @(posedge clk)
        if (load) r <= in;
endmodule

`default_nettype wire
