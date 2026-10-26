// =====================================================================
// ALU_tb.v  --  Self-checking testbench for the Hack ALU
// Verifies the DUT against a behavioral reference of the ALU spec across
// all 64 control-bit combinations for several (x,y) pairs.
//
//   iverilog -g2001 -o alu_tb primitives.v adders.v ALU.v ALU_tb.v
//   vvp alu_tb
// (primitives.v is provided here; copy your completed adders.v in too)
// =====================================================================

`default_nettype none
`timescale 1ns/1ps

module ALU_tb;
    reg  [15:0] x, y;
    reg         zx, nx, zy, ny, f, no;
    wire [15:0] out;
    wire        zr, ng;

    ALU dut(.x(x), .y(y), .zx(zx), .nx(nx), .zy(zy), .ny(ny),
            .f(f), .no(no), .out(out), .zr(zr), .ng(ng));

    integer errors = 0;
    integer p, c;
    reg [15:0] xs [0:5];
    reg [15:0] ys [0:5];

    // Behavioral reference: returns {ng, zr, out[15:0]}
    function [17:0] alu_ref;
        input [15:0] rx, ry;
        input rzx, rnx, rzy, rny, rf, rno;
        reg [15:0] xr, yr, o;
        begin
            xr = rzx ? 16'b0 : rx;
            xr = rnx ? ~xr   : xr;
            yr = rzy ? 16'b0 : ry;
            yr = rny ? ~yr   : yr;
            o  = rf  ? (xr + yr) : (xr & yr);
            o  = rno ? ~o : o;
            alu_ref = {o[15], (o == 16'b0), o};
        end
    endfunction

    task expect_row;          // Check against expected row 
        input [15:0] ex; input [15:0] ey;
        input ezx, enx, ezy, eny, ef, eno;
        input [15:0] eout; input ezr, eng;
        begin
            x = ex; y = ey; zx = ezx; nx = enx; zy = ezy; ny = eny; f = ef; no = eno; #1;
            if (out !== eout || zr !== ezr || ng !== eng) begin
                errors = errors + 1;
                $display("FAIL anchor: out=%b zr=%b ng=%b (want %b %b %b)",
                         out, zr, ng, eout, ezr, eng);
            end
        end
    endtask

    initial begin
        // (x,y) pairs
        xs[0]=16'h0000; ys[0]=16'hFFFF;   // 0, -1
        xs[1]=16'h0011; ys[1]=16'h0003;   // 17, 3
        xs[2]=16'h7FFF; ys[2]=16'h0001;   // max+, 1
        xs[3]=16'h8000; ys[3]=16'hFFFF;   // min-, -1
        xs[4]=16'hA5A5; ys[4]=16'h5A5A;
        xs[5]=16'h1234; ys[5]=16'h89AB;

        // Sweep every (x,y) pair against all 64 control combinations
        for (p = 0; p < 6; p = p + 1)
        for (c = 0; c < 64; c = c + 1) begin
            x = xs[p]; y = ys[p];
            {zx, nx, zy, ny, f, no} = c[5:0]; #1;
            if ({ng, zr, out} !== alu_ref(x, y, zx, nx, zy, ny, f, no)) begin
                errors = errors + 1;
                $display("FAIL x=%h y=%h ctrl=%b -> out=%h zr=%b ng=%b",
                         x, y, c[5:0], out, zr, ng);
            end
        end

        // Check ALU behavior. Each row contains the inputs provided and the expected outputs
        //          x       y      zx nx zy ny f no     out      zr ng
        expect_row(16'h0000,16'hFFFF, 1,0,1,0,1,0, 16'h0000, 1,0); // compute 0
        expect_row(16'h0000,16'hFFFF, 1,1,1,1,1,1, 16'h0001, 0,0); // compute 1
        expect_row(16'h0000,16'hFFFF, 1,1,1,0,1,0, 16'hFFFF, 0,1); // compute -1
        expect_row(16'h0011,16'h0003, 0,0,0,0,1,0, 16'h0014, 0,0); // 17 + 3 = 20
        expect_row(16'h0011,16'h0003, 0,1,0,0,1,1, 16'h000E, 0,0); // 17 - 3 = 14
        expect_row(16'h0011,16'h0003, 0,0,0,1,1,1, 16'hFFF2, 0,1); // 3 - 17 = -14

        if (errors == 0) $display("ALU: ALL TESTS PASSED");
        else             $display("ALU: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule

`default_nettype wire
