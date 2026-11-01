; mpy85 - podmnozina Pythonu (REPL) pre PMD 85-1 (monitor M1), i8080
; Typy hodnot: A = typ, HL = hodnota
T_INT   EQU 0
T_STR   EQU 1
T_NONE  EQU 2
T_FUN   EQU 3
T_BOOL  EQU 4

PUTC    EQU 8500H
GETK    EQU 84A1H
CURSOR  EQU 0C03EH

; --- pamat ---
VARS    EQU 2F00H
TP      EQU 2F00H
FLAG    EQU 2F02H
RETV    EQU 2F03H
RETT    EQU 2F05H
SYMTOP  EQU 2F06H
FRAMEBASE EQU 2F08H
GLBEND  EQU 2F0AH
PROGTOP EQU 2F0CH
HP      EQU 2F0EH
HPMARK  EQU 2F10H
STRST   EQU 2F12H
NOEXEC  EQU 2F13H
ECHO    EQU 2F14H
ARGSP   EQU 2F15H
ARG0    EQU 2F17H
CURARG  EQU 2F19H
OUTP    EQU 2F1BH
TMP1    EQU 2F1DH
TMP2    EQU 2F1FH
DM_SA   EQU 2F21H
DM_SB   EQU 2F22H
DM_B    EQU 2F23H
SLQ     EQU 2F25H
SLC     EQU 2F26H
NAMEBUF EQU 2F28H
NUMBUF  EQU 2F30H
HCUR    EQU 2F38H
HEND    EQU 2F3AH
HIST    EQU 6000H
HISTEND EQU 61FFH
KEY_UP  EQU 81H
KEY_DOWN EQU 87H

SYMTAB  EQU 1C00H
SYMEND  EQU 2EFEH
ARGBASE EQU 3000H
BLK     EQU 3400H
LINEBUF EQU 3800H
PROG    EQU 3900H
PROGEND EQU 5000H
HEAP    EQU 5000H
HEAPEND EQU 6000H
STACKTOP EQU 7E00H

; makra: nazov (8 B) sa uklada na zasobnik tak, ze SP ukazuje na NAMEBUF[0]
PUSHNAME MACRO
        lhld NAMEBUF+6
        push h
        lhld NAMEBUF+4
        push h
        lhld NAMEBUF+2
        push h
        lhld NAMEBUF
        push h
ENDM
POPNAME MACRO
        pop h
        shld NAMEBUF
        pop h
        shld NAMEBUF+2
        pop h
        shld NAMEBUF+4
        pop h
        shld NAMEBUF+6
ENDM

        ORG 0100H

start:  lxi sp,STACKTOP
        lxi h,PROG
        shld PROGTOP
        lxi h,HEAP
        shld HP
        shld HPMARK
        lxi h,SYMTAB
        shld SYMTOP
        shld FRAMEBASE
        shld GLBEND
        xra a
        sta STRST
        lxi h,HIST
        shld HEND
        mvi a,1CH
        call PUTC
        lxi h,M_BANNER
        call puts
        call nl

; ---------------------------------------------------------------- REPL
repl:   lxi sp,STACKTOP
        xra a
        sta FLAG
        sta NOEXEC
        sta SLQ
        lxi h,ARGBASE
        shld ARGSP
        ; ak chyba nastala vo funkcii, zahod lokalne premenne
        lhld FRAMEBASE
        lxi d,SYMTAB
        call cmp16
        jz rp1
        lhld GLBEND
        shld SYMTOP
        lxi h,SYMTAB
        shld FRAMEBASE
rp1:    lxi h,P_PROMPT
        call puts
        call readline
        call nl
        lxi h,BLK
        call store_line
        ora a
        jz repl
        mov b,a
        mvi a,1
        sta ECHO
        mov a,b
        cpi ':'
        jnz rb_done
        xra a
        sta ECHO
rb_more: push h
        lxi h,P_CONT
        call puts
        call readline
        call nl
        pop h
        call store_line
        mov b,a
        mov a,h
        cpi 37H
        jnc e_mem
        mov a,b
        ora a
        jnz rb_more
rb_done: mvi m,0FFH
        lxi h,BLK
        call run_lines
        ; uvolni haldu, ak sa nic nezapamatalo
        lda STRST
        ora a
        jz rp_free
        lhld HP
        shld HPMARK
        xra a
        sta STRST
        jmp repl
rp_free: lhld HPMARK
        shld HP
        jmp repl

; ---------------------------------------------------------------- vystup
; pc: znak v A na obrazovku (zalamuje riadok)
pc:     push psw
        push h
        lhld CURSOR
        mov a,l
        ani 3FH
        cpi 30H
        jnz pc1
        mvi a,0DH
        call PUTC
pc1:    pop h
        pop psw
        jmp PUTC
nl:     mvi a,0DH
        jmp PUTC
; puts: retazec HL zakonceny 0 (LF -> novy riadok)
puts:   mov a,m
        ora a
        rz
        cpi 0AH
        jnz ps1
        mvi a,0DH
ps1:    call pc
        inx h
        jmp puts

; emit: A do [OUTP]++
emit:   push h
        lhld OUTP
        mov m,a
        inx h
        shld OUTP
        pop h
        ret
emit_str: mov a,m
        ora a
        rz
        call emit
        inx h
        jmp emit_str
heap_commit: lhld OUTP
        lxi d,HEAPEND
        call cmp16
        jnc e_mem
        shld HP
        ret

; itoa: HL (znamienkove) -> znaky do [OUTP]
itoa:   mov a,h
        ora a
        jp it1
        mvi a,'-'
        call emit
        call neg_hl
it1:    mvi b,0
        lxi d,10000
        call pd
        lxi d,1000
        call pd
        lxi d,100
        call pd
        lxi d,10
        call pd
        mov a,l
        adi '0'
        jmp emit
pd:     mvi c,'0'
pd1:    push h
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        jc pd2
        inx sp
        inx sp
        inr c
        jmp pd1
pd2:    pop h
        mov a,c
        cpi '0'
        jnz pd3
        mov a,b
        ora a
        rz
pd3:    mvi b,1
        mov a,c
        jmp emit

