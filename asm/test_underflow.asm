; stack underflow test
;  by yoshiki9636
NOP
PUSH I 00
OUT 00
:loop1
POP
JMP SU loop2
JMP IM loop1
:loop2
PUSH I 07
OUT 00
JMP IM loop2

