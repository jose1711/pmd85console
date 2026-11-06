#!/usr/bin/env python3
"""Joystick test of a game: starts it (pre-steps = keys), then drives the joystick through PMD_JOYFILE only (no keys):
idle, down, up, right, left, fire, each held for HOLD s, and writes a montage <out>/<GAME>.png of the screen at the end of each.

  joytest.py JETPAC Space 4 5 [--out DIR]      pre-steps: key names, wait:<s>
Bits (low = pressed): 0 down, 1 up, 2 right, 3 left, 4 fire.
"""
import argparse, os, sys, tempfile, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pmdplay as p
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument('game'); ap.add_argument('steps', nargs='*')
ap.add_argument('--out', default=os.path.expanduser('~/tmp/playtest/joy'))
ap.add_argument('--hold', type=float, default=0.8)
ap.add_argument('--port', type=int, default=8330); ap.add_argument('--display', default=':230')
ap.add_argument('--settle', type=float, default=3)
ap.add_argument('--allbits', action='store_true', help='test the bits 0-7 one by one instead of down/up/right/left/fire')
ap.add_argument('--taphold', type=float, default=0.3)
a = ap.parse_args()
os.makedirs(a.out, exist_ok=True)
jf = tempfile.NamedTemporaryFile(delete=False); jf.write(b'\xff'); jf.close()
def joy(v):
    open(jf.name, 'wb').write(bytes([v]))
os.environ['PMD_JOYFILE'] = jf.name
e = p.Emu(a.game, a.port, a.display)
e.start('/tmp/joytest-%s.log' % a.game)
tiles, diffs = [], []
try:
    e.wait_loaded(240)
    time.sleep(a.settle)
    for s in a.steps:
        if s.startswith('wait:'):
            time.sleep(float(s[5:]))
        else:
            e.key(s, 1); time.sleep(a.taphold); e.key(s, 0); time.sleep(1.0)
    time.sleep(1.5)
    prev = e.screen()
    seq = [('idle', None)] + [('bit%d' % b, b) for b in range(8)] if a.allbits else (('idle', None), ('down', 0), ('up', 1), ('right', 2), ('left', 3), ('fire', 4))
    for name, bit in seq:
        joy(0xFF if bit is None else 0xFF & ~(1 << bit))
        time.sleep(a.hold)
        scr = e.screen()
        diffs.append((name, p.changed(prev, scr)))
        tiles.append(p.to_image(scr, 1))
        joy(0xFF); time.sleep(0.4)
        prev = e.screen()
finally:
    e.stop(); os.unlink(jf.name)
w, h = tiles[0].size
cols = 3
rows = (len(tiles) + cols - 1) // cols
m = Image.new('RGB', (w * cols, h * rows))
for i, t in enumerate(tiles):
    m.paste(t, ((i % cols) * w, (i // cols) * h))
out = os.path.join(a.out, a.game + '.png'); m.save(out)
print(a.game, ' '.join('%s=%d' % d for d in diffs), out)
