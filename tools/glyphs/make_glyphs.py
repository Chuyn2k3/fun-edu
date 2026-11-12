#!/usr/bin/env python3
"""Generate provisional reference glyphs (basic strokes and digits 0-9).

Usage: python3 tools/glyphs/make_glyphs.py --out assets/glyphs
Unit square, y grows downward. Placeholder data until the owner re-records it.
"""
import argparse
import json
import math
import os


def r4(p):
    return [round(p[0], 4), round(p[1], 4)]


def line(a, b, n=12):
    return [(a[0] + (b[0] - a[0]) * i / (n - 1), a[1] + (b[1] - a[1]) * i / (n - 1))
            for i in range(n)]


def bezier(p0, p1, p2, p3, n=24):
    out = []
    for i in range(n):
        t = i / (n - 1)
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def arc(cx, cy, rx, ry, t0, t1, n=32):
    """Ellipse arc; t in degrees measured clockwise from the top (y down).
    Decreasing t runs counter-clockwise on screen."""
    pts = []
    for i in range(n):
        t = math.radians(t0 + (t1 - t0) * i / (n - 1))
        pts.append((cx + rx * math.sin(t), cy - ry * math.cos(t)))
    return pts


def join(*parts):
    out = []
    for part in parts:
        for p in part:
            if not out or math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) > 1e-9:
                out.append(p)
    return out


def glyphs():
    g = {}
    g['net-xien'] = ('Nét xiên', [line((0.7, 0.1), (0.3, 0.9), 16)])
    # C shape opening to the right: starts upper right, runs counter-clockwise.
    g['net-cong'] = ('Nét cong', [
        [(0.55 + 0.35 * math.cos(math.radians(a)), 0.5 - 0.35 * math.sin(math.radians(a)))
         for a in [60 + 240 * i / 35 for i in range(36)]]])
    g['net-moc'] = ('Nét móc', [join(
        line((0.4, 0.1), (0.4, 0.75), 14),
        bezier((0.4, 0.75), (0.4, 0.95), (0.62, 0.95), (0.62, 0.72), 16))])
    # Oval starting at the top going left; 340 degrees leaves a gap at the top.
    g['so-0'] = ('Số 0', [arc(0.5, 0.5, 0.25, 0.4, 0, -340, 40)])
    g['so-1'] = ('Số 1', [line((0.35, 0.35), (0.6, 0.1)), line((0.6, 0.1), (0.6, 0.9))])
    g['so-2'] = ('Số 2', [
        join(arc(0.5, 0.33, 0.23, 0.23, -140, 140, 28), line((0.6, 0.55), (0.27, 0.9), 10)),
        line((0.27, 0.9), (0.75, 0.9))])
    g['so-3'] = ('Số 3', [join(
        arc(0.48, 0.3, 0.2, 0.2, -130, 180, 28),
        arc(0.48, 0.7, 0.2, 0.2, 0, 230, 28))])
    g['so-4'] = ('Số 4', [line((0.55, 0.1), (0.25, 0.65)), line((0.25, 0.65), (0.75, 0.65)),
                          line((0.6, 0.35), (0.6, 0.9))])
    g['so-5'] = ('Số 5', [
        line((0.35, 0.1), (0.32, 0.45)),
        bezier((0.32, 0.45), (0.85, 0.4), (0.85, 0.95), (0.27, 0.85), 28),
        line((0.35, 0.1), (0.72, 0.1))])
    g['so-6'] = ('Số 6', [join(
        bezier((0.68, 0.15), (0.35, 0.25), (0.27, 0.5), (0.27, 0.67), 14),
        arc(0.5, 0.67, 0.23, 0.23, -90, -420, 36))])
    g['so-7'] = ('Số 7', [line((0.25, 0.1), (0.75, 0.1)), line((0.75, 0.1), (0.4, 0.9), 14)])
    g['so-8'] = ('Số 8', [join(
        arc(0.5, 0.3, 0.2, 0.2, 61, -180, 28),
        arc(0.5, 0.7, 0.2, 0.2, 0, 360, 36),
        arc(0.5, 0.3, 0.2, 0.2, -180, -270, 14))])
    g['so-9'] = ('Số 9', [
        arc(0.5, 0.33, 0.23, 0.23, 68, -262, 36),
        bezier((0.7, 0.25), (0.78, 0.55), (0.6, 0.85), (0.45, 0.9), 16)])
    return g


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='assets/glyphs')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    for gid, (label, strokes) in glyphs().items():
        data = {'id': gid, 'label': label,
                'strokes': [{'points': [r4(p) for p in s]} for s in strokes]}
        with open(os.path.join(args.out, gid + '.json'), 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
            f.write('\n')


if __name__ == '__main__':
    main()
