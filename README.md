# stackmachine

This repository is stack machine CPU for Tang Nano FPGA.

#Specification:

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

#Instructions:
- 1st byte 7:4 : opecode
- 1st byte 3:0 : control bits
- 2nd byte 7:0 : Immediate value or jump address (2byte instruction only)


- opecode: 0 : JMP

               Jump command controlled by flag bits
               
               bit 3 : Stack Underflow : 1: data stack underflow : can be cleard by CLR
               
               bit 2 : Stack Overflow : 1: data stack underflow : can be cleard by CLR
               
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

- opecode 6 : ADD

              Add reg_a and reg_b or Immediate value, push result to data stack and change flags
              
              bit 0: Add reg_a and reg_b
              
              none : Add reg_a and Immediate
              
              2nd byte : Immediate value (when immediate selected)

- opecode 8 : SUB

              Subtract from reg_a to reg_b or Immediate value, push result to data stack and change flags
              
              bit 0: Subtract from reg_a to reg_b
              
              none : Subtract from reg_a to Immediate
              
              2nd byte : Immediate value (when immediate selected)

- opecode a : SUB

              Subtract from reg_a to reg_b or Immediate value, and only change flags
              
              bit 0: Subtract from reg_a to reg_b
              
              none : Subtract from reg_a to Immediate
              
              2nd byte : Immediate value (when immediate selected)

- opecode c : OUT

              Pop a data and output poped data to port#'s port, reg_a and reg_b also changed as POP
              
              2nd byte : port# ( only port 0 is impremented for LED )

- opecode e : CLR

              Clear data stack pointer to zero and clear all flags to zero

- opecode f : NOP

              Only step PC up

#Uart monitor

Uart monitor can use to control CPU, read/write memory, monitor CPU status.
Control commands

- g XX : Execute CPU form address XX

- w XX : Write instruction memory from address XX

- r XX YY : Dump instruction memory between XX and YY

- p : Dump data stack memory

- s : Step CPU execution

- t : Trash and fill 0 to instuction memory, data stack, registers, flags 

- q :  Quit : using g and w

Command g and s : Output log to uart. Each instruction makes log 

                  incuding PC, instruction bytes, flag, reg_a, reg_b, stack pointer
                  
Command r and p : Dump memory with 4 bytes per line.


Author Yoshiki Kurokawa @yoshiki9636
