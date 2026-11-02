import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import asm8080, sim8080, gen, build

def boot():
    org, code, syms = asm8080.assemble(build.source())
    s = sim8080.Sim()
    s.m[org:org+len(code)] = code
    s.hooks[0x8500] = lambda m: None
    cnt = [0]
    def f5(m):
        cnt[0] += 1
        col = m.ports.get(0xF4, 0) & 15
        return 0xEF if (40 <= cnt[0] < 300 and col == 0) else 0xFF
    s.inport[0xF5] = f5
    s.pc = org
    return s, syms

def frame(s, syms, keys=None):
    """spusti jeden prechod main -> main; vrati T-cykly"""
    s.stop = {syms['main']}
    if s.pc != syms['main']:
        s.run(10_000_000)
    s.stop = set()
    t0 = s.tcycles
    s.step()
    s.stop = {syms['main']}
    s.run(50_000_000)
    return s.tcycles - t0

def ref(px, py, ang, mp):
    """referencny render: luce pre parne stlpce a 47, nepárne interpolovane (presne ako v assembleri)"""
    ang_t, mov, wp, pat = gen.tables()[:4]
    r0x, r0y, ix, iy = ang_t[ang]
    R = [((r0x + c * ix) & 0xFFFF, (r0y + c * iy) & 0xFFFF) for c in range(48)]
    def cast(rx, ry):
        sdx = (rx >> 8) & 255; sdy = (ry >> 8) & 255
        sx = sdx if sdx < 128 else sdx - 256
        sy = sdy if sdy < 128 else sdy - 256
        x, y, n = px, py, 0
        while True:
            x = (x + sx) & 0xFFFF; y = (y + sy) & 0xFFFF; n += 1
            cell = mp[((y >> 8) & 255) * 16 + ((x >> 8) & 255)] if (y >> 8) < 16 and (x >> 8) < 16 else 1
            if cell: return n & 255, cell
    cols = [None] * 48
    cols[0] = cast(*R[0])
    for c in range(1, 46, 2):
        right = cast(*R[c + 1]); ln, lc = cols[c - 1]; rn, rc = right
        if lc == rc and abs(ln - rn) < 5: cols[c] = ((ln + rn) >> 1, lc)
        else: cols[c] = cast(*R[c])
        cols[c + 1] = right
    cols[47] = cast(*R[47])
    vram = {}
    for col, (n, cell) in enumerate(cols):
        w = wp[n]
        c = gen.VH // 4 - (w >> 1)
        p1, p2 = pat[((cell - 1) * 16 + ((n >> 4) & 15)) * 2: ((cell - 1) * 16 + ((n >> 4) & 15)) * 2 + 2]
        rows = [0, 0] * c + [p1, p2] * w
        for r in range(len(rows), gen.VH):
            for end, q1, q2 in gen.FBANDS:
                if r < end:
                    rows.append(q1 if r % 2 == 0 else q2); break
        for r, b in enumerate(rows): vram[(r, col)] = b
    return vram

if __name__ == '__main__':
    s, syms = boot()
    ang = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    frame(s, syms)
    s.m[0x4F04] = ang
    for i in range(11): s.m[0x5224 + 8 * i] = 0
    tc = frame(s, syms)
    print('T-cykly na snimku:', tc, '=> %.0f ms pri 2 MHz' % (tc / 2000))
    px = s.m[0x4F00] | s.m[0x4F01] << 8; py = s.m[0x4F02] | s.m[0x4F03] << 8
    mp = [s.m[0x5000 + y * 256 + x] for y in range(16) for x in range(16)]
    rv = ref(px, py, s.m[0x4F04], mp)
    bad = 0
    for (r, c), b in rv.items():
        if (20 <= c <= 27 and r >= gen.VH - 60): continue
        if s.m[gen.VIDEO + r * 64 + c] != b: bad += 1
    print('rozdiely proti referencii:', bad, 'z', len(rv))
    for r in range(0, gen.VH, 4):
        print(''.join(' .:*#'[min(4, bin(s.m[gen.VIDEO + r * 64 + c] & 63).count('1') * 4 // 7)] for c in range(48)))
