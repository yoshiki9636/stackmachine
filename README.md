# stackmachine

This repository is stack machine CPU for Tang Nano FPGA.

Specification:

- 8bit data stack machine archtecture with uart debugger
- Instruction: 8bit or 16bit word length
- 8 instructions available
- Instruction memory: 8bit 256words : all for instructions
- Data: 8bit length
- Data stack 31 steps: because of Tang Nano's capacity of logics
- Data register: reg_a and reg_b 8bit rength
- Data reg_a is set stack's pop'ed data
- Data reg_b is set reg_a's data when pop stack
- Uart: controlling load programs, reading wiriting memory, excecutions, and monitoring

Instructions:
- 1st byte 7:4 : opecode
- 1st byte 3:0 : control bits
- 2nd byte 7:0 : Immediate value or jump address (2byte instruction only)


- opecode: 0 : JMP
               Jump command controlled by flag bits
               bit 3 : Stack Underflow : 1: data stack underflow : can be cleard by uart
               bit 2 : Stack Overflow : 1: data stack underflow : can be cleard by uart
               bit 1 : Carry : 1: previouse calculation results carry 
               bit 0 : Zero : 1: previouse calculation results zero value
                                 calculation: ADD SUB CMP only
               none : Immediate Jump
               2nd byte : Jump address

- opecode 2 : POP
              Pop 1 value from data stack and store reg_a
              reg_b also stored reg_a's previouse value
              
- opecode 4 : PUSH
              Push 1 value to data stack
              value can be used as reg_a, reg_b and Immediate
              bit 1: reg_b selected
              bit 0: reg_a selected
              none : Immediate value selected
              2nd byte : Immediate value (when immediate selected)

  4 : PSH A,B or Immediate (16bit ops) byte1; Immediate value
          | 1:0 |
            0:A
　　　　　　1:B
            none : Immediate

　6 : ADD A and B or Immediate values, PUSH result and change flags
          | 1:0 |
            0:AB
            none : Immediate

　8 : SUB A and B or Immediate values, PUSH result and change flags
          | 1:0 |
            0:AB
            none : Immediate

　a : CMP sub A and B or Immediate values, and only change flags, not pushed result
          | 1:0 |
            0:AB
            none : Immediate

　c : OUT pop and output poped data to port#'s port 

　e : CLR clear stack and all flags

  f : NOP only step pc up


