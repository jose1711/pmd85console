"""Tvar v HUD: stav podla zdravia, bolest pri poklese zdravia, usmev pri zabiti; bajty na obrazovke = faces.bin."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
s, syms = t_doom.boot()
t_doom.frame(s, syms)
for i in range(14): s.m[0x5224 + 8 * i] = 0          # ziadne priserky
import gen
fn = os.path.join(HERE, 'faces_local.bin') if os.path.exists(os.path.join(HERE, 'faces_local.bin')) else os.path.join(HERE, 'faces.bin')
fb = open(fn, 'rb').read()
DST = 0xC000 + 194 * 64 + 20
def shown():
    res = []
    for st in range(26):
        if all(s.m[DST + y * 64 + b] == fb[st * 384 + y * 8 + b] for y in range(48) for b in range(8)): res.append(st)
    return res
def lvl(hp): return 0 if hp > 80 else 1 if hp > 60 else 2 if hp > 40 else 3 if hp > 20 else 4
bad = 0
for hp in (100, 80, 60, 40, 20, 5):
    for _ in range(18): s.m[0x4F1A] = hp; t_doom.frame(s, syms)
    got = shown(); exp = lvl(hp) * 3
    ok = any(g in (exp, exp + 1, exp + 2) for g in got); bad += not ok
    print('zdravie %3d -> bitmapa %s (cakane %d-%d) %s' % (hp, got, exp, exp + 2, 'OK' if ok else 'CHYBA'))
# pokles zdravia -> bolest (15 + uroven)
s.m[0x4F1A] = 100
for _ in range(18): t_doom.frame(s, syms)
s.m[0x4F1A] = 90; t_doom.frame(s, syms)
got = shown(); ok = 15 in got; bad += not ok; print('po zraneni:', got, 'OK' if ok else 'CHYBA')
for _ in range(5): t_doom.frame(s, syms)
got = shown(); ok = any(g < 3 for g in got); bad += not ok; print('po 5 snimkach:', got, 'OK' if ok else 'CHYBA')
s.m[0x4F1C] = 1; t_doom.frame(s, syms)
got = shown(); ok = 20 in got; bad += not ok; print('po zabiti:', got, 'OK' if ok else 'CHYBA')
print('chyby', bad)
