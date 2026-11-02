; doom85 - raycaster (Wolfenstein styl) pre PMD 85-1, i8080
PUTC    EQU 8500H
VIDEO   EQU 0D000H+((128-VH)/2)*64   ; pohlad 48 stlpcov x VH riadkov, vycentrovany v pasme 128 riadkov od riadku 64
MAPHI   EQU 50H               ; mapa: 16 stranok po 16 bajtov (stranka = riadok y)
STACKTOP EQU 7E00H
PX      EQU 4F00H
PY      EQU 4F02H
ANG     EQU 4F04H
RX      EQU 4F06H
RY      EQU 4F08H
IX      EQU 4F0AH
IY      EQU 4F0CH
COLP    EQU 4F0EH
COLN    EQU 4F10H
WP      EQU 4F11H
CP      EQU 4F12H
P1      EQU 4F13H
P2      EQU 4F14H
KEYS    EQU 4F15H
SAVESP  EQU 4F16H
ZP      EQU 4F18H
HEALTH  EQU 4F1AH
AMMO    EQU 4F1BH
KILLS   EQU 4F1CH
FIREF   EQU 4F1DH
RECOIL  EQU 4F1EH
PRECOIL EQU 4FD6H
GTOP    EQU 4FD7H
GPTR    EQU 4FD8H
FHELD   EQU 4F1FH
DXV     EQU 4F50H
DYV     EQU 4F52H
COSV    EQU 4F54H
SINV    EQU 4F55H
DEPTH   EQU 4F56H
SIDE    EQU 4F58H
SN      EQU 4F5AH
C0V     EQU 4F5BH
HWV     EQU 4F5DH
BASEADDR EQU 4F5EH
USTEP   EQU 4F60H
UACC    EQU 4F62H
CCV     EQU 4F64H
CNT     EQU 4F66H
EPTR    EQU 4F67H
NIDX    EQU 4F69H
ADX     EQU 4F6AH
ADY     EQU 4F6CH
EXV     EQU 4F6EH
EYV     EQU 4F70H
BESTN   EQU 4F72H
BESTP   EQU 4F73H
SGN     EQU 4F75H
SEED    EQU 4FB0H
CX      EQU 4FB2H
CY      EQU 4FB3H
NX      EQU 4FB4H
NY      EQU 4FB5H
STKP    EQU 4FB6H
STK     EQU 6000H
TEXP    EQU 4F76H
RECP    EQU 4F7BH
CURN    EQU 4F7DH
COLIDX  EQU 4F7EH
SCN     EQU 4F7FH
TMPU    EQU 4F80H
VP      EQU 4F84H
FROW    EQU 4F86H
FBP     EQU 4F87H
FEND    EQU 4F89H
FP1     EQU 4F8AH
FP2     EQU 4F8BH
ESPR    EQU 5010H
LASTH   EQU 4F78H
LASTA   EQU 4F79H
LASTK   EQU 4F7AH
ENEM    EQU 5220H
ZBUF    EQU 5120H
NEN     EQU 6
NPK     EQU 5
NOBJ    EQU 14
NPR     EQU 3
BHV     EQU 4FB8H
PKP     EQU 4FB9H
MUSI    EQU 4FBBH
MUSOFF  EQU 4FBCH
SFXF    EQU 4FBDH
MHELD   EQU 4FBEH
SIG     EQU 4FBFH
OLDW    EQU 4FC0H
NP      EQU 4FC1H
FLIM    EQU 4FC2H
SLN     EQU 4FC3H
SLP     EQU 4FC4H
SLP2    EQU 4FC6H
SLIST   EQU 5290H
PCELLV  EQU 4FE0H
QH      EQU 4FE1H
QT      EQU 4FE2H
GRC     EQU 4FE3H
GROWL   EQU 4FE4H
CC      EQU 4FE5H
NN      EQU 4FE6H
BD      EQU 4FE7H
KK      EQU 4FE8H
K0      EQU 4FE9H
PASS    EQU 4FEAH
DCUR    EQU 4FEBH
TXV     EQU 4FECH
TYV     EQU 4FEDH
STV     EQU 4FEEH
SPDV    EQU 4FEFH
AIP     EQU 4FF0H
FACECUR EQU 4FF2H
FACETM  EQU 4FF3H
FACEOV  EQU 4FF4H
LHP     EQU 4FF5H
LKL     EQU 4FF6H
FACEDST EQU 0C000H+196*64
MAPDST  EQU 0C000H+196*64+40
MAPBM   EQU 6200H
TMP8    EQU 6380H
HUDL1   EQU 0F580H+9
HUDL2   EQU 0F980H+9
HUDL3   EQU 0FD80H+9
LASTMC  EQU 4F20H
LASTMQ  EQU 4F21H
MIY     EQU 4F22H
MBP     EQU 4F23H
SPX     EQU 4F25H
SPY     EQU 4F26H
FIDLE   EQU 4FF7H
DIFFSEL EQU 4F30H
NACT    EQU 4F31H
HPE     EQU 4F32H
DMGV    EQU 4F33H
SPDPV   EQU 4F34H
SPDCV   EQU 4F35H
RNGV    EQU 4F36H
AMMO0   EQU 4F37H
PACKV   EQU 4F38H
TKH     EQU 4F39H
TCUR    EQU 4F3AH
WPN     EQU 4F3CH
NSHOT   EQU 4F3DH
PDMG    EQU 4F3EH
LASTW   EQU 4F3FH
LOSD    EQU 4F40H
LOSN    EQU 4F41H
PRJP    EQU 4F42H
KRANGE  EQU 10
IDLEV   EQU 4FF8H
CIDX    EQU 4FC8H
IX2     EQU 4FC9H
IY2     EQU 4FCBH
CRX     EQU 4FCDH
CRY     EQU 4FCFH
LN      EQU 4FD1H
LC      EQU 4FD2H
RN      EQU 4FD3H
RC      EQU 4FD4H
PCN     EQU 4FD5H
PWP     EQU 5160H
PSIG    EQU 5190H
DIRTY   EQU 51C0H
CURSOR  EQU 0C03EH
FLOOR1  EQU 48H
FLOOR2  EQU 40H

        ORG 0100H
start:  lxi sp,STACKTOP
        di
        call title
        call gen_maze
        call init_game
        mvi a,1CH
        call PUTC
main:   call keys
        call mkey
        call wkey
        call pickups
        call ai
        call prjstep
        call setup
        call sprprep
        call gunprep
        call render
        call gunstep
        call sprhit
        call hud
        call facepick
        call maptick
        call music
        lda HEALTH
        ora a
        jz gameover
        lda NACT
        mov b,a
        lda KILLS
        cmp b
        jz victory
        jmp main

init_game: mvi a,0FFH
        sta PCELLV
        sta FACECUR
        mvi a,100
        sta LHP
        xra a
        sta LKL
        sta FACETM
        xra a
        sta GRC
        lxi h,PSIG
        lxi d,DIRTY
        mvi b,48
        mvi a,0FFH
ig0:    mov m,a
        inx h
        xra a
        stax d
        inx d
        mvi a,0FFH
        dcr b
        jnz ig0
        lxi h,0180H
        shld PX
        shld PY
        lda MAPHI*256+256+2
        ora a
        mvi a,0
        jz ig_ang
        mvi a,16
ig_ang: sta ANG
        xra a
        sta KILLS
        sta FIREF
        sta RECOIL
        sta PRECOIL
        sta FHELD
        mvi a,1
        sta MUSOFF
        mvi a,100
        sta HEALTH
        lda AMMO0
        sta AMMO
        mvi a,0FFH
        sta LASTH
        lxi h,ENEM
        mvi b,NEN
