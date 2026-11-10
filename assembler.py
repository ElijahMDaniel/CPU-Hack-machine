# -*- coding: utf-8 -*-
"""Assembler for the Hack processor.

Translates a Hack assembly-language program into the binary code understood by
the Hack computer:

    python assembler.py mult.asm        ->  writes mult.hack

The translation is organized as two passes over the source program. The first
pass scans every statement, splits it into its constituent fields, and records
the result in an intermediate representation; it also binds every label to the
ROM address of the instruction that follows it. The second pass walks that
intermediate representation and emits one 16-bit word per instruction,
resolving symbols against the symbol table as it goes. Labels must all be bound
before any code is emitted, which is precisely why two passes are needed.

The places you must complete are marked FIXME. In outline:

    parse()                 the finite automaton that scans one statement
    valid_tokens()          checks the scanned fields against the tables below
    run_assembler()         the two passes and the symbol table they build
    generate_machine_code() emits the binary words

Author: Naga Kandasamy
Date modified: August 3, 2026

Student name(s): Elijah Daniel
Date modified: November 9, 2026
"""

import os
import sys

"""The comp field is a c1 c2 c3 c4 c5 c6"""
valid_comp_patterns = {'0':'0101010', 
                       '1':'0111111',
                       '-1':'0111010',
                       'D':'0001100',
                       'A':'0110000',
                       '!D':'0001101',
                       '!A':'0110001',
                       '-D':'0001111',
                       '-A':'0110011',
                       'D+1':'0011111',
                       'A+1':'0110111',
                       'D-1':'0001110',
                       'A-1':'0110010',
                       'D+A':'0000010',
                       'D-A':'0010011',
                       'A-D':'0000111',
                       'D&A':'0000000',
                       'D|A':'0010101',
                       'M':'1110000',
                       '!M':'1110001',
                       '-M':'1110011',
                       'M+1':'1110111',
                       'M-1':'1110010',
                       'D+M':'1000010',
                       'M+D':'1000010',
                       'D-M':'1010011',
                       'M-D':'1000111',
                       'D&M':'1000000',
                       'D|M':'1010101'
                       }

"""The dest bits are d1 d2 d3"""
valid_dest_patterns = {'null':'000',
                       'M':'001',
                       'D':'010',
                       'MD':'011',
                       'A':'100',
                       'AM':'101',
                       'AD':'110',
                       'AMD':'111'
                       }

"""The jump fields are j1 j2 j3"""
valid_jmp_patterns =  {'null':'000',
                       'JGT':'001',
                       'JEQ':'010',
                       'JGE':'011',
                       'JLT':'100',
                       'JNE':'101',
                       'JLE':'110',
                       'JMP':'111'
                       }

"""Symbol table populated with predefined symbols and RAM locations"""
symbol_table = {'SP':0,
                'LCL':1,
                'ARG':2,
                'THIS':3,
                'THAT':4,
                'R0':0,
                'R1':1,
                'R2':2,
                'R3':3,
                'R4':4,
                'R5':5,
                'R6':6,
                'R7':7,
                'R8':8,
                'R9':9,
                'R10':10,
                'R11':11,
                'R12':12,
                'R13':13,
                'R14':14,
                'R15':15,
                'SCREEN':16384,
                'KBD':24576
                }

def print_intermediate_representation(ir):
    """Print intermediate representation"""
    
    for i in ir:
        print()
        for key, value in i.items():
            print(key, ':', value)

        
def print_instruction_fields(s):
    """Print fields in instruction"""
    
    print()
    for key, value in s.items():
        print(key, ':', value)


def valid_tokens(s):
    """Return True if tokens belong to valid instruction-field patterns.

    The automaton in parse() establishes that a statement is well formed as a
    sequence of characters; it does not establish that the fields it collected
    name real operations. 'D=D+Q' is rejected by the automaton, but 'D=A+A' is
    not --- it scans perfectly and is still not a legal computation. Checking
    the collected fields against valid_dest_patterns, valid_comp_patterns, and
    valid_jmp_patterns is what separates the two.

    Branch on s['instruction_type']: a comment or an A-instruction has no fields
    to check, whereas a C-instruction must have a valid dest and comp, and a
    jump must have a valid comp and jmp.
    """
    instruction_type = s['instruction_type']
    if instruction_type in ('COMMENT', 'L', 'A'):
        return True

    if instruction_type == 'C':
        return (s['dest'] in valid_dest_patterns and s['comp'] in valid_comp_patterns and s['jmp'] in valid_jmp_patterns)

    if instruction_type == 'J':
        return (s['comp'] in valid_comp_patterns and s['jmp'] in valid_jmp_patterns and s['jmp'] != 'null')

    return False


