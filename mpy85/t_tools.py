import sys
sys.path.insert(0,'.')
import asm8080, sim8080
src='''
        ORG 0100H
start:  LXI H,data
        MVI B,5
        XRA A
loop:   ADD M
        INX H
        DCR B
        JNZ loop
        STA result
        LXI D,1234
        LXI B,0
        CALL sub
        HLT
sub:    XCHG
        DAD D
        RET
data:   DB 1,2,3,4,5
result: DS 1
msg:    DB "hi",0
'''
org,code,syms=asm8080.assemble(src)
s=sim8080.Sim()
s.m[org:org+len(code)]=code
s.pc=org; s.sp=0x7000
s.run()
print('sum',s.m[syms['result']],'DE/HL',hex((s.d<<8)|s.e),hex((s.h<<8)|s.l),'size',len(code))
assert s.m[syms['result']]==15
