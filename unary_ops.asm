// Exercises the unary operators of the Hack instruction set, in particular the
// bitwise negation operator (!). None of the other test programs supplied with
// this problem uses !, so an assembler that fails to recognize it will pass all
// of them and fail here.
//
// Expected results:
//   R0 <-- !0    = -1  (0xFFFF)   uses !A
//   R1 <-- !(-1) =  0             uses !D
//   R2 <-- 5
//   R3 <-- !5    = -6  (0xFFFA)   uses !M
//   R4 <-- -6                     uses AD = !D, a compound destination
//   R5 <-- -5                     uses -D, the unary minus, for contrast
// Author: Naga Kandasamy

    @0
    D = !A      // D <-- !0 = -1
    @0
    M = D       // R0 <-- -1

    @1
    M = !D      // R1 <-- !(-1) = 0

    @5
    D = A
    @2
    M = D       // R2 <-- 5
    D = !M      // D <-- !5 = -6
    @3
    M = D       // R3 <-- -6

    @5
    D = A       // D <-- 5
    AD = !D     // A and D both <-- !5 = -6
    @4
    M = D       // R4 <-- -6

    @5
    D = A       // D <-- 5
    D = -D      // D <-- -5
    @5
    M = D       // R5 <-- -5

(END)
    @END
    0;JMP       // While (1);