pr_int: lxi d,NUMBUF
        xchg
        shld OUTP
        xchg
        call itoa
        xra a
        call emit
        lxi h,NUMBUF
        jmp puts

; print_val: HL, A=typ
print_val: cpi T_STR
        jz puts
        cpi T_NONE
        jz pv_n
        cpi T_BOOL
        jz pv_b
        cpi T_FUN
        jz pv_f
        jmp pr_int
pv_n:   lxi h,S_NONE
        jmp puts
pv_b:   mov a,h
        ora l
        lxi h,S_FALSE
        jz puts
        lxi h,S_TRUE
        jmp puts
pv_f:   lxi h,S_FUNC
        jmp puts
print_repr: cpi T_STR
        jnz print_val
        push h
        mvi a,27H
        call pc
        pop h
        call puts
        mvi a,27H
        jmp pc

; ---------------------------------------------------------------- vstup
KEY_ENTER1 EQU 0DH
KEY_ENTER2 EQU 89H
KEY_BS1    EQU 83H
KEY_BS2    EQU 7FH
KEY_BS3    EQU 8AH

readline: lhld HEND
        shld HCUR
        lxi h,LINEBUF
        mvi b,0
rl_k:   call GETK
        cpi KEY_UP
        jz rl_up
        cpi KEY_DOWN
        jz rl_dn
        cpi KEY_ENTER1
        jz rl_end
        cpi KEY_ENTER2
        jz rl_end
        cpi KEY_BS1
        jz rl_bs
        cpi KEY_BS2
        jz rl_bs
        cpi KEY_BS3
        jz rl_bs
        cpi 20H
        jc rl_k
        cpi 7FH
        jnc rl_k
        mov c,a
        mov a,b
        cpi 200
        jnc rl_k
        mov a,c
        cpi 'a'
        jc rl_st
        cpi 7BH
        jnc rl_st
        sui 20H
rl_st:  mov m,a
        inx h
        inr b
        call pc
        jmp rl_k
rl_bs:  mov a,b
        ora a
        jz rl_k
        dcx h
        dcr b
        push h
        lhld CURSOR
        dcx h
        shld CURSOR
        mvi a,' '
        call PUTC
        lhld CURSOR
        dcx h
        shld CURSOR
        pop h
        jmp rl_k
rl_end: xra a
        mov m,a
        mov a,b
        ora a
        jz rl_fin
        mov e,b
        mvi d,0
        lhld HEND
        dad d
        inx h
        lxi d,HISTEND+1
        call cmp16
        jc rl_ok
        lxi h,HIST
        shld HEND
rl_ok:  lhld HEND
        xchg
        lxi h,LINEBUF
rl_cp:  mov a,m
        stax d
        inx h
        inx d
        ora a
        jnz rl_cp
        xchg
        shld HEND
rl_fin: lhld HEND
        shld HCUR
        ret
rl_k2:  lxi h,LINEBUF
        mov e,b
        mvi d,0
        dad d
        jmp rl_k
rl_up:  lhld HCUR
        lxi d,HIST
        call cmp16
        jz rl_k2
        dcx h
hp1:    mov a,l
        cmp e
        jnz hp2
        mov a,h
        cmp d
        jz hp_f
hp2:    dcx h
        mov a,m
        ora a
        jnz hp1
        inx h
hp_f:   shld HCUR
        jmp hl_show
rl_dn:  lhld HEND
        xchg
        lhld HCUR
        call cmp16
        jz rl_k2
dn1:    mov a,m
        inx h
        ora a
        jnz dn1
        shld HCUR
        lhld HEND
        xchg
        lhld HCUR
        call cmp16
        jnz hl_show
        call erase_line
        mvi b,0
        jmp rl_k2
hl_show: call erase_line
        lhld HCUR
        lxi d,LINEBUF
        mvi b,0
hs1:    mov a,m
        ora a
        jz rl_k2
        stax d
        inx h
        inx d
        inr b
        call pc
        jmp hs1
erase_line: mov a,b
        ora a
        rz
el1:    lhld CURSOR
        dcx h
        shld CURSOR
        mvi a,' '
        call PUTC
        lhld CURSOR
        dcx h
        shld CURSOR
        dcr b
        jnz el1
        ret

; ---------------------------------------------------------------- pomocne
cmp16:  mov a,h
        cmp d
        rnz
        mov a,l
        cmp e
        ret
neg_hl: mov a,l
        cma
        mov l,a
        mov a,h
        cma
        mov h,a
        inx h
        ret
lower:  cpi 'A'
        rc
        cpi 'Z'+1
        rnc
        ori 20H
        ret
isdig:  cpi '0'
        jc nd
        cpi '9'+1
        jnc nd
        stc
        ret
nd:     ora a
        ret
isal:   push b
        mov b,a
        cpi '_'
        jz isal_y
        ori 20H
        cpi 'a'
        jc isal_n
        cpi 7BH
        jnc isal_n
isal_y: mov a,b
        pop b
        stc
        ret
isal_n: mov a,b
        pop b
        ora a
        ret
isaln:  call isal
        rc
        jmp isdig

cur:    push h
        lhld TP
cu1:    mov a,m
        cpi ' '
        jnz cu2
        inx h
        jmp cu1
cu2:    shld TP
        pop h
        ret
adv:    push h
        lhld TP
        inx h
        shld TP
        pop h
        ret
expect: push psw
        call cur
        push h
        lxi h,3
        dad sp
        cmp m
        pop h
        jnz e_syntax
        pop psw
        jmp adv
accept: push psw
        call cur
        push h
        lxi h,3
        dad sp
        cmp m
        pop h
        jnz acc_no
        pop psw
        call adv
        xra a
        ret
acc_no: pop psw
        ori 1
        ret

; rd_ident: nacita identifikator (male pismena) do NAMEBUF
rd_ident: call cur
        lhld TP
        lxi d,NAMEBUF
        mvi b,8
ri1:    mov a,m
        call isaln
        jnc ri_end
        call lower
        inx h
        mov c,a
        mov a,b
        ora a
        jz ri1
        mov a,c
        stax d
        inx d
        dcr b
        jmp ri1
