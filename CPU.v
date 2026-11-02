// =====================================================================
// CPU.v  --  The Hack CPU   (STUDENT STARTER CODE)
// Structural Verilog. Build the CPU datapath and its decode logic from the
// chips you completed in earlier labs plus the gates in primitives.v.
// Depends on: primitives.v, adders.v (Add16/Inc16), ALU.v, PC.v, and
//             given.v (ARegister, DRegister, Register).
//
// Name of student(s): Elijah Daniel
//
// Instructions:
//   * Fill in the body of the module below (marked "// FIXME").
//   * Do NOT rename the module or change its port list -- the testbench
//     (CPU_tb.v) connects to this interface exactly as written.
//   * Build the design STRUCTURALLY: instantiate gates / sub-chips, e.g.
//         Mux16 m(.a(instruction), .b(aluOut), .sel(instruction[15]), .out(w));
//     A separate "decoder" chip is NOT needed -- generate each control
//     signal with a small Boolean circuit built from the basic gates
//     (And, Or, Not) applied to the instruction bit-fields.
//   * primitives.v and given.v are already in this folder. Copy the files
//     you completed in the earlier labs in as well:
//         adders.v (adder lab),  ALU.v (ALU lab),  PC.v (program-counter lab)
//     (you do NOT need memory.v -- the Register your PC uses is in given.v),
//     then build and run the self-checking testbench with:
//         iverilog -g2001 -o cpu_tb primitives.v given.v adders.v ALU.v \
//                  PC.v CPU.v CPU_tb.v
//         vvp cpu_tb
//     A correct design prints "CPU: ALL TESTS PASSED".
//
// Registers A, D and PC commit on the rising edge of clk. outM and writeM
// are combinational (they reflect execution of the current instruction
// against the current register state). addressM and pc are clocked.
//
// The instruction fields (see the handout, Fig. of the datapath):
//   instruction[15]        : opcode  (0 = A-instruction, 1 = C-instruction)
//   instruction[12]        : a-bit   (ALU y input is A when 0, M when 1)
//   instruction[11:6]      : comp    (the six ALU control bits zx,nx,zy,ny,f,no)
//   instruction[5:3]       : dest    (d1 d2 d3 -> load A, load D, write M)
//   instruction[2:0]       : jump    (j1 j2 j3 -> negative, zero, positive)
// =====================================================================