ig1:    push h
ig2:    call rnd
        ani 15
        mov c,a
        call rnd
        ani 15
        mov d,a
        mov a,c
        ani 1
        jz ig2
        mov a,d
        ani 1
        jz ig2
        mov a,c
        cpi 14
        jnc ig2
        mov a,d
        cpi 14
        jnc ig2
        mov a,c
        sui 1
        mov e,a
        mov a,d
        sui 1
        add e
        cpi 8
        jc ig2
        pop h
        mvi m,128
        inx h
        mov m,c
        inx h
        mvi m,128
        inx h
        mov m,d
        inx h
        lda HPE
        mov m,a
        inx h
        mov m,c
        inx h
        mov m,d
        inx h
        mvi m,0
        inx h
        dcr b
        jnz ig1
        lda NACT
        mov c,a
        mvi a,NEN
        sub c
        jz ig_nd
        mov b,a
        mov a,c
        add a
        add a
        add a
        mov e,a
        mvi d,0
        lxi h,ENEM+4
        dad d
ig_dl:  mvi m,0
        lxi d,8
        dad d
        dcr b
        jnz ig_dl
ig_nd:  lda NSHOT
        ora a
        jz ig_ns
        mov b,a
        lda NACT
        sub b
        add a
        add a
        add a
        mov e,a
        mvi d,0
        lxi h,ENEM+7
        dad d
ig_sh:  mov a,m
        ori 8
        mov m,a
        lxi d,8
        dad d
        dcr b
        jnz ig_sh
ig_ns:  xra a
        sta WPN
        call mapinit
        mvi a,0FFH
        sta LASTMC
        lxi h,ENEM+8*NEN
        mvi b,NPK
ip1:    push h
ip2:    call rnd
        ani 15
        mov c,a
        call rnd
        ani 15
        mov d,a
        mov a,c
        ani 1
        jz ip2
        mov a,d
        ani 1
        jz ip2
        mov a,c
        cpi 14
        jnc ip2
        mov a,d
        cpi 14
        jnc ip2
        pop h
        mvi m,128
        inx h
        mov m,c
        inx h
        mvi m,128
        inx h
        mov m,d
        inx h
        mvi m,1
        inx h
        mvi m,0
        inx h
        mvi m,0
        inx h
        mvi m,0
        inx h
        dcr b
        jnz ip1
        mvi b,NPR
ip_z:   lxi d,4
        dad d
        mvi m,0
        lxi d,4
        dad d
        dcr b
        jnz ip_z
        ret

; ---------------------------------------------------------------- uvodna obrazovka a generator bludiska
title:  lda DIFFSEL
        ora a
        jnz ti_d
        mvi a,3
        sta DIFFSEL
ti_d:   mvi a,1CH
        call PUTC
        lxi h,0D000H+12
        shld CURSOR
        lxi h,S_T1
        call puts
        lxi h,0D400H+4
        shld CURSOR
        lxi h,S_T2
        call puts
        lxi h,0D800H+4
        shld CURSOR
        lxi h,S_T3
        call puts
        lxi h,0DC00H+8
        shld CURSOR
        lxi h,S_T5
        call puts
        lxi h,0E000H+22
        shld TCUR
        lxi h,S_LV
        mvi b,5
ti_l:   push h
        lhld TCUR
        shld CURSOR
        lxi d,400H
        dad d
        shld TCUR
        pop h
        push b
        call puts
        pop b
        inx h
        dcr b
        jnz ti_l
        lxi h,0F400H+4
        shld CURSOR
        lxi h,S_T6
        call puts
        lxi h,0F600H+4
        shld CURSOR
        lxi h,S_T7
        call puts
        lxi h,0FA00H+4
        shld CURSOR
        lxi h,S_T4
        call puts
        call mark
tt_w:   call note
        lhld SEED
        inx h
        shld SEED
        ; E (hore) a Y (dole) menia uroven, cislice 1-5 ju zvolia a spustia hru
        mvi a,2
        out 0F4H
        in 0F5H
        ani 4
        mov b,a
        mvi a,1
        out 0F4H
        in 0F5H
        ani 10H
        mov c,a
        mov a,b
        ora a
        jz ti_pr
        mov a,c
        ora a
        jnz ti_nk
ti_pr:  lda TKH
        ora a
        jnz ti_dg
        mvi a,1
        sta TKH
        mov a,b
        ora a
        jnz ti_dn
        lda DIFFSEL
        dcr a
        jz ti_dg
        sta DIFFSEL
        call mark
        jmp ti_dg
ti_dn:  lda DIFFSEL
        cpi 5
        jnc ti_dg
        inr a
        sta DIFFSEL
        call mark
        jmp ti_dg
ti_nk:  xra a
        sta TKH
ti_dg:  mvi c,0
ti_c:   mov a,c
        out 0F4H
        in 0F5H
        ani 2
        jnz ti_cn
        mov a,c
        inr a
        sta DIFFSEL
        jmp tt_ok
ti_cn:  inr c
        mov a,c
        cpi 5
        jc ti_c
        mvi a,0
        out 0F4H
        in 0F5H
        ani 10H
        jz tt_ok
        mvi a,14
        out 0F4H
        in 0F5H
        ani 10H
        jnz tt_w
tt_ok:  lhld SEED
        mov a,l
        ori 1
        mov l,a
        shld SEED
tt_r:   mvi a,0
        out 0F4H
        in 0F5H
        ani 10H
        jz tt_r
        mvi a,14
        out 0F4H
        in 0F5H
        ani 10H
        jz tt_r
        mvi c,0
tt_rd:  mov a,c
        out 0F4H
        in 0F5H
        ani 2
        jz tt_r
        inr c
        mov a,c
        cpi 5
        jc tt_rd
        ; parametre zvolenej urovne
        lda DIFFSEL
        dcr a
        add a
        add a
        add a
        mov e,a
        mvi d,0
        lxi h,DIFFT
        dad d
        mov a,m
        sta NACT
        inx h
        mov a,m
        sta HPE
        inx h
        mov a,m
        sta DMGV
        inx h
        mov a,m
        sta SPDPV
        inx h
        mov a,m
        sta SPDCV
        inx h
        mov a,m
        sta RNGV
        inx h
        mov a,m
        sta AMMO0
        inx h
        mov a,m
        sta PACKV
        lda DIFFSEL
        dcr a
        add a
        mov e,a
        mvi d,0
        lxi h,DIFFS
        dad d
        mov a,m
        sta NSHOT
        inx h
        mov a,m
        sta PDMG
        mvi a,1CH
        jmp PUTC
; mark: oznaci zvolenu uroven znakom > pred riadkom
mark:   mvi c,1
        lxi d,0E000H+20
mk_l:   xchg
        shld CURSOR
        xchg
        lda DIFFSEL
        cmp c
        mvi a,' '
        jnz mk_p
        mvi a,'>'
mk_p:   call PUTC
        lxi h,400H
        dad d
        xchg
        inr c
        mov a,c
        cpi 6
        jc mk_l
        ret
; DIFFT: pocet priserok, zdravie, poskodenie, rychlost patrola, honby, dosah (bunky), naboje, naboje v balicku
DIFFT:  DB 2,1,1,7,10,7,40,15
        DB 3,2,1,8,12,9,35,12
        DB 4,2,2,9,14,10,30,10
        DB 6,3,3,10,15,12,25,8
        DB 6,4,4,12,16,14,20,6
