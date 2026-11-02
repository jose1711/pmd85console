#!/usr/bin/env python3 -I
"""Tvare pre HUD (ako v Doome): vyrobi bitmapy 48x48 bodov pre stavy zdravia, zranenie, uspech a smrt.

  python3 -I faces.py                 vlastna kreslena tvar (predvolene)
  python3 -I faces.py foto.jpg        z fotky (hocijakej, oci a usta sa predpokladaju v strede), stavy sa odvodia upravou obrazu
  python3 -I faces.py a.png b.png ... vlastny obrazok pre kazdy stav v poradi STATES (chybajuce sa odvodia z prveho)

Vystup: faces.bin (kreslena tvar) alebo faces_local.bin (z obrazkov) = 26 stavov x 384 B (bajt = 6 bodov, bit 0 vlavo, bit 6 = jas) a nahlad .png.
  python3 -I faces.py --sheet sheet.png   plansa tvari (5 riadkov zdravia x vyrazy), 26 stavov: 15 pokojnych (3 na uroven), 5 bolest, 5 usmev, 1 mrtva
Vstupny obrazok sa preskaluje na 48x48, upravi kontrast a rozptyli (Floyd-Steinberg)."""
import sys, random
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

W = H = 48
STATES = ['zdrava', 'mierne', 'zranena', 'zle', 'umiera', 'bolest', 'spokojna', 'mrtva']

def draw_face(state, S=192):
    """kreslena tvar S x S (siva), state = index v STATES"""
    im = Image.new('L', (S, S), 0)
    d = ImageDraw.Draw(im)
    skin = (235, 205, 175, 150, 120)[min(state, 4)] if state < 5 else (215, 235, 235)[state - 5]
    # hlava a vlasy
    d.ellipse([S*0.10, S*0.04, S*0.90, S*0.98], fill=skin, outline=255, width=6)
    d.pieslice([S*0.08, S*0.00, S*0.92, S*0.56], 180, 360, fill=30, outline=255, width=3)
    d.rectangle([S*0.10, S*0.26, S*0.20, S*0.52], fill=30)
    d.rectangle([S*0.80, S*0.26, S*0.90, S*0.52], fill=30)
    hurt = (0, 0, 1, 2, 3, 2, 0, 3)[state]
    dead = state == 7
    # oci
    ey = S * 0.46
    for cx in (S*0.36, S*0.64):
        if dead:
            d.line([cx-12, ey-12, cx+12, ey+12], fill=0, width=5); d.line([cx-12, ey+12, cx+12, ey-12], fill=0, width=5)
        elif hurt >= 3 and cx > S/2:
            d.line([cx-14, ey, cx+14, ey+3], fill=0, width=5)            # zatvorene oko
        else:
            r = 11 if state != 5 else 8
            d.ellipse([cx-r*1.3, ey-r, cx+r*1.3, ey+r], fill=250, outline=0, width=3)
            d.ellipse([cx-r*0.55, ey-r*0.55, cx+r*0.55, ey+r*0.55], fill=0)
    # oboci
    by = S * 0.36
    tilt = 10 if hurt else 0
    d.line([S*0.26, by - tilt, S*0.44, by + (4 if state != 6 else -4)], fill=0, width=7)
    d.line([S*0.56, by + (4 if state != 6 else -4), S*0.74, by - (tilt if hurt < 2 else -tilt)], fill=0, width=7)
    # nos
    d.line([S*0.50, S*0.50, S*0.46, S*0.64], fill=0, width=4); d.line([S*0.46, S*0.64, S*0.54, S*0.64], fill=0, width=4)
    # usta
    my = S * 0.77
    if state == 6:       # usmev (zuby)
        d.chord([S*0.32, my-22, S*0.68, my+22], 0, 180, fill=250, outline=0, width=4)
    elif state == 5:     # bolest: otvorene usta
        d.ellipse([S*0.40, my-18, S*0.60, my+16], fill=0, outline=0, width=3)
        d.rectangle([S*0.43, my-16, S*0.57, my-8], fill=250)
    elif dead:
        d.line([S*0.38, my, S*0.62, my+4], fill=0, width=5)
    elif hurt >= 2:
        d.arc([S*0.38, my-6, S*0.62, my+20], 200, 340, fill=0, width=5)
    else:
        d.line([S*0.38, my, S*0.62, my], fill=0, width=5)
    # zranenia (skrabance, krv)
    rnd = random.Random(7 + state)
    if hurt >= 1 or state == 5:
        d.line([S*0.58, S*0.22, S*0.72, S*0.40], fill=0, width=3)
    for _ in range((0, 0, 5, 11, 18, 4, 0, 14)[state]):
        x = rnd.uniform(S*0.24, S*0.76); y = rnd.uniform(S*0.2, S*0.88)
        r = rnd.uniform(3, 8 + 2 * hurt)
        d.ellipse([x-r, y-r*1.3, x+r, y+r*1.3], fill=15)
    if hurt >= 3:
        d.rectangle([S*0.26, S*0.62, S*0.30, S*0.92], fill=15)
    return im

