#!/usr/bin/env python3
"""Render the review sheet of the provisional letters and tone marks.

Usage: python3 tools/glyphs/render_sheet.py --out docs/superpowers/specs/assets/letters-sheet.png

Every glyph sits on ô li paper (baseline and x-height line heavier, the
square pad window dashed). Each stroke has its own colour, a numbered circle
at its start point and arrows showing the direction.
"""
import argparse
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import letters  # noqa: E402

FONT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'fonts')

PX = 56            # pixels per ô li
COLS_LI = 8        # ô li shown across each cell
TOP_LI = 1.0       # first frame row shown (frame y in ô li)
ROWS_LI = 11       # rows shown: 7 above the baseline, 4 below
LABEL_H = 64
GAP = 18
COLS = 6
MARGIN = 40
TITLE_H = 120

PAPER = (255, 253, 246)
LINE = (186, 206, 226)
HEAVY = (70, 110, 170)
VLINE = (226, 234, 242)
WINDOW = (232, 150, 60)
CONTEXT = (200, 200, 200)
INK = (40, 40, 40)
COLORS = [(214, 48, 49), (9, 132, 227), (0, 148, 50), (142, 68, 173)]


def font(size, bold=True):
    name = 'Nunito-ExtraBold.ttf' if bold else 'Nunito-SemiBold.ttf'
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def to_px(p, ox, oy):
    u = p[0] / letters.CELL - (letters.CENTER_U - COLS_LI / 2)
    v = p[1] / letters.CELL - TOP_LI
    return (ox + u * PX, oy + v * PX)


def arrow(d, a, b, color, size=13):
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    tip = b
    left = (tip[0] - size * math.cos(ang - 0.45), tip[1] - size * math.sin(ang - 0.45))
    right = (tip[0] - size * math.cos(ang + 0.45), tip[1] - size * math.sin(ang + 0.45))
    d.polygon([tip, left, right], fill=color)


def point_at(pts, frac):
    """Point and next point at a fraction of the polyline length."""
    lens = [0.0]
    for a, b in zip(pts, pts[1:]):
        lens.append(lens[-1] + math.dist(a, b))
    s = lens[-1] * frac
    for i in range(1, len(pts)):
        if lens[i] >= s:
            j = min(i + 2, len(pts) - 1)
            return pts[i], pts[j]
    return pts[-2], pts[-1]


def draw_cell(img, d, g, ctx, ox, oy):
    w, h = COLS_LI * PX, ROWS_LI * PX
    d.rectangle([ox, oy, ox + w, oy + h], fill=PAPER)
    for i in range(COLS_LI + 1):
        d.line([(ox + i * PX, oy), (ox + i * PX, oy + h)], fill=VLINE, width=1)
    for i in range(ROWS_LI + 1):
        y = TOP_LI + i
        heavy = abs(y - 8) < 1e-6 or abs(y - 6) < 1e-6
        d.line([(ox, oy + i * PX), (ox + w, oy + i * PX)],
               fill=HEAVY if heavy else LINE, width=3 if heavy else 1)
    # Pad window (dashed).
    x0, y0, side = g['ruling']['window']
    a = to_px((x0, y0), ox, oy)
    b = to_px((x0 + side, y0 + side), ox, oy)
    for (p, q) in [((a[0], a[1]), (b[0], a[1])), ((b[0], a[1]), (b[0], b[1])),
                   ((b[0], b[1]), (a[0], b[1])), ((a[0], b[1]), (a[0], a[1]))]:
        n = int(math.dist(p, q) // 12)
        for k in range(0, n, 2):
            s = (p[0] + (q[0] - p[0]) * k / n, p[1] + (q[1] - p[1]) * k / n)
            e = (p[0] + (q[0] - p[0]) * (k + 1) / n, p[1] + (q[1] - p[1]) * (k + 1) / n)
            d.line([s, e], fill=WINDOW, width=2)
    if ctx is not None:
        for s in ctx['strokes']:
            d.line([to_px(p, ox, oy) for p in s], fill=CONTEXT, width=7, joint='curve')
    strokes = [[to_px(p, ox, oy) for p in s] for s in g['strokes']]
    for i, s in enumerate(strokes):
        c = COLORS[i % len(COLORS)]
        if len(s) == 1:
            x, y = s[0]
            d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=c)
        else:
            d.line(s, fill=c, width=6, joint='curve')
            length = sum(math.dist(p, q) for p, q in zip(s, s[1:]))
            fracs = [0.5] if length < 4 * PX else [0.3, 0.62, 0.9]
            for f in fracs:
                p, q = point_at(s, f)
                arrow(d, p, q, c, 16)
    f = font(20)
    for i, s in enumerate(strokes):
        c = COLORS[i % len(COLORS)]
        x, y = s[0]
        if len(s) == 1:
            x += 20
        d.ellipse([x - 13, y - 13, x + 13, y + 13], fill=(255, 255, 255), outline=c, width=3)
        d.text((x, y), str(i + 1), font=f, fill=c, anchor='mm')
    d.rectangle([ox, oy, ox + w, oy + h], outline=INK, width=2)
    label = g['label'] + ' · ' + ('%d nét' % len(g['strokes']))
    d.text((ox + w / 2, oy + h + LABEL_H / 2), label, font=font(30), fill=INK, anchor='mm')


def render(out, only=None):
    all_glyphs = letters.letters()
    by_id = {g['id']: g for g in all_glyphs}
    glyphs = [g for g in all_glyphs if not only or g['id'] in only]
    rows = math.ceil(len(glyphs) / COLS)
    cw, ch = COLS_LI * PX, ROWS_LI * PX + LABEL_H
    W = MARGIN * 2 + COLS * cw + (COLS - 1) * GAP
    H = MARGIN * 2 + TITLE_H + rows * ch + (rows - 1) * GAP
    img = Image.new('RGB', (W, H), (255, 255, 255))
    d = ImageDraw.Draw(img)
    d.text((MARGIN, MARGIN), 'Chữ cái viết thường + dấu thanh — nét mẫu tạm (máy sinh), cần duyệt',
           font=font(40), fill=INK)
    d.text((MARGIN, MARGIN + 56),
           'Số trong vòng tròn = thứ tự nét, đặt ở điểm bắt đầu; mũi tên = chiều nét. '
           'Đường đậm: kẻ chân chữ và đầu chữ thường (2 ô li). Khung cam nét đứt = vùng ô viết.',
           font=font(24, bold=False), fill=INK)
    for i, g in enumerate(glyphs):
        r, c = divmod(i, COLS)
        ox = MARGIN + c * (cw + GAP)
        oy = MARGIN + TITLE_H + r * (ch + GAP)
        draw_cell(img, d, g, by_id.get(g.get('context')), ox, oy)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    img.save(out, optimize=True)


def main():
    global PX
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='docs/superpowers/specs/assets/letters-sheet.png')
    ap.add_argument('--only', nargs='*', help='glyph ids to draw (default: all)')
    ap.add_argument('--px', type=int, default=PX, help='pixels per ô li')
    args = ap.parse_args()
    PX = args.px
    render(args.out, args.only)


if __name__ == '__main__':
    main()
