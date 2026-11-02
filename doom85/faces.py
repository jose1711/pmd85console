#!/usr/bin/env python3 -I
"""Tvare pre HUD (ako v Doome): vyrobi bitmapy 48x48 bodov pre stavy zdravia, zranenie, uspech a smrt.

  python3 -I faces.py                 vlastna kreslena tvar (predvolene)
  python3 -I faces.py foto.jpg        z fotky (hocijakej, oci a usta sa predpokladaju v strede), stavy sa odvodia upravou obrazu
  python3 -I faces.py a.png b.png ... vlastny obrazok pre kazdy stav v poradi STATES (chybajuce sa odvodia z prveho)

Vystup: faces.bin (8 stavov x 8 B x 48 riadkov = 3072 B, bajt = 6 bodov, bit 0 vlavo, bit 6 = jas), faces.png (nahlad).
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
    if state == 7:
        for cx in (S*0.36, S*0.64):
            d.line([cx-S*0.07, S*0.40-S*0.07, cx+S*0.07, S*0.40+S*0.07], fill=0, width=max(2, S//30))
            d.line([cx-S*0.07, S*0.40+S*0.07, cx+S*0.07, S*0.40-S*0.07], fill=0, width=max(2, S//30))
    return im

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

def to_bits(im):
    """L obrazok -> 48x48 (0/1): usporiadane rozptylenie 4x4 (cisty retro vzor, bez sumu mimo tvare)"""
    im = im.resize((W, H), Image.LANCZOS)
    im = ImageEnhance.Contrast(im).enhance(1.25)
    px = im.load()
    out = [[0] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            v = px[x, y]
            th = (BAYER[y % 4][x % 4] + 0.5) / 16 * 255
            out[y][x] = 1 if v > th else 0
    return out

def pack(bits):
    data = bytearray()
    for y in range(H):
        for bx in range(W // 6):
            v = 0
            for k in range(6):
                if bits[y][bx * 6 + k]: v |= 1 << k
            data.append(v)
    return bytes(data)

def build(args):
    imgs = []
    if not args:
        imgs = [draw_face(s) for s in range(8)]
    else:
        loaded = [Image.open(p).convert('L') for p in args]
        def crop_square(im):
            w, h = im.size; s = min(w, h)
            return im.crop(((w - s) // 2, (h - s) // 2, (w + s) // 2, (h + s) // 2)).resize((192, 192), Image.LANCZOS)
        loaded = [crop_square(i) for i in loaded]
        for s in range(8):
            imgs.append(loaded[s] if s < len(loaded) else derive(loaded[0], s))
    return [pack(to_bits(i)) for i in imgs]

def preview(frames, path):
    sheet = Image.new('L', (8 * (W * 6 + 12), H * 6 + 12), 60)
    for i, f in enumerate(frames):
        for y in range(H):
            for bx in range(8):
                for k in range(6):
                    if (f[y * 8 + bx] >> k) & 1:
                        for dx in range(6):
                            for dy in range(6):
                                sheet.putpixel((i * (W * 6 + 12) + 6 + (bx * 6 + k) * 6 // 6 + dx * 0, 6 + y * 6 + dy), 255) if False else None
    # jednoduchsie: kazdy bod ako stvorcek 4x4
    sc = 4
    sheet = Image.new('L', (8 * (W * sc + 8), H * sc + 8), 70)
    for i, f in enumerate(frames):
        for y in range(H):
            for bx in range(8):
                for k in range(6):
                    if (f[y * 8 + bx] >> k) & 1:
                        x0 = 4 + i * (W * sc + 8) + (bx * 6 + k) * sc
                        for dx in range(sc):
                            for dy in range(sc): sheet.putpixel((x0 + dx, 4 + y * sc + dy), 255)
    sheet.save(path)

if __name__ == '__main__':
    frames = build(sys.argv[1:])
    open('faces.bin', 'wb').write(b''.join(frames))
    preview(frames, 'faces.png')
    print('faces.bin', sum(len(f) for f in frames), 'B, nahlad faces.png')
