import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import asm8080, sim8080, gen, build

def boot():
    org, code, syms = asm8080.assemble(build.source())
    s = sim8080.Sim()
    s.m[org:org+len(code)] = code
    s.hooks[0x8500] = lambda m: None
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

def ref(px, py, ang):
    ang_t, mov, wp, pat, mp = gen.tables()[:5]
    r0x, r0y, ix, iy = ang_t[ang]
    sg = lambda v: v - 65536 if v & 0x8000 else v
    rx, ry = r0x, r0y
    vram = {}
    for col in range(48):
        sdx = (rx >> 8) & 255; sdy = (ry >> 8) & 255
        rx = (rx + ix) & 0xFFFF; ry = (ry + iy) & 0xFFFF
        sx = sdx if sdx < 128 else sdx - 256
        sy = sdy if sdy < 128 else sdy - 256
        x, y, n = px, py, 0
        while True:
            x = (x + sx) & 0xFFFF; y = (y + sy) & 0xFFFF; n += 1
            cell = mp[((y >> 8) & 255) * 16 + ((x >> 8) & 255)] if (y >> 8) < 16 and (x >> 8) < 16 else 1
            if cell: break
        w = wp[n & 255]
        c = 32 - (w >> 1)
        p1, p2 = pat[((cell - 1) * 16 + ((n >> 4) & 15)) * 2: ((cell - 1) * 16 + ((n >> 4) & 15)) * 2 + 2]
        rows = [0, 0] * c + [p1, p2] * w + [gen.FLOOR[0], gen.FLOOR[1]] * c
        for r, b in enumerate(rows): vram[(r, col)] = b
    return vram

if __name__ == '__main__':
    s, syms = boot()
    ang = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    frame(s, syms)
    s.m[0x2F04] = ang
    for i in range(4): s.m[0x2F94 + 8 * i] = 0
    tc = frame(s, syms)
    print('T-cykly na snimku:', tc, '=> %.0f ms pri 2 MHz' % (tc / 2000))
    px = s.m[0x2F00] | s.m[0x2F01] << 8; py = s.m[0x2F02] | s.m[0x2F03] << 8
    rv = ref(px, py, s.m[0x2F04])
    bad = 0
    for (r, c), b in rv.items():
        if (22 <= c <= 25 and r >= 90): continue
        if s.m[0xD000 + r * 64 + c] != b: bad += 1
    print('rozdiely proti referencii:', bad, 'z', len(rv))
    for r in range(0, 128, 4):
        print(''.join(' .:*#'[min(4, bin(s.m[0xD000 + r * 64 + c] & 63).count('1') * 4 // 7)] for c in range(48)))
