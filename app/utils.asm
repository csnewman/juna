; --------------------------------
; Sleep
; --------------------------------
; R0: time

fn_sleep:
pushw r1

ldc r1, fn_sleep_ret
ldc i1, 0
lcb i2, 1

fn_sleep_body:
beq r1, r0, i1
sub r0, r0, i2
brn fn_sleep_body

fn_sleep_ret:
popw r1
ret

; --------------------------------
; Lights frame
; --------------------------------
; R0: addr

fn_lights_frame:
ldc i1, 1
tcp i1, r0
ret

; tcp {d: register}, {a: register}