ri_end: shld TP
ri2:    mov a,b
        ora a
        rz
        xra a
        stax d
        inx d
        dcr b
        jmp ri2

; mkw: HL = klucove slovo; ak je na TP, posunie TP a vrati Z. Zachova B,C.
mkw:    xchg
        call cur
        lhld TP
mk1:    ldax d
        ora a
        jz mk_end
        mov a,m
        call lower
        xchg
        cmp m
        xchg
        rnz
        inx h
        inx d
        jmp mk1
mk_end: mov a,m
        call isaln
        jc mk_no
        shld TP
        xra a
        ret
mk_no:  ori 1
        ret

; nameq: HL = 8 B meno; Z ak sa rovna NAMEBUF
nameq:  lxi d,NAMEBUF
        mvi b,8
nq1:    ldax d
        cmp m
        rnz
        inx h
        inx d
        dcr b
        jnz nq1
        ret

; ---------------------------------------------------------------- tabulka symbolov
; find_in: DE=dolna hranica, HL=vrch (vylucne) -> HL=zaznam, CY=nasiel
find_in: call cmp16
        jz fi_no
        jc fi_no
        push d
        lxi b,-11
        dad b
        push h
        lxi d,NAMEBUF
        mvi b,8
fi_c:   ldax d
        cmp m
        jnz fi_next
        inx h
        inx d
        dcr b
        jnz fi_c
        pop h
        pop d
        stc
        ret
fi_next: pop h
        pop d
        jmp find_in
fi_no:  ora a
        ret
lookup: lhld FRAMEBASE
        xchg
        lhld SYMTOP
        call find_in
        rc
        lhld FRAMEBASE
        lxi d,SYMTAB
        call cmp16
        jz lk_no
        lxi d,SYMTAB
        lhld GLBEND
        jmp find_in
lk_no:  ora a
        ret
; setvar: NAMEBUF, A=typ, DE=hodnota
setvar: push psw
        push d
        cpi T_STR
        jnz sv_a
        lhld FRAMEBASE
        lxi d,SYMTAB
        call cmp16
        jnz sv_a
        mvi a,1
        sta STRST
sv_a:   lhld FRAMEBASE
        xchg
        lhld SYMTOP
        call find_in
        jc sv_have
        lhld SYMTOP
        push h
        lxi d,11
        dad d
        lxi d,SYMEND+1
        call cmp16
        jnc e_mem
        shld SYMTOP
        pop h
sv_have: lxi d,NAMEBUF
        mvi b,8
sv_cp:  ldax d
        mov m,a
        inx h
        inx d
        dcr b
        jnz sv_cp
        pop d
        pop psw
        mov m,a
        inx h
        mov m,e
        inx h
        mov m,d
        ret

; ---------------------------------------------------------------- aritmetika
mul16:  push b
        mov b,h
        mov c,l
        lxi h,0
        mvi a,16
mu1:    dad h
        xchg
        dad h
        xchg
        jnc mu2
        dad b
mu2:    dcr a
        jnz mu1
        pop b
        ret
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
; divmod: znamienkove HL/DE (floor) -> HL podiel, DE zvysok
divmod: mov a,d
        ora e
        jnz dm_ok
        lda NOEXEC
        ora a
        jz e_div0
        lxi h,0
        lxi d,0
        ret
dm_ok:  mvi c,0
        mov a,h
        ora a
        jp dm1
        inr c
        call neg_hl
dm1:    mvi b,0
        mov a,d
        ora a
        jp dm2
        inr b
        xchg
        call neg_hl
        xchg
dm2:    mov a,c
        sta DM_SA
        mov a,b
        sta DM_SB
        xchg
        shld DM_B
        xchg
        call udiv
        lda DM_SA
        mov b,a
        lda DM_SB
        xra b
        jz dm_same
        mov a,e
        ora d
        jnz dm_nz
        call neg_hl
        ret
dm_nz:  inx h
        call neg_hl
        push h
        lhld DM_B
        mov a,l
        sub e
        mov e,a
        mov a,h
        sbb d
        mov d,a
        lda DM_SB
        ora a
        jz dm_p1
        xchg
        call neg_hl
        xchg
dm_p1:  pop h
        ret
dm_same: lda DM_SA
        ora a
        rz
        xchg
        call neg_hl
        xchg
        ret
; scmp: znamienkove HL vs DE -> A=0 rovne, 1 HL>DE, FFh HL<DE
scmp:   mov a,h
        xra d
        jm sc_d
        mov a,h
        cmp d
        jnz sc_f
        mov a,l
        cmp e
sc_f:   jz sc_eq
        jc sc_lt
sc_gt:  mvi a,1
        ret
sc_eq:  xra a
        ret
sc_lt:  mvi a,0FFH
        ret
sc_d:   mov a,h
        ora a
        jm sc_lt
        jmp sc_gt
; stcmp: retazce HL vs DE
stcmp:  ldax d
        mov c,a
        mov a,m
        cmp c
        jc sc_lt
        jnz sc_gt
        mov a,m
        ora a
        jz sc_eq
        inx h
        inx d
        jmp stcmp
; str_cat: HL+DE (retazce) -> novy retazec
str_cat: xchg
        shld TMP2
        xchg
        push h
        lhld HP
        shld OUTP
        shld TMP1
        pop h
        call emit_str
        lhld TMP2
        call emit_str
        xra a
        call emit
        call heap_commit
        lhld TMP1
        mvi a,T_STR
        ret
