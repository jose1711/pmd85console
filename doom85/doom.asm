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
ZP      EQU 2F18H
HEALTH  EQU 2F1AH
AMMO    EQU 2F1BH
KILLS   EQU 2F1CH
FIREF   EQU 2F1DH
FLASH   EQU 2F1EH
FHELD   EQU 2F1FH
DXV     EQU 2F50H
DYV     EQU 2F52H
COSV    EQU 2F54H
SINV    EQU 2F55H
DEPTH   EQU 2F56H
SIDE    EQU 2F58H
SN      EQU 2F5AH
C0V     EQU 2F5BH
HWV     EQU 2F5DH
BASEADDR EQU 2F5EH
USTEP   EQU 2F60H
UACC    EQU 2F62H
CCV     EQU 2F64H
CNT     EQU 2F66H
EPTR    EQU 2F67H
NIDX    EQU 2F69H
ADX     EQU 2F6AH
ADY     EQU 2F6CH
EXV     EQU 2F6EH
EYV     EQU 2F70H
BESTN   EQU 2F72H
BESTP   EQU 2F73H
SGN     EQU 2F75H
TEXP    EQU 2F76H
RECP    EQU 2F7BH
CURN    EQU 2F7DH
COLIDX  EQU 2F7EH
SCN     EQU 2F7FH
TMPU    EQU 2F80H
ESPR    EQU 3010H
LASTH   EQU 2F78H
LASTA   EQU 2F79H
LASTK   EQU 2F7AH
ENEM    EQU 2F90H
ZBUF    EQU 2FC0H
NEN     EQU 4
CURSOR  EQU 0C03EH
FLOOR1  EQU 08H
FLOOR2  EQU 00H

        ORG 0100H
start:  lxi sp,STACKTOP
        di
        call init_map
        call init_game
        mvi a,1CH
        call PUTC
main:   call keys
        call ai
        call setup
        call sprprep
        call render
        call sprhit
        call gunstep
        call hud
        lda HEALTH
        ora a
        jz gameover
        lda KILLS
        cpi NEN
        jz victory
        jmp main

init_game: lxi h,0180H
        shld PX
        shld PY
        xra a
        sta ANG
        sta KILLS
        sta FIREF
        sta FLASH
        sta FHELD
        mvi a,100
        sta HEALTH
        mvi a,30
        sta AMMO
        mvi a,0FFH
        sta LASTH
        lxi h,ENEMINIT
        lxi d,ENEM
        mvi b,32
ig1:    mov a,m
        stax d
        inx h
        inx d
        dcr b
        jnz ig1
        ret

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
        jnz fire_key
        call back
fire_key: mvi a,0
        out 0F4H
        in 0F5H
        ani 10H
        jnz fk_up
        lda FHELD
        ora a
        rnz
        mvi a,1
        sta FHELD
        lda AMMO
        ora a
        rz
        mvi a,1
        sta FIREF
        ret
fk_up:  xra a
        sta FHELD
        ret

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
        lxi h,ZBUF
        shld ZP
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
        push psw
        lhld ZP
        mov m,a
        inx h
        shld ZP
        pop psw
        sta CURN
        call drawcol
        lda COLN
        cma
        adi 49
        sta COLIDX
        call sprcol
        call guncol
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


; ================================================================ fáza 2: príšery, streľba, HUD
neg_hl: mov a,l
        cma
        mov l,a
        mov a,h
        cma
        mov h,a
        inx h
        ret
absHL:  mov a,h
        ora a
        rp
        jmp neg_hl
cmp16:  mov a,h
        cmp d
        rnz
        mov a,l
        cmp e
        ret
sar4:   mvi b,4
s4:     mov a,h
        ral
        mov a,h
        rar
        mov h,a
        mov a,l
        rar
        mov l,a
        dcr b
        jnz s4
        ret
; smul: A (so znamienkom, 8 bit) * DE (so znamienkom, 16 bit) -> HL
smul:   mvi c,0
        ora a
        jp sm1
        cma
        inr a
        inr c
sm1:    mov b,a
        mov a,d
        ora a
        jp sm2
        xchg
        call neg_hl
        xchg
        mov a,c
        xri 1
        mov c,a
