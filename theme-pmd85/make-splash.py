#!/usr/bin/env python3 -I
"""Generates the scene images of the splash theme (scene-N.png, block.png, count in scenes.count).
Usage: python3 -I make-splash.py   (needs Pillow, run from theme-pmd85/)"""
from PIL import Image, ImageDraw, ImageFont
import os

DATA = '../simpmd/data'
W, H = 830, 570
GRAY = (0x92, 0x92, 0xAA)
FONT = ImageFont.truetype(f'{DATA}/font/atari-classic.ttf', 28)
SMALL = ImageFont.truetype(f'{DATA}/font/atari-classic.ttf', 20)

def canvas():
    return Image.new('RGBA', (W, H), (0, 0, 0, 255))

def text_c(d, y, s, font=FONT, fill=(255, 255, 255)):
    w = d.textlength(s, font=font)
    d.text(((W - w) / 2, y), s, font=font, fill=fill)

scenes = []

# 1: the computer drawing
im = canvas()
im.alpha_composite(Image.open('pmd85_830_570.png').convert('RGBA'))
scenes.append(im)

# 2-5: game logos
for name, title in (('flappy', 'FLAPPY'), ('boulder', 'BOULDER DASH'), ('manic', 'MANIC MINER'), ('fred', 'FRED')):
    logo = Image.open(f'{DATA}/logo/{name}.bmp').convert('L').resize((522, 522), Image.NEAREST)
    im = canvas()
    d = ImageDraw.Draw(im)
    im.paste(Image.merge('RGBA', (logo, logo, logo, Image.new('L', logo.size, 255))), ((W - 522) // 2, 0))
    text_c(d, 535, title, SMALL, GRAY)
    scenes.append(im)

# 6: monitor screen, 288x256 look at 2x
im = canvas()
d = ImageDraw.Draw(im)
x0, y0 = (W - 576) // 2, 10
d.rectangle((x0 - 4, y0 - 4, x0 + 580, y0 + 516), outline=GRAY, width=4)
for i, (s, c) in enumerate((('PMD 85', (255, 255, 255)), ('', None), ('MONITOR 1', GRAY), ('', None),
                            ('MGLD 00', (255, 255, 255)), ('', None), ('READY', GRAY), ('*', (255, 255, 255)))):
    if s:
        d.text((x0 + 24, y0 + 30 + i * 52), s, font=FONT, fill=c)
scenes.append(im)

# 7: tape loading, striped border
im = canvas()
d = ImageDraw.Draw(im)
y = 0
for i in range(0, H, 30):
    d.rectangle((0, i, 60, i + 14), fill=GRAY)
    d.rectangle((W - 61, i + 15, W - 1, i + 29), fill=GRAY)
text_c(d, 240, 'LOADING', FONT)
text_c(d, 300, 'TAPE  00', SMALL, GRAY)
scenes.append(im)

for n, im in enumerate(scenes, 1):
    im.save(f'scene-{n}.png')
open('scenes.count', 'w').write(f'{len(scenes)}\n')
Image.new('RGBA', (14, 22), (255, 255, 255, 255)).save('block.png')
print(len(scenes), 'scenes')
