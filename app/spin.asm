; --------------------------------
; Spin frame
; --------------------------------
; R0: tgt

fn_spin:
pushall
mov r11, r0

mov r5, r1

ldc r6, 0
ldc r8, 1
ldc r9, 0
ldc r10, 100

;  r4 = 
;  r5 = 
;  r6 = cycle pos
;  r7 = 
;  r8 = 1
;  r9 = 0
; r10 = led counter
; r11 = address



.loop:


; mov r0, r8


ldc r4, 0
beq .on, r6, r4

ldc r4, 26
beq .on, r6, r4

ldc r4, 42
beq .on, r6, r4

ldc r4, 56
beq .on, r6, r4

ldc r4, 74
beq .on, r6, r4

ldc r4, 84
beq .on, r6, r4

ldc r4, 92
beq .on, r6, r4

ldc r4, 96
beq .on, r6, r4

ldc r4, 98
beq .on, r6, r4

ldc r0, 0
brn .do

.on:
ldc r0, 255
; mov r0, r5
brn .do

; mov r0, r8

.do:

; r
stb r0, r11
add r11, r11, r8

; g
stb r0, r11
add r11, r11, r8

; b
stb r0, r11
add r11, r11, r8

; increment cycle pos
add r6, r6, r8

sub r10, r10, r8
beq .exit, r10, r9
brn .loop

.exit:
popall
ret