def parse(command):
    """Implements finite automate to scan hack assembly commands and parse them.

    WHITE SPACE: Space characters are ignored. Empty lines are ignored.
    
    COMMENT: Text beginning with two slashes (//) and ending at the end of the line is considered 
    comment and is ignored.
    
    CONSTANTS: Must be non-negative and are written in decimal notation. 
    
    SYMBOL: A user-defined symbol can be any sequence of letters, digits, underscore (_), dot (.), 
    dollar sign ($), and colon (:) that does not begin with a digit.
    
    LABEL: (SYMBOL)
    """
    
    # Data structure to hold the parsed fields for the command
    s = {}
    s['instruction_type'] = ''
    s['value'] = ''
    s['value_type'] = ''
    s['dest'] = ''
    s['comp'] = ''
    s['jmp'] = ''
    s['status'] = 0
      
    
    # Valid operands and operations for C-type instructions
    valid_operands = '01DMA'
    valid_operations = '+-&|'
    comp_chars = valid_operands + valid_operations + '!'

    accepting_states = ('START', 'A_CONSTANT', 'A_SYMBOL', 'L_END', 'C_SECOND', 'C_JUMP')
    state = 'START'
    
    for i,char in enumerate(command):
        if char == '/':
            if command[i + 1:i + 2] != '/':
                s['status'] = 1
            break
        if char in ' \t\r\n':
            continue

        #checks to see if current state is start
        #If @ then a type, if ( then l type, if char in comp_chars then c type
        #else status = 1
        if state == 'START':
            if char == '@':
                s['instruction_type'] = 'A'
                state = 'A_START'
            elif char == '(':
                s['instruction_type'] = 'L'
                state = 'L_START'
            elif char in comp_chars:
                s['instruction_type'] = 'C'
                s['comp'] = char
                state = 'C_FIRST'
            else:
                s['status'] = 1

        #checks to see if current state is A_START
        #if all digits then A_CONSTANT
        #if letter or any previous special characters then A_SYMBOL
        #else status = 1
        elif state == 'A_START':
            if char.isdigit():
                s['value'] = char
                s['value_type'] = 'constant'
                state = 'A_CONSTANT'
            elif char.isalpha() or char == '_' or char == '.' or char == '$' or char == ':':
                s['value'] = char
                s['value_type'] = 'symbol'
                state = 'A_SYMBOL'
            else:
                s['status'] = 1

        #checks to see if current state is A_CONSTANT
        #if all digits then add char to value
        #else status = 1
        elif state == 'A_CONSTANT':
            if char.isdigit():
                s['value'] += char
            else:
                s['status'] = 1

        #checks to see if current state is A_SYMBOL
        #if all digit or special character then add char to value 
        #else status = 1
        elif state == 'A_SYMBOL':
            if char.isalnum() or char == '_' or char == '.' or char == '$' or char == ':':
                s['value'] += char
            else:
                s['status'] = 1

        #checks to see if current state is L_START
        #if letter or any special characters then state = L_SYMBOL
        #else status = 1
        elif state == 'L_START':
            if char.isalpha() or char == '_' or char == '.' or char == '$' or char == ':':
                s['value'] = char
                s['value_type'] = 'symbol'
                state = 'L_SYMBOL'
            else:
                s['status'] = 1

        #checks to see if current state is L_SYMBOL
        #if number or special character then char to value
        #if ) then state = L_END
        #else status = 1
        elif state == 'L_SYMBOL':
            if char.isalnum() or char == '_' or char == '.' or char == '$' or char == ':':
                s['value'] += char
            elif char == ')':
                state = 'L_END'
            else:
                s['status'] = 1

        #checks to see if current state is L_END
        #if state = L_END then status = 1
        elif state == 'L_END':
            s['status'] = 1

        #checks to see if current state is C_FIRST
        #if char in comp_chars then add char to comp
        #if char is = then dest = comp, comp = '', state = C_SECOND
        #if char is ; then instruction type = J
        #else status = 1
        elif state == 'C_FIRST':
            if char in comp_chars:
                s['comp'] += char
            elif char == '=':
                s['dest'] = s['comp']
                s['comp'] = ''
                state = 'C_SECOND'
            elif char == ';':
                s['instruction_type'] = 'J'
                state = 'C_JUMP'
            else:
                s['status'] = 1
        
        #checks to see if current state is C_SECOND
        #if char in comp_chars then add char to comp
        #if char is ; then instruction type = J
        #else status = 1
        elif state == 'C_SECOND':
            if char in comp_chars:
                s['comp'] += char
            elif char == ';':
                state = 'C_JUMP'
            else:
                s['status'] = 1

        #checks to see if current state is C_JUMP
        #if char in comp_chars then add char to jmp
        #else status = 1
        elif state == 'C_JUMP':
            if char.isalpha():
                s['jmp'] += char
            else:
                s['status'] = 1

        if s['status'] != 0:
            break

    if s['status'] == 0:
        if (state not in accepting_states or (state == 'C_SECOND' and s['comp'] == '') or (state == 'C_JUMP' and s['jmp'] == '')):
            s['status'] = 1

    if s['status'] == 0:
        if state == 'START':
            s['instruction_type'] = 'COMMENT'
        if s['instruction_type'] == 'J':
            s['dest'] = 'null'
        if state == 'C_SECOND':
            s['jmp'] = 'null'
        if not valid_tokens(s):
            s['status'] = 1
    return s
   
