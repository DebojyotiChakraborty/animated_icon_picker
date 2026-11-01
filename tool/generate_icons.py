"""Generate every app icon variant from one original sprout-fruit glyph.

Run from the project root:

    python3 -I tool/generate_icons.py

Outputs:
  assets/icons/<id>.png              1024x1024 full-bleed square, no alpha
  assets/icons/<id>_glyph.png        1024x1024 glyph only, transparent
  ios/Runner/Assets.xcassets/<set>.appiconset   single-size 1024 icon sets
  android/app/src/main/res/...       adaptive (v26+) and legacy launcher icons

The glyph is drawn at 4x and downsampled with Lanczos for anti-aliasing.
"""

import json
import math
import os
import site
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:  # `-I` hides the user site; Pillow may live there.
    sys.path.append(site.getusersitepackages())
    from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SS = 4  # supersampling factor
MASTER = 1024

# id, display name, iOS icon set, bg (top, bottom), glyph (top, bottom).
# Sampled from the reference recording; the bg is almost flat there, so the
# gradient is kept subtle, while the glyph has a clearer vertical shade.
ICONS = [
    ("default", "Default", "AppIcon",
     ("#0EDD91", "#00D183"), ("#003A27", "#06513A")),
    ("blush", "Blush", "AppIcon-Blush",
     ("#FFADC5", "#FC9DB9"), ("#83203F", "#9A3554")),
    ("grape", "Grape", "AppIcon-Grape",
     ("#8049FD", "#7039F5"), ("#EFE5FB", "#D8C4FD")),
    ("midnight", "Midnight", "AppIcon-Midnight",
     ("#23222D", "#15141C"), ("#F7ECE5", "#D8CBC3")),
    ("mono", "Mono", "AppIcon-Mono",
     ("#FBFBFC", "#EBEBEE"), ("#151419", "#36353B")),
    ("ocean", "Ocean", "AppIcon-Ocean",
     ("#08728F", "#00607D"), ("#BCF5FC", "#92DEEA")),
]

# Android density buckets: legacy launcher size (48dp) and adaptive layer
# size (108dp) in px.
DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def vertical_gradient(size, top, bottom, y0=0.0, y1=1.0):
    """RGB image fading from top to bottom between fractions y0..y1."""
    w, h = size
    t, b = hex_rgb(top), hex_rgb(bottom)
    col = Image.new("RGB", (1, h))
    px = col.load()
    for y in range(h):
        f = (y / max(h - 1, 1) - y0) / max(y1 - y0, 1e-6)
        f = min(max(f, 0.0), 1.0)
        px[0, y] = tuple(round(t[i] + (b[i] - t[i]) * f) for i in range(3))
    return col.resize((w, h))


# --- Glyph geometry, in a 1024 x 1024 design space ---------------------------

def _superellipse(cx, cy, a, b, n, steps=720):
    pts = []
    for i in range(steps):
        th = 2 * math.pi * i / steps
        c, s = math.cos(th), math.sin(th)
        x = cx + a * math.copysign(abs(c) ** (2 / n), c)
        y = cy + b * math.copysign(abs(s) ** (2 / n), s)
        pts.append((x, y))
    return pts


def _bezier(p0, p1, p2, t):
    u = 1 - t
    return (u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
            u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1])


def _leaf(base, tip, half_width, bend, steps=200):
    """Almond leaf from base to tip, bowed sideways by `bend`."""
    bx, by = base
    dx, dy = tip[0] - bx, tip[1] - by
    length = math.hypot(dx, dy)
    ux, uy = dx / length, dy / length
    nx, ny = -uy, ux  # left normal
    upper, lower = [], []
    for i in range(steps + 1):
        t = i / steps
        w = half_width * math.sin(math.pi * t) ** 0.85
        off = bend * math.sin(math.pi * t)
        cx = bx + ux * length * t + nx * off
        cy = by + uy * length * t + ny * off
        upper.append((cx + nx * w, cy + ny * w))
        lower.append((cx - nx * w, cy - ny * w))
    return upper + lower[::-1]


def _capsule(c, angle_deg, length, radius, steps=60):
    a = math.radians(angle_deg)
    ux, uy = math.cos(a), math.sin(a)
    half = length / 2
    p = (c[0] - ux * half, c[1] - uy * half)
    q = (c[0] + ux * half, c[1] + uy * half)
    pts = []
    base = math.atan2(uy, ux)
    for i in range(steps + 1):  # cap around q
        th = base - math.pi / 2 + math.pi * i / steps
        pts.append((q[0] + radius * math.cos(th), q[1] + radius * math.sin(th)))
    for i in range(steps + 1):  # cap around p
        th = base + math.pi / 2 + math.pi * i / steps
        pts.append((p[0] + radius * math.cos(th), p[1] + radius * math.sin(th)))
    return pts


# Vertical extent of the glyph in design space (used for its gradient).
GLYPH_TOP, GLYPH_BOTTOM = 178.0, 828.0
GAP = 24  # clearance between leaf and body