; binop: B=op (1 +, 2 -, 3 *, 4 %, 5 //), A=typ vlavo, C=typ vpravo, HL vlavo, DE vpravo
binop:  push psw
        mov a,b
        cpi 1
        jnz bo_ar
        pop psw
        cpi T_STR
        jnz bo_ai
        mov a,c
        cpi T_STR
        jnz e_type
        jmp str_cat
bo_ai:  mov a,c
        cpi T_STR
        jz e_type
        dad d
        mvi a,T_INT
        ret
bo_ar:  pop psw
        cpi T_STR
        jz e_type
        mov a,c
        cpi T_STR
        jz e_type
        mov a,b
        cpi 2
        jnz bo3
        mov a,l
        sub e
        mov l,a
        mov a,h
        sbb d
        mov h,a
        mvi a,T_INT
        ret
bo3:    cpi 3
        jnz bo4
        call mul16
        mvi a,T_INT
        ret
bo4:    push b
        call divmod
        pop b
        mov a,b
        cpi 4
        jnz bo5
        xchg
bo5:    mvi a,T_INT
        ret

truthy: cpi T_STR
        jz tr_s
        cpi T_NONE
        jz tr_f
        cpi T_FUN
        jz tr_t
        mov a,h
        ora l
        jz tr_f
tr_t:   mvi a,1
        ora a
        ret
tr_f:   xra a
        ret
tr_s:   mov a,m
        ora a
        jz tr_f
        jmp tr_t

; ---------------------------------------------------------------- vyrazy
e_expr: call e_and
eo1:    push psw
        push h
        lxi h,KW_OR
        call mkw
        jz eo2
        pop h
        pop psw
        ret
eo2:    pop h
        pop psw
        push psw
        push h
        call truthy
        jnz eo_t
        pop h
        pop psw
        call e_and
        jmp eo1
eo_t:   lda NOEXEC
        inr a
        sta NOEXEC
        call e_and
        lda NOEXEC
        dcr a
        sta NOEXEC
        pop h
        pop psw
        jmp eo1

e_and:  call e_not
ea0:    push psw
        push h
        lxi h,KW_AND
        call mkw
        jz ea0b
        pop h
        pop psw
        ret
ea0b:   pop h
        pop psw
        push psw
        push h
        call truthy
        jz ea0_f
        pop h
        pop psw
        call e_not
        jmp ea0
ea0_f:  lda NOEXEC
        inr a
        sta NOEXEC
        call e_not
        lda NOEXEC
        dcr a
        sta NOEXEC
        pop h
        pop psw
        jmp ea0

e_not:  lxi h,KW_NOT
        call mkw
        jnz e_cmp
        call e_not
        call truthy
        jnz en_f
        lxi h,1
        mvi a,T_BOOL
        ret
en_f:   lxi h,0
        mvi a,T_BOOL
        ret

e_cmp:  call e_arith
        push psw
        push h
        call cur
        lhld TP
        mov b,a
        inx h
        mov c,m
        mov a,b
        cpi '<'
        jz ec_lt
        cpi '>'
        jz ec_gt
        cpi '='
        jz ec_eq
        cpi '!'
        jnz ec_none
        mov a,c
        cpi '='
        jnz ec_none
        mvi d,1
        jmp ec_adv2
ec_eq:  mov a,c
        cpi '='
        jnz ec_none
        mvi d,0
        jmp ec_adv2
ec_lt:  mov a,c
        cpi '='
        jz ec_le
        mvi d,2
        jmp ec_adv1
ec_le:  mvi d,3
        jmp ec_adv2
ec_gt:  mov a,c
        cpi '='
        jz ec_ge
        mvi d,4
        jmp ec_adv1
ec_ge:  mvi d,5
ec_adv2: call adv
ec_adv1: call adv
        mov a,d
        push psw
        call e_arith
        mov c,a
        xchg
        pop psw
        mov b,a
        pop h
        pop psw
        cpi T_STR
        jnz ec_int
        mov a,c
        cpi T_STR
        jnz ec_ne
        call stcmp
        jmp ec_res
ec_int: mov a,c
        cpi T_STR
        jz ec_ne
        call scmp
        jmp ec_res
ec_ne:  mvi a,1
ec_res: mov c,a
        ora a
        mov a,c
        mvi c,1
        jz ec_got
        mvi c,2
        jp ec_got
        mvi c,4
ec_got: lxi h,OPMASK
        mov e,b
        mvi d,0
        dad d
        mov a,m
        ana c
        lxi h,0
        jz ec_f
        inx h
ec_f:   mvi a,T_BOOL
        ret
ec_none: pop h
        pop psw
        ret

e_arith: call e_term
ear1:   push psw
        push h
        call cur
        cpi '+'
        jz ear_add
        cpi '-'
        jz ear_sub
        pop h
        pop psw
        ret
ear_add: call adv
        mvi b,1
        jmp ear_go
ear_sub: call adv
        mvi b,2
ear_go: mov a,b
        push psw
        call e_term
        mov c,a
        xchg
        pop psw
        mov b,a
        pop h
        pop psw
        call binop
        jmp ear1

e_term: call e_fact
et1:    push psw
        push h
        call cur
        cpi '*'
        jz et_mul
        cpi '%'
        jz et_mod
        cpi '/'
        jz et_div
        pop h
        pop psw
        ret
et_mul: call adv
        mvi a,3
        jmp et_go
et_mod: call adv
        mvi a,4
        jmp et_go
et_div: call adv
        call cur
        cpi '/'
        jnz et_d1
        call adv
et_d1:  mvi a,5
et_go:  push psw
        call e_fact
        mov c,a
        xchg
        pop psw
        mov b,a
        pop h
        pop psw
        call binop
        jmp et1

e_fact: call cur
        cpi '-'
        jnz ef1
        call adv
        call e_fact
        call neg_hl
        mvi a,T_INT
        ret
ef1:    cpi '+'
        jnz e_atom
        call adv
        jmp e_fact

e_atom: call cur
        cpi '('
        jz at_par
        cpi 22H
        jz at_str
        cpi 27H
        jz at_str
        call isdig
        jc at_num
        call isal
        jc at_name
        jmp e_syntax
at_par: call adv
        call e_expr
        push psw
        push h
        mvi a,')'
        call expect
        pop h
        pop psw
        ret
at_num: call parse_num
        mvi a,T_INT
        ret
at_str: mov b,a
        call adv
        lhld HP
        push h
        xchg
        lhld TP
as1:    mov a,m
        ora a
        jz e_syntax
        inx h
        cmp b
        jz as_end
        cpi 5CH
        jnz as_put
        mov a,m
        inx h
        cpi 'n'
        jz as_nl
        cpi 'N'
        jnz as_put
as_nl:  mvi a,0AH
as_put: stax d
        inx d
        jmp as1
as_end: shld TP
        xra a
        stax d
        inx d
        xchg
        lxi d,HEAPEND
        call cmp16
        jnc e_mem
        shld HP
        pop h
        mvi a,T_STR
        ret

; cislo na TP (desiatkove alebo 0x..) -> HL
parse_num: call cur
        lhld TP
        lxi d,0
        mvi b,10
        mov a,m
        cpi '0'
        jnz pn_loop
        inx h
        mov a,m
        ori 20H
        cpi 'x'
        jnz pn_loop
        inx h
        mvi b,16
pn_loop: mov a,m
        call digval
        cmp b
        jnc pn_end
        push h
        mov c,a
        xchg
        mov a,b
        cpi 16
        jz pn_h
        mov d,h
        mov e,l
        dad h
        dad h
        dad d
        dad h
        jmp pn_add
pn_h:   dad h
        dad h
        dad h
        dad h
pn_add: mov e,c
        mvi d,0
        dad d
        xchg
        pop h
        inx h
        jmp pn_loop
pn_end: shld TP
        xchg
        ret
digval: cpi '0'
        jc dv_bad
        cpi '9'+1
        jnc dv_al
        sui '0'
        ret
dv_al:  ori 20H
        cpi 'a'
        jc dv_bad
        cpi 'g'
        jnc dv_bad
        sui 'a'-10
        ret
dv_bad: mvi a,0FFH
        ret
parse_int: call cur
        cpi '-'
        jnz parse_num
        call adv
        call parse_num
        jmp neg_hl

; meno: konstanty, volanie, premenna
at_name: call rd_ident
        lxi h,N_TRUE
        call nameq
        jnz an1
        lxi h,1
        mvi a,T_BOOL
        ret
an1:    lxi h,N_FALSE
        call nameq
        jnz an2
        lxi h,0
        mvi a,T_BOOL
        ret
an2:    lxi h,N_NONE
        call nameq
        jnz an3
        lxi h,0
        mvi a,T_NONE
        ret
an3:    call cur
        cpi '('
        jnz an_var
        call adv
        lxi h,BTAB
an4:    mov a,m
        ora a
        jz an_user
        push h
        call nameq
        pop h
        jz an_bi
        lxi d,10
        dad d
        jmp an4
an_bi:  lxi d,8
        dad d
        mov e,m
        inx h
        mov d,m
        xchg
        pchl
an_user: call lookup
        jc an_u2
        lda NOEXEC
        ora a
        jz e_name
        lxi h,0
        jmp do_call
an_u2:  lxi d,8
        dad d
        mov a,m
        cpi T_FUN
        jnz e_type
        inx h
        mov e,m
        inx h
        mov d,m
        xchg
        jmp do_call
an_var: call lookup
        jnc an_undef
        lxi d,8
        dad d
        mov a,m
        inx h
        mov e,m
        inx h
        mov d,m
        xchg
        ret
an_undef: lda NOEXEC
        ora a
        jz e_name
        lxi h,0
        mvi a,T_INT
        ret

; ---------------------------------------------------------------- volanie funkcie
do_call: push h
        lhld ARGSP
        push h
        call cur
        cpi ')'
        jnz dc_a
        call adv
        jmp dc_go
dc_a:   call e_expr
        xchg
        lhld ARGSP
        mov m,a
        inx h
        mov m,e
        inx h
        mov m,d
        inx h
        shld ARGSP
        mov a,h
        cpi 33H+1
        jnc e_mem
        call cur
        cpi ','
        jnz dc_cl
        call adv
        jmp dc_a
dc_cl:  mvi a,')'
        call expect
dc_go:  lda NOEXEC
        ora a
        jz dc_run
        pop h
        shld ARGSP
        pop h
        lxi h,0
        mvi a,T_INT
        ret
dc_run: pop h
        pop d
; invoke: HL=ARGSP0, DE=funkcia
invoke: shld ARG0
        push h
        lxi h,0
        dad sp
        mov a,h
        cpi 62H
        jc e_mem
        pop h
        shld CURARG
        push d
        lhld TP
        push h
        lhld FRAMEBASE
        push h
        lhld GLBEND
        push h
        lhld FRAMEBASE
        lxi d,SYMTAB
        call cmp16
        jnz iv_ng
        lhld SYMTOP
        shld GLBEND
iv_ng:  lhld SYMTOP
        shld FRAMEBASE
        lxi h,6
        dad sp
        mov e,m
        inx h
        mov d,m
        xchg
        inx h
        shld TP
        lxi h,KW_DEF
        call mkw
        jnz e_syntax
        call rd_ident
        mvi a,'('
        call expect
        call cur
        cpi ')'
        jz iv_pe
iv_p:   call rd_ident
        lhld CURARG
        xchg
        lhld ARGSP
        call cmp16
        jc e_args
        jz e_args
        xchg
        mov a,m
        inx h
        mov e,m
        inx h
        mov d,m
        inx h
        shld CURARG
        call setvar
        call cur
        cpi ','
        jnz iv_pe
        call adv
        jmp iv_p
iv_pe:  mvi a,')'
        call expect
        lhld CURARG
        xchg
        lhld ARGSP
        call cmp16
        jnz e_args
        lhld ARG0
        shld ARGSP
        mvi a,':'
        call expect
        lhld TP
        inx h
        call run_lines
        lda FLAG
        cpi 3
        jnz iv_none
        lhld RETV
        lda RETT
        jmp iv_fin
iv_none: lxi h,0
        mvi a,T_NONE
iv_fin: push psw
        push h
        xra a
        sta FLAG
        lhld FRAMEBASE
        shld SYMTOP
        pop b
        pop psw
        mov d,a
        pop h
        shld GLBEND
        pop h
        shld FRAMEBASE
        pop h
        shld TP
        pop h
        mov a,d
        mov h,b
        mov l,c
        ret

; ---------------------------------------------------------------- prikazy
; next_line: HL=riadok -> HL=dalsi riadok
next_line: inx h
nl1:    mov a,m
        ora a
        jz nl2
        inx h
        jmp nl1
nl2:    inx h
        ret
; skip_blk: HL=riadok, B=odsadenie hlavicky -> prvy riadok s odsadenim <= B
skip_blk: mov a,m
        cpi 0FFH
        rz
        cmp b
        rc
        rz
        call next_line
        jmp skip_blk

; run_lines: HL=prvy riadok bloku -> vykona riadky s tym istym odsadenim
run_lines: mov a,m
        cpi 0FFH
        rz
        mov b,a
rl_lp:  mov a,m
        cpi 0FFH
        rz
        cmp b
        rc
        jnz e_indent
        push b
        call exec_stmt
        pop b
        lda FLAG
        ora a
        rnz
        jmp rl_lp

exec_stmt: push h
        inx h
        shld TP
        lxi h,KW_IF
        call mkw
        jz st_if
        lxi h,KW_WHILE
        call mkw
        jz st_while
        lxi h,KW_FOR
        call mkw
        jz st_for
        lxi h,KW_DEF
        call mkw
        jz st_def
        lxi h,KW_RETURN
        call mkw
        jz st_return
        lxi h,KW_BREAK
        call mkw
        jz st_break
        lxi h,KW_CONT
        call mkw
        jz st_cont
        lxi h,KW_PASS
        call mkw
        jz fin_simple
        jmp st_simple

fin_simple: call cur
        ora a
        jnz e_syntax
        lhld TP
        inx h
        pop d
        ret
st_break: mvi a,1
        sta FLAG
        jmp fin_simple
st_cont: mvi a,2
        sta FLAG
        jmp fin_simple
st_return: call cur
        ora a
        jnz sr_val
        lxi h,0
        mvi a,T_NONE
        jmp sr_set
sr_val: call e_expr
sr_set: shld RETV
        sta RETT
        mvi a,3
        sta FLAG
        jmp fin_simple

; jednoduchy prikaz: priradenie alebo vyraz
st_simple: call cur
        call isal
        jnc ss_expr
        lhld TP
        push h
        call rd_ident
        call cur
        mov b,a
        lhld TP
        inx h
        mov c,m
        mov a,b
        cpi '='
        jnz ss_aug
        mov a,c
        cpi '='
        jz ss_back
        call adv
        mvi d,0
        jmp ss_rhs
ss_aug: mvi d,1
        cpi '+'
        jz ss_a2
        mvi d,2
        cpi '-'
        jz ss_a2
        mvi d,3
        cpi '*'
        jz ss_a2
        mvi d,4
        cpi '%'
        jz ss_a2
        cpi '/'
        jnz ss_back
        mov a,c
        cpi '/'
        jnz ss_back
        lhld TP
        inx h
        inx h
        mov a,m
        cpi '='
        jnz ss_back
        mvi d,5
        call adv
        call adv
        call adv
        jmp ss_rhs
ss_a2:  mov a,c
        cpi '='
        jnz ss_back
        call adv
        call adv
ss_rhs: mov a,d
        push psw
        PUSHNAME
        call e_expr
        mov c,a
        xchg
        POPNAME
        pop psw
        ora a
        jz ss_plain
        mov b,a
        push b
        push d
        call lookup
        jnc e_name
        lxi d,8
        dad d
        mov a,m
        inx h
        mov e,m
        inx h
        mov d,m
        xchg
        pop d
        pop b
        call binop
        xchg
        jmp ss_set
ss_plain: mov a,c
ss_set: call setvar
        pop h
        jmp fin_simple
ss_back: pop h
        shld TP
ss_expr: call e_expr
        push psw
        push h
        lda ECHO
        ora a
        jz ss_ne
        lhld FRAMEBASE
        lxi d,SYMTAB
        call cmp16
        jnz ss_ne
        pop h
        pop psw
        cpi T_NONE
        jz fin_simple
        call print_repr
        call nl
        jmp fin_simple
ss_ne:  pop h
        pop psw
        jmp fin_simple

; if / elif / else
st_if:
st_if_e: call e_expr
        call truthy
        push psw
        mvi a,':'
        call expect
        call cur
        ora a
        jnz e_syntax
        lhld TP
        inx h
        pop psw
        pop d
        push psw
        ldax d
        mov b,a
        push b
        push h
        call skip_blk
        xchg
        pop h
        pop b
        pop psw
        ora a
        jnz sif_true
        xchg
        call chain_kw
        ora a
        jz sif_end
        cpi 2
        jz sif_elif
        ; else
        mvi a,':'
        call expect
        call cur
        ora a
        jnz e_syntax
        lhld TP
        inx h
        push h
        call skip_blk
        xthl
        push b
        call run_lines
        pop b
        pop h
        ret
sif_elif: push h
        jmp st_if_e
sif_true: push b
        push d
        call run_lines
        pop h
        pop b
sif_skip: call chain_kw
        ora a
        jz sif_end
        call next_line
        call skip_blk
        jmp sif_skip
sif_end: ret
; chain_kw: HL=riadok, B=odsadenie -> A=0 nic, 1 else, 2 elif; TP za klucovym slovom
chain_kw: mov a,m
        cmp b
        jnz ck_none
        push h
        inx h
        shld TP
        lxi h,KW_ELIF
        call mkw
        jz ck_elif
        lxi h,KW_ELSE
        call mkw
        jz ck_else
        pop h
ck_none: xra a
        ret
ck_elif: pop h
        mvi a,2
        ret
ck_else: pop h
        mvi a,1
        ret

; while
st_while: call cur
        lhld TP
        push h
        lxi h,2
        dad sp
        mov e,m
        inx h
        mov d,m
        xchg
        mov b,m
        call next_line
        push h
        call skip_blk
        push h
sw_loop: lxi h,4
        dad sp
        mov e,m
        inx h
        mov d,m
        xchg
        shld TP
        call e_expr
        call truthy
        jz sw_done
        lxi h,2
        dad sp
        mov e,m
        inx h
        mov d,m
        xchg
        call run_lines
        lda FLAG
        ora a
        jz sw_loop
        cpi 1
        jnz sw_nb
        xra a
        sta FLAG
        jmp sw_done
sw_nb:  cpi 2
        jnz sw_done
        xra a
        sta FLAG
        jmp sw_loop
sw_done: pop h
        pop d
        pop d
        pop d
        ret

; for x in range(...)
st_for: call rd_ident
        PUSHNAME
        lxi h,KW_IN
        call mkw
        jnz e_syntax
        lxi h,KW_RANGE
        call mkw
        jnz e_syntax
        mvi a,'('
        call expect
        call e_expr
        push h
        call cur
        cpi ','
        jnz sf_one
        call adv
        call e_expr
        push h
        call cur
        cpi ','
        jnz sf_two
        call adv
        call e_expr
        push h
        jmp sf_have
sf_one: mvi a,')'
        call expect
        pop h
        lxi d,0
        push d
        push h
        lxi h,1
        push h
        jmp sf_have2
sf_two: mvi a,')'
        call expect
        pop h
        pop d
        push d
        push h
        lxi h,1
        push h
        jmp sf_have2
sf_have: mvi a,')'
        call expect
sf_have2: mvi a,':'
        call expect
        call cur
        ora a
        jnz e_syntax
        lhld TP
        inx h
        push h
        lxi h,16
        dad sp
        mov e,m
        inx h
        mov d,m
        ldax d
        mov b,a
        pop h
        push h
        call skip_blk
        push h
sf_loop: lxi h,4
        dad sp
        mov e,m
        inx h
        mov d,m
        lxi h,8
        dad sp
        mov c,m
        inx h
        mov b,m
        lxi h,6
        dad sp
        mov a,m
        inx h
        mov h,m
        mov l,a
        mov a,d
        push psw
        xchg
        mov h,b
        mov l,c
        call scmp
        mov b,a
        pop psw
        ora a
        jm sf_neg
        mov a,b
        cpi 0FFH
        jnz sf_done
        jmp sf_body
sf_neg: mov a,b
        cpi 1
        jnz sf_done
sf_body: lxi h,10
        dad sp
        lxi d,NAMEBUF
        mvi b,8
sf_cp:  mov a,m
        stax d
        inx h
        inx d
        dcr b
        jnz sf_cp
        lxi h,8
        dad sp
        mov e,m
        inx h
        mov d,m
        mvi a,T_INT
        call setvar
        lxi h,2
        dad sp
        mov e,m
        inx h
        mov d,m
        xchg
        call run_lines
        lda FLAG
        ora a
        jz sf_next
        cpi 1
        jz sf_brk
        cpi 2
        jnz sf_done
        xra a
        sta FLAG
        jmp sf_next
sf_brk: xra a
        sta FLAG
        jmp sf_done
sf_next: lxi h,4
        dad sp
        mov e,m
        inx h
        mov d,m
        lxi h,8
        dad sp
        mov a,m
        add e
        mov m,a
        inx h
        mov a,m
        adc d
        mov m,a
        jmp sf_loop
sf_done: pop h
        pop d
        pop d
        pop d
        pop d
        pop d
        pop d
        pop d
        pop d
        pop d
        ret

; def
st_def: call rd_ident
        pop h
        mov b,m
        push h
        call next_line
        call skip_blk
        push h
        lhld PROGTOP
        push h
        mov b,h
        mov c,l
        lxi h,2
        dad sp
        mov e,m
        inx h
        mov d,m
        lxi h,4
        dad sp
        mov a,m
        inx h
        mov h,m
        mov l,a
dcp1:   mov a,l
        cmp e
        jnz dcp2
        mov a,h
        cmp d
        jz dcp3
dcp2:   mov a,m
        stax b
        inx h
        inx b
        jmp dcp1
dcp3:   mvi a,0FFH
        stax b
        inx b
        mov a,b
        cpi hi(PROGEND)
        jnc e_mem
        mov h,b
        mov l,c
        shld PROGTOP
        pop d
        pop h
        pop b
        push h
        mvi a,T_FUN
        call setvar
        pop h
        ret

; ---------------------------------------------------------------- ulozenie riadku
; store_line: LINEBUF -> [HL]: odsadenie, text, 0. Vrati HL za zapisom, A = posledny znak (0 = prazdny riadok)
store_line: push h
        xra a
        sta SLQ
        sta SLC
        lxi d,LINEBUF
        mvi b,0
sl_i:   ldax d
        cpi ' '
        jnz sl_t
        inx d
        inr b
        jmp sl_i
sl_t:   ora a
        jz sl_empty
        cpi '#'
        jz sl_empty
        xchg
        shld TP
        xchg
        push d
        lxi h,KW_IF
        call mkw
        jz sl_cf
        lxi h,KW_ELIF
        call mkw
        jz sl_cf
        lxi h,KW_ELSE
        call mkw
        jz sl_cf
        lxi h,KW_WHILE
        call mkw
        jz sl_cf
        lxi h,KW_FOR
        call mkw
        jz sl_cf
        lxi h,KW_DEF
        call mkw
        jnz sl_nf
sl_cf:  mvi a,1
        sta SLC
sl_nf:  pop d
        pop h
        mov m,b
        inx h
sl_c:   ldax d
        ora a
        jz sl_done
        inx d
        mov m,a
        inx h
        mov c,a
        lda SLQ
        ora a
        jz sl_nq
        cmp c
        jnz sl_c
        xra a
        sta SLQ
        jmp sl_c
sl_nq:  mov a,c
        cpi 22H
        jz sl_oq
        cpi 27H
        jz sl_oq
        cpi '#'
        jz sl_cmt
        cpi ':'
        jnz sl_c
        lda SLC
        ora a
        jz sl_c
        push d
sl_sp:  ldax d
        cpi ' '
        jnz sl_sp2
        inx d
        jmp sl_sp
sl_sp2: ora a
        jz sl_nsp
        cpi '#'
        jz sl_nsp
        inx sp
        inx sp
        xra a
        mov m,a
        inx h
        mov a,b
        inr a
        mov m,a
        inx h
        xra a
        sta SLC
        jmp sl_c
sl_nsp: pop d
        xra a
        sta SLC
        jmp sl_c
sl_oq:  sta SLQ
        jmp sl_c
sl_cmt: dcx h
sl_done:
sl_st:  dcx h
        mov a,m
        cpi ' '
        jz sl_st
        mov c,a
        inx h
        xra a
        mov m,a
        inx h
        mov a,c
        ret
sl_empty: pop h
        xra a
        ret

; ---------------------------------------------------------------- vstavane funkcie (TP je za '(')
arg1:   call e_expr
        push psw
        push h
        mvi a,')'
        call expect
        pop h
        pop psw
        ret

b_print: call cur
        cpi ')'
        jz bp_end
bp_lp:  call e_expr
        mov b,a
        lda NOEXEC
        ora a
        jnz bp_sk
        mov a,b
        call print_val
bp_sk:  call cur
        cpi ','
        jnz bp_end
        call adv
        lda NOEXEC
        ora a
        jnz bp_lp
        mvi a,' '
        call pc
        jmp bp_lp
bp_end: mvi a,')'
        call expect
        lda NOEXEC
        ora a
        jnz bp_ret
        call nl
bp_ret: lxi h,0
        mvi a,T_NONE
        ret

b_len:  call arg1
        cpi T_STR
        jnz e_type
        lxi d,0
bl1:    mov a,m
        ora a
        jz bl2
        inx h
        inx d
        jmp bl1
bl2:    xchg
        mvi a,T_INT
        ret

b_abs:  call arg1
        mov a,h
        ora a
        jp ba1
        call neg_hl
ba1:    mvi a,T_INT
        ret

b_ord:  call arg1
        cpi T_STR
        jnz e_type
        mov l,m
        mvi h,0
        mvi a,T_INT
        ret

b_chr:  call arg1
        xchg
        lhld HP
        push h
        mov m,e
        inx h
        mvi m,0
        inx h
        shld HP
        pop h
        mvi a,T_STR
        ret

b_peek: call arg1
        mov l,m
        mvi h,0
        mvi a,T_INT
        ret

b_poke: call e_expr
        push h
        mvi a,','
        call expect
        call e_expr
        push h
        mvi a,')'
        call expect
        pop d
        pop h
        lda NOEXEC
        ora a
        jnz bpk1
        mov m,e
bpk1:   lxi h,0
        mvi a,T_NONE
        ret

b_int:  call arg1
        cpi T_STR
        jnz bi_r
        xchg
        lhld TP
        push h
        xchg
        shld TP
        call parse_int
        pop d
        xchg
        shld TP
        xchg
bi_r:   mvi a,T_INT
        ret

b_str:  call arg1
        cpi T_STR
        rz
        mov b,a
        push h
        lhld HP
        shld OUTP
        push h
        mov a,b
        cpi T_NONE
        jz bs_none
        cpi T_FUN
        jz bs_fun
        cpi T_BOOL
        jz bs_bool
        lxi h,2
        dad sp
        mov e,m
        inx h
        mov d,m
        xchg
        call itoa
        jmp bs_fin
bs_none: lxi h,S_NONE
        jmp bs_cp
bs_fun: lxi h,S_FUNC
        jmp bs_cp
bs_bool: lxi h,2
        dad sp
        mov a,m
        inx h
        ora m
        lxi h,S_FALSE
        jz bs_cp
        lxi h,S_TRUE
bs_cp:  call emit_str
bs_fin: xra a
        call emit
        call heap_commit
        pop h
        pop d
        mvi a,T_STR
        ret

b_input: call cur
        cpi ')'
        jz bin1
        call e_expr
        push psw
        push h
        mvi a,')'
        call expect
        pop h
        pop psw
        call puts
        jmp bin2
bin1:   call adv
bin2:   call readline
        call nl
        lhld HP
        push h
        shld OUTP
        lxi h,LINEBUF
        call emit_str
        xra a
        call emit
        call heap_commit
        pop h
        mvi a,T_STR
        ret

; ---------------------------------------------------------------- data
BTAB:   DB "print",0,0,0
        DW b_print
        DB "len",0,0,0,0,0
        DW b_len
        DB "abs",0,0,0,0,0
        DW b_abs
        DB "ord",0,0,0,0,0
        DW b_ord
        DB "chr",0,0,0,0,0
        DW b_chr
        DB "peek",0,0,0,0
        DW b_peek
        DB "poke",0,0,0,0
        DW b_poke
        DB "int",0,0,0,0,0
        DW b_int
        DB "str",0,0,0,0,0
        DW b_str
        DB "input",0,0,0
        DW b_input
        DB 0

N_TRUE: DB "true",0,0,0,0
N_FALSE: DB "false",0,0,0
N_NONE: DB "none",0,0,0,0

KW_IF:  DB "if",0
KW_ELIF: DB "elif",0
KW_ELSE: DB "else",0
KW_WHILE: DB "while",0
KW_FOR: DB "for",0
KW_IN:  DB "in",0
KW_RANGE: DB "range",0
KW_DEF: DB "def",0
KW_RETURN: DB "return",0
KW_BREAK: DB "break",0
KW_CONT: DB "continue",0
KW_PASS: DB "pass",0
KW_AND: DB "and",0
KW_OR:  DB "or",0
KW_NOT: DB "not",0

S_NONE: DB "NONE",0
S_TRUE: DB "TRUE",0
S_FALSE: DB "FALSE",0
S_FUNC: DB "<FUNKCIA>",0
P_PROMPT: DB ">>> ",0
P_CONT: DB "... ",0
M_BANNER: DB "PMD 85  MICRO PYTHON 8080",0
M_ERR:  DB "CHYBA: ",0
M_SYNTAX: DB "SYNTAX",0
M_NAME: DB "MENO",0
M_TYPE: DB "TYP",0
M_DIV0: DB "DELENIE NULOU",0
M_MEM:  DB "PAMAT",0
M_ARGS: DB "ARGUMENTY",0
M_INDENT: DB "ODSADENIE",0


e_syntax: lxi h,M_SYNTAX
        jmp err
e_name: lxi h,M_NAME
        jmp err
e_type: lxi h,M_TYPE
        jmp err
e_div0: lxi h,M_DIV0
        jmp err
e_mem:  lxi h,M_MEM
        jmp err
e_args: lxi h,M_ARGS
        jmp err
e_indent: lxi h,M_INDENT
err:    push h
        lhld CURSOR
        mov a,l
        ani 3FH
        cnz nl
        lxi h,M_ERR
        call puts
        pop h
        call puts
        call nl
        jmp repl

OPMASK: DB 1,6,4,5,2,3
        END start
