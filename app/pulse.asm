; --------------------------------
; Pulse frame
; --------------------------------
; R0: tgt

pulse_pos:
#d8 0

#align 16
nop

fn_pulse:
pushall
mov r11, r0
mov r6, r1

ldc r5, 255
ldc r7, hsl_table
ldc r8, 1
ldc r9, 0
ldc r10, 100

mov r2, r9
;sub r2, r9, r8
;sub r2, r2, r8

;r0 val

;r2 bright

;  r4 = hsl addr
;  r5 = hsl mask
;  r6 = cycle pos
;  r7 = hsl table
;  r8 = 1
;  r9 = 0
; r10 = led counter
; r11 = address


ldc r0, 0
ldc r1, 0

pushw r0
pushw r1


ldb r1, pulse_pos

beq .pulr, r1, r10

add r1, r1, r8
brn .pulc

.pulr:
ldc r1, 0

.pulc:
stb r1, pulse_pos


.loop:

popw r1
popw r0
add r0, r0, r8
pushw r0
pushw r1

ldb r1, pulse_pos

blt .off_ver_1, r0, r1

ldc i1, 5
add r1, r1, i1

blt .main_ver, r0, r1
;brn .main_ver

.off_ver_1:


;ldb r1, pulse_pos

;ldc i1, 50
;sub r1, r1, i1

;blts .off_ver_2, r0, r1

;ldc i1, 5
;add r1, r1, i1

;blts .main_ver, r0, r1

ldc i1, 4
sub r2, r9, i1

brn .do_it



.off_ver_2:

; r
ldb r0, 0
stb r0, r11
add r11, r11, r8

; g
stb r0, r11
add r11, r11, r8

; b
stb r0, r11
add r11, r11, r8

brn .cont

.main_ver:

ldc r2, 0

.do_it:

; ensure in range
and r6, r6, r5

; r4=r6*3
mov r4, r6
add r4, r4, r6
add r4, r4, r6

; index into table
add r4, r4, r7

; r
ldb r0, r4
shf r0, r0, r2
stb r0, r11
add r11, r11, r8
add r4, r4, r8

; g
ldb r0, r4
shf r0, r0, r2
stb r0, r11
add r11, r11, r8
add r4, r4, r8

; b
ldb r0, r4
shf r0, r0, r2
stb r0, r11
add r11, r11, r8
add r4, r4, r8

.cont:

; increment cycle pos
add r6, r6, r8

sub r10, r10, r8
beq .exit, r10, r9
brn .loop

.exit:

popw r1
popw r0

popall
ret
