"""Nôž (blizky dosah, nizka ucinnost, bez nabojov) a strelci (strela z priamej ciary, poskodenie, zablokovana ciara)."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
E = 0x5220
HEALTH, AMMO, KILLS, WPN, PDMG, PX, PY, ANG = 0x4F1A, 0x4F1B, 0x4F1C, 0x4F3C, 0x4F3E, 0x4F00, 0x4F02, 0x4F04
held = set()
def mk():
    s, syms = t_doom.boot()
    base = s.inport[0xF5]
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
    return s, syms
def run_cell(s):
    """vodorovny rad >= 8 volnych buniek"""
    for y in range(1, 15):
        x = 1
        while x < 15:
            if s.m[0x5000 + y * 256 + x] == 0:
                x1 = x
                while x1 < 15 and s.m[0x5000 + y * 256 + x1] == 0: x1 += 1
                if x1 - x >= 8: return y, x
                x = x1
            else: x += 1
    raise SystemExit('ziadny vhodny rad')
def setpos(s, i, cx, cy, hp=2, st=0):
    o = E + 8 * i
    s.m[o:o + 8] = bytes([128, cx, 128, cy, hp, cx, cy, st])
def clear(s):
    for i in range(14): s.m[E + 8 * i + 4] = 0
bad = 0
# --- strelec s priamou ciarou
s, syms = mk(); y, x = run_cell(s)
clear(s); setpos(s, 0, x, y, 2, 8)
s.m[PX:PX + 4] = bytes([128, x + 5, 128, y]); s.m[ANG] = 32; s.m[HEALTH] = 100; s.m[PDMG] = 3
seen = set(); xs = []
for f in range(60):
    t_doom.frame(s, syms)
    o = E + 8 * (6 + 5)
    if s.m[o + 4]:
        seen.add(0); xs.append(s.m[o] | s.m[o + 1] << 8)
    if s.m[HEALTH] < 100: break
ok = s.m[HEALTH] == 97 and xs and all(b >= a for a, b in zip(xs, xs[1:]))
print('strelec: zdravie', s.m[HEALTH], 'po', f + 1, 'snimkach, polohy strely', xs[:4], '...', 'OK' if ok else 'CHYBA'); bad += not ok
# --- zablokovana ciara
s, syms = mk(); y, x = run_cell(s)
clear(s); setpos(s, 0, x, y, 2, 8); s.m[0x5000 + y * 256 + x + 2] = 1
s.m[PX:PX + 4] = bytes([128, x + 5, 128, y]); s.m[ANG] = 32; s.m[HEALTH] = 100; s.m[PDMG] = 3
shots = 0
for f in range(50):
    t_doom.frame(s, syms)
    shots += sum(1 for j in range(3) if s.m[E + 8 * (11 + j) + 4])
ok = shots == 0 and s.m[HEALTH] == 100
print('zablokovana ciara: striel', shots, 'zdravie', s.m[HEALTH], 'OK' if ok else 'CHYBA'); bad += not ok
# --- noz
s, syms = mk(); y, x = run_cell(s)
clear(s); setpos(s, 0, x + 1, y, 1, 0); setpos(s, 1, x + 6, y, 1, 0)       # blizko a ďaleko, obe mimo pohybu: hrac je v x
s.m[PX:PX + 4] = bytes([128, x, 128, y]); s.m[ANG] = 0; s.m[WPN] = 1; s.m[AMMO] = 30; s.m[HEALTH] = 100
for f in range(40):
    held.clear()
    if f % 2 == 0: held.add((0, 4))
    s.m[PX:PX + 4] = bytes([128, x, 128, y]); s.m[ANG] = 0; s.m[WPN] = 1
    s.m[E + 8 * 1 + 4] = 1                                              # vzdialeny nesmie utrpiet
    for k in (0, 1): s.m[E + 8 * k + 5] = s.m[E + 8 * k + 1]; s.m[E + 8 * k + 6] = s.m[E + 8 * k + 3]
    t_doom.frame(s, syms)
    if s.m[E + 4] == 0: break
held.clear()
ok = s.m[E + 4] == 0 and s.m[KILLS] >= 1 and s.m[AMMO] == 30 and s.m[E + 8 + 4] == 1
print('noz: blizka priserka zabita po', f + 1, 'snimkach, naboje', s.m[AMMO], 'vzdialena hp', s.m[E + 8 + 4], 'OK' if ok else 'CHYBA'); bad += not ok
# klavesy: 1 = noz, 2 = pistol
s, syms = mk()
for key, exp in (((0, 1), 1), ((1, 1), 0)):
    s.m[WPN] = 1 - exp
    held.clear(); held.add(key)
    for _ in range(3): t_doom.frame(s, syms)
    held.clear()
    ok = s.m[WPN] == exp; bad += not ok
    print('klaves', 'cislica %d' % (key[0] + 1), '-> zbran', 'noz' if s.m[WPN] else 'pistol', 'OK' if ok else 'CHYBA')
# E dopredu, Y dozadu (a DEL, END): poloha hraca sa mení v smere pohľadu
for name, key, sgn in (('E', (2, 2), 1), ('Y', (1, 4), -1), ('DEL', (13, 1), 1), ('END', (13, 3), -1)):
    s, syms = mk(); y, x = run_cell(s)
    clear(s)
    s.m[PX:PX + 4] = bytes([128, x + 3, 128, y]); s.m[ANG] = 0
    px0 = s.m[PX] | s.m[PX + 1] << 8
    held.clear(); held.add(key)
    for _ in range(5): t_doom.frame(s, syms)
    held.clear()
    px1 = s.m[PX] | s.m[PX + 1] << 8
    ok = (px1 - px0) * sgn > 0 and s.m[PY + 1] == y
    bad += not ok
    print('kláves', name, 'posun x', px1 - px0, 'OK' if ok else 'CHYBA')
# strelba pocas chodze dozadu (drzi sa END a medzernik naraz)
s, syms = mk(); y, x = run_cell(s)
clear(s); s.m[PX:PX + 4] = bytes([128, x + 3, 128, y]); s.m[ANG] = 0; s.m[WPN] = 0; s.m[AMMO] = 30
held.clear(); held.add((13, 3)); held.add((0, 4))
for _ in range(2): t_doom.frame(s, syms)
held.clear()
ok = s.m[AMMO] == 29; bad += not ok
print('strelba pocas pohybu dozadu: naboje', s.m[AMMO], 'OK' if ok else 'CHYBA')
print('chyby', bad)
