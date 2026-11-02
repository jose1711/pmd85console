"""Mapka v HUD: bitmapa bludiska (3x3 body na bunku) bez priser + znacka hraca (3x3) a bod v smere pohladu; tvar a text vedla."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
s, syms = t_doom.boot()
t_doom.frame(s, syms)
for i in range(14): s.m[0x5224 + 8 * i] = 0
MAPDST = 0xC000 + 196 * 64 + 40
def expected(px, py, ang):
    mp = [[s.m[0x5000 + y * 256 + x] for x in range(16)] for y in range(16)]
    pix = [[1 if mp[y // 3][x // 3] else 0 for x in range(48)] for y in range(48)]
    cx, cy = px >> 8, py >> 8
    for dy in range(3):
        for dx in range(3): pix[cy * 3 + dy][cx * 3 + dx] = 1
    q = ((ang + 8) >> 4) & 3
    nx, ny = (cx * 3 + 1 + (2, 0, -2, 0)[q], cy * 3 + 1 + (0, 2, 0, -2)[q])
    pix[ny][nx] = 1
    return pix
def shown():
    return [[(s.m[MAPDST + y * 64 + x // 6] >> (x % 6)) & 1 for x in range(48)] for y in range(48)]
bad = 0
mp0 = [[s.m[0x5000 + y * 256 + x] for x in range(16)] for y in range(16)]
free = [(x, y) for y in range(1, 15) for x in range(1, 15) if mp0[y][x] == 0]
import random
random.seed(5)
for k in range(8):
    x, y = random.choice(free); ang = random.randrange(64)
    s.m[0x4F00:0x4F04] = bytes([random.randrange(256), x, random.randrange(256), y]); s.m[0x4F04] = ang
    t_doom.frame(s, syms)
    px = s.m[0x4F00] | s.m[0x4F01] << 8; py = s.m[0x4F02] | s.m[0x4F03] << 8
    ok = shown() == expected(px, py, s.m[0x4F04]); bad += not ok
    print('poloha', (x, y), 'smer', ang, 'OK' if ok else 'CHYBA')
print('chyby', bad)