def derive(base, state):
    """odvodi stav z fotky (L, 48x48+): stmavi, pridá poskodenie vzorom bodov"""
    S = base.size[0]
    im = base.copy()
    hurt = (0, 0, 1, 2, 3, 2, 0, 3)[state]
    im = ImageEnhance.Brightness(im).enhance((1, 1, 0.92, 0.82, 0.7, 0.95, 1.1, 0.5)[state])
    d = ImageDraw.Draw(im)
    rnd = random.Random(11 + state)
    for _ in range((0, 0, 4, 9, 15, 3, 0, 12)[state]):
        x = rnd.uniform(S*0.2, S*0.8); y = rnd.uniform(S*0.2, S*0.9); r = rnd.uniform(S*0.02, S*0.05 + S*0.01*hurt)
        d.ellipse([x-r, y-r*1.3, x+r, y+r*1.3], fill=10)
    if state in (3, 4, 7):
        d.line([S*0.58, S*0.40, S*0.72, S*0.40], fill=0, width=max(2, S//30))     # zatvorene oko
    if state == 5:
        d.ellipse([S*0.42, S*0.70, S*0.58, S*0.84], fill=10)                      # otvorene usta
    if state == 6:
        d.chord([S*0.34, S*0.62, S*0.66, S*0.86], 0, 180, fill=250, outline=0, width=max(2, S//60))   # usmev so zubami
    if state == 7:
        for cx in (S*0.36, S*0.64):
            d.line([cx-S*0.07, S*0.40-S*0.07, cx+S*0.07, S*0.40+S*0.07], fill=0, width=max(2, S//30))
            d.line([cx-S*0.07, S*0.40+S*0.07, cx+S*0.07, S*0.40-S*0.07], fill=0, width=max(2, S//30))
    return im

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
GRAY = 146          # jas bodov pri nastavenom bite 6 (ako ho kresli emulator)

def to_cells(im):
    """L obrazok -> 48x48: ((bity), (stlpec bunky 0-7 -> dim 0/1)); kazda bunka (bajt = 6 bodov v riadku) je biela alebo stlmena
    (sedá), v oboch pripadoch rozptylena usporiadanym ditherom 4x4; tmave bunky dostanu sedu a viac bodov, svetle bielu"""
    im = im.resize((W, H), Image.LANCZOS)
    im = ImageEnhance.Contrast(im).enhance(1.15)
    px = im.load()
    bits = [[0] * W for _ in range(H)]
    dim = [[0] * (W // 6) for _ in range(H)]
    for y in range(H):
        for c in range(W // 6):
            vals = [px[c * 6 + k, y] for k in range(6)]
            mean = sum(vals) / 6.0
            d = 1 if 40 < mean < 175 else 0            # stredne tony -> seda bunka
            dim[y][c] = d
            for k in range(6):
                x = c * 6 + k
                v = vals[k] * (255.0 / GRAY) if d else vals[k]
                th = (BAYER[y % 4][x % 4] + 0.5) / 16 * 255
                bits[y][x] = 1 if v > th else 0
    return bits, dim

def pack(cells):
    bits, dim = cells
    data = bytearray()
    for y in range(H):
        for bx in range(W // 6):
            v = 0
            for k in range(6):
                if bits[y][bx * 6 + k]: v |= 1 << k
            if dim[y][bx] and v: v |= 64
            data.append(v)
    return bytes(data)

def load(spec):
    """'subor' alebo 'subor.gif:N' -> L obrazok 192x192 (orez na obsah, nebiele pozadie, so stvorcovym okrajom)"""
    path, _, n = spec.partition(':')
    im = Image.open(path)
    if n: im.seek(int(n))
    rgb = im.convert('RGB')
    gray = rgb.convert('L')
    bg = Image.new('RGB', rgb.size, rgb.getpixel((0, 0)))
    from PIL import ImageChops
    box = ImageChops.difference(rgb, bg).convert('L').point(lambda v: 255 if v > 24 else 0).getbbox() or (0, 0) + rgb.size
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    side = int(max(w, h) * 1.06)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    mask = ImageChops.difference(rgb, bg).convert('L').point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.MaxFilter(3))
    g2 = Image.composite(gray, Image.new('L', rgb.size, 0), mask)          # pozadie na cierno
    out = Image.new('L', (side, side), 0)
    out.paste(g2.crop((x0, y0, x1, y1)), ((side - w) // 2, (side - h) // 2))
    out = out.resize((192, 192), Image.LANCZOS)
    return enhance(out)

def enhance(im, lo=0, hi=255, gamma=1.3):
    """tony: koza ostava stredna (seda bunka), ciary a oci sa zvyraznia a zhustia do tmy, hrany sa zaostria"""
    px = im.point(lambda v: 0 if v < 4 else max(0, min(255, int((max(0, v - lo) / float(hi - lo)) ** gamma * 255))))
    return px.filter(ImageFilter.UnsharpMask(radius=1.5, percent=200, threshold=2))

def to26(f8):
    """8 stavov (zdravie 0-4, bolest, usmev, mrtva) -> 26: 3 vyrazy v pokoji na uroven zdravia, bolest a usmev na uroven, mrtva"""
    out = []
    for h in range(5):
        out += [f8[h]] * 3
    out += [f8[5]] * 5 + [f8[6]] * 5 + [f8[7]]
    return out

def sheet_cells(path):
    """sheet.png (5 riadkov = zdravie 100..20 %, stlpce: 3 pohlady dopredu, otoceny doprava, doľava, bolest, usmev, zlost; v poslednom riadku stlpec 8 = mrtvy)"""
    from PIL import ImageChops
    im = Image.open(path).convert('RGB')
    bg = Image.new('RGB', im.size, im.getpixel((0, 0)))
    m = ImageChops.difference(im, bg).convert('L').point(lambda v: 255 if v > 40 else 0)
    w, h = im.size; px = m.load()
    def runs(vec, gap=3):
        out = []; st = None; last = None
        for i, v in enumerate(vec):
            if v:
                if st is None: st = i
                last = i
            elif st is not None and i - last > gap:
                out.append((st, last)); st = None
        if st is not None: out.append((st, last))
        return out
    rows = runs([sum(1 for x in range(w) if px[x, y]) for y in range(h)])
    cells = []
    for r in rows:
        cols = runs([sum(1 for y in range(r[0], r[1] + 1) if px[x, y]) for x in range(w)])
        cells.append([(c[0], r[0], c[1] + 1, r[1] + 1) for c in cols])
    gray = im.convert('L')
    def cell(box):
        x0, y0, x1, y1 = box; cw, ch = x1 - x0, y1 - y0
        side = int(max(cw, ch) * 1.06)
        msk = m.crop(box).filter(ImageFilter.MaxFilter(3))
        g = Image.composite(gray.crop(box), Image.new('L', (cw, ch), 0), msk)
        out = Image.new('L', (side, side), 0)
        out.paste(g, ((side - cw) // 2, (side - ch) // 2))
        return enhance(out.resize((192, 192), Image.LANCZOS))
    imgs = [cell(cells[h][v]) for h in range(5) for v in range(3)]
    imgs += [cell(cells[h][5]) for h in range(5)]
    imgs += [cell(cells[h][6]) for h in range(5)]
    imgs += [cell(cells[4][8])]
    return imgs

def build(args):
    if args and args[0] == '--sheet':
        return [pack(to_cells(i)) for i in sheet_cells(args[1])]
    if not args:
        imgs = [draw_face(s) for s in range(8)]
    else:
        loaded = [None if a == '-' else load(a) for a in args]
        base = loaded[0]
        imgs = [(loaded[s] if s < len(loaded) and loaded[s] is not None else derive(base, s)) for s in range(8)]
    return to26([pack(to_cells(i)) for i in imgs])

def preview(frames, path, sc=3):
    per = 13
    rows = (len(frames) + per - 1) // per
    sheet = Image.new('L', (per * (W * sc + 8), rows * (H * sc + 8)), 70)
    for i, f in enumerate(frames):
        ox = 4 + (i % per) * (W * sc + 8); oy = 4 + (i // per) * (H * sc + 8)
        for y in range(H):
            for bx in range(8):
                v = f[y * 8 + bx]
                col = GRAY if v & 64 else 255
                for k in range(6):
                    if (v >> k) & 1:
                        for dx in range(sc):
                            for dy in range(sc): sheet.putpixel((ox + (bx * 6 + k) * sc + dx, oy + y * sc + dy), col)
    sheet.save(path)

if __name__ == '__main__':
    args = sys.argv[1:]
    out = 'faces_local.bin' if args else 'faces.bin'          # vlastne obrazky sa nikdy nezapisu do faces.bin (verejny repozitar)
    frames = build(args)
    open(out, 'wb').write(b''.join(frames))
    preview(frames, out.replace('.bin', '.png'))
    print(out, sum(len(f) for f in frames), 'B (%d stavov), nahlad %s' % (len(frames), out.replace('.bin', '.png')))