sm2:    lxi h,0
sm3:    mov a,b
        ora a
        jz sm5
        rar
        mov b,a
        jnc sm4
        dad d
sm4:    xchg
        dad h
        xchg
        jmp sm3
sm5:    mov a,c
        ora a
        rz
        jmp neg_hl
; udiv: HL/DE bez znamienka -> HL podiel, DE zvysok
udiv:   mov b,h
        mov c,l
        lxi h,0
        mvi a,16
ud1:    push psw
        mov a,c
        add a
        mov c,a
        mov a,b
        ral
        mov b,a
        mov a,l
        ral
        mov l,a
        mov a,h
        ral
        mov h,a
        mov a,l
        sub e
        mov a,h
        sbb d
        jc ud2
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        inr c
ud2:    pop psw
        dcr a
        jnz ud1
        mov d,h
        mov e,l
        mov h,b
        mov l,c
        ret

; ---------------------------------------------------------------- AI nepriatelov
ai:     lxi h,ENEM
        mvi a,NEN
        sta NIDX
ai_l:   push h
        call ai1
        pop h
        lxi d,8
        dad d
        lda NIDX
        dcr a
        sta NIDX
        jnz ai_l
        ret
ai1:    push h
        lxi d,4
        dad d
        mov a,m
        pop h
        ora a
        rz
        push h
        mov e,m
        inx h
        mov d,m
        inx h
        mov c,m
        inx h
        mov b,m
        xchg
        shld EXV
        mov h,b
        mov l,c
        shld EYV
        lhld EXV
        xchg
        lhld PX
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        shld ADX
        lhld EYV
        xchg
        lhld PY
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        shld ADY
        lhld ADX
        call absHL
        push h
        lhld ADY
        call absHL
        xchg
        pop h
        call cmp16
        jnc ai_m1
        xchg
ai_m1:  lxi d,192
        call cmp16
        jc ai_hit
        lxi d,3072
        call cmp16
        jnc ai_done
        lhld ADX
        call sgn10
        xchg
        lhld EXV
        dad d
        push h
        lhld EYV
        xchg
        pop h
        call cellfree
        jnz ai_y
        shld EXV
ai_y:   lhld ADY
        call sgn10
        xchg
        lhld EYV
        dad d
        xchg
        push d
        lhld EXV
        call cellfree
        pop h
        jnz ai_st
        shld EYV
ai_st:  pop h
        lda EXV
        mov m,a
        inx h
        lda EXV+1
        mov m,a
        inx h
        lda EYV
        mov m,a
        inx h
        lda EYV+1
        mov m,a
        ret
ai_hit: lda HEALTH
        sui 2
        jnc ai_h2
        xra a
ai_h2:  sta HEALTH
ai_done: pop h
        ret
sgn10:  mov a,h
        ora a
        jm sg_n
        jnz sg_p
        mov a,l
        cpi 16
        jc sg_0
sg_p:   lxi h,14
        ret
sg_n:   cpi 0FFH
        jnz sg_m
        mov a,l
        cpi 0F0H
        jnc sg_0
sg_m:   lxi h,-14
        ret
sg_0:   lxi h,0
        ret

; ---------------------------------------------------------------- spritey
; proj: HL = nepriatel -> CY ak je viditelny; SN, C0V, HWV
proj:   push h
        mov e,m
        inx h
        mov d,m
        inx h
        push h
        lhld PX
        mov a,e
        sub l
        mov e,a
        mov a,d
        sbb h
        mov d,a
        xchg
        call sar4
        shld DXV
        pop h
        mov e,m
        inx h
        mov d,m
        lhld PY
        mov a,e
        sub l
        mov e,a
        mov a,d
        sbb h
        mov d,a
        xchg
        call sar4
        shld DYV
        pop h
        lda ANG
        add a
        mov e,a
        mvi d,0
        lxi h,DIRTAB
        dad d
        mov a,m
        sta COSV
        inx h
        mov a,m
        sta SINV
        lhld DXV
        xchg
        lda COSV
        call smul
        push h
        lhld DYV
        xchg
        lda SINV
        call smul
        pop d
        dad d
        shld DEPTH
        lhld DYV
        xchg
        lda COSV
        call smul
        push h
        lhld DXV
        xchg
        lda SINV
        call smul
        xchg
        pop h
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        shld SIDE
        lhld DEPTH
        mov a,h
        ora a
        jm pj_no
        ora l
        jz pj_no
        mov a,l
        add a
        mov a,h
        ral
        cpi 2
        jc pj_no
        sta SN
        lhld DEPTH
        xchg
        lhld SIDE
