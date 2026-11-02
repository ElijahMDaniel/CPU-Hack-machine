// =====================================================================
// Computer.v  --  The complete Hack computer   (STUDENT STARTER CODE)
// Structural Verilog. Compose the topmost computer chip from the ROM,
// the CPU you built in the previous part, and the Memory chip.
// Depends on: every earlier stage -- primitives.v, given.v (ROM32K and the
//             built-ins), adders.v, ALU.v, PC.v, CPU.v, Memory.v.
//
// Name of student(s): FIXME
//
// Instructions:
//   * Fill in the body of the module below (marked "// FIXME").
//   * Do NOT rename the module or change its port list.
//   * Name the three instances exactly rom, cpu and mem:
//         ROM32K rom(...);   CPU cpu(...);   Memory mem(...);
//     The testbench reaches into the design through these names (and the
//     RAM16K instance "ram" inside Memory); any other name is a compile
//     error ("Unable to bind ... uut.rom.mem").
//   * This is pure top-level wiring -- three chip instances connected by
//     the buses that run between them; no new logic is needed.
//   * primitives.v and given.v are in this folder. Copy in the files you
//     completed earlier: adders.v, ALU.v, PC.v, CPU.v (the CPU you finished
//     in the previous part). You also write Memory.v in this same folder.
//     (You do NOT need memory.v -- Register is in given.v.) Then build and
//     run the self-checking testbench with:
//         iverilog -g2001 -o computer_tb primitives.v given.v adders.v \
//                  ALU.v PC.v CPU.v Memory.v Computer.v Computer_tb.v
//         vvp computer_tb            (run from this folder so it finds Add.hack)
//     A correct design prints "COMPUTER: ALL TESTS PASSED".
//
// reset==1 restarts the program (PC -> 0); reset==0 runs it. The program
// itself lives in ROM32K, loaded by the testbench from a .hack file.
// =====================================================================

`default_nettype none

module Computer(input wire clk, input wire reset);

    // FIXME: wire up the three chips as shown in the handout figure:
    //
    //   (a) ROM32K instruction memory: address it with the CPU's pc; its
    //       output is the current instruction.
    //
    //   (b) Memory (the chip you built in the previous part): its address is
    //       the CPU's addressM, its input is the CPU's outM, and it loads
    //       when the CPU asserts writeM. Its output is the M value read back.
    //
    //   (c) CPU: feed it the instruction (from ROM), the M value (from
    //       Memory), and reset. It produces outM, writeM, addressM and pc,
    //       which connect back to ROM and Memory as above.
    //
    // Declare internal wires for instruction, inM, outM, writeM, addressM, pc.

    wire [15:0] instruction, inM, outM;
    wire writeM;
    wire [14:0] addressM, pc;
    ROM32K rom(.address(pc), .out(instruction));
    CPU cpu(.clk(clk), .inM(inM), .instruction(instruction), .reset(reset),
            .outM(outM), .writeM(writeM), .addressM(addressM), .pc(pc));
    Memory mem(.clk(clk), .in(outM), .load(writeM), .address(addressM), .out(inM));


endmodule

`default_nettype wire
