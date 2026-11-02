"""Profil snimky pri pohybe: kolko ms zerie ktora cast (zoskupene)."""
import sys, os, collections, bisect
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
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
held.add((13, 1))
for _ in range(10): t_doom.frame(s, syms)
names = sorted((v, k) for k, v in syms.items() if not k.isupper())
addrs = [v for v, k in names]
nm = lambda p: names[bisect.bisect_right(addrs, p) - 1][1]
funcs = ['keys','mkey','pickups','ai','ai1','setup','sprprep','proj','pk_adj','udiv','smul','sar4','render','cast','emit','drawcol','floor_rows','rowaddr','fill2','sprcol','slice','guncol','sprhit','gunstep','hud','music','note','snd','noise','rnd','puts','pnum','cellfree','absHL','neg_hl','cmp16']
fa = sorted((syms[f], f) for f in funcs if f in syms)
fad = [a for a, f in fa]
def grp(pc):
    return fa[bisect.bisect_right(fad, pc) - 1][1] if pc >= fad[0] else '?'
cnt = collections.Counter(); tot = 0
s.stop = {syms['main']}; s.step()
while True:
    pc = s.pc; t0 = s.tcycles; s.step()
    d = s.tcycles - t0; tot += d; cnt[grp(pc)] += d
    if s.pc == syms['main']: break
print('snimka %.1f ms' % (tot / 2000))
for k, v in cnt.most_common(14): print('%-12s %6.1f ms %4.1f%%' % (k, v / 2000, 100 * v / tot))
