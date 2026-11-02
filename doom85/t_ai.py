"""AI priserok: mapa vzdialenosti = BFS v Pythone, priserky zostavaju v otvorenych bunkach a chodia po susednych bunkach, v patrole sa pohybuju, v dosahu dobehnu hraca."""
import sys, os, collections
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
s, syms = t_doom.boot()
t_doom.frame(s, syms)
mp = [[s.m[0x5000 + y * 256 + x] for x in range(16)] for y in range(16)]
E = 0x5220
def pcell(): return (s.m[0x4F03], s.m[0x4F01])      # (y, x)
def bfs(sy, sx):
    d = {(sy, sx): 0}; q = collections.deque([(sy, sx)])
    while q:
        y, x = q.popleft()
        for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
            n = (y + dy, x + dx)
            if mp[n[0]][n[1]] == 0 and n not in d: d[n] = d[(y, x)] + 1; q.append(n)
    return d
bad = 0
moved = set(); prev = {}
for f in range(260):
    t_doom.frame(s, syms)
    py, px = pcell()
    d = bfs(py, px)
    if f % 13 == 0:
        for (y, x), v in d.items():
            if s.m[0x5000 + y * 256 + 0xF0 + x] != (v if v <= 23 else 255): bad += 1
    for i in range(6):
        o = E + 8 * i
        if s.m[o + 4] == 0: continue
        ex = s.m[o] | s.m[o + 1] << 8; ey = s.m[o + 2] | s.m[o + 3] << 8
        cy, cx = ey >> 8, ex >> 8
        if mp[cy][cx] != 0: bad += 1; print('prisera v stene', f, i, cx, cy)
        if i in prev and prev[i] != (cy, cx):
            moved.add(i)
            if abs(prev[i][0] - cy) + abs(prev[i][1] - cx) != 1: bad += 1; print('skok o viac buniek', f, i, prev[i], (cy, cx))
        prev[i] = (cy, cx)
    if s.m[0x4F1A] == 0: break
print('snimok', f + 1, 'chyby', bad, '| pohybovali sa priserky', sorted(moved), '| zdravie', s.m[0x4F1A])