`default_nettype none

module CPU(
    input  wire        clk,
    input  wire [15:0] inM,          // M value input (= RAM[A])
    input  wire [15:0] instruction,  // instruction to execute
    input  wire        reset,        // restart (1) or continue (0)
    output wire [15:0] outM,         // M value output
    output wire        writeM,       // write to M?
    output wire [14:0] addressM,     // address of M
    output wire [14:0] pc            // address of next instruction
);
    // FIXME: implement the Hack CPU structurally. A suggested staging that
    // follows the datapath blueprint in the handout:
    //
    //   (a) A register: its input is the instruction itself (A-instruction)
    //       or the ALU output (C-instruction) -- select with a Mux16 on
    //       instruction[15]. Load it when the instruction is type A, OR it
    //       is type C with dest bit instruction[5] set:
    //           loadA = !instruction[15] OR instruction[5]
    //       Drive addressM from the low 15 bits of the A register.
    //
    //   (b) D register: load it only on a C-instruction whose dest bit
    //       instruction[4] is set:  loadD = instruction[15] AND instruction[4].
    //       Its input is the ALU output.
    //
    //   (c) ALU: x is the D register; y is either the A register or inM,
    //       selected by the a-bit instruction[12] with a Mux16. The six
    //       control bits are instruction[11:6]. Drive outM from the ALU
    //       output; expose the zr and ng status flags for the jump logic.
    //
    //   (d) writeM: a C-instruction with dest bit instruction[3] set:
    //           writeM = instruction[15] AND instruction[3].
    //
    //   (e) Jump logic: decode the jump field instruction[2:0] and combine
    //       it with zr/ng to decide whether to branch. A DMux8Way fed by a
    //       constant 1 and selected by instruction[2:0] gives one wire per
    //       jump mnemonic (null, JGT, JEQ, JGE, JLT, JNE, JLE, JMP); AND each
    //       with the matching condition on zr/ng (e.g. JGT needs !zr AND !ng),
    //       OR the results together, and AND with instruction[15] so jumps
    //       only occur on C-instructions. Call this loadPC.
    //
    //   (f) PC: instantiate your PC with in = A register, load = loadPC,
    //       inc = 1 (always advance unless loaded or reset), and reset =
    //       reset. Drive pc from the low 15 bits of the PC output.
    //
    // Declare internal wires as needed for the intermediate signals.
    wire one;
    assign one = 1'b1;

    wire isC, isA, loadA, loadD;
    assign isC = instruction[15];
    Not nIsA(.in(isC), .out(isA));
    Or oLoadA(.a(isA), .b(instruction[5]), .out(loadA));
    And aLoadD(.a(isC), .b(instruction[4]), .out(loadD));
    And aWriteM(.a(isC), .b(instruction[3]), .out(writeM));

    wire[15:0] aIn, aOut, dOut, aluy, aluOut;
    wire zr, ng;

    Mux16 muxA(.a(instruction), .b(aluOut), .sel(isC), .out(aIn));
    ARegister regA(.clk(clk), .in(aIn), .load(loadA), .out(aOut));
    DRegister regD(.clk(clk), .in(aluOut), .load(loadD), .out(dOut));
    Mux16 muxAM(.a(aOut), .b(inM), .sel(instruction[12]), .out(aluy));

    ALU alu(.x(dOut), .y(aluy), .zx(instruction[11]), .nx(instruction[10]),
            .zy(instruction[9]), .ny(instruction[8]), .f(instruction[7]),
            .no(instruction[6]), .out(aluOut), .zr(zr), .ng(ng));

    assign outM = aluOut;
    assign addressM = aOut[14:0];

    wire jNull, JGT, JEQ, JGE, JLT, JNE, JLE, JMP;
    DMux8Way dmuxJump(.in(one), .sel(instruction[2:0]),
                        .a(jNull), .b(JGT), .c(JEQ), .d(JGE),
                        .e(JLT), .f(JNE), .g(JLE), .h(JMP));
    
    wire zrORng, notZr, notNg, pos;
    Or oZrNg(.a(zr), .b(ng), .out(zrORng));
    Not nZr(.in(zr), .out(notZr));
    Not nPos(.in(zrORng), .out(pos));
    Not nNg(.in(ng), .out(notNg));

    wire tGT, tEQ, tGE, tLT, tNE, tLE, tJMP;
    And aGT(.a(JGT), .b(pos), .out(tGT));
    And aEQ(.a(JEQ), .b(zr), .out(tEQ));
    And aGE(.a(JGE), .b(notNg), .out(tGE));
    And aLT(.a(JLT), .b(ng), .out(tLT));
    And aNE(.a(JNE), .b(notZr), .out(tNE));
    And aLE(.a(JLE), .b(zrORng), .out(tLE));
    And aJMP(.a(JMP), .b(one), .out(tJMP));

    wire o1, o2, o3, o4, anyJump, loadPC;
    Or o1o2(.a(tGT), .b(tEQ), .out(o1));
    Or o3o4(.a(tGE), .b(tLT), .out(o2));
    Or o5o6(.a(tNE), .b(tLE), .out(o3));
    Or o1o2o3(.a(o1), .b(o2), .out(o4));
    Or o4o3(.a(o4), .b(o3), .out(anyJump));

    wire o6;
    Or oIncludeJMP(.a(anyJump), .b(tJMP), .out(o6));
    And aLoadPC(.a(isC), .b(o6), .out(loadPC));

    wire[15:0] pcOut;
    PC pcReg(.clk(clk), .in(aOut), .load(loadPC), .inc(one), .reset(reset), .out(pcOut));
    assign pc = pcOut[14:0];

endmodule

`default_nettype wire
