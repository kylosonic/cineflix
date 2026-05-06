"""
Generates CineFlix app icon: 1024x1024 PNG.

Design:
  - Deep dark background  #050913
  - Soft radial glow      #0C1A3A  (centre pool of light)
  - Film-strip overlay:   vertical perforations on left+right thirds
  - Centred play triangle #F9A826  (gold)  with a teal halo #45D3C1
  - Thin gold ring frame around the triangle
"""

import math, struct, zlib, sys
from PIL import Image, ImageDraw, ImageFilter

SIZE        = 1024
BG          = (5,   9,  19)        # #050913
BG_SOFT     = (12,  26,  58)       # #0C1A3A
SURFACE     = (25,  36,  62)       # #19243E
STROKE      = (49,  68, 107)       # #31446B
GOLD        = (249, 168,  38)      # #F9A826
GOLD_DIM    = (180, 120,  20)
TEAL        = (69, 211, 193)       # #45D3C1
WHITE       = (246, 247, 251)

def rgba(rgb, a=255):
    return rgb + (a,)

img = Image.new("RGBA", (SIZE, SIZE), rgba(BG))

# ── radial glow in centre ──────────────────────────────────────────────────
glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd   = ImageDraw.Draw(glow)
for r in range(420, 0, -1):
    t = r / 420
    # from BG_SOFT at centre → transparent at edge
    a = int(80 * (1 - t) * (1 - t))
    c = tuple(int(BG_SOFT[i] * (1-t) + BG[i]*t) for i in range(3))
    gd.ellipse([SIZE//2-r, SIZE//2-r, SIZE//2+r, SIZE//2+r], fill=c+(a,))
img = Image.alpha_composite(img, glow)

draw = ImageDraw.Draw(img)

# ── film-strip perforations ────────────────────────────────────────────────
PERF_W, PERF_H = 52, 72
PERF_R         = 10
PERF_MARGIN_X  = 52          # left edge of left-strip / right edge of right-strip
STRIP_W        = PERF_W + 28 # total strip band width
N_PERFS        = 7

for side in ("left", "right"):
    if side == "left":
        sx = PERF_MARGIN_X
    else:
        sx = SIZE - PERF_MARGIN_X - PERF_W

    # strip background
    bx0 = sx - 14
    bx1 = sx + PERF_W + 14
    draw.rectangle([bx0, 0, bx1, SIZE], fill=rgba(SURFACE, 180))

    # perforation holes
    total_gap = SIZE - N_PERFS * PERF_H
    step      = total_gap // (N_PERFS + 1)
    for i in range(N_PERFS):
        py0 = step + i * (PERF_H + step)
        py1 = py0 + PERF_H
        draw.rounded_rectangle([sx, py0, sx+PERF_W, py1],
                                radius=PERF_R, fill=rgba(BG, 255))
        # subtle inner highlight
        draw.rounded_rectangle([sx+2, py0+2, sx+PERF_W-2, py1-2],
                                radius=PERF_R-2, fill=rgba(STROKE, 90))

# ── teal soft halo behind triangle ────────────────────────────────────────
halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
hd   = ImageDraw.Draw(halo)
hr   = 270
for r in range(hr, 0, -1):
    t = r / hr
    a = int(55 * (1 - t))
    hd.ellipse([SIZE//2-r, SIZE//2-r, SIZE//2+r, SIZE//2+r],
               fill=TEAL+(a,))
halo = halo.filter(ImageFilter.GaussianBlur(18))
img  = Image.alpha_composite(img, halo)
draw = ImageDraw.Draw(img)

# ── thin teal circle ring ─────────────────────────────────────────────────
RING_R = 240
RING_T = 5
cx = cy = SIZE // 2
draw.ellipse([cx-RING_R, cy-RING_R, cx+RING_R, cy+RING_R],
             outline=rgba(TEAL, 110), width=RING_T)

# ── outer gold ring ────────────────────────────────────────────────────────
GOLD_R = 258
draw.ellipse([cx-GOLD_R, cy-GOLD_R, cx+GOLD_R, cy+GOLD_R],
             outline=rgba(GOLD, 70), width=3)

# ── play triangle ──────────────────────────────────────────────────────────
# equilateral-ish triangle, shifted slightly right so it looks visually centred
TRI_H   = 260          # height of triangle
TRI_W   = int(TRI_H * 0.90)
OFFSET  = 24           # nudge right for optical centering

pts = [
    (cx - TRI_W//2 + OFFSET,  cy - TRI_H//2),
    (cx - TRI_W//2 + OFFSET,  cy + TRI_H//2),
    (cx + TRI_W//2 + OFFSET + 20, cy),
]

# shadow / depth
shadow_pts = [(x+6, y+8) for x, y in pts]
draw.polygon(shadow_pts, fill=rgba(GOLD_DIM, 120))

# main fill
draw.polygon(pts, fill=rgba(GOLD, 255))

# bright highlight on top-left edge
hi_pts = [
    pts[0],
    (pts[0][0] + 18, pts[0][1] + 10),
    (pts[2][0] - 90, pts[2][1] - 20),
    pts[2],
]
draw.polygon(hi_pts, fill=rgba(WHITE, 40))

# ── convert to RGB and save ────────────────────────────────────────────────
out_path = "assets/icon/icon.png"
import os; os.makedirs(os.path.dirname(out_path), exist_ok=True)

rgb = Image.new("RGB", (SIZE, SIZE), BG)
rgb.paste(img, mask=img.split()[3])
rgb.save(out_path, "PNG", optimize=True)
print(f"Saved {out_path}")
