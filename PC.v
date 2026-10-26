// =====================================================================
// PC.v  --  16-bit program counter with load / inc / reset
//                                          (STUDENT STARTER CODE)
// Structural Verilog. Build the counter from the gates in primitives.v
// and the provided Inc16 / Register parts (given.v).
// Depends on: primitives.v, given.v (Inc16, Register)
//
// Name of student(s): Elijah Daniel
//
// Instructions:
//   * Fill in the body of the module below (marked "// FIXME").
//   * Do NOT rename the module or change its port list -- the testbench
//     (PC_tb.v) connects to this interface exactly as written.
//   * Build the design STRUCTURALLY: instantiate gates / sub-chips, e.g.
//         Mux16 m(.a(p), .b(q), .sel(s), .out(w));
//     Available parts: Not, Or, Mux16 (from primitives.v) and Inc16,
//     Register (from given.v -- do not modify given.v).
//   * primitives.v and given.v are already in this folder; build and run
//     the self-checking testbench with:
//         iverilog -g2001 -o pc_tb primitives.v given.v PC.v PC_tb.v
//         vvp pc_tb
//     A correct design prints "PC: ALL TESTS PASSED".
//
// Behavior each clock cycle, in PRIORITY order  reset > load > inc > hold:
//   reset: out(t+1) = 0
//   load : out(t+1) = in
//   inc  : out(t+1) = out(t) + 1
//   else : out(t+1) = out(t)      (hold)
// =====================================================================

`default_nettype none

module PC(input wire clk, input wire [15:0] in,
          input wire load, input wire inc, input wire reset,
          output wire [15:0] out);

    // FIXME: implement the program counter structurally. A suggested plan:
    //
    //   (a) Increment: feed the current count `out` into an Inc16 to get
    //       out+1.
    //   (b) Pick inc vs. load: use a Mux16 to choose between out+1 (when
    //       only inc is requested) and the load value `in`. Derive the
    //       select from `inc`/`load` with Not/Or so that `load` takes
    //       priority over `inc`.
    //   (c) Apply reset: a second Mux16 forces the value to 0 when `reset`
    //       is asserted (reset has top priority).
    //   (d) Commit: a Register captures the chosen value each cycle. Load
    //       the register whenever ANY of load/reset/inc is asserted (OR
    //       them together); when none are, it holds. The register's output
    //       is `out`, which also feeds back into the Inc16 in step (a).
    //
    // Declare internal wires as needed for the intermediate signals.
    wire [15:0] inc_out;
    wire [15:0] inc_or_hold;
    wire [15:0] load_or_inc;
    wire [15:0] next_out;

    wire temp_load;
    wire reg_load;

    Inc16 inc1(.in(out), .out(inc_out));

    Mux16 mux1(.a(out), .b(inc_out), .sel(inc), .out(inc_or_hold));

    Mux16 mux2(.a(inc_or_hold), .b(in), .sel(load), .out(load_or_inc));

    Mux16 mux3(.a(load_or_inc), .b(16'd0), .sel(reset), .out(next_out));

    Or or1(.a(load), .b(inc), .out(temp_load));
    Or or2(.a(temp_load), .b(reset), .out(reg_load));

    Register reg1(.clk(clk), .in(next_out), .load(reg_load), .out(out));
endmodule

`default_nettype wire
