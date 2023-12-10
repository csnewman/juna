#include "utils.asm"

lights_adr = 1000
lights_adr_alt = 2000

; nop
; nop
; add r0, r0, r0
; ldc r1, 0x10
; ldc r2, 1024
; ldc r3, 0xFFFFFF
; ldc r4, 0xFFFFFFFF



entry_point:

; ldc r0, {lights_adr_alt}

ldc r1, 0
ldc r2, 1

ldc r3, fn_pulse
ldc r4, 0
ldc r5, 100
ldc r6, 0 ; 0

.loop:

ldc r0, lights_blob
call fn_pulse
; call r3
call fn_lights_frame
add r1, r1, r2

ldc r0, 0xFFFF
call fn_sleep

ldc r0, lights_blob_alt
call fn_pulse
; call r3
call fn_lights_frame
add r1, r1, r2

ldc r0, 0xFFFF
call fn_sleep


; beq .switch, r1, r5
brn .loop

.switch:
ldc r1, 0

beq .switch_alt, r4, r6

ldc r4, 0
ldc r3, fn_rainbow
brn .loop

.switch_alt:

ldc r4, 1
ldc r3, fn_spin
brn .loop

hlt

#include "rainbow.asm"
#include "spin.asm"
#include "pulse.asm"
#include "hsl.asm"

lights_blob:
#res 304
lights_blob_alt:
; #res 304