DIFFS:  DB 0,0,1,3,2,3,3,4,4,5
S_LV:   DB "1 LAHKA",0,"2 STREDNA",0,"3 NORMALNA",0,"4 TAZKA",0,"5 NOCNA MORA",0
S_T5:   DB "OBTIAZNOST:",0
S_T6:   DB "MEDZERNIK STRELBA  1 NOZ  2 PISTOL  M HUDBA",0
S_T7:   DB ", . = UKROK VLAVO / VPRAVO",0

; rnd: A = nahodne cislo (16 bit LFSR, 8 krokov); zachova B, C
rnd:    lhld SEED
        mvi d,8
rn1:    mov a,h
        ora a
        rar
        mov h,a
        mov a,l
        rar
        mov l,a
        jnc rn2
        mov a,h
        xri 0B4H
        mov h,a
rn2:    dcr d
        jnz rn1
        shld SEED
        mov a,l
        ret

; gen_maze: bludisko 7x7 buniek (DFS), steny typu 1-4, par prerazenych stien
gen_maze: mvi d,MAPHI
gm1:    mvi e,0
        mvi b,16
gm2:    mvi a,1
        stax d
        inx d
        dcr b
        jnz gm2
        inr d
        mov a,d
        cpi MAPHI+16
        jnz gm1
        mvi a,1
        sta CX
        sta CY
        lxi h,MAPHI*256+1+256
        mvi m,0
        lxi h,STK
        shld STKP
        mvi m,1
        inx h
        mvi m,1
        inx h
        shld STKP
gm_loop: lhld STKP
        lxi d,STK
        call cmp16
        jz gm_done
        dcx h
        mov a,m
        sta CY
        dcx h
        mov a,m
        sta CX
        call rnd
        ani 3
        mov c,a
        mvi b,4
gm_try: mov a,c
        ani 3
        mov e,a
        mvi d,0
        lxi h,DXT
        dad d
        lda CX
        add m
        sta NX
        lxi h,DYT
        dad d
        lda CY
        add m
        sta NY
        lda NX
        cpi 1
        jc gm_next
        cpi 14
        jnc gm_next
        lda NY
        cpi 1
        jc gm_next
        cpi 14
        jnc gm_next
        adi MAPHI
        mov h,a
        lda NX
        mov l,a
        mov a,m
        ora a
        jz gm_next
        mvi m,0
        lda CX
        mov d,a
        lda NX
        add d
        ora a
        rar
        mov l,a
        lda CY
        mov d,a
        lda NY
        add d
        ora a
        rar
        adi MAPHI
        mov h,a
        mvi m,0
        lhld STKP
        lda NX
        mov m,a
        inx h
        lda NY
        mov m,a
        inx h
        shld STKP
        jmp gm_loop
gm_next: inr c
        dcr b
        jnz gm_try
        lhld STKP
        dcx h
        dcx h
        shld STKP
        jmp gm_loop
gm_done: mvi b,30
gm_door: push b
        call rnd
        ani 15
        mov c,a
        call rnd
        ani 15
        mov b,a
        mov a,c
        cpi 1
        jc gm_dn
        cpi 14
        jnc gm_dn
        mov a,b
        cpi 1
        jc gm_dn
        cpi 14
        jnc gm_dn
        mov a,b
        xra c
        ani 1
        jz gm_dn
        mov a,b
        adi MAPHI
        mov h,a
        mov l,c
        mvi m,0
gm_dn:  pop b
        dcr b
        jnz gm_door
        mvi d,MAPHI
gm_ty1: mvi e,0
gm_ty2: ldax d
        ora a
        jz gm_ty3
        mov a,e
        rrc
        rrc
        ani 3
        mov b,a
        mov a,d
        sui MAPHI
        rrc
        rrc
        ani 3
        add b
        ani 3
        inr a
        stax d
gm_ty3: inr e
        mov a,e
        cpi 16
        jnz gm_ty2
        inr d
        mov a,d
        cpi MAPHI+16
        jnz gm_ty1
        ret
DXT:    DB 2,0,0FEH,0
DYT:    DB 0,2,0,0FEH

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
k_nr:   mvi a,2
        out 0F4H
        in 0F5H
        ani 4
        jnz k_nu
        call fwd
k_nu:   mvi a,1
        out 0F4H
        in 0F5H
        ani 10H
        jnz k_s
        call back
k_s:    mvi a,8
        out 0F4H
        in 0F5H
        ani 10H
        jnz k_s2
        call strafe_l
k_s2:   mvi a,9
        out 0F4H
        in 0F5H
        ani 10H
        jnz fire_key
        call strafe_r
        jmp fire_key
; ukrok: krok kolmo na smer pohladu (uhol +-16 z 64), kolizia a klzanie ako pri chodzi
strafe_l: lda ANG
        push psw
        sui 16
        ani 3FH
        sta ANG
        call fwd
        pop psw
        sta ANG
        ret
strafe_r: lda ANG
        push psw
        adi 16
        ani 3FH
        sta ANG
        call fwd
        pop psw
        sta ANG
        ret
wkey:   mvi a,0
        out 0F4H
        in 0F5H
        ani 2
        jnz wk1
        mvi a,1
        sta WPN
        ret
wk1:    mvi a,1
        out 0F4H
        in 0F5H
        ani 2
        rnz
        xra a
        sta WPN
        ret
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
        lda WPN
        ora a
        jnz fk_kn
        lda AMMO
        ora a
        jz sfx_click
fk_kn:  mvi a,1
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

; render: lúče sa vrhajú len pre parné stlpce (a stlpec 47), nepárne sa interpoluju z oboch susedov,
; ak trafili tú istú bunku a vzdialenosti sa lisia najviac o 4; inak sa vrhne aj ich lúč
render: lxi h,ZBUF
        shld ZP
        lxi h,VIDEO
        shld COLP
        xra a
        sta CIDX
        lhld IX
        dad h
        shld IX2
        lhld IY
        dad h
        shld IY2
        lhld RX
        shld CRX
        lhld RY
        shld CRY
        call cast
        sta LN
        mov a,b
        sta LC
        lda LN
        call emit
        mvi a,23
        sta PCN
pair:   lhld RX
        xchg
        lhld IX2
        dad d
        shld RX
        shld CRX
        lhld RY
        xchg
        lhld IY2
        dad d
        shld RY
        shld CRY
        call cast
        sta RN
        mov a,b
        sta RC
        lda LC
        cmp b
        jnz pr_cast
        lda RN
        mov c,a
        lda LN
        sub c
        jnc pr_a
        cma
        inr a
pr_a:   cpi 5
        jnc pr_cast
        lda RN
        mov c,a
        lda LN
        add c
        rar
        mov c,a
        lda LC
        mov b,a
        mov a,c
        jmp pr_emit
pr_cast: lhld RX
        xchg
        lhld IX
        mov a,e
        sub l
        mov l,a
        mov a,d
        sbb h
        mov h,a
        shld CRX
        lhld RY
        xchg
        lhld IY
        mov a,e
        sub l
        mov l,a
        mov a,d
        sbb h
        mov h,a
        shld CRY
        call cast
pr_emit: call emit
        lda RN
        mov c,a
        sta LN
        lda RC
        sta LC
        mov b,a
        mov a,c
        call emit
        lda PCN
        dcr a
        sta PCN
        jnz pair
        lhld RX
        xchg
        lhld IX
        dad d
        shld CRX
        lhld RY
        xchg
        lhld IY
        dad d
        shld CRY
        call cast
        jmp emit

