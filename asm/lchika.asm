; LED chika chika
;  by yoshiki9636

NOP
PUSH I 00
PUSH I 00
:mainloop
POP
POP
ADD I 01
OUT 00 
PUSH A
PUSH I 02
:waitloop
POP
SUB I 01
JMP Z mainloop
JMP IM waitloop
