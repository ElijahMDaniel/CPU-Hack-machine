# Assembler
- Elijah Daniel
- 11/9/26
## Requirements
- Python
- Assembler python file
- A hack assembly file

## How to Run
Open a terminal containing assembler.py and the assembly file then run:
```bash
python assembler.py Add.asm
```
The output file is written in the same directory, using the input file's name with the .hack extension. Add.asm produces a Add.hack file. 

## Test Results
- Add.asm | pass
- mult.asm | pass
- max.asm | pass
- series_sum.asm | pass
- rect.asm | pass
- unary_ops.asm | pass

To verify these test results use
```bash
FC add.hack add_ref.hack
```
If that doesn't work try
```bash
fc.exe add.hack add_ref.hack
```

## Known Limitations
Error handling isn't perfect, since the test programs are error-free the more indepth checks aren't done and won't be caught 