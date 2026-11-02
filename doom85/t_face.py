"""Tvar v HUD: stav podla zdravia, bolest pri poklese zdravia, usmev pri zabiti; bajty na obrazovke = faces.bin."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
s, syms = t_doom.boot()
t_doom.frame(s, syms)
for i in range(9): s.m[0x3224 + 8 * i] = 0          # ziadne priserky
fb = open(os.path.join(HERE, 'faces.bin'), 'rb').read()
DST = 0xC000 + 194 * 64 + 20
def shown():
    for st in range(8):
        if all(s.m[DST + y * 64 + b] == fb[st * 384 + y * 8 + b] for y in range(48) for b in range(8)): return st
    return None
bad = 0
for hp, exp in ((100, 0), (80, 1), (60, 2), (40, 3), (20, 4), (5, 4)):
    for _ in range(6): s.m[0x2F1A] = hp; t_doom.frame(s, syms)
    got = shown()
    ok = got == exp; bad += not ok
    print('zdravie %3d -> tvar %s (cakane %d) %s' % (hp, got, exp, 'OK' if ok else 'CHYBA'))
# pokles zdravia -> bolest, po par snimkach spat
s.m[0x2F1A] = 100
for _ in range(6): t_doom.frame(s, syms)
s.m[0x2F1A] = 90; t_doom.frame(s, syms)
got = shown(); print('po zraneni:', got, 'OK' if got == 5 else 'CHYBA'); bad += got != 5
for _ in range(5): t_doom.frame(s, syms)
got = shown(); print('po 5 snimkach:', got, 'OK' if got == 0 else 'CHYBA'); bad += got != 0
# zabitie -> spokojna
s.m[0x2F1C] = 1; t_doom.frame(s, syms)
got = shown(); print('po zabiti:', got, 'OK' if got == 6 else 'CHYBA'); bad += got != 6
print('chyby', bad)
