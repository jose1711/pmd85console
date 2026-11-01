; doom85 - raycaster (Wolfenstein styl) pre PMD 85-1, i8080
PUTC    EQU 8500H
VIDEO   EQU 0D000H            ; riadok 64 videopamate, pohlad 48 stlpcov x 128 riadkov
MAPHI   EQU 30H               ; mapa: 16 stranok po 16 bajtov (stranka = riadok y)
STACKTOP EQU 7E00H
PX      EQU 2F00H
PY      EQU 2F02H
ANG     EQU 2F04H
RX      EQU 2F06H
RY      EQU 2F08H
IX      EQU 2F0AH
IY      EQU 2F0CH
COLP    EQU 2F0EH
COLN    EQU 2F10H
WP      EQU 2F11H
CP      EQU 2F12H
P1      EQU 2F13H
P2      EQU 2F14H
KEYS    EQU 2F15H
SAVESP  EQU 2F16H
FLOOR1  EQU 08H
FLOOR2  EQU 00H

        ORG 0100H
start:  lxi sp,STACKTOP
        di
        call init_map
        lxi h,0180H
        shld PX
        shld PY
        xra a
        sta ANG
        mvi a,1CH
        call PUTC
main:   call keys
        call setup
        call render
        jmp main

init_map: lxi h,MAPSRC
        mvi d,MAPHI
im1:    mvi e,0
        mvi b,16
im2:    mov a,m
        stax d
        inx h
        inx d
        dcr b
        jnz im2
        inr d
        mov a,d
        cpi MAPHI+16
        jnz im1
        ret

; klavesnica: stlpec do F4, riadky z F5 (0 = stlacene)
keys:   mvi a,12
        out 0F4H
        in 0F5H
        ani 4
        jnz k_nl
        lda ANG
        dcr a
        ani 3FH
        sta ANG
k_nl:   mvi a,14
        out 0F4H
        in 0F5H
        ani 4
        jnz k_nr
        lda ANG
        inr a
        ani 3FH
        sta ANG
k_nr:   mvi a,13
        out 0F4H
        in 0F5H
        sta KEYS
        ani 2
        jnz k_nu
        call fwd
k_nu:   lda KEYS
        ani 8
        rnz
        jmp back

fwd:    mvi c,0
        jmp domove
back:   mvi c,1
domove: lda ANG
        add a
        mov e,a
        mvi d,0
        lxi h,MOVTAB
        dad d
        mov e,m
        inx h
        mov d,m
        mov a,c
        ora a
        jz dm_pos
        xra a
        sub e
        mov e,a
        xra a
        sub d
        mov d,a
dm_pos: push d
        mov a,e
        add a
        sbb a
        mov b,a
        lhld PX
        mov a,l
        add e
        mov l,a
        mov a,h
        adc b
        mov h,a
        push h
        lhld PY
        xchg
        pop h
        call cellfree
        jnz dm_y
        shld PX
dm_y:   pop d
        mov a,d
        add a
        sbb a
        mov b,a
        lhld PY
        mov a,l
        add d
        mov l,a
        mov a,h
        adc b
        mov h,a
        push h
        xchg
        lhld PX
        call cellfree
        pop h
        rnz
        shld PY
        ret
; cellfree: HL=x, DE=y -> Z ak je bunka volna
cellfree: mov c,h
        mov a,d
        adi MAPHI
        mov b,a
        ldax b
        ora a
        ret

setup:  lda ANG
        mov l,a
        mvi h,0
        dad h
        dad h
        dad h
        lxi d,ANGTAB
        dad d
        lxi d,RX
        mvi b,8
su1:    mov a,m
        stax d
        inx h
        inx d
        dcr b
        jnz su1
        ret

render: lxi h,0
        dad sp
        shld SAVESP
        lxi h,VIDEO
        shld COLP
        mvi a,48
        sta COLN
rcol:   lda RX+1
        sta mx1+1
        add a
        sbb a
        sta mx2+1
        lda RY+1
        sta my1+1
        add a
        sbb a
        sta my2+1
        lhld RX
        xchg
        lhld IX
        dad d
        shld RX
        lhld RY
        xchg
        lhld IY
        dad d
        shld RY
        lhld PY
        xchg
        lhld PX
        lxi sp,0
mloop:  mov a,l
mx1:    adi 0
        mov l,a
        mov a,h
mx2:    aci 0
        mov h,a
        xchg
        mov a,l
my1:    adi 0
        mov l,a
        mov a,h
my2:    aci 0
        mov h,a
        xchg
        dcx sp
        mov c,h
        mov a,d
        adi MAPHI
        mov b,a
        ldax b
        ora a
        jz mloop
        mov b,a
        lxi h,0
        dad sp
        xchg
        lhld SAVESP
        sphl
        xra a
        sub e
        call drawcol
        lhld COLP
        inx h
        shld COLP
        lda COLN
        dcr a
        sta COLN
        jnz rcol
        ret

; drawcol: A=n (vzdialenost), B=typ steny
drawcol: mov e,a
        mvi d,0
        lxi h,WPTAB
        dad d
        mov a,m
        sta WP
        ora a
        rar
        cma
        adi 33
        sta CP
        mov a,e
        rrc
        rrc
        rrc
        rrc
        ani 0FH
        mov c,a
        mov a,b
        dcr a
        add a
        add a
        add a
        add a
        add c
        add a
        mov c,a
        mvi b,0
        lxi h,PATTAB
        dad b
        mov a,m
        sta P1
        inx h
        mov a,m
        sta P2
        lhld COLP
        lxi b,0040H
        lda CP
        mov e,a
        xra a
        mov d,a
        call fill2
        lda P2
        mov d,a
        lda WP
        mov e,a
        lda P1
        call fill2
        lda CP
        mov e,a
        mvi a,FLOOR1
        mvi d,FLOOR2
; fill2: E dvojic riadkov so vzormi A, D (HL = adresa, BC = 64)
fill2:  mov m,a
        dad b
        mov m,d
        dad b
        dcr e
        jnz fill2
        ret