; emit: A=n, B=typ steny: ulozi vzdialenost, nakresli stlpec, prisery a zbran
emit:   push psw
        lhld ZP
        mov m,a
        inx h
        shld ZP
        pop psw
        sta CURN
        lda CIDX
        sta COLIDX
        inr a
        sta CIDX
        lda CURN
        call drawcol
        call sprcol
        call guncol
        lhld COLP
        inx h
        shld COLP
        ret

; cast: luc podla (CRX, CRY) -> A = n, B = typ steny (krokovanie po 1/8 bunky, SP je pocitadlo krokov)
cast:   lxi h,0
        dad sp
        shld SAVESP
        lda CRX+1
        sta mx1+1
        add a
        sbb a
        sta mx1+2
        lda CRY+1
        sta my1+1
        add a
        sbb a
        sta my1+2
        lhld PY
        lxi d,MAPHI*256
        dad d
        xchg
        lhld PX
        lxi sp,0
mloop:
mx1:    lxi b,0
        dad b
        xchg
my1:    lxi b,0
        dad b
        xchg
        dcx sp
        mov c,h
        mov b,d
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
        ret

; drawcol: A=n (vzdialenost), B=typ steny
drawcol: mov e,a
        mvi d,0
        lxi h,WPTAB
        dad d
        mov a,m
        sta WP
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
        sta SIG
        mov c,a
        mvi b,0
        lxi h,PATTAB
        dad b
        mov a,m
        sta P1
        inx h
        mov a,m
        sta P2
        lda COLIDX
        mov e,a
        mvi d,0
        lxi h,DIRTY
        dad d
        mov a,m
        ora a
        jnz dc_full
        lxi h,PSIG
        dad d
        lda SIG
        cmp m
        jnz dc_full
        lxi h,PWP
        dad d
        mov c,m
        lda WP
        cmp c
        rz
        mov b,a
        mov a,c
        sta OLDW
        mov a,b
        cmp c
        jc dc_shrink
        mov a,b
        sub c
        ora a
        rar
        sta NP
        mvi a,CEN
        sub b
        call rowaddr
        lda NP
        mov e,a
        lda P2
        mov d,a
        lxi b,0040H
        lda P1
        call fill2
        lda OLDW
        adi CEN
        call rowaddr
        lda NP
        mov e,a
        lda P2
        mov d,a
        lxi b,0040H
        lda P1
        call fill2
        jmp dc_done
dc_shrink: mov a,c
        sub b
        ora a
        rar
        sta NP
        mvi a,CEN
        sub c
        call rowaddr
        lda NP
        mov e,a
        xra a
        mov d,a
        lxi b,0040H
        call fill2
        lda WP
        adi CEN
        sta FROW
        call rowaddr
        shld VP
        lda OLDW
        adi CEN
        sta FLIM
        call floor_rows
        jmp dc_done
dc_full: lxi h,DIRTY
        dad d
        mvi m,0
        lhld COLP
        lxi b,0040H
        lda WP
        ora a
        rar
        cma
        adi VH/4+1
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
        shld VP
        lda WP
        adi CEN
        sta FROW
        mvi a,VH
        sta FLIM
        call floor_rows
dc_done: lda COLIDX
        mov e,a
        mvi d,0
        lxi h,PWP
        dad d
        lda WP
        mov m,a
        lxi h,PSIG
        dad d
        lda SIG
        mov m,a
        ret
; rowaddr: A = riadok pohladu (0-127) -> HL = adresa v stlpci COLIDX
rowaddr: mov l,a
        mvi h,0
        dad h
        dad h
        dad h
        dad h
        dad h
        dad h
        lxi d,VIDEO
        dad d
        lda COLIDX
        mov e,a
        mvi d,0
        dad d
        ret
; floor_rows: podlaha od riadku FROW po FLIM (vyssi), VP = adresa zaciatku
floor_rows: lxi h,FBANDS
        shld FBP
fl:     lhld FBP
        mov a,m
        ora a
        rz
        sta FEND
        inx h
        mov a,m
        sta FP1
        inx h
        mov a,m
        sta FP2
        inx h
        shld FBP
        lda FLIM
        mov b,a
        lda FEND
        cmp b
        jc fl_1
        mov a,b
fl_1:   mov b,a
        lda FROW
        mov c,a
        mov a,b
        sub c
        jc fl_nx
        jz fl_nx
        ora a
        rar
        mov e,a
        mov a,b
        sta FROW
        lda FP2
        mov d,a
        lhld VP
        lxi b,0040H
        lda FP1
        call fill2
        shld VP
fl_nx:  lda FLIM
        mov b,a
        lda FROW
        cmp b
        rnc
        jmp fl
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
; Priserky chodia z bunky do bunky: v patrole nahodne (bez otocenia sa spat), ak je cesta k hracovi kratsia ako 10 buniek
; (pri 15 sa vzdaju), nasleduju najkratsiu cestu z mapy vzdialenosti (BFS od bunky hraca, pocita sa pri zmene bunky hraca).
; Zaznam (8 B): +0/1 x, +2/3 y (1/256 bunky), +4 hp, +5 cielova bunka x, +6 cielova bunka y, +7 smer (bity 0-1), bit 2 = naháňa
QPAGE   EQU 61H
SPD_PAT EQU 9
SPD_CH  EQU 14
OFFT:   DB 1,16,0FFH,0F0H
DX1T:   DB 1,0,0FFH,0
DY1T:   DB 0,1,0,0FFH
; maddr: A = bunka (y*16+x) -> HL = adresa v mape;  dmaddr: -> HL = adresa v mape vzdialenosti (offset F0)
maddr:  mov e,a
        ani 0FH
        mov l,a
        mov a,e
        rrc
        rrc
        rrc
        rrc
        ani 0FH
        adi MAPHI
        mov h,a
        ret
dmaddr: mov e,a
        ani 0FH
        adi 0F0H
        mov l,a
        mov a,e
        rrc
        rrc
        rrc
        rrc
        ani 0FH
        adi MAPHI
        mov h,a
        ret
; nbr: A = smer 0-3 -> A = cislo susednej bunky od CC
nbr:    mov e,a
        mvi d,0
        lxi h,OFFT
        dad d
        lda CC
        add m
        ret
; bfs: vzdialenosti od bunky hraca (PCELLV), nezistene = FF
bfs:    mvi d,MAPHI
bf1:    mvi e,0F0H
        mvi b,16
bf2:    mvi a,0FFH
        stax d
        inx d
        dcr b
        jnz bf2
        mov a,d
        cpi MAPHI+16
        jnz bf1
        lda PCELLV
        mov c,a
        call dmaddr
        mvi m,0
        lxi h,QPAGE*256
        mov m,c
        xra a
        sta QH
        mvi a,1
        sta QT
bf_l:   lda QH
        mov e,a
        lda QT
        cmp e
        rz
        mvi d,QPAGE
        ldax d
        sta CC
        mov a,e
        inr a
        sta QH
        lda CC
        call dmaddr
        mov a,m
        inr a
        sta BD
        cpi 24
        jnc bf_l
        mvi a,4
        sta KK
bf_n:   lda KK
        dcr a
        call nbr
        sta NN
        call maddr
        mov a,m
        ora a
        jnz bf_s
        mov a,l
        ori 0F0H
        mov l,a
        mov a,m
        inr a
        jnz bf_s
        lda BD
        mov m,a
        lda QT
        mov e,a
        mvi d,QPAGE
        lda NN
        stax d
        inr e
        mov a,e
        sta QT
bf_s:   lxi h,KK
        dcr m
        jnz bf_n
        jmp bf_l