pj_red: mov a,d
        cpi 4
        jc pj_ok
        mov a,d
        ora a
        rar
        mov d,a
        mov a,e
        rar
        mov e,a
        mov a,h
        ral
        mov a,h
        rar
        mov h,a
        mov a,l
        rar
        mov l,a
        jmp pj_red
pj_ok:  mov a,h
        rlc
        ani 1
        sta SGN
        mov a,h
        ora a
        cm neg_hl
        mov b,h
        mov c,l
        mov a,d
        ora a
        rar
        mov h,a
        mov a,e
        rar
        mov l,a
        dad d
        push d
        mov d,b
        mov e,c
        call cmp16
        pop d
        jc pj_no
        mov h,b
        mov l,c
        dad h
        dad h
        push h
        dad h
        dad h
        dad h
        pop b
        dad b
        call udiv
        lda SGN
        ora a
        jz pj_pos
        call neg_hl
pj_pos: lxi d,24
        dad d
        push h
        lda SN
        mov e,a
        mvi d,0
        lxi h,HWTAB
        dad d
        mov a,m
        sta HWV
        pop h
        mov e,a
        mvi d,0
        push h
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        shld C0V
        pop h
        dad d
        mov a,h
        ora a
        jm pj_no
        lhld C0V
        mov a,h
        ora a
        jm pj_yes
        jnz pj_no
        mov a,l
        cpi 48
        jnc pj_no
pj_yes: stc
        ret
pj_no:  ora a
        ret

; ---------------------------------------------------------------- spritey po stlpcoch (bez blikania)
; zaznam prisery (16 B) na ESPR: +0 platny, +1 SN, +2 CS, +3 CE, +4 BH, +5 HW, +6/7 BASE, +8/9 USTEP,
; +10/11 UACC, +12/13 stred stlpca (so znamienkom), +15 poradie
sprprep: lxi h,ENEM
        shld EPTR
        lxi h,ESPR
        shld RECP
        mvi a,NEN
        sta NIDX
        xra a
        sta NIDX+1
sp_e:   lhld RECP
        xra a
        mov m,a
        lhld EPTR
        push h
        lxi d,4
        dad d
        mov a,m
        ora a
        pop h
        jz sp_en
        call proj
        jnc sp_en
        lhld RECP
        mvi m,1
        inx h
        lda SN
        mov m,a
        inx h
        push h
        lhld C0V
        mov a,h
        ora a
        jm sp_cs0
        mov a,l
        jmp sp_cs1
sp_cs0: xra a
sp_cs1: pop h
        mov m,a
        inx h
        push h
        lda HWV
        add a
        mov e,a
        mvi d,0
        lhld C0V
        dad d
        mov a,h
        ora a
        jnz sp_ce_hi
        mov a,l
        cpi 48
        jc sp_ce1
sp_ce_hi: mvi a,47
sp_ce1: pop h
        mov m,a
        inx h
        lda SN
        mov e,a
        mvi d,0
        push h
        lxi h,BHTAB
        dad d
        mov a,m
        pop h
        mov m,a
        inx h
        lda HWV
        mov m,a
        inx h
        push h
        lda SN
        mov e,a
        mvi d,0
        push d
        lxi h,BHTAB
        dad d
        mov c,m
        lxi h,WPTAB
        pop d
        dad d
        mov a,m
        adi 64
        mov b,a
        mov a,c
        add a
        add a
        add a
        mov c,a
        mov a,b
        sub c
        mov l,a
        mvi h,0
        dad h
        dad h
        dad h
        dad h
        dad h
        dad h
        lxi d,VIDEO
        dad d
        xchg
        pop h
        mov m,e
        inx h
        mov m,d
        inx h
        push h
        lda HWV
        add a
        inr a
        mov e,a
        mvi d,0
        lxi h,2048
        call udiv
        xchg
        pop h
        mov m,e
        inx h
        mov m,d
        inx h
        push h
        lxi h,0
        shld TMPU
        lhld C0V
        mov a,h
        ora a
        jp sp_u0
        call neg_hl
        mov b,h
        mov c,l
        lhld RECP
        lxi d,8
        dad d
        mov e,m
        inx h
        mov d,m
        lxi h,0
