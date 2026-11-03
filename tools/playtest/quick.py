#!/usr/bin/env python3
"""Rychla kontrola hry: spusti ju v Xvfb, posle klavesy, urobi snimky a zlozi ich do jedneho obrazka.

  quick.py DOMCEKY                          # snimka po nacitani
  quick.py DOMCEKY Return wait:3 shot F12 shot "Keypad +" shot
  quick.py ROBOTIK --games-lst /cesta/games.lst --out /tmp/x.png ...

Kroky: <nazov klavesy> (SDL, napr. Return, F12, Left, "Keypad +"), wait:<s>, shot (snimka; prvy je automaticky po nacitani).
Pouziva binarku ~/tmp/playtest/bin/simpmd a games.lst z PMD_SHARE tej binarky (kopiruj tam simpmd/data/games.lst).
Vystup: ~/tmp/playtest/quick/<HRA>.png (cestu vypise).
"""
import argparse, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pmdplay as p
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument('game'); ap.add_argument('steps', nargs='*')
ap.add_argument('--out'); ap.add_argument('--port', type=int, default=8199); ap.add_argument('--display', default=':91')
ap.add_argument('--settle', type=float, default=4, help='pauza po nacitani (s)')
a = ap.parse_args()
out = a.out or os.path.expanduser('~/tmp/playtest/quick/%s.png' % a.game)
os.makedirs(os.path.dirname(out), exist_ok=True)
shots = []
e = p.Emu(a.game, a.port, a.display)
e.start('/tmp/quick-%s.log' % a.game)
try:
    e.wait_loaded(180); time.sleep(a.settle)
    def shot():
        shots.append(p.to_image(e.screen(), 2))
    shot()
    for s in a.steps:
        if s.startswith('wait:'): time.sleep(float(s[5:]))
        elif s == 'shot': shot()
        else:
            e.key(s, 1); time.sleep(.3); e.key(s, 0); time.sleep(.8)
finally:
    e.stop()
w, h = shots[0].size
cols = min(len(shots), 3); rows = (len(shots) + cols - 1) // cols
m = Image.new('RGB', (w * cols, h * rows))
for i, im in enumerate(shots): m.paste(im, ((i % cols) * w, (i // cols) * h))
m.save(out); print(out)
