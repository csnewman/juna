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

    ; Reserved for helper instructions
    i3 => 0xB
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
            lcb i1, 0x8

            lcb {d}, {value}[15:8]
            shf {d}, {d}, i1

            lcb i2, {value}[7:0]
            orr {d}, {d}, i2
        }
    }
    ldc {d: register}, {value} => {
        assert(value >= 0)
        assert(value <= 0xffffff)
        
        asm {
            lcb i1, 0x8

            lcb {d}, {value}[23:16]
            shf {d}, {d}, i1

            lcb i2, {value}[15:8]
            orr {d}, {d}, i2
            shf {d}, {d}, i1

            lcb i2, {value}[7:0]
            orr {d}, {d}, i2
        }
    }
    ldc {d: register}, {value} => {
        assert(value >= 0)
        assert(value <= 0xffffffff)
        
        asm {
            lcb i1, 0x8

            lcb {d}, {value}[31:24]
            shf {d}, {d}, i1

            lcb i2, {value}[23:16]
            orr {d}, {d}, i2
            shf {d}, {d}, i1

            lcb i2, {value}[15:8]
            orr {d}, {d}, i2
            shf {d}, {d}, i1

            lcb i2, {value}[7:0]
            orr {d}, {d}, i2
        }
    }

    ; Jump to address
    jmp {d} => asm {
        ldc i3, {d}
        brn i3
    }
    jeq {d}, {a: register}, {b: register} => asm {
        ldc i3, {d}
        beq i3, {a}, {b}
    }
    ; jne {d}, {a: register}, {b: register} => asm {
    ;     ldc i3, {d}
    ;     bne i3, {a}, {b}
    ; }
    jlt {d}, {a: register}, {b: register} => asm {
        ldc i3, {d}
        blt i3, {a}, {b}
    }
    jle {d}, {a: register}, {b: register} => asm {
        ldc i3, {d}
        ble i3, {a}, {b}
    }
    jlts {d}, {a: register}, {b: register} => asm {
        ldc i3, {d}
        blts i3, {a}, {b}
    }

    ; Stack ops
    pushb {r: register} => asm {
        lcb i3, 1
        sub sp, sp, i3
        stb {r}, sp
    }
    popb {r: register} => asm {
        ldb {r}, sp
        lcb i3, 1
        add sp, sp, i3
    }
    pushs {r: register} => asm {
        lcb i3, 2
        sub sp, sp, i3
        sts {r}, sp
    }
    pops {r: register} => asm {
        lds {r}, sp
        lcb i3, 2
        add sp, sp, i3
    }
    pushw {r: register} => asm {
        lcb i3, 4
        sub sp, sp, i3
        stw {r}, sp
    }
    popw {r: register} => asm {
        ldw {r}, sp
        lcb i3, 4
        add sp, sp, i3
    }

    ; Function calls
    call {d} => asm {
        ldc i3, {d}

        lcb i1, 4
        lcb i2, 6      ; Offset from add to after brn

        add i2, i2, pc
        sub sp, sp, i1
        stw i2, sp

        brn i3
    }
    ret => asm {
        ldw i2, sp
        lcb i3, 4
        add sp, sp, i3
        brn i2
    }

    ; Busy loop
    hlt => asm {
        ldc i3, $
        brn i3
    }
}