sp_ul:  mov a,b
        ora c
        jz sp_ud
        dad d
        dcx b
        jmp sp_ul
sp_ud:  shld TMPU
sp_u0:  pop h
        lda TMPU
        mov m,a
        inx h
        lda TMPU+1
        mov m,a
        inx h
        lhld C0V
        lda HWV
        mov e,a
        mvi d,0
        dad d
        xchg
        lhld RECP
        lxi b,12
        dad b
        mov m,e
        inx h
        mov m,d
        inx h
        inx h
        lda NIDX+1
        mov m,a
sp_en:  lhld EPTR
        lxi d,8
        dad d
        shld EPTR
        lhld RECP
        lxi d,16
        dad d
        shld RECP
        lda NIDX+1
        inr a
        sta NIDX+1
        lda NIDX
        dcr a
        sta NIDX
        jnz sp_e
        ret

; sprcol: dokresli rezy prisier pre stlpec COLIDX (stena v tom stlpci je vo vzdialenosti CURN)
sprcol: lxi h,ESPR
        mvi a,NEN
        sta SCN
scl:    shld RECP
        mov a,m
        ora a
        jz scn
        lda COLIDX
        mov e,a
        lhld RECP
        inx h
        inx h
        mov a,e
        cmp m
        jc scn
        inx h
        mov a,m
        cmp e
        jc scn
        lhld RECP
        inx h
        mov b,m
        lda CURN
        cmp b
        jc sc_adv
        jz sc_adv
        call slice
sc_adv: lhld RECP
        lxi d,8
        dad d
        mov e,m
        inx h
        mov d,m
        inx h
        mov a,m
        add e
        mov m,a
        inx h
        mov a,m
        adc d
        mov m,a
scn:    lhld RECP
        lxi d,16
        dad d
        lda SCN
        dcr a
        sta SCN
        jnz scl
        ret

; slice: jeden stlpec prisery (zaznam v RECP)
slice:  lhld RECP
        lxi d,11
        dad d
        mov a,m
        add a
        add a
        add a
        mov e,a
        mvi d,0
        lxi h,TEX
        dad d
        shld TEXP
        lhld RECP
        lxi d,4
        dad d
        mov a,m
        sta sbh+1
        lhld RECP
        lxi d,6
        dad d
        mov e,m
        inx h
        mov d,m
        lda COLIDX
        mov l,a
        mvi h,0
        dad d
        lxi b,0040H
        mvi d,8
sb:     push h
        lhld TEXP
        mov a,m
        inx h
        shld TEXP
        pop h
sbh:    mvi e,0
        ora a
        jz sb_s
sf:     mov m,a
        dad b
        dcr e
        jnz sf
        jmp sb_n
sb_s:   dad b
        dcr e
        jnz sb_s
sb_n:   dcr d
        jnz sb
        ret

; zbran: stlpce 22..25
guncol: lda COLIDX
        cpi 22
        rc
        cpi 26
        rnc
        sui 22
        mov c,a
        lda COLIDX
        mov e,a
        mvi d,0
        lxi h,VIDEO+104*64
        dad d
        mov a,c
        cpi 1
        jz g_barrel
        cpi 2
        jz g_barrel
        jmp g_flash
g_barrel: lxi b,0040H
        mvi e,12
        mvi a,3FH
        mov d,a
        call fill2
g_flash: lda FLASH
        ora a
        rz
        lda COLIDX
        mov e,a
        mvi d,0
        lxi h,VIDEO+92*64
        dad d
        lxi b,0040H
        mvi e,6
        lda COLIDX
        cpi 22
        jz gf_a
        cpi 25
        jz gf_b
        mvi a,3FH
        mov d,a
        jmp fill2
