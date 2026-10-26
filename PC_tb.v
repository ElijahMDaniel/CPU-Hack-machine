// =====================================================================
// PC_tb.v  --  Self-checking testbench for the program counter
// Verifies count, load, reset, hold, and the reset>load>inc priority.
//
//   iverilog -g2001 -o pc_tb primitives.v given.v PC.v PC_tb.v
//   vvp pc_tb
// (primitives.v and given.v are provided in the starter folder)
// =====================================================================

`default_nettype none
`timescale 1ns/1ps

module PC_tb;
    integer errors = 0;

    reg clk = 0;
    always #5 clk = ~clk;

    reg [15:0] in;
    reg load, inc, reset;
    wire [15:0] out;
    PC dut(.clk(clk), .in(in), .load(load), .inc(inc), .reset(reset), .out(out));

    task chk(input [15:0] exp, input [127:0] name);
        begin
            if (out !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s: got %0d want %0d", name, out, exp);
            end
        end
    endtask

    initial begin
        in = 0; load = 0; inc = 0; reset = 0;

        // count up: 0 -> 1 -> 2 -> 3
        @(negedge clk); inc = 1;
        @(posedge clk); #1; chk(16'd1, "inc->1");
        @(posedge clk); #1; chk(16'd2, "inc->2");
        @(posedge clk); #1; chk(16'd3, "inc->3");

        // load 50
        @(negedge clk); inc = 0; load = 1; in = 16'd50;
        @(posedge clk); #1; chk(16'd50, "load 50");

        // resume counting
        @(negedge clk); load = 0; inc = 1;
        @(posedge clk); #1; chk(16'd51, "inc->51");

        // hold (nothing asserted)
        @(negedge clk); inc = 0;
        @(posedge clk); #1; chk(16'd51, "hold");

        // reset wins
        @(negedge clk); reset = 1; load = 1; inc = 1; in = 16'd999;
        @(posedge clk); #1; chk(16'd0, "reset > load,inc");

        // load wins over inc
        @(negedge clk); reset = 0; load = 1; inc = 1; in = 16'd80;
        @(posedge clk); #1; chk(16'd80, "load > inc");

        // inc only
        @(negedge clk); load = 0; inc = 1;
        @(posedge clk); #1; chk(16'd81, "inc->81");

        if (errors == 0) $display("PC: ALL TESTS PASSED");
        else             $display("PC: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule

`default_nettype wire
