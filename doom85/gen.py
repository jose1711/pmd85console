"""Generuje tables.inc (tabulky pre doom.asm) a model pre referencny renderer."""
import math

MAP = [
    "################",
    "#..............#",
    "#.####..####...#",
    "#.#..........#.#",
    "#.#..2222....#.#",
    "#....2..2......#",
    "#.33.2..23######",
    "#.3......3.....#",
    "#.3.####.3.###.#",
    "#...#..#.......#",
    "###.#..#.##.####",
    "#...4..4.#.....#",
    "#.###..#.#.###.#",
    "#.....##...#...#",
    "#....44........#",
    "################",
]
NANG = 64
STEP = 32                 # dlzka kroku luca (v 1/256 bunky)
PLANE = 0.66
NCOL = 48
MASK = [0x7F, 0x7B, 0x77, 0x6D]
LEVELS = [(0x3F, 0x3F), (0x7F, 0x7F), (0x2A, 0x15), (0x6A, 0x55), (0x61, 0x4C), (0x48, 0x41)]
BANDS = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 5, 5, 5]
FLOOR = (0x48, 0x40)
# podlaha: pasy podle radku pohledu (konec pasu, vzor sudy radek, vzor lichy radek); tma u obzoru, svetlejsi bliz
FBANDS = [(80, 0x00, 0x00), (96, 0x48, 0x41), (112, 0x6A, 0x55), (128, 0x7F, 0x7F)]
ENEMIES = [(13, 1), (14, 5), (10, 9), (14, 13)]


def s16(v):
    return int(round(v)) & 0xFFFF


def tables():
    ang = []
    mov = []
    for a in range(NANG):
        t = a * 2 * math.pi / NANG
        dx, dy = math.cos(t) * STEP * 256, math.sin(t) * STEP * 256
        px, py = -math.sin(t) * PLANE * STEP * 256, math.cos(t) * PLANE * STEP * 256
        r0x, r0y = dx - px + 128, dy - py + 128
        ix, iy = 2 * px / (NCOL - 1), 2 * py / (NCOL - 1)
        ang.append((s16(r0x), s16(r0y), s16(ix), s16(iy)))
        mov.append((int(round(math.cos(t) * 16)) & 255, int(round(math.sin(t) * 16)) & 255))
    wp = []
    for n in range(256):
        h = 124 if n == 0 else min(124, max(4, 4 * round(1024 / n / 4)))
        wp.append(h // 2)
    pat = []
    for ty in range(4):
        for b in range(16):
            p1, p2 = LEVELS[BANDS[b]]
            pat += [p1 & MASK[ty], p2 & MASK[ty]]
    dirt = []
    for a in range(NANG):
        t = a * 2 * math.pi / NANG
        dirt += [int(round(math.cos(t) * 64)) & 255, int(round(math.sin(t) * 64)) & 255]
    hw = [0] * 256
    bh = [0] * 256
    for n in range(256):
        hw[n] = 60 if n < 2 else min(60, max(1, round(87 / n)))
        h = 124 if n == 0 else min(124, max(4, 4 * round(1024 / n / 4)))
        bh[n] = max(1, round(0.75 * h / 8))
    mp = []
    for row in MAP:
        for c in row:
            mp.append(0 if c == '.' else int(c) if c.isdigit() else 1)
    return ang, mov, wp, pat, mp, dirt, hw, bh


def emit():
    ang, mov, wp, pat, mp, dirt, hw, bh = tables()
    out = []
    def db(label, vals, per=16):
        out.append(label + ':')
        for i in range(0, len(vals), per):
            out.append('        DB ' + ','.join(str(v) for v in vals[i:i + per]))
    flat = []
    for a in ang:
        for w in a:
            flat += [w & 255, w >> 8]
    db('ANGTAB', flat, 16)
    db('MOVTAB', [v for m in mov for v in m], 16)
    db('WPTAB', wp)
    db('PATTAB', pat)
    db('FBANDS', [v for b in FBANDS for v in b] + [0])
    db('DIRTAB', dirt)
    db('HWTAB', hw)
    db('BHTAB', bh)
    tex = ["·X····X·", "·XGGGGX·", "·GXGGXG·", "XGGGGGGX", "X·GXXG·X", "X·GGGG·X", "··G··G··", "·XX··XX·"]
    cv = {'·': 0, 'X': 0x3F, 'G': 0x7F}
    db('TEX', [cv[tex[k][u]] for u in range(8) for k in range(8)], 8)
    tex2 = ["XXXXXXXX", "XGGGGGGX", "XGXXXXGX", "XGXGGXGX", "XGXGGXGX", "XGXXXXGX", "XGGGGGGX", "XXXXXXXX"]
    db('TEX2', [cv[tex2[k][u].replace('X', 'X').replace('.', '·')] for u in range(8) for k in range(8)], 8)
    en = []
    for (cx, cy) in ENEMIES:
        en += [(cx * 256 + 128) & 255, (cx * 256 + 128) >> 8, (cy * 256 + 128) & 255, (cy * 256 + 128) >> 8, 2, 0, 0, 0]
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    open('tables.inc', 'w').write(emit())
    print('ok')