; ai: jedno kolo pohybu vsetkych priserok
ai:     lda PY+1
        add a
        add a
        add a
        add a
        mov b,a
        lda PX+1
        add b
        lxi h,PCELLV
        cmp m
        jz ai_nb
        mov m,a
        call bfs
ai_nb:  xra a
        sta GROWL
        lda GRC
        ora a
        jz ai_g0
        dcr a
        sta GRC
ai_g0:  lxi h,ENEM
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
        lda GROWL
        ora a
        rz
        lda GRC
        ora a
        rnz
        mvi a,14
        sta GRC
        jmp sfx_growl
; clampv: HL (so znamienkom) -> HL orezane na +-SPDV
clampv: lda SPDV
        mov c,a
        mov a,h
        ora a
        jm cl_n
        jnz cl_p
        mov a,l
        cmp c
        rc
        rz
cl_p:   mov l,c
        mvi h,0
        ret
cl_n:   cpi 0FFH
        jnz cl_m
        mov a,l
        add c
        rc
cl_m:   mov a,c
        cma
        inr a
        mov l,a
        mvi h,0FFH
        ret
; ai1: HL = zaznam priserky
ai1:    push h
        lxi d,4
        dad d
        mov a,m
        pop h
        ora a
        rz
        shld AIP
        mov a,m
        sta EXV
        inx h
        mov a,m
        sta EXV+1
        inx h
        mov a,m
        sta EYV
        inx h
        mov a,m
        sta EYV+1
        inx h
        inx h
        mov a,m
        sta TXV
        inx h
        mov a,m
        sta TYV
        inx h
        mov a,m
        sta STV
        ani 4
        lda SPDPV
        jz ai_sp
        lda SPDCV
ai_sp:  sta SPDV
        lda STV
        ani 8
        jz ai_ns
        call losck
        jnc ai_ns
        lda STV
        ani 0F0H
        jnz ai_cd
        call fireprj
        lda STV
        ori 0F0H
        sta STV
        jmp ai_st
ai_cd:  lda STV
        sui 10H
        sta STV
        jmp ai_st
ai_ns:
        lhld EXV
        xchg
        lda TXV
        mov h,a
        mvi l,128
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        shld ADX
        lhld EYV
        xchg
        lda TYV
        mov h,a
        mvi l,128
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        shld ADY
        lhld ADX
        call absHL
        mov a,h
        ora a
        jnz ai_mv
        lda SPDV
        cmp l
        jc ai_mv
        lhld ADY
        call absHL
        mov a,h
        ora a
        jnz ai_mv
        lda SPDV
        cmp l
        jc ai_mv
        lda TXV
        sta EXV+1
        lda TYV
        sta EYV+1
        mvi a,128
        sta EXV
        sta EYV
        call choose
        jmp ai_st
ai_mv:  lhld ADX
        call clampv
        xchg
        lhld EXV
        dad d
        shld EXV
        lhld ADY
        call clampv
        xchg
        lhld EYV
        dad d
        shld EYV
ai_st:  lhld AIP
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
        inx h
        inx h
        lda TXV
        mov m,a
        inx h
        lda TYV
        mov m,a
        inx h
        lda STV
        mov m,a
        lhld PX
        xchg
        lhld EXV
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        call absHL
        push h
        lhld PY
        xchg
        lhld EYV
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        call absHL
        xchg
        pop h
        call cmp16
        jnc ai_m1
        xchg
ai_m1:  lxi d,192
        call cmp16
        rnc
        lda DMGV
        mov b,a
        lda HEALTH
        sub b
        jnc ai_h2
        xra a
ai_h2:  sta HEALTH
        jmp sfx_hurt
; settarget: A = smer -> TXV, TYV, STV
settarget: mov c,a
        mov e,a
        mvi d,0
        lxi h,DX1T
        dad d
        lda TXV
        add m
        sta TXV
        lxi h,DY1T
        dad d
        lda TYV
        add m
        sta TYV
        lda STV
        ani 0FCH
        ora c
        sta STV
        ret
; choose: vyber dalsej cielovej bunky pre priserku v bunke (TXV, TYV)
choose: lda TYV
        add a
        add a
        add a
        add a
        mov b,a
        lda TXV
        add b
        sta CC
        call dmaddr
        mov a,m
        sta DCUR
        lda STV
        ani 4
        jnz chs_in
        lda DCUR
        lxi h,RNGV
        cmp m
        jnc chs_pat
        lda STV
        ori 4
        sta STV
        mvi a,1
        sta GROWL
        jmp chs_ch
chs_in: lda RNGV
        adi 5
        mov b,a
        lda DCUR
        cmp b
        jc chs_ch
        lda STV
        ani 0FBH
        sta STV
        jmp chs_pat
chs_ch: lda DCUR
        ora a
        rz
        cpi 6
        jnc chs_c1
        mvi a,1
        sta GROWL
chs_c1: call rnd
        ani 3
        sta K0
        mvi a,4
        sta KK
chs_c2: lda K0
        ani 3
        call nbr
        sta NN
        call maddr
        mov a,m
        ora a
        jnz chs_cn
        lda NN
        call dmaddr
        mov b,m
        lda DCUR
        cmp b
        jc chs_cn
        jz chs_cn
        lda K0
        ani 3
        jmp settarget
chs_cn: lda K0
        inr a
        sta K0
        lxi h,KK
        dcr m
        jnz chs_c2
chs_pat: call rnd
        ani 3
        sta K0
        mvi a,4
        sta KK
        xra a
        sta PASS
chs_p1: lda K0
        ani 3
        mov b,a
        lda PASS
        ora a
        jnz chs_p2
        lda STV
        ani 3
        adi 2
        ani 3
        cmp b
        jz chs_pn
chs_p2: mov a,b
        call nbr
        sta NN
        call maddr
        mov a,m
        ora a
        jnz chs_pn
        lda K0
        ani 3
        jmp settarget
chs_pn: lda K0
        inr a
        sta K0
        lxi h,KK
        dcr m
        jnz chs_p1
        lda PASS
        ora a
        rnz
        mvi a,1
        sta PASS
        mvi a,4
        sta KK
        jmp chs_p1
sfx_growl: mvi b,170
        mvi c,14
        mvi e,2
        jmp snd

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
sprprep: lxi h,SLIST
        shld SLP2
        xra a
        sta SLN
        lxi h,ENEM
        shld EPTR
        lxi h,ESPR
        shld RECP
        mvi a,NOBJ
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
        call pk_adj
        call vis_chk
        jnc sp_en
        lhld RECP
        xchg
        lhld SLP2
        mov m,e
        inx h
        mov m,d
        inx h
        shld SLP2
        lda SLN
        inr a
        sta SLN
        xchg
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
        lda BHV
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
        lda BHV
        mov c,a
        lxi h,WPTAB
        pop d
        dad d
        mov a,m
        adi CEN
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
        lxi h,USTEPTAB
        dad d
        dad d
        mov e,m
        inx h
        mov d,m
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
        lda NIDX+1
        cpi NEN
        jc sp_te
        cpi NEN+NPK
        mvi a,1
        jc sp_t0
        mvi a,2
        jmp sp_t0
sp_te:  push h
        lhld EPTR
        lxi d,7
        dad d
        mov a,m
        pop h
        ani 8
        mvi a,0
        jz sp_t0
        mvi a,3
sp_t0:  mov m,a
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

; vis_chk: po pk_adj znovu overi, ci sprite (C0V, HWV) zasahuje do stlpcov 0-47; CY = viditelny
vis_chk: lda HWV
        add a
        mov e,a
        mvi d,0
        lhld C0V
        dad d
        mov a,h
        ora a
        jm vc_no
        lhld C0V
        mov a,h
        ora a
        jm vc_yes
        jnz vc_no
        mov a,l
        cpi 48
        jnc vc_no
