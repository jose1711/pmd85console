"""Premenne v oblasti 4F00h-4FFFh sa nesmu prekryvat (slovo = 2 bajty): chyba takeho druhu prekreslovala mapku kazdu snimku."""
import re, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
a = open(os.path.join(HERE, 'doom.asm')).read()
words = set('PRJP TCUR MBP ZP SEED STKP EXV EYV ADX ADY COLP RX RY IX IY PX PY SAVESP SIDE DEPTH DXV DYV BASEADDR USTEP UACC CCV EPTR BESTP TEXP RECP TMPU VP FBP SLP SLP2 PKP IX2 IY2 CRX CRY AIP GPTR C0V'.split())
occ = {}; bad = []
for n, v in re.findall(r'^(\w+)\s+EQU\s+([0-9A-F]{4})H', a, re.M):
    v = int(v, 16)
    if not 0x4F00 <= v < 0x5000: continue
    for k in range(2 if n in words else 1):
        if v + k in occ: bad.append((n, occ[v + k], hex(v + k)))
        occ[v + k] = n
print('prekryvy premennych:', bad, 'OK' if not bad else 'CHYBA')
sys.exit(1 if bad else 0)
