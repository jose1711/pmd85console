"""Generuje tables.inc (tabulky pre doom.asm) a model pre referencny renderer."""
import math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

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
import os
VH = int(os.environ.get('DOOM_VH', '128'))      # vyska pohladu v riadkoch (nasobok 8)
CEN = VH // 2
VIDEO = 0xD000 + ((128 - VH) // 2) * 64
NANG = 64
STEP = 32                 # dlzka kroku luca (v 1/256 bunky)
PLANE = 0.66
NCOL = 48
MASK = [0x7F, 0x7B, 0x77, 0x6D]
LEVELS = [(0x3F, 0x3F), (0x7F, 0x7F), (0x2A, 0x15), (0x6A, 0x55), (0x61, 0x4C), (0x48, 0x41)]
BANDS = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 5, 5, 5]
FLOOR = (0x48, 0x40)
# podlaha: pasy podle radku pohledu (konec pasu, vzor sudy radek, vzor lichy radek); tma u obzoru, svetlejsi bliz
FBANDS = [(CEN + CEN // 4 * k, p, q) for k, (p, q) in enumerate([(0x00, 0x00), (0x48, 0x41), (0x6A, 0x55), (0x7F, 0x7F)], 1)]
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
        h = VH - 4 if n == 0 else min(VH - 4, max(4, 4 * round(VH * 8 / n / 4)))
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
        h = VH - 4 if n == 0 else min(VH - 4, max(4, 4 * round(VH * 8 / n / 4)))
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
    notes = ['A3','C4','E4','C4','A3','C4','E4','A4','G3','B3','D4','B3','G3','B3','D4','G4',
             'F3','A3','C4','A3','F3','A3','C4','F4','E3','G#3','B3','G#3','E3','G#3','B3','E4']
    names = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11}
    mus = []
    for nt in notes:
        n, o = nt[:-1], int(nt[-1])
        f = 440.0 * 2 ** ((names[n] + 12 * (o + 1) - 69) / 12.0)
        h = 1000000.0 / f
        b = max(1, min(255, round((h - 40) / 30)))
        c = max(2, round(0.012 * f))
        mus += [b, c]
    db('MUSTAB', mus, 8)
    ust = []
    for w in range(0, 123):
        v = 2048 // w if w else 0
        ust += [v & 255, v >> 8]
    db('USTEPTAB', ust, 16)
    tex3 = ["..GGGG..", ".GXXXXG.", "GXXXXXXG", "GXXXXXXG", "GXXXXXXG", "GXXXXXXG", ".GXXXXG.", "..GGGG.."]
    tex4 = ["..XXXX..", ".XGGGGX.", ".GXGGXG.", ".XGGGGX.", "XGGXXGGX", "X.GXXG.X", "..GGGG..", "..XXXX.."]
    cv2 = {'.': 0, 'X': 0x3F, 'G': 0x7F}
    db('TEX3', [cv2[tex3[k][u]] for u in range(8) for k in range(8)], 8)
    db('TEX4', [cv2[tex4[k][u]] for u in range(8) for k in range(8)], 8)
    knife = ["...DD...", "..DXXD..", "..DXXD..", "..DXXD..", "..DXXD..", "..DGGD..", ".DDXXDD.", "..DGGD..", "..DGGD..", "..DDDD.."]
    kv = {'.': 0, 'X': 0x3F, 'G': 0x7F, 'D': 0x40}
    db('KNT', [kv[knife[k][c]] for c in range(8) for k in range(10)], 10)
    gun = ["..DGGD..", "..DXXD..", "..DXXD..", ".DGXXGD.", ".DGXXGD.", "DGXXXXGD", "DGXGGXGD", "DXXXXXXD", ".DGXXGD.", "..DDDD.."]
    flash = ["X.GG.X", ".XXXX.", "XGXXGX"]
    gv = {'.': 0, 'X': 0x3F, 'G': 0x7F, 'D': 0x40}
    db('GUNT', [gv[gun[k][c]] for c in range(8) for k in range(10)], 10)
    db('FLT', [gv[flash[k][c]] for c in range(6) for k in range(3)], 3)
    import faces
    here = os.path.dirname(os.path.abspath(__file__))
    for name in (('faces.bin',) if os.environ.get('DOOM_FACES') == 'default' else ('faces_local.bin', 'faces.bin')):
        if os.path.exists(os.path.join(here, name)):
            fb = open(os.path.join(here, name), 'rb').read(); break
    else:
        fb = b''.join(faces.build([]))
    assert len(fb) == 26 * 384, len(fb)
    db('FACES', list(fb), 16)
    out.append('FACETAB:')
    out.append('        DW ' + ','.join('FACES+%d' % (384 * k) for k in range(26)))
    en = []
    for (cx, cy) in ENEMIES:
        en += [(cx * 256 + 128) & 255, (cx * 256 + 128) >> 8, (cy * 256 + 128) & 255, (cy * 256 + 128) >> 8, 2, 0, 0, 0]
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tables.inc'), 'w').write(emit())
    print('ok')
