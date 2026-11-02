"""STOP (bit 6 portu F5, aktivne v nule, v kazdom stlpci): v hre aj na obrazovke konca hry sa vrati na titulku."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import asm8080, sim8080, build, t_doom
org, code, syms = asm8080.assemble(build.source())
def mk():
    s, sy = t_doom.boot()
    st = {'stop': False}
    base = s.inport[0xF5]
    def f5(m):
        v = base(m)
        return v & 0xBF if st['stop'] else v
    s.inport[0xF5] = f5
    t_doom.frame(s, sy)
    return s, sy, st
bad = 0
# v hre
s, sy, st = mk()
for _ in range(3): t_doom.frame(s, sy)
st['stop'] = True
s.stop = {sy['title']}; s.run(30_000_000)
ok = s.pc == sy['title']; bad += not ok
print('STOP v hre -> titulka:', 'OK' if ok else 'CHYBA')
# na konci hry (zdravie 0)
s, sy, st = mk()
for _ in range(2): t_doom.frame(s, sy)
s.m[0x4F1A] = 0
s.stop = {sy['gameover']}; s.run(30_000_000)
st['stop'] = True
s.stop = {sy['title']}; s.run(60_000_000)
ok = s.pc == sy['title']; bad += not ok
print('STOP na obrazovke konca hry -> titulka:', 'OK' if ok else 'CHYBA')
print('chyby', bad)
