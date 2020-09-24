# stackmachine

This repository is stack machine CPU for Tang Nano FPGA.

Specification:

- Instruction: 8bit or 16bit word length
- 8 instructions available
- Instruction memory: 8bit 256words : all for instructions
- Data: 8bit length
- Data stack 31 steps: because of Tang Nano's capacity of logics
- Data register: reg_a and reg_b 8bit rength
- Data reg_a is set stack's pop'ed data.
- Data reg_b is set reg_a's data when pop stack.