gf_a:   mvi a,2AH
        mvi d,15H
        jmp fill2
gf_b:   mvi a,15H
        mvi d,2AH
        jmp fill2
gunstep: lda FLASH
        ora a
        rz
        dcr a
        sta FLASH
        ret

; po vykresleni: zasah (strelba) a uberanie nabojov
sprhit: lda FIREF
        ora a
        rz
        mvi a,255
        sta BESTN
        lxi h,0
        shld BESTP
        lxi h,ESPR
        mvi a,NEN
        sta SCN
sh_l:   shld RECP
        mov a,m
        ora a
        jz sh_n
        lhld RECP
        lxi d,12
        dad d
        mov e,m
        inx h
        mov d,m
        xchg
        lxi d,-24
        dad d
        call absHL
        push h
        lhld RECP
        lxi d,5
        dad d
        mov a,m
        ora a
        rar
        inr a
        mov e,a
        mvi d,0
        pop h
        call cmp16
        jc sh_hit
        jnz sh_n
sh_hit: lhld RECP
        inx h
        mov b,m
        lda ZBUF+24
        cmp b
        jc sh_n
        jz sh_n
        lda BESTN
        cmp b
        jc sh_n
        jz sh_n
        mov a,b
        sta BESTN
        lhld RECP
        lxi d,15
        dad d
        mov a,m
        add a
        add a
        add a
        mov e,a
        mvi d,0
        lxi h,ENEM
        dad d
        shld BESTP
sh_n:   lhld RECP
        lxi d,16
        dad d
        lda SCN
        dcr a
        sta SCN
        jnz sh_l
        lda AMMO
        dcr a
        sta AMMO
        mvi a,2
        sta FLASH
        xra a
        sta FIREF
        lhld BESTP
        mov a,h
        ora l
        rz
        lxi d,4
        dad d
        dcr m
        rnz
        lda KILLS
        inr a
        sta KILLS
        ret

hud:    lda HEALTH
        mov b,a
        lda LASTH
        cmp b
        jnz hd_go
        lda AMMO
        mov b,a
        lda LASTA
        cmp b
        jnz hd_go
        lda KILLS
        mov b,a
        lda LASTK
        cmp b
        rz
hd_go:  lda HEALTH
        sta LASTH
        lda AMMO
        sta LASTA
        lda KILLS
        sta LASTK
        lxi h,0FB00H
        shld CURSOR
        lxi h,S_HP
        call puts
        lda HEALTH
        call pnum
        lxi h,S_AM
        call puts
        lda AMMO
        call pnum
        lxi h,S_KL
        call puts
        lda KILLS
        adi '0'
        jmp PUTC
puts:   mov a,m
        ora a
        rz
        call PUTC
        inx h
        jmp puts
pnum:   mvi d,0
pn1:    cpi 100
        jc pn2
        sui 100
        inr d
        jmp pn1
pn2:    mvi b,0
pn3:    cpi 10
        jc pn4
        sui 10
        inr b
        jmp pn3
pn4:    mov e,a
        mov a,d
        ora a
        jnz ph
        mvi a,' '
        jmp pp1
ph:     adi '0'
pp1:    call PUTC
        mov a,d
        ora b
        jnz pt
        mvi a,' '
        jmp pp2
pt:     mov a,b
        adi '0'
pp2:    call PUTC
        mov a,e
        adi '0'
        jmp PUTC

gameover: lxi h,0FB00H
        shld CURSOR
        lxi h,S_GO
        call puts
        call waitkey
        jmp start
victory: lxi h,0FB00H
        shld CURSOR
        lxi h,S_WIN
        call puts
        call waitkey
        jmp start
waitkey: mvi a,14
        out 0F4H
        in 0F5H
        ani 10H
        jnz waitkey
        ret

S_HP:   DB "ZDRAVIE ",0
S_AM:   DB " NABOJE ",0
S_KL:   DB " ZABITO ",0
S_GO:   DB "KONEC HRY - ENTER = ZNOVU           ",0
S_WIN:  DB "VITEZSTVI! - ENTER = ZNOVU          ",0
