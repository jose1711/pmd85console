"""Priemerna dlzka snimky pocas skriptovaneho pohybu (T-cykly -> ms pri 2 MHz); argument: cesta k doom.asm (inak aktualny)."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom, build
if len(sys.argv) > 1:
    src = open(sys.argv[1]).read()
    build.source = lambda: src + __import__('gen').emit() + '        END start\n'
s, syms = t_doom.boot()
held = set(); base = s.inport[0xF5]
def f5(m):
    col = m.ports.get(0xF4, 0) & 15
    if held:
        v = 0xFF
        for (c, b) in held:
            if c == col: v &= ~(1 << b)
        return v
    return base(m)
s.inport[0xF5] = f5
t_doom.frame(s, syms)
tot = n = 0
for keys, cnt in [({(13, 1)}, 14), ({(14, 2)}, 8), ({(13, 1)}, 14), ({(12, 2)}, 8), ({(13, 1)}, 12), (set(), 3)]:
    held.clear(); held.update(keys)
    for _ in range(cnt): tot += t_doom.frame(s, syms); n += 1
print('priemerna snimka %.0f ms (%.1f snimky/s), polohy %s' % (tot / n / 2000, 2000000 / (tot / n), hex(s.m[0x4F00] | s.m[0x4F01] << 8)))
