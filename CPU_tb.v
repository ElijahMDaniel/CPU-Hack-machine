// =====================================================================
// CPU_tb.v  --  Self-checking testbench for the Hack CPU
// Drives the exact instruction sequence from
// computer/hack_computer_solution/CPU.tst and checks the DUT against an
// independent behavioral Hack-CPU reference model, cycle by cycle:
//   * pre-edge  (current register state): outM, writeM, addressM
//   * post-edge (committed):              addressM, pc
// A few externally-visible values from CPU.cmp are asserted as anchors.
//
// This is the grading harness -- do NOT modify it. After copying your
// adders.v, ALU.v and PC.v into this folder, build and run with:
//   iverilog -g2001 -o cpu_tb primitives.v given.v adders.v ALU.v \
//            PC.v CPU.v CPU_tb.v
//   vvp cpu_tb
// =====================================================================

`default_nettype none
`timescale 1ns/1ps

module CPU_tb;
    integer errors = 0;
    integer idx;

    reg clk = 0;            // first posedge (t=5) primes the registers' initial
    always #5 clk = ~clk;   // values; we hold reset=1 across it so PC stays 0

    reg  [15:0] instruction, inM;
    reg         reset;
    wire [15:0] outM;
    wire        writeM;
    wire [14:0] addressM, pc;

    CPU dut(.clk(clk), .inM(inM), .instruction(instruction), .reset(reset),
            .outM(outM), .writeM(writeM), .addressM(addressM), .pc(pc));

    // Behavioral reference state
    reg [15:0] refA = 0, refD = 0, refPC = 0;

    // Program (from CPU.tst). Index 44 re-runs index 43's instruction with
    // reset=1; index 45 is @32767 with reset=0.
    reg [15:0] prog [0:45];
    initial begin
        prog[0]=16'b0011000000111001; prog[1]=16'b1110110000010000;
        prog[2]=16'b0101101110100000; prog[3]=16'b1110000111010000;
        prog[4]=16'b0000001111101000; prog[5]=16'b1110001100001000;
        prog[6]=16'b0000001111101001; prog[7]=16'b1110001110011000;
        prog[8]=16'b0000001111101000; prog[9]=16'b1111010011010000;
        prog[10]=16'b0000000000001110; prog[11]=16'b1110001100000100;
        prog[12]=16'b0000001111100111; prog[13]=16'b1110110111100000;
        prog[14]=16'b1110001100001000; prog[15]=16'b0000000000010101;
        prog[16]=16'b1110011111000010; prog[17]=16'b0000000000000010;
        prog[18]=16'b1110000010010000; prog[19]=16'b0000001111101000;
        prog[20]=16'b1110111010010000;
        prog[21]=16'b1110001100000001; prog[22]=16'b1110001100000010;
        prog[23]=16'b1110001100000011; prog[24]=16'b1110001100000100;
        prog[25]=16'b1110001100000101; prog[26]=16'b1110001100000110;
        prog[27]=16'b1110001100000111;
        prog[28]=16'b1110101010010000;
        prog[29]=16'b1110001100000001; prog[30]=16'b1110001100000010;
        prog[31]=16'b1110001100000011; prog[32]=16'b1110001100000100;
        prog[33]=16'b1110001100000101; prog[34]=16'b1110001100000110;
        prog[35]=16'b1110001100000111;
        prog[36]=16'b1110111111010000;
        prog[37]=16'b1110001100000001; prog[38]=16'b1110001100000010;
        prog[39]=16'b1110001100000011; prog[40]=16'b1110001100000100;
        prog[41]=16'b1110001100000101; prog[42]=16'b1110001100000110;
        prog[43]=16'b1110001100000111;
        prog[44]=16'b1110001100000111;   // reset cycle (instr unchanged)
        prog[45]=16'b0111111111111111;   // @32767
    end

    // Hack ALU reference (returns the 16-bit result)
    function [15:0] alu_compute;
        input [15:0] x, y;
        input [5:0]  ctrl;            // {zx,nx,zy,ny,f,no}
        reg [15:0] xr, yr, o;
        begin
            xr = ctrl[5] ? 16'b0 : x;  xr = ctrl[4] ? ~xr : xr;
            yr = ctrl[3] ? 16'b0 : y;  yr = ctrl[2] ? ~yr : yr;
            o  = ctrl[1] ? (xr + yr) : (xr & yr);
            o  = ctrl[0] ? ~o : o;
            alu_compute = o;
        end
    endfunction

    // locals for the reference computation
    reg        isC, jump;
    reg [15:0] ins, yval, aluRes, newA, newD, newPC;
    reg        zr, ng;

    task anchor15(input [14:0] got, input [14:0] exp, input [127:0] name);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL anchor %0s: got %0d want %0d", name, got, exp);
            end
        end
    endtask

    initial begin
        // Prime registers to a defined 0 state: the first posedge (t=5) latches
        // initial values; reset=1 across it keeps PC at 0 (no spurious +1).
        instruction = 0; inM = 0; reset = 1;

        for (idx = 0; idx < 46; idx = idx + 1) begin
            @(negedge clk);
            ins         = prog[idx];
            instruction = ins;
            inM         = (idx >= 9)  ? 16'd11111 : 16'd0;  // inM set at step 10 onward
            reset       = (idx == 44) ? 1'b1 : 1'b0;        // reset asserted once
            #1;

            // ----- reference: combinational (pre-edge) -----
            isC    = ins[15];
            yval   = ins[12] ? inM : refA;
            aluRes = isC ? alu_compute(refD, yval, ins[11:6]) : 16'b0;
            zr     = (aluRes == 16'b0);
            ng     = aluRes[15];

            // pre-edge checks
            if (writeM !== (isC & ins[3])) begin
                errors = errors + 1;
                $display("FAIL step %0d writeM: got %b want %b", idx, writeM, (isC & ins[3]));
            end
            if (addressM !== refA[14:0]) begin
                errors = errors + 1;
                $display("FAIL step %0d addressM(pre): got %0d want %0d", idx, addressM, refA[14:0]);
            end
            if ((isC & ins[3]) && (outM !== aluRes)) begin   // outM matters when writing M
                errors = errors + 1;
                $display("FAIL step %0d outM: got %h want %h", idx, outM, aluRes);
            end

            // ----- reference: next state -----
            jump  = isC & ((ng & ins[2]) | (zr & ins[1]) | (~ng & ~zr & ins[0]));
            newA  = isC ? (ins[5] ? aluRes : refA) : ins;
            newD  = (isC & ins[4]) ? aluRes : refD;
            newPC = reset ? 16'b0 : (jump ? refA : (refPC + 16'b1));

            @(posedge clk);
            #1;
            refA = newA; refD = newD; refPC = newPC;

            // post-edge checks (committed)
            if (addressM !== refA[14:0]) begin
                errors = errors + 1;
                $display("FAIL step %0d addressM(post): got %0d want %0d", idx, addressM, refA[14:0]);
            end
            if (pc !== refPC[14:0]) begin
                errors = errors + 1;
                $display("FAIL step %0d pc: got %0d want %0d", idx, pc, refPC[14:0]);
            end
        end

        // Anchors taken directly from CPU.cmp (externally-visible columns)
        // (final committed state after @32767 at step 46: addressM=32767, pc=1)
        anchor15(addressM, 15'd32767, "final addressM");
        anchor15(pc,       15'd1,     "final pc");

        if (errors == 0) $display("CPU: ALL TESTS PASSED");
        else             $display("CPU: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule

`default_nettype wire