def generate_machine_code(ir):
    """Generate machine code from the intermediate data structure.

    Returns a list of 16-character strings, one per instruction, in ROM order.

    An A-instruction becomes a 0 followed by its 15-bit address. If the value is
    a constant, use it directly; if it is a symbol, look it up in the symbol
    table --- and a symbol still absent at this point is a variable being
    mentioned for the first time, so allocate it the next free RAM location
    starting at address 16.

    A C-instruction becomes 111 followed by the comp, dest, and jump bits read
    out of the three pattern tables defined above.
    """

    machine_code = []
    next_variable_address = 16

    for s in ir:
        if s['instruction_type'] == 'A':
            if s['value_type'] == 'constant':
                address = int(s['value'])

            else:
                if s['value'] in symbol_table:
                    address = symbol_table[s['value']]
                else:
                    address = next_variable_address
                    symbol_table[s['value']] = address
                    next_variable_address += 1
            binary_code = '0' + format(address, '015b')
            machine_code.append(binary_code)

        elif s['instruction_type'] == 'C' or s['instruction_type'] == 'J':
            comp = valid_comp_patterns[s['comp']]
            dest = valid_dest_patterns[s['dest']]
            jmp = valid_jmp_patterns[s['jmp']]
            binary_code = '111' + comp + dest + jmp
            machine_code.append(binary_code)

    return machine_code
    

def print_machine_code(machine_code):
    """Print generated machine code"""
    
    rom_address = 0
    for code in machine_code:
        print(rom_address, ':', code)
        rom_address = rom_address + 1


def run_assembler(file_name):
    """Pass 1: Parse the assembly commands into an intermediate data structure.
    This can be a list of elements, called ir, where each element is a dictionary with the following
    structure:

    s['instruction_type'] = ''
    s['value'] = ''
    s['value_type'] = ''
    s['dest'] = ''
    s['comp'] = ''
    s['jmp'] = ''
    s['status'] = 0

    The symbol table is also generated in this step.

    Comments and blank lines occupy no ROM address and contribute nothing to the
    intermediate representation. A label declaration, (SYMBOL), occupies no ROM
    address either --- it binds its symbol to the address of the next
    instruction and is then discarded. Only A-, C-, and jump instructions
    advance the ROM address counter.

    The six supplied test programs are free of errors, so reporting a faulty
    program is not required and no marks depend on it. The scaffolding is here
    anyway, and you will be glad of it while debugging your own code: parse()
    returns a status flag, line_number is tracked below, and a message such as

        Error, line 23: syntax error  --> 'D=A+Q'

    tells you what to fix, where 'syntax error' alone does not.
    """

    ir = []
    rom_address = 0

    with open(file_name, 'r') as f:
        for line_number, command in enumerate(f, start = 1):
            s = parse(command)

            if s['status'] != 0:
                print("Error, line", line_number, ": syntax_error  -->", command.strip())
                return []

            if s['instruction_type'] == 'COMMENT':
                continue

            elif s['instruction_type'] == 'L':
                symbol_table[s['value']] = rom_address

            else:
                ir.append(s)
                rom_address += 1

    machine_code = generate_machine_code(ir)

    return machine_code
    
  
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: Python assembler.py file-name.asm")
        print("Example: Python assembler.py series_sum.asm")
    else:
        print("Assembling file:", sys.argv[1])
        print()
        file_name_minus_extension, _ = os.path.splitext(sys.argv[1])
        output_file = file_name_minus_extension + '.hack'
        machine_code = run_assembler(sys.argv[1])
        if machine_code:
            print('Machine code was generated successfully');
            print('Writing machine code output to file:', output_file)
            f = open(output_file, 'w')
            for s in machine_code:
                f.write('%s\n' %s)
            f.close()
        else:
            print('Error generating machine code')