vc_yes: stc
        ret
vc_no:  ora a
        ret

; pk_adj: po proj: pre baliky (index >= NEN) zmensi sirku a vysku; vypocita BHV
pk_adj: lda SN
        mov e,a
        mvi d,0
        lxi h,BHTAB
        dad d
        mov b,m
        lda NIDX+1
        cpi NEN
        jc pa_e
        lda HWV
        mov c,a
        inr a
        ora a
        rar
        mov d,a
        mov a,c
        sub d
        mov e,a
        mov a,d
        sta HWV
        mvi d,0
        lhld C0V
        dad d
        shld C0V
        mov a,b
        inr a
        ora a
        rar
        mov b,a
pa_e:   mov a,b
        sta BHV
        ret

; pickups: zber balickov nabojov (bunka hraca = bunka balicka)
pickups: lxi h,ENEM+8*NEN
        shld PKP
        mvi a,NPK
        sta NIDX
pk_l:   lhld PKP
        lxi d,4
        dad d
        mov a,m
        ora a
        jz pk_n
        lhld PKP
        inx h
        mov b,m
        lda PX+1
        cmp b
        jnz pk_n
        inx h
        inx h
        mov b,m
        lda PY+1
        cmp b
        jnz pk_n
        lda PACKV
        mov b,a
        lda AMMO
        add b
        cpi 100
        jc pk_ok
        mvi a,99
pk_ok:  sta AMMO
        lhld PKP
        lxi d,4
        dad d
        mvi m,0
        call sfx_pick
pk_n:   lhld PKP
        lxi d,8
        dad d
        shld PKP
        lda NIDX
        dcr a
        sta NIDX
        jnz pk_l
        ret

; sprcol: dokresli rezy prisier pre stlpec COLIDX (stena v tom stlpci je vo vzdialenosti CURN)
sprcol: lda SLN
        ora a
        rz
        sta SCN
        lxi h,SLIST
        shld SLP
scl:    lhld SLP
        mov e,m
        inx h
        mov d,m
        inx h
        shld SLP
        xchg
        shld RECP
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
scn:    lda SCN
        dcr a
        sta SCN
        jnz scl
        ret

; slice: jeden stlpec prisery (zaznam v RECP)
slice:  lda COLIDX
        mov e,a
        mvi d,0
        lxi h,DIRTY
        dad d
        mvi m,1
        lhld RECP
        lxi d,11
        dad d
        mov a,m
        add a
        add a
        add a
        mov e,a
        mvi d,0
        push d
        lhld RECP
        lxi d,14
        dad d
        mov a,m
        add a
        mov e,a
        mvi d,0
        lxi h,TEXTT
        dad d
        mov e,m
        inx h
        mov d,m
        xchg
        pop d
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
; zbran: stlpce GCOL0..GCOL0+7 (bitmapa 8x10 buniek po 4 riadky, 0 = priehladne), pri vystrele odskok a zablesk
GCOL0   EQU 20
; gunprep: pred snimkou - poloha zbrane podla RECOIL; ak sa zmenila, prekresli jej stlpce cele
gunprep: lda RECOIL
        mov e,a
        mvi d,0
        lxi h,GOFFT
        dad d
        mov a,m
        cma
        adi VH-39
        sta GTOP
        lda WPN
        add a
        add a
        mov b,a
        lda RECOIL
        add b
        lxi h,PRECOIL
        cmp m
        rz
        mov m,a
        lxi h,DIRTY+GCOL0
        mvi b,8
gp1:    mvi m,1
        inx h
        dcr b
        jnz gp1
        ret
guncol: lda COLIDX
        cpi GCOL0
        rc
        cpi GCOL0+8
        rnc
        sui GCOL0
        mov l,a
        mvi h,0
        mov d,h
        mov e,a
        dad h
        dad h
        dad d
        dad h
        lxi d,GUNT
        lda WPN
        ora a
        jz gc_t
        lxi d,KNT
gc_t:   dad d
        shld GPTR
        lda GTOP
        call rowaddr
        lxi b,0040H
        mvi d,10
        call gcells
        lda WPN
        ora a
        rnz
        lda RECOIL
        cpi 3
        rnz
        lda COLIDX
        cpi GCOL0+1
        rc
        cpi GCOL0+7
        rnc
        sui GCOL0+1
        mov l,a
        mvi h,0
        mov e,a
        mov d,h
        dad h
        dad d
        lxi d,FLT
        dad d
        shld GPTR
        lda GTOP
        sui 12
        call rowaddr
        lxi b,0040H
        mvi d,3
gcells: push h
        lhld GPTR
        mov a,m
        inx h
        shld GPTR
        pop h
        ora a
        jz gc_skip
        mov m,a
        dad b
        mov m,a
        dad b
        mov m,a
        dad b
        mov m,a
        dad b
        jmp gc_n
gc_skip: inr h
gc_n:   dcr d
        jnz gcells
        ret
GOFFT:  DB 0,1,3,6
gunstep: lda RECOIL
        ora a
        rz
        dcr a
        sta RECOIL
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
        lxi d,15
        dad d
        mov a,m
        cpi NEN
        jnc sh_n
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
        lda WPN
        ora a
        jz sh_np
        mov a,b
        cpi KRANGE+1
        jnc sh_n
sh_np:
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
        lda WPN
        ora a
        jnz sh_kn
        lda AMMO
        dcr a
        sta AMMO
        mvi a,3
        sta RECOIL
        xra a
        sta FIREF
        call sfx_shot
        lhld BESTP
        mov a,h
        ora l
        rz
        lxi d,4
        dad d
        dcr m
        jnz sfx_hit
        lda KILLS
        inr a
        sta KILLS
        jmp sfx_kill
; noz: nizka ucinnost (zasiahne len polovica uderov), len na blizko
sh_kn:  mvi a,3
        sta RECOIL
        xra a
        sta FIREF
        lhld BESTP
        mov a,h
        ora l
        jz sfx_swish
        call rnd
        ani 1
        jz sfx_swish
        lhld BESTP
        lxi d,4
        dad d
        dcr m
        jnz sfx_stab
        lda KILLS
        inr a
        sta KILLS
        jmp sfx_kill

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
        jnz hd_go
        lda WPN
        mov b,a
        lda LASTW
        cmp b
        rz
hd_go:  lda WPN
        sta LASTW
        lda HEALTH
        sta LASTH
        lda AMMO
        sta LASTA
        lda KILLS
        sta LASTK
        lxi h,HUDL1
        shld CURSOR
        lxi h,S_HEALTH
        call puts
        lda HEALTH
        call pnum
        lxi h,HUDL2
        shld CURSOR
        lxi h,S_AMMO
        call puts
        lda AMMO
        call pnum
        lxi h,HUDL3
        shld CURSOR
        lxi h,S_KILLS
        call puts
        lda KILLS
        call pnum
        mvi a,'/'
        call PUTC
        lda NACT
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

gameover: mvi a,25
        call facedraw
        lxi h,HUDL2
        shld CURSOR
        lxi h,S_GO
        call puts
        call jingle_over
        call waitkey
        jmp start
victory: call faclev
        adi 20
        call facedraw
        lxi h,HUDL2
        shld CURSOR
        lxi h,S_WIN
        call puts
        call jingle_win
        call waitkey
        jmp start
waitkey: mvi a,14
        out 0F4H
        in 0F5H
        ani 10H
        jnz waitkey
        ret