def glyph_mask(size, scale=1.0):
    """L-mode mask of the glyph on a size x size canvas.

    `scale` shrinks the glyph about the centre (1.0 = master proportions,
    roughly 55% of the canvas width).
    """
    big = size * SS
    k = big / MASTER * scale
    off = big / 2 - MASTER / 2 * k

    def tr(pts):
        return [(off + x * k, off + y * k) for x, y in pts]

    # Plump fruit body.
    body = _superellipse(512, 590, 282, 238, 2.15)
    body_img = Image.new("L", (big, big), 0)
    ImageDraw.Draw(body_img).polygon(tr(body), fill=255)

    # Short curved stem with round caps.
    stem_img = Image.new("L", (big, big), 0)
    sd = ImageDraw.Draw(stem_img)
    r = 23 * k
    for i in range(121):
        x, y = _bezier((514, 400), (512, 300), (482, 236), i / 120)
        x, y = off + x * k, off + y * k
        sd.ellipse((x - r, y - r, x + r, y + r), fill=255)

    # Leaf sweeping up and to the right, kept clear of the body.
    leaf_img = Image.new("L", (big, big), 0)
    ImageDraw.Draw(leaf_img).polygon(
        tr(_leaf((512, 318), (748, 214), 66, -14)), fill=255)
    halo = Image.new("L", (big, big), 0)
    ImageDraw.Draw(halo).polygon(
        tr(_superellipse(512, 590, 282 + GAP, 238 + GAP, 2.15)), fill=255)
    leaf_img.paste(0, mask=halo)

    mask = body_img
    mask.paste(255, mask=stem_img)
    mask.paste(255, mask=leaf_img)

    # Glossy highlight cut out of the upper-left of the body.
    shine = Image.new("L", (big, big), 0)
    ImageDraw.Draw(shine).polygon(
        tr(_capsule((382, 500), -58, 92, 27)), fill=255)
    mask.paste(0, mask=shine)

    return mask.resize((size, size), Image.LANCZOS)


def glyph_rgba(size, glyph_colors, scale=1.0):
    mask = glyph_mask(size, scale)
    # Map the glyph's own vertical extent onto the gradient.
    c = 0.5 - 0.5 * scale
    y0 = c + GLYPH_TOP / MASTER * scale
    y1 = c + GLYPH_BOTTOM / MASTER * scale
    fill = vertical_gradient((size, size), *glyph_colors, y0, y1).convert("RGBA")
    fill.putalpha(mask)
    return fill


def full_icon(size, bg, glyph_colors):
    img = vertical_gradient((size, size), *bg).convert("RGBA")
    img.alpha_composite(glyph_rgba(size, glyph_colors))
    return img.convert("RGB")


def legacy_icon(size, bg, glyph_colors):
    """Pre-API-26 launcher icon: rounded square with a small margin."""
    big = size * SS
    inset = round(big * 2 / 48)
    radius = round(big * 9 / 48)
    shape = Image.new("L", (big, big), 0)
    ImageDraw.Draw(shape).rounded_rectangle(
        (inset, inset, big - inset - 1, big - inset - 1), radius, fill=255)
    shape = shape.resize((size, size), Image.LANCZOS)
    inner = size - 2 * round(size * 2 / 48)
    tile = full_icon(inner, bg, glyph_colors)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pad = (size - inner) // 2
    canvas.paste(tile, (pad, pad))
    canvas.putalpha(shape)
    return canvas


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(data)


def main():
    assets = os.path.join(ROOT, "assets", "icons")
    xcassets = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets")
    res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    os.makedirs(assets, exist_ok=True)

    for icon_id, name, ios_set, bg, glyph in ICONS:
        print(f"{icon_id}: {name}")
        master = full_icon(MASTER, bg, glyph)
        master.save(os.path.join(assets, f"{icon_id}.png"), optimize=True)
        glyph_rgba(MASTER, glyph).save(
            os.path.join(assets, f"{icon_id}_glyph.png"), optimize=True)

        # iOS: single-size universal 1024 icon set.
        set_dir = os.path.join(xcassets, f"{ios_set}.appiconset")
        os.makedirs(set_dir, exist_ok=True)
        master.save(os.path.join(set_dir, "Icon-1024.png"), optimize=True)
        write(os.path.join(set_dir, "Contents.json"), json.dumps({
            "images": [{
                "filename": "Icon-1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            }],
            "info": {"author": "xcode", "version": 1},
        }, indent=2) + "\n")

        # Android legacy + adaptive layers.
        res_name = f"ic_launcher_{icon_id}"
        for bucket, d in DENSITIES.items():
            mip = os.path.join(res, f"mipmap-{bucket}")
            os.makedirs(mip, exist_ok=True)
            legacy_icon(round(48 * d), bg, glyph).save(
                os.path.join(mip, f"{res_name}.png"), optimize=True)
            # Adaptive foreground: 108dp layer, of which ~72dp is visible
            # after masking. Scale the glyph by 72/108 so it keeps the same
            # proportions as the master and stays inside the 66dp safe zone.
            glyph_rgba(round(108 * d), glyph, scale=72 / 108).save(
                os.path.join(mip, f"{res_name}_foreground.png"), optimize=True)

        write(os.path.join(res, "drawable", f"{res_name}_background.xml"),
              '<?xml version="1.0" encoding="utf-8"?>\n'
              '<!-- Generated by tool/generate_icons.py -->\n'
              '<shape xmlns:android="http://schemas.android.com/apk/res/android"\n'
              '    android:shape="rectangle">\n'
              '    <gradient\n'
              '        android:angle="270"\n'
              f'        android:startColor="{bg[0]}"\n'
              f'        android:endColor="{bg[1]}" />\n'
              '</shape>\n')
        write(os.path.join(res, "mipmap-anydpi-v26", f"{res_name}.xml"),
              '<?xml version="1.0" encoding="utf-8"?>\n'
              '<!-- Generated by tool/generate_icons.py -->\n'
              '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
              f'    <background android:drawable="@drawable/{res_name}_background" />\n'
              f'    <foreground android:drawable="@mipmap/{res_name}_foreground" />\n'
              f'    <monochrome android:drawable="@mipmap/{res_name}_foreground" />\n'
              '</adaptive-icon>\n')


if __name__ == "__main__":
    main()
