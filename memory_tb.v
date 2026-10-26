// =====================================================================
// memory_tb.v  --  Self-checking testbench for the sequential memory chips
// Drives a clock and verifies load / hold / addressed read-write behavior
// for Bit, Register, RAM8 and RAM64.
//
//   iverilog -g2001 -o memory_tb primitives.v memory.v memory_tb.v
//   vvp memory_tb
// (primitives.v is provided in the starter folder)
//
// Convention: inputs are applied on the falling edge so they are stable
// before the rising edge that commits state; outputs are sampled after.
// =====================================================================

`default_nettype none
`timescale 1ns/1ps

module memory_tb;
    integer errors = 0;

    reg clk = 0;
    always #5 clk = ~clk;

    // DUTs
    reg b_in, b_load;
    wire b_out;
    Bit bit_dut(.clk(clk), .in(b_in), .load(b_load), .out(b_out));

    reg [15:0] r_in; reg r_load;
    wire [15:0] r_out;
    Register reg_dut(.clk(clk), .in(r_in), .load(r_load), .out(r_out));

    reg [15:0] m8_in; reg m8_load; reg [2:0] m8_addr;
    wire [15:0] m8_out;
    RAM8 ram8_dut(.clk(clk), .in(m8_in), .load(m8_load), .address(m8_addr), .out(m8_out));

    reg [15:0] m64_in; reg m64_load; reg [5:0] m64_addr;
    wire [15:0] m64_out;
    RAM64 ram64_dut(.clk(clk), .in(m64_in), .load(m64_load), .address(m64_addr), .out(m64_out));

    task chk1(input got, input exp, input [127:0] name);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s: got %b want %b", name, got, exp);
            end
        end
    endtask

    task chk16(input [15:0] got, input [15:0] exp, input [127:0] name);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s: got %h want %h", name, got, exp);
            end
        end
    endtask

    initial begin
        // idle everything
        b_load = 0; b_in = 0;
        r_load = 0; r_in = 0;
        m8_load = 0; m8_in = 0; m8_addr = 0;
        m64_load = 0; m64_in = 0; m64_addr = 0;

        // ---------------- Bit ----------------
        @(negedge clk); b_in = 1; b_load = 1;        // load 1
        @(posedge clk); #1; chk1(b_out, 1'b1, "Bit load1");
        @(negedge clk); b_in = 0; b_load = 0;        // hold
        @(posedge clk); #1; chk1(b_out, 1'b1, "Bit hold1");
        @(negedge clk); b_in = 0; b_load = 1;        // load 0
        @(posedge clk); #1; chk1(b_out, 1'b0, "Bit load0");
        @(negedge clk); b_in = 1; b_load = 0;        // hold
        @(posedge clk); #1; chk1(b_out, 1'b0, "Bit hold0");

        // ---------------- Register ----------------
        @(negedge clk); r_in = 16'hBEEF; r_load = 1;
        @(posedge clk); #1; chk16(r_out, 16'hBEEF, "Reg load");
        @(negedge clk); r_in = 16'h1234; r_load = 0; // hold
        @(posedge clk); #1; chk16(r_out, 16'hBEEF, "Reg hold");
        @(negedge clk); r_in = 16'h1234; r_load = 1;
        @(posedge clk); #1; chk16(r_out, 16'h1234, "Reg reload");

        // ---------------- RAM8 ----------------
        @(negedge clk); m8_addr = 3'd3; m8_in = 16'hAAAA; m8_load = 1;
        @(posedge clk); #1;                          // write A->[3]
        @(negedge clk); m8_addr = 3'd5; m8_in = 16'h5555; m8_load = 1;
        @(posedge clk); #1;                          // write B->[5]
        @(negedge clk); m8_load = 0; m8_addr = 3'd3; #1;
        chk16(m8_out, 16'hAAAA, "RAM8 read[3]");
        @(negedge clk); m8_addr = 3'd5; #1;
        chk16(m8_out, 16'h5555, "RAM8 read[5]");
        @(negedge clk); m8_addr = 3'd3; m8_in = 16'h00FF; m8_load = 1;
        @(posedge clk); #1;                          // overwrite [3]
        @(negedge clk); m8_load = 0; m8_addr = 3'd3; #1;
        chk16(m8_out, 16'h00FF, "RAM8 overwrite[3]");
        @(negedge clk); m8_addr = 3'd5; #1;
        chk16(m8_out, 16'h5555, "RAM8 untouched[5]");

        // ---------------- RAM64 (cross-bank) ----------------
        @(negedge clk); m64_addr = 6'd2;  m64_in = 16'h0F0F; m64_load = 1; // bank 0
        @(posedge clk); #1;
        @(negedge clk); m64_addr = 6'd40; m64_in = 16'hF0F0; m64_load = 1; // bank 5
        @(posedge clk); #1;
        @(negedge clk); m64_load = 0; m64_addr = 6'd2; #1;
        chk16(m64_out, 16'h0F0F, "RAM64 read[2]");
        @(negedge clk); m64_addr = 6'd40; #1;
        chk16(m64_out, 16'hF0F0, "RAM64 read[40]");

        if (errors == 0) $display("MEMORY: ALL TESTS PASSED");
        else             $display("MEMORY: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule

`default_nettype wire
