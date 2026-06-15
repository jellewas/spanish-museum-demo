#!/usr/bin/env python3
"""Generate a clean Spanish museum wall-label image for the OCR demo."""
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1500
BG = (244, 239, 228)      # parchment
INK = (43, 38, 32)        # warm near-black
MUTED = (120, 110, 95)
F = "/System/Library/Fonts/Supplemental/"

def font(name, size): return ImageFont.truetype(F + name, size)

header   = font("Georgia.ttf", 30)
title    = font("Georgia Bold.ttf", 78)
artist   = font("Georgia Italic.ttf", 46)
meta     = font("Georgia.ttf", 34)
body     = font("Georgia.ttf", 40)

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)

# framed-label border
d.rectangle([28, 28, W - 28, H - 28], outline=(210, 200, 182), width=3)
d.rectangle([40, 40, W - 40, H - 40], outline=(225, 216, 199), width=1)

M = 90  # text margin
y = 120

def center(text, fnt, yy, fill=INK):
    w = d.textlength(text, font=fnt)
    d.text(((W - w) / 2, yy), text, font=fnt, fill=fill)

def wrap(text, fnt, maxw):
    words, lines, line = text.split(), [], ""
    for w in words:
        trial = (line + " " + w).strip()
        if d.textlength(trial, font=fnt) <= maxw:
            line = trial
        else:
            lines.append(line); line = w
    if line: lines.append(line)
    return lines

center("M U S E O   N A C I O N A L", header, y, MUTED); y += 70
d.line([M, y, W - M, y], fill=(210, 200, 182), width=2); y += 60

center("El Guitarrista", title, y); y += 110
center("Pablo Ruiz Picasso", artist, y, MUTED); y += 80
center("Málaga, 1903  ·  Óleo sobre lienzo", meta, y, MUTED); y += 110

d.line([M, y, W - M, y], fill=(225, 216, 199), width=1); y += 50

desc = ("Esta obra refleja la pasión del flamenco y el corazón de la música "
        "española. La guitarra simboliza la tradición andaluza y el alma del "
        "pueblo. El joven músico toca con una mirada melancólica.")
for line in wrap(desc, body, W - 2 * M):
    d.text((M, y), line, font=body, fill=INK); y += 58

img.save("placard.png")
print("wrote placard.png", img.size)
