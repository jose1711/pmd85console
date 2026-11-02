import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import asm8080, sim8080, build
org, code, syms = asm8080.assemble(build.source())
bad = 0; times = []; seeds = set()
for k in range(6, 150, 3):
    s = sim8080.Sim(); s.m[org:org+len(code)] = code
    s.hooks[0x8500] = lambda m: None
    cnt = [0]
    def f5(m, k=k, cnt=cnt):
        cnt[0] += 1
        col = m.ports.get(0xF4, 0) & 15
        return 0xEF if (2*k <= cnt[0] < 2*k + 6 and col == 0) else 0xFF
    s.inport[0xF5] = f5
    s.pc = org; s.stop = {syms['main']}; s.run(5_000_000)
    times.append(s.tcycles)
    mp = [[s.m[0x5000 + y * 256 + x] for x in range(16)] for y in range(16)]
    seeds.add(tuple(map(tuple, mp)))
    w = lambda x, y: mp[y][x] != 0
    ok = True
    for i in range(16):
        if not (w(i, 0) and w(i, 15) and w(0, i) and w(15, i)): ok = False
    for y in range(15):
        for x in range(15):
            a_, b_, c_, d_ = w(x, y), w(x+1, y), w(x, y+1), w(x+1, y+1)
            if (a_ and d_ and not b_ and not c_) or (b_ and c_ and not a_ and not d_): ok = False
    free = {(x, y) for y in range(16) for x in range(16) if not w(x, y)}
    st = [(1, 1)]; seen = set(st)
    while st:
        x, y = st.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p = (x+dx, y+dy)
            if p in free and p not in seen: seen.add(p); st.append(p)
    if seen != free: ok = False
    for i in range(4):
        ex = s.m[0x5221 + 8*i]; ey = s.m[0x5223 + 8*i]
        if (ex, ey) not in free or ((ex-1) + (ey-1)) < 8: ok = False
    if not ok: bad += 1
print('behov', len(times), 'zle', bad, 'rozne mapy', len(seeds), 'T-cykly gen+init max', max(times), '= %.0f ms' % (max(times)/2000))
for r in mp: print(''.join('.' if c == 0 else str(c) for c in r))
