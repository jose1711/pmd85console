"""Generuje tables.inc (tabulky pre doom.asm) a model pre referencny renderer."""
import math

MAP = [
    "################",
    "#..............#",
    "#.####..####...#",
    "#.#..........#.#",
    "#.#..2222....#.#",
    "#....2..2......#",
    "#.33.2..2.######",
    "#.3......3.....#",
    "#.3.####.3.###.#",
    "#...#..#.......#",
    "###.#..#.##.####",
    "#...4..4.#.....#",
    "#.###..#.#.###.#",
    "#.....##...#...#",
    "#....4.........#",
    "################",
]
NANG = 64
STEP = 32                 # dlzka kroku luca (v 1/256 bunky)
PLANE = 0.66
NCOL = 48
MASK = [0x3F, 0x3B, 0x37, 0x2D]
LEVELS = [(0x3F, 0x3F), (0x3F, 0x2A), (0x2A, 0x15), (0x2A, 0x00), (0x21, 0x0C), (0x08, 0x01)]
BANDS = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 5, 5, 5]
FLOOR = (0x08, 0x00)
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
    db('MAPSRC', mp)
    db('DIRTAB', dirt)
    db('HWTAB', hw)
    db('BHTAB', bh)
    tex = ["..XXXX..", ".XXXXXX.", ".XEXXEX.", "XXXXXXXX", "XXEEEEXX", "XXXXXXXX", ".XX..XX.", ".XX..XX."]
    cv = {'.': 0, 'X': 0x3F, 'E': 0x40}
    db('TEX', [cv[tex[k][u]] for u in range(8) for k in range(8)], 8)
    en = []
    for (cx, cy) in ENEMIES:
        en += [(cx * 256 + 128) & 255, (cx * 256 + 128) >> 8, (cy * 256 + 128) & 255, (cy * 256 + 128) >> 8, 2, 0, 0, 0]
    db('ENEMINIT', en, 8)
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    open('tables.inc', 'w').write(emit())
    print('ok')
