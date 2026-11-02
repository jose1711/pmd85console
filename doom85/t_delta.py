"""Overi, ze prekreslovanie len zmenenych riadkov (DIRTY/PSIG/PWP) da po kazdej snimke rovnaky obraz ako plne prekreslenie."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom, gen
DIRTY = 0x31C0
UP, DOWN, LEFT, RIGHT, FIRE = (13, 1), (13, 3), (12, 2), (14, 2), (0, 4)

def mk(force):
    s, syms = t_doom.boot()
    held = set()
    base = s.inport[0xF5]
    def f5(m):
        col = m.ports.get(0xF4, 0) & 15
        if held:
            v = 0xFF
            for (c, b) in held:
                if c == col: v &= ~(1 << b)
            if col in [c for c, b in held]: return v
        return base(m)
    s.inport[0xF5] = f5
    return s, syms, held

A, symsA, heldA = mk(False)
B, symsB, heldB = mk(True)
t_doom.frame(A, symsA); t_doom.frame(B, symsB)
script = [({UP}, 10), ({RIGHT}, 6), ({UP}, 12), ({FIRE}, 1), (set(), 1), ({FIRE}, 1), ({LEFT}, 9), ({UP}, 10), ({DOWN}, 6), ({RIGHT}, 14), ({UP}, 14), (set(), 3)]
bad = 0; n = 0; ta = tb = 0
for keys, cnt in script:
    for _ in range(cnt):
        heldA.clear(); heldA.update(keys); heldB.clear(); heldB.update(keys)
        for i in range(48): B.m[DIRTY + i] = 1
        ta += t_doom.frame(A, symsA); tb += t_doom.frame(B, symsB)
        n += 1
        if A.m[gen.VIDEO:gen.VIDEO + 8192] != B.m[gen.VIDEO:gen.VIDEO + 8192]:
            bad += 1
            d = [i for i in range(8192) if A.m[gen.VIDEO + i] != B.m[gen.VIDEO + i]]
            print('rozdiel v snimke', n, 'pocet', len(d), 'prvy (riadok, stlpec)', divmod(d[0], 64))
print('snimok', n, 'rozdielnych', bad, '| priemer T-cyklov delta %.0f plne %.0f (%.0f ms vs %.0f ms)' % (ta / n, tb / n, ta / n / 2000, tb / n / 2000))
print('stav: zdravie', A.m[0x2F1A], 'naboje', A.m[0x2F1B], 'zabitych', A.m[0x2F1C], 'poloha', hex(A.m[0x2F00] | A.m[0x2F01] << 8), hex(A.m[0x2F02] | A.m[0x2F03] << 8))
