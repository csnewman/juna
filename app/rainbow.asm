; --------------------------------
; Rainbow frame
; --------------------------------
; R0: tgt

fn_rainbow:
pushall
mov r11, r0
mov r6, r1

ldc r5, 255
ldc r7, hsl_table
ldc r8, 1
ldc r9, 0
ldc r10, 100

mov r2, r9
sub r2, r9, r8
sub r2, r2, r8
; sub r2, r2, r8
; sub r2, r2, r8
; sub r2, r2, r8
; sub r2, r2, r8
; sub r2, r2, r8


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



.loop:

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

; increment cycle pos
add r6, r6, r8

sub r10, r10, r8
beq .exit, r10, r9
brn .loop

.exit:
popall
ret