; ---------------------------------------------------------------- zvuk (bit 2 portu C = reproduktor)
; snd: B = oneskorenie (nesmie byt 0), C = pocet polperiod, E = krok oneskorenia (so znamienkom)
snd:    mvi a,1
        sta SFXF
snd0:   mvi a,4
        out 0F6H
        mov d,b
sn2:    dcr d
        jnz sn2
        mov d,b
sn3:    dcr d
        jnz sn3
        xra a
        out 0F6H
        mov d,b
sn4:    dcr d
        jnz sn4
        mov d,b
sn5:    dcr d
        jnz sn5
        mov a,b
        add e
        mov b,a
        dcr c
        jnz snd0
        xra a
        out 0F6H
        ret
; noise: C = pocet polperiod
noise:  mvi a,1
        sta SFXF
nz1:    call rnd
        ani 3FH
        adi 4
        mov b,a
        mvi a,4
        out 0F6H
        mov d,b
nz2:    dcr d
        jnz nz2
        xra a
        out 0F6H
        mov d,b
nz3:    dcr d
        jnz nz3
        dcr c
        jnz nz1
        ret
sfx_shot: mvi c,40
        call noise
        mvi b,70
        mvi c,10
        mvi e,6
        jmp snd
sfx_hit: mvi b,55
        mvi c,30
        mvi e,2
        jmp snd
sfx_kill: mvi b,22
        mvi c,110
        mvi e,1
        jmp snd
sfx_hurt: mvi b,110
        mvi c,10
        mvi e,0
        jmp snd
sfx_click: mvi b,6
        mvi c,6
        mvi e,0
        jmp snd
sfx_pick: mvi b,48
        mvi c,18
        mvi e,0FEH
        call snd
        mvi b,30
        mvi c,24
        mvi e,0FFH
        jmp snd
jingle_over: lxi h,JOVER
        jmp jingle
jingle_win: lxi h,JWIN
jingle: mov b,m
        mov a,b
        ora a
        rz
        inx h
        mov c,m
        inx h
        push h
        mvi e,0
        call snd
        pop h
        jmp jingle
JOVER:  DB 70,45,90,40,120,35,180,60,0
JWIN:   DB 110,30,85,35,65,40,45,60,0
; note: zahra dalsiu notu melodie (22 ms)
note:   lda MUSI
        mov e,a
        mvi d,0
        inr a
        ani 31
        sta MUSI
        lxi h,MUSTAB
        dad d
        dad d
        mov b,m
        inx h
        mov c,m
        mvi e,0
        jmp snd0
; music: jedna nota za snimku, ak nezneli efekt a hudba nie je vypnuta
music:  lda SFXF
        ora a
        jnz mu_clr
        lda MUSOFF
        ora a
        rnz
        jmp note
mu_clr: xra a
        sta SFXF
        ret
; mkey: kláves M prepina hudbu (stlpec 7, bit 4)
mkey:   mvi a,7
        out 0F4H
        in 0F5H
        ani 10H
        jnz mk_up
        lda MHELD
        ora a
        rnz
        mvi a,1
        sta MHELD
        lda MUSOFF
        xri 1
        sta MUSOFF
        ret
mk_up:  xra a
        sta MHELD
        ret

; ---------------------------------------------------------------- tvar (HUD)
; facedraw: A = stav (0-4 zdravie, 5 bolest, 6 spokojnost, 7 mrtva) -> 48x48 bodov na obrazovku
facedraw: sta FACECUR
        mov e,a
        mvi d,0
        lxi h,FACETAB
        dad d
        dad d
        mov e,m
        inx h
        mov d,m
        xchg
        lxi d,FACEDST
        mvi c,48
fd_r:   mvi b,8
fd_b:   mov a,m
        stax d
        inx h
        inx d
        dcr b
        jnz fd_b
        push h
        lxi h,56
        dad d
        xchg
        pop h
        dcr c
        jnz fd_r
        ret
; faclev: A = uroven zdravia 0-4 (100-81, 80-61, 60-41, 40-21, <=20)
faclev: lda HEALTH
        cpi 81
        jc fv_1
        xra a
        ret
fv_1:   cpi 61
        jc fv_2
        mvi a,1
        ret
fv_2:   cpi 41
        jc fv_3
        mvi a,2
        ret
fv_3:   cpi 21
        jc fv_4
        mvi a,3
        ret
fv_4:   mvi a,4
        ret
; facepick: vyber tvare podla zdravia (3 vyrazy v pokoji), zranenia (bolest) a zabitia (usmev); stavy 0-14 pokoj, 15-19 bolest, 20-24 usmev, 25 mrtva
facepick: lda HEALTH
        mov b,a
        lda LHP
        cmp b
        jc fp_k
        jz fp_k
        mvi a,3
        sta FACETM
        mvi a,1
        sta FACEOV
fp_k:   mov a,b
        sta LHP
        lda KILLS
        mov c,a
        lda LKL
        cmp c
        jnc fp_s
        mvi a,8
        sta FACETM
        mvi a,2
        sta FACEOV
fp_s:   mov a,c
        sta LKL
        lda FIDLE
        ora a
        jz fp_nv
        dcr a
        sta FIDLE
        jmp fp_u
fp_nv:  call rnd
        ani 3
        cpi 3
        jc fp_v
        mvi a,1
fp_v:   sta IDLEV
        mvi a,14
        sta FIDLE
fp_u:   call faclev
        mov c,a
        lda FACETM
        ora a
        jz fp_i
        dcr a
        sta FACETM
        lda FACEOV
        cpi 1
        mov a,c
        jnz fp_g
        adi 15
        jmp fp_d
fp_g:   adi 20
        jmp fp_d
fp_i:   mov a,c
        add a
        add c
        mov c,a
        lda IDLEV
        add c
fp_d:   mov b,a
        lda FACECUR
        cmp b
        rz
        mov a,b
        jmp facedraw

; losck: strelec (EXV, EYV) vidi hraca v rovnakom riadku alebo stlpci do 8 buniek cez volne bunky -> CY, LOSD = smer
losck:  lda EXV+1
        mov d,a
        lda EYV+1
        mov e,a
        lda PX+1
        mov b,a
        lda PY+1
        mov c,a
        mov a,e
        cmp c
        jnz lo_c
        mov a,d
        cmp b
        jz lo_no
        jc lo_r0
        mvi a,2
        sta LOSD
        mov a,d
        sub b
        jmp lo_n
lo_r0:  xra a
        sta LOSD
        mov a,b
        sub d
        jmp lo_n
lo_c:   mov a,d
        cmp b
        jnz lo_no
        mov a,e
        cmp c
        jc lo_c0
        mvi a,3
        sta LOSD
        mov a,e
        sub c
        jmp lo_n
lo_c0:  mvi a,1
        sta LOSD
        mov a,c
        sub e
lo_n:   sta LOSN
        cpi 9
        jnc lo_no
        mov a,e
        add a
        add a
        add a
        add a
        add d
        sta CC
        lda LOSN
        dcr a
        jz lo_yes
        mov b,a
lo_s:   lda LOSD
        call nbr
        sta CC
        call maddr
        mov a,m
        ora a
        jnz lo_no
        dcr b
        jnz lo_s
lo_yes: stc
        ret
lo_no:  ora a
        ret
; fireprj: strela z pozicie strelca v smere LOSD (prvy volny slot)
fireprj: lxi h,ENEM+8*(NEN+NPK)
        mvi b,NPR
