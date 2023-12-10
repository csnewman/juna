#once

#subruledef register
{
    ; General purpose
    r0 => 0x0
    r1 => 0x1
    r2 => 0x2
    r3 => 0x3
    r4 => 0x4
    r5 => 0x5
    r6 => 0x6
    r7 => 0x7
    r8 => 0x8
    r9 => 0x9
    r10 => 0xA
    r11 => 0xB

    ; Reserved for helper instructions
    i2 => 0xC
    i1 => 0xD

    ; Special meaning
    sp => 0xE
    pc => 0xF
}

#ruledef
{
    nop => asm { and r0, r0, r0 }
    mov {d: register}, {a: register} => asm { and {d}, {a}, {a} }
    add {d: register}, {a: register}, {b: register} => b @ d @ 0b0000 @ a
    sub {d: register}, {a: register}, {b: register} => b @ d @ 0b0001 @ a
    xor {d: register}, {a: register}, {b: register} => b @ d @ 0b0010 @ a
    and {d: register}, {a: register}, {b: register} => b @ d @ 0b0011 @ a
    orr {d: register}, {a: register}, {b: register} => b @ d @ 0b0100 @ a
    shf {d: register}, {a: register}, {b: register} => b @ d @ 0b0101 @ a
    ; TODO: ROT
    ; TODO: ASH

    brn {d: register} => asm { beq {d}, r0, r0 }
    beq {d: register}, {a: register}, {b: register} => b @ d @ 0b1011 @ a
    ; bne {d: register}, {a: register}, {b: register} => b @ d @ 0b1100 @ a
    blt {d: register}, {a: register}, {b: register} => b @ d @ 0b1100 @ a
    ble {d: register}, {a: register}, {b: register} => b @ d @ 0b1101 @ a
    blts {d: register}, {a: register}, {b: register} => b @ d @ 0b1110 @ a

    lcb {d: register}, {value: u8} => {value}[3:0] @ d @ 0b1010 @ {value}[7:4]
    ldb {d: register}, {a: register} => a @ d @ 0b1111 @ 0b0000
    stb {d: register}, {a: register} => a @ d @ 0b1111 @ 0b0001
    lds {d: register}, {a: register} => a @ d @ 0b1111 @ 0b0010
    sts {d: register}, {a: register} => a @ d @ 0b1111 @ 0b0011
    ldw {d: register}, {a: register} => a @ d @ 0b1111 @ 0b0100
    stw {d: register}, {a: register} => a @ d @ 0b1111 @ 0b0101

    tcp {d: register}, {a: register} => a @ d @ 0b1111 @ 0b0110

    ldb {d: register}, {a} => asm {
        ldc i1, {a}
        ldb {d}, i1
    }
    stb {d: register}, {a} => asm {
        ldc i1, {a}
        stb {d}, i1
    }
    lds {d: register}, {a} => asm {
        ldc i1, {a}
        lds {d}, i1
    }
    sts {d: register}, {a} => asm {
        ldc i1, {a}
        sts {d}, i1
    }
    ldw {d: register}, {a} => asm {
        ldc i1, {a}
        ldw {d}, i1
    }
    stw {d: register}, {a} => asm {
        ldc i1, {a}
        stw {d}, i1
    }

    ldc {d: register}, {value} => {
        assert(value >= 0)
        assert(value <= 0xff)
        asm {
            lcb {d}, {value}
        }
    }
    ldc {d: register}, {value} => {
        assert(value >= 0)
        assert(value <= 0xffff)

        asm {
            lds {d}, pc
        } @ {value}[7:0] @ {value}[15:8]
    }
    ldc {d: register}, {value} => {
        assert(value >= 0)
        assert(value <= 0xffffffff)

        asm {
            ldw {d}, pc
        } @ {value}[7:0] @ {value}[15:8] @ {value}[23:16] @ {value}[31:24]
    }

    ; Jump to address
    brn {d} => asm { ldc pc, {d} }
    beq {d}, {a: register}, {b: register} => asm {
        ldc i1, {d}
        beq i1, {a}, {b}
    }
    ; jne {d}, {a: register}, {b: register} => asm {
    ;     ldc i1, {d}
    ;     bne i1, {a}, {b}
    ; }
    blt {d}, {a: register}, {b: register} => asm {
        ldc i1, {d}
        blt i1, {a}, {b}
    }
    ble {d}, {a: register}, {b: register} => asm {
        ldc i1, {d}
        ble i1, {a}, {b}
    }
    blts {d}, {a: register}, {b: register} => asm {
        ldc i1, {d}
        blts i1, {a}, {b}
    }

    ; Stack ops
    pushb {r: register} => asm {
        lcb i1, 1
        sub sp, sp, i1
        stb {r}, sp
    }
    popb {r: register} => asm {
        ldb {r}, sp
        lcb i1, 1
        add sp, sp, i1
    }
    pushs {r: register} => asm {
        lcb i1, 2
        sub sp, sp, i1
        sts {r}, sp
    }
    pops {r: register} => asm {
        lds {r}, sp
        lcb i1, 2
        add sp, sp, i1
    }
    pushw {r: register} => asm {
        lcb i1, 4
        sub sp, sp, i1
        stw {r}, sp
    }
    popw {r: register} => asm {
        ldw {r}, sp
        lcb i1, 4
        add sp, sp, i1
    }

    pushall => asm {
        pushw r0
        pushw r1
        pushw r2
        pushw r3
        pushw r4
        pushw r5
        pushw r6
        pushw r7
        pushw r8
        pushw r9
        pushw r10
        pushw r11
    }
    popall => asm {
        popw r11
        popw r10
        popw r9
        popw r8
        popw r7
        popw r6
        popw r5
        popw r4
        popw r3
        popw r2
        popw r1
        popw r0
    }

    ; Function calls
    call {d} => asm {
        lcb i1, 4
        lcb i2, 6      ; Offset from add to after brn

        add i2, i2, pc
        sub sp, sp, i1
        stw i2, sp

        brn {d}
    }
    call {d: register} => asm {
        lcb i1, 4
        lcb i2, 6      ; Offset from add to after brn

        add i2, i2, pc
        sub sp, sp, i1
        stw i2, sp

        brn {d}
    }
    ret => asm {
        ldw i2, sp
        lcb i1, 4
        add sp, sp, i1
        brn i2
    }

    ; Busy loop
    hlt => asm {
        ldc pc, $
    }
}
