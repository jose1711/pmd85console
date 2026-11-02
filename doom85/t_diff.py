"""Obtiaznost: parametre vybranej urovne (pocet priserok, zdravie, naboje, ...) sa prenesu do hry."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85')); sys.path.insert(0, HERE)
import t_doom
T = [(2,1,1,7,10,7,40,15),(3,2,1,8,12,9,35,12),(4,2,2,9,14,10,30,10),(6,3,3,10,15,12,25,8),(6,4,4,12,16,14,20,6)]
bad = 0
for lvl in range(1, 6):
    s, syms = t_doom.boot()
    s.m[0x4F30] = lvl                      # vybrana uroven (inak 3)
    t_doom.frame(s, syms)
    got = tuple(s.m[0x4F31 + i] for i in range(8))
    hp = [s.m[0x5224 + 8 * i] for i in range(6)]
    alive = sum(1 for h in hp if h)
    ok = got == T[lvl - 1] and alive == T[lvl - 1][0] and all(h in (0, T[lvl - 1][1]) for h in hp) and s.m[0x4F1B] == T[lvl - 1][6]
    bad += not ok
    print('uroven', lvl, 'parametre', got, 'zive priserky', alive, 'hp', hp, 'naboje', s.m[0x4F1B], 'OK' if ok else 'CHYBA')
print('chyby', bad)

# vyber klavesmi na titulke: E = hore, Y = dole, medzernik potvrdi (3 -> E -> 2 -> E -> 1 -> Y -> 2)
import asm8080, sim8080, build
org, code, syms = asm8080.assemble(build.source())
s = sim8080.Sim(); s.m[org:org + len(code)] = code
s.hooks[0x8500] = lambda m: None
it = [0]; g = [0]; first = [None]
def f5(m):
    col = m.ports.get(0xF4, 0) & 15
    g[0] += 1
    if col == 2: it[0] += 1                      # E sa cita raz za iteraciu
    i = it[0]
    if col == 2 and (3 <= i < 6 or 8 <= i < 11): return 0xFB          # E (bit 2)
    if col == 1 and 13 <= i < 16: return 0xEF                         # Y (bit 4)
    if col == 0 and i >= 20:
        if first[0] is None: first[0] = g[0]
        if g[0] - first[0] < 40: return 0xEF                          # medzernik (po case sa pusti)
    return 0xFF
s.inport[0xF5] = f5
s.pc = org; s.stop = {syms['main']}; s.run(30_000_000)
ok = s.m[0x4F30] == 2 and s.m[0x4F31] == 3
print('titulka klavesmi E/Y: uroven', s.m[0x4F30], 'priserok', s.m[0x4F31], 'OK' if ok else 'CHYBA')
print('chyby', bad + (not ok))
