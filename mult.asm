// Calculate C = A * B 
// A>= 0, B >= 0
// A and B are stored in memory registers R0 and R1
// C is placed in memory register R2
// Author: Naga Kandasamy


    @2  
    M = 0   // Initialize R2  
(BEGIN)
    @1 
    D = M   // D <-- B
    @END
    D;JEQ   // Check for termination condition 
    @0
    D = M   // D <-- A
    @2
    M = M + D   // sum <-- sum + A
    @1
    M = M - 1   // B <-- B - 1
    @BEGIN
    0;JMP
(END)
    @END
    0;JMP   // While (1);
