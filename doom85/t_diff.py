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