fp_l:   push h
        lxi d,4
        dad d
        mov a,m
        pop h
        ora a
        jz fp_f
        lxi d,8
        dad d
        dcr b
        jnz fp_l
        ret
fp_f:   lda EXV
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
        inx h
        mvi m,1
        inx h
        lda LOSD
        mov m,a
        jmp sfx_efire
; prjstep: pohyb striel (24 jednotiek na snimku), zasah steny alebo hraca
PDXT:   DW 24,0,0FFE8H,0
PDYT:   DW 0,24,0,0FFE8H
prjstep: lxi h,ENEM+8*(NEN+NPK)
        mvi a,NPR
        sta NIDX
ps_l:   shld PRJP
        push h
        lxi d,4
        dad d
        mov a,m
        ora a
        pop h
        jz ps_n
        mov e,m
        inx h
        mov d,m
        inx h
        mov a,e
        sta EXV
        mov a,d
        sta EXV+1
        mov e,m
        inx h
        mov d,m
        inx h
        mov a,e
        sta EYV
        mov a,d
        sta EYV+1
        inx h
        mov e,m
        mvi d,0
        lxi h,PDXT
        dad d
        dad d
        mov c,m
        inx h
        mov b,m
        lhld EXV
        dad b
        shld EXV
        lxi h,PDYT
        dad d
        dad d
        mov c,m
        inx h
        mov b,m
        lhld EYV
        dad b
        shld EYV
        lda EYV+1
        add a
        add a
        add a
        add a
        mov b,a
        lda EXV+1
        add b
        call maddr
        mov a,m
        ora a
        jnz ps_kill
        lhld PX
        xchg
        lhld EXV
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        call absHL
        lxi d,96
        call cmp16
        jnc ps_st
        lhld PY
        xchg
        lhld EYV
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        call absHL
        lxi d,96
        call cmp16
        jnc ps_st
        lda PDMG
        mov b,a
        lda HEALTH
        sub b
        jnc ps_h
        xra a
ps_h:   sta HEALTH
        call sfx_hurt
ps_kill: lhld PRJP
        lxi d,4
        dad d
        mvi m,0
        jmp ps_n
ps_st:  lhld PRJP
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
ps_n:   lhld PRJP
        lxi d,8
        dad d
        lda NIDX
        dcr a
        sta NIDX
        jnz ps_l
        ret
sfx_efire: mvi b,36
        mvi c,12
        mvi e,3
        jmp snd
sfx_stab: mvi b,16
        mvi c,10
        mvi e,2
        jmp snd
sfx_swish: mvi c,10
        jmp noise
TEXTT:  DW TEX,TEX2,TEX3,TEX4
; ---------------------------------------------------------------- mapka (16x16 buniek po 3x3 bodoch = 48x48 bodov), bez priser
; mapinit: zo steny bludiska postavi bitmapu MAPBM (8 B x 48 riadkov, bajt = 2 bunky)
mapinit: lxi h,MAPBM
        shld MBP
        xra a
        sta MIY
mi_y:   mvi c,0
mi_j:   lda MIY
        adi MAPHI
        mov h,a
        mov a,c
        add a
        mov l,a
        mov a,m
        ora a
        mvi a,0
        jz mi_l
        mvi a,7
mi_l:   mov e,a
        inx h
        mov a,m
        ora a
        mvi a,0
        jz mi_r
        mvi a,38H
mi_r:   ora e
        jz mi_s
        ori 40H
mi_s:   push psw
        lxi h,TMP8
        mov e,c
        mvi d,0
        dad d
        pop psw
        mov m,a
        inr c
        mov a,c
        cpi 8
        jc mi_j
        mvi b,3
mi_t:   lxi h,TMP8
        xchg
        lhld MBP
        xchg
        mvi c,8
mi_c:   mov a,m
        stax d
        inx h
        inx d
        dcr c
        jnz mi_c
        xchg
        shld MBP
        xchg
        dcr b
        jnz mi_t
        lda MIY
        inr a
        sta MIY
        cpi 16
        jc mi_y
        ret
; maptick: pri zmene bunky hraca alebo smeru pohladu prekresli mapku s polohou hraca
maptick: lda ANG
        adi 8
        rrc
        rrc
        rrc
        rrc
        ani 3
        mov b,a
        lda PY+1
        add a
        add a
        add a
        add a
        mov c,a
        lda PX+1
        add c
        mov c,a
        lda LASTMC
        cmp c
        jnz mt_d
        lda LASTMQ
        cmp b
        rz
mt_d:   mov a,c
        sta LASTMC
        mov a,b
        sta LASTMQ
; mapdraw: MAPBM do videopamate + znacka hraca (3x3 body) a bod v smere pohladu
mapdraw: lxi h,MAPBM
        lxi d,MAPDST
        mvi c,48
md_r:   mvi b,8
md_b:   mov a,m
        stax d
        inx h
        inx d
        dcr b
        jnz md_b
        push h
        lxi h,56
        dad d
        xchg
        pop h
        dcr c
        jnz md_r
        lda LASTMC
        mov b,a
        ani 15
        mov c,a
        add a
        add c
        mov c,a
        sta SPX
        mov a,b
        rrc
        rrc
        rrc
        rrc
        ani 15
        mov c,a
        add a
        add c
        sta SPY
        mvi d,3
md_y:   mvi e,3
md_x:   lda SPX
        add e
        dcr a
        mov b,a
        lda SPY
        add d
        dcr a
        mov c,a
        push d
        call setpix
        pop d
        dcr e
        jnz md_x
        dcr d
        jnz md_y
        lda LASTMQ
        mov d,a
        lda SPX
        inr a
        mov b,a
        lda SPY
        inr a
        mov c,a
        mov a,d
        ora a
        jnz mn_1
        mov a,b
        adi 2
        mov b,a
        jmp setpix
mn_1:   cpi 1
        jnz mn_2
        mov a,c
        adi 2
        mov c,a
        jmp setpix
mn_2:   cpi 2
        jnz mn_3
        mov a,b
        sui 2
        mov b,a
        jmp setpix
mn_3:   mov a,c
        sui 2
        mov c,a
; setpix: B = x, C = y (0-47) -> nastavi bod v mapke (6 bodov na bajt, bit 0 vlavo)
setpix: mvi d,0
        mov a,b
sp_d:   cpi 6
        jc sp_m
        sui 6
        inr d
        jmp sp_d
sp_m:   mov b,a
        mvi a,1
sp_s:   inr b
        dcr b
        jz sp_w
        add a
        dcr b
        jmp sp_s
sp_w:   mov e,a
        mov l,c
        mvi h,0
        dad h
        dad h
        dad h
        dad h
        dad h
        dad h
        lxi b,MAPDST
        dad b
        mov a,d
        mov c,a
        mvi b,0
        dad b
        mov a,m
        ora e
        ani 3FH
        mov m,a
        ret
S_KN:   DB " NOZ        ",0
S_NOAM: DB " BEZ NABOJOV",0
S_BL:   DB "            ",0
S_T1:   DB "DOOM85",0
S_T2:   DB "E DOPREDU   Y DOZADU   <- -> OTACANIE",0
S_T3:   DB "ZLIKVIDUJ VSETKY PRISERY V BLUDISKU",0
S_T4:   DB "1-5 ALEBO E / Y + MEDZERNIK",0
S_HEALTH: DB "HEALTH ",0
S_AMMO: DB "AMMO   ",0
S_KILLS: DB "KILLS  ",0
S_GO:   DB "KONIEC HRY - ENTER = ZNOVA",0
S_WIN:  DB "VITAZSTVO! - ENTER = ZNOVA",0
