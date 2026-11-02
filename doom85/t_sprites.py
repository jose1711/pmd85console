"""Nahodne stavy: kazdy zaznam v zozname viditelnych spritov musi mat CS <= CE <= 47 a UACC nepresiahne tabulku (u <= 8)."""
import sys, os, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
s, syms = t_doom.boot()
t_doom.frame(s, syms)
mp = [s.m[0x3000 + y * 256 + x] for y in range(16) for x in range(16)]
free = [(x, y) for y in range(16) for x in range(16) if mp[y * 16 + x] == 0]
random.seed(3)
bad = 0; recs = 0
for k in range(400):
    x, y = random.choice(free)
    px = x * 256 + random.randrange(8, 248); py = y * 256 + random.randrange(8, 248)
    s.m[0x2F00:0x2F02] = bytes([px & 255, px >> 8]); s.m[0x2F02:0x2F04] = bytes([py & 255, py >> 8])
    s.m[0x2F04] = random.randrange(64)
    for i in range(48): s.m[0x3190 + i] = 0xFF
    # objekty nahodne rozmiestni (aj blizko hraca)
    for i in range(9):
        ox, oy = random.choice(free)
        o = 0x3220 + 8 * i
        s.m[o:o + 5] = bytes([random.randrange(256), ox, random.randrange(256), oy, 1 if i >= 4 else 2])
    s.m[0x2F1A] = 100
    t_doom.frame(s, syms)
    for i in range(s.m[0x2FC3]):
        r = s.m[0x3270 + 2 * i] | s.m[0x3271 + 2 * i] << 8
        b = s.m[r:r + 16]; recs += 1
        uacc = b[10] | b[11] << 8
        if not (b[2] <= b[3] <= 47) or (uacc >> 8) > 8:
            bad += 1
            if bad < 6: print('zly zaznam', k, 'idx', b[15], 'CS', b[2], 'CE', b[3], 'UACC', uacc, 'typ', b[14])
print('stavov 400, zaznamov', recs, 'zlych', bad)
