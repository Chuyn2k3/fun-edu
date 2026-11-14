"""Provisional lowercase Vietnamese letters and tone marks (phase 2A).

Letters follow the primary-school handwriting model ("mẫu chữ viết trong
trường tiểu học", 2002): upright, one ô li = 1/12 of the shared frame, baseline
at y = 8/12. Every letter is composed from the school's basic strokes (nét hất,
móc xuôi, móc ngược, móc hai đầu, cong kín, cong trái/phải, khuyết trên/dưới,
nét thắt, thẳng/ngang) drawn as smooth curves.

Shapes are written in ô li with the origin on the baseline and v growing
upward; `frame()` converts to the glyph frame ([0,1], y down).

Stroke split: "rê bút" (pen stays on paper) joins parts into one stroke,
"lia bút" (pen lifted) starts a new one. Dots, bars, diacritics and tone
marks are separate strokes after the body.

Machine-generated placeholder data until real strokes are recorded.
"""
import math

CELL = 1 / 12
BASELINE = 8 / 12
SPACING = 0.15  # ô li between consecutive output points (0.0125 frame)
CENTER_U = 6.0  # letters are centred on this column (ô li)

# ----------------------------------------------------------------- curve kit


def _bezier(p0, p1, p2, p3, n=48):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def _catmull(pts, start_tangent=None, end_tangent=None, n=24):
    """Centripetal Catmull-Rom through pts (as cubic Béziers)."""
    out = [pts[0]]
    k = len(pts)
    for i in range(k - 1):
        p1, p2 = pts[i], pts[i + 1]
        d12 = math.dist(p1, p2)
        if i > 0:
            p0 = pts[i - 1]
            t1 = _tangent(p0, p1, p2)
        elif start_tangent is not None:
            t1 = _unit(start_tangent)
        else:
            t1 = _unit((p2[0] - p1[0], p2[1] - p1[1]))
        if i + 2 < k:
            t2 = _tangent(p1, p2, pts[i + 2])
        elif end_tangent is not None:
            t2 = _unit(end_tangent)
        else:
            t2 = _unit((p2[0] - p1[0], p2[1] - p1[1]))
        h = d12 / 3
        c1 = (p1[0] + t1[0] * h, p1[1] + t1[1] * h)
        c2 = (p2[0] - t2[0] * h, p2[1] - t2[1] * h)
        out.extend(_bezier(p1, c1, c2, p2, n)[1:])
    return out


def _unit(v):
    d = math.hypot(v[0], v[1]) or 1.0
    return (v[0] / d, v[1] / d)


def _tangent(a, b, c):
    """Tangent at b, weighted like a centripetal spline."""
    da = math.sqrt(math.dist(a, b)) or 1e-9
    dc = math.sqrt(math.dist(b, c)) or 1e-9
    u1 = _unit((b[0] - a[0], b[1] - a[1]))
    u2 = _unit((c[0] - b[0], c[1] - b[1]))
    return _unit((u1[0] * dc + u2[0] * da, u1[1] * dc + u2[1] * da))


def _resample(seg, spacing):
    """Evenly spaced points along a dense polyline, keeping both ends."""
    lens = [0.0]
    for a, b in zip(seg, seg[1:]):
        lens.append(lens[-1] + math.dist(a, b))
    total = lens[-1]
    if total < 1e-9:
        return [seg[0]]
    n = max(1, math.ceil(total / spacing))
    out = []
    j = 0
    for i in range(n + 1):
        s = total * i / n
        while j < len(seg) - 2 and lens[j + 1] < s:
            j += 1
        a, b = seg[j], seg[j + 1]
        span = lens[j + 1] - lens[j]
        t = 0 if span < 1e-12 else (s - lens[j]) / span
        out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return out


class Pen:
    """One pen-down run, built from pieces in ô li (u right, v up).

    A corner between pieces stays sharp (a cusp in the handwriting); inside a
    piece the curve is smooth.
    """

    def __init__(self, u, v):
        self.pieces = []
        self.cur = (u, v)
        self.heading = None

    def _add(self, pts):
        self.pieces.append(pts)
        self.cur = pts[-1]
        a, b = pts[-2], pts[-1]
        self.heading = _unit((b[0] - a[0], b[1] - a[1]))
        return self

    def line(self, u, v):
        return self._add([self.cur, (u, v)])

    def curve(self, *pts, smooth=False, end=None):
        """Smooth curve through pts. smooth=True continues the current heading
        (no corner); end fixes the final direction."""
        start = self.heading if smooth else None
        return self._add(_catmull([self.cur] + list(pts), start, end))

    def bez(self, c1, c2, p):
        return self._add(_bezier(self.cur, c1, c2, p))

    def ellipse(self, cu, cv, ru, rv, a0, a1):
        """Elliptic arc, angles in degrees counter-clockwise from +u. The
        piece starts at angle a0 (normally the current point)."""
        n = max(8, int(abs(a1 - a0) / 2))
        pts = [(cu + ru * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
                cv + rv * math.sin(math.radians(a0 + (a1 - a0) * i / n)))
               for i in range(n + 1)]
        if math.dist(self.cur, pts[0]) > 1e-6:
            pts.insert(0, self.cur)
        return self._add(pts)

    def points(self):
        out = [self.cur] if not self.pieces else []
        for piece in self.pieces:
            for p in _resample(piece, SPACING):
                if not out or math.dist(p, out[-1]) > 1e-9:
                    out.append(p)
        return out


def dot(u, v):
    return [(u, v)]


# ------------------------------------------------------------ basic strokes
# Each helper continues a Pen; numbers are ô li.


def hat(pen, u, v):
    """Nét hất: short slanted up-stroke to (u, v), slightly concave."""
    a = pen.cur
    mid = ((a[0] + u) / 2 + 0.06, (a[1] + v) / 2 - 0.08)
    return pen.curve(mid, (u, v))


def moc_nguoc(pen, end_u, end_v, r=0.45):
    """Nét móc ngược (phải): straight down from the current point to the
    baseline, round the bottom to the right and rise to (end_u, end_v)."""
    u, _ = pen.cur
    pen.line(u, r + 0.05)
    return pen.curve((u + r * 0.35, 0.08), (u + r + 0.05, 0.0),
                     (u + (end_u - u) * 0.8, end_v * 0.55), (end_u, end_v),
                     smooth=True)


def moc_nguoc_to_stem(pen, stem_u, end_v=1.0, r=0.45):
    """Móc ngược whose hook rises into a vertical stem at stem_u (u, y)."""
    u, _ = pen.cur
    pen.line(u, r + 0.05)
    return pen.curve((u + r * 0.35, 0.08), (u + r + 0.05, 0.0),
                     (stem_u - 0.08, 0.45), (stem_u, end_v),
                     smooth=True, end=(0, 1))


def moc_xuoi_head(pen, stem_u, top=2.0):
    """Head of nét móc xuôi (trái): from the current point (left, lower)
    round over the top into a vertical stem at stem_u."""
    u0, v0 = pen.cur
    return pen.curve(((u0 + stem_u) / 2 - 0.05, top - 0.03), (stem_u, top - 0.45),
                     end=(0, -1))


def arch(pen, w, top=2.0, branch=0.9):
    """Nét móc hai đầu without its hook: from the bottom of a stem at the
    current u retrace up to `branch`, arch over to a new stem w to the right,
    and come down that stem (caller adds the hook)."""
    u, v = pen.cur
    pen.line(u, branch)
    pen.curve((u + 0.12, top - 0.35), (u + w * 0.5, top), (u + w, top - 0.45),
              smooth=True, end=(0, -1))
    return pen


def khuyet_tren(pen, stem_u, top=5.0, w=0.75, cross=2.0):
    """Nét khuyết trên: from the current point (left of the stem, on line 2)
    rise to the right, loop over the top (head at `top`) and come straight
    down the stem at stem_u, crossing the up-stroke on line `cross`."""
    u0, v0 = pen.cur
    pen.curve((stem_u, cross), (stem_u + w * 0.55, (cross + top) / 2 + 0.2),
              (stem_u + w * 0.3, top - 0.1), (stem_u - w * 0.05, top),
              (stem_u - w * 0.35, top - 0.5), (stem_u - 0.12, cross + 1.2),
              (stem_u, cross + 0.4), end=(0, -1))
    return pen


def khuyet_duoi(pen, end_u, end_v=1.0, depth=3.0, w=0.75, cross=0.0):
    """Nét khuyết dưới: from the current point straight down the stem, loop at
    `depth` below the baseline to the left and rise across the stem on the
    baseline, ending at (end_u, end_v)."""
    u, v = pen.cur
    pen.line(u, -depth + 1.3)
    pen.curve((u - w * 0.15, -depth + 0.25), (u - w * 0.55, -depth),
              (u - w * 0.85, -depth + 0.5), (u - w * 0.4, -1.0),
              (u, cross), (end_u, end_v), smooth=True)
    return pen


def cong_kin_pen(cu, rx=0.75, ry=1.0, start=55.0, sweep=362.0):
    """Nét cong kín: oval centred (cu, 1) started below line 3 on the right,
    run counter-clockwise (right to left over the top) back to the start."""
    a0 = start
    p = (cu + rx * math.cos(math.radians(a0)), 1 + ry * math.sin(math.radians(a0)))
    return Pen(*p).ellipse(cu, 1.0, rx, ry, a0, a0 + sweep)


def mu(cu, base=2.55, apex=3.35, half=0.55):
    """Dấu mũ (^) for â ê ô: up from the left, down to the right."""
    return Pen(cu - half, base).line(cu, apex).line(cu + half, base)


def breve(cu, top=3.35, bottom=2.55, half=0.55):
    """Dấu á (˘) for ă: a small cup written left to right."""
    return Pen(cu - half, top).curve((cu - half * 0.75, bottom + 0.2), (cu, bottom),
                                     (cu + half * 0.75, bottom + 0.2), (cu + half, top))


def rau(stem_u, stem_v=2.0):
    """Dấu râu for ơ ư: a small hook written top-down, bulging to the right
    and ending on the top of the letter at stem_u."""
    return Pen(stem_u + 0.3, stem_v + 0.9).curve(
        (stem_u + 0.66, stem_v + 0.5), (stem_u + 0.45, stem_v + 0.12),
        (stem_u + 0.1, stem_v + 0.0))


def bar(u0, u1, v):
    """Nét ngang (t, đ): written left to right."""
    return Pen(u0, v).line(u1, v)


# ------------------------------------------------------------------- letters
# Each builder returns (body pens, extra pens); extra = dot/bar/diacritic.


def _i():
    p = Pen(0.0, 1.0)
    hat(p, 0.65, 2.0)
    moc_nguoc(p, 1.4, 1.0)
    return [p], [Pen(0.65, 3.0)]


def _t():
    p = Pen(0.0, 1.0)
    hat(p, 0.8, 3.0)
    moc_nguoc(p, 1.55, 1.0)
    return [p], [bar(0.3, 1.35, 2.0)]


def _u_body(tail=None):
    """u (and the start of y): hất, móc ngược into the second stem, rê bút up
    to line 3 and back down."""
    p = Pen(0.0, 1.0)
    hat(p, 0.65, 2.0)
    moc_nguoc_to_stem(p, 1.85, 1.0)
    p.line(1.85, 2.0)
    if tail is None:
        moc_nguoc(p, 2.55, 1.0)
    else:
        tail(p)
    return p


def _u():
    return [_u_body()], []


def _uw():
    return [_u_body()], [rau(1.85)]


def _n():
    p = Pen(0.0, 1.5)
    moc_xuoi_head(p, 0.7)
    p.line(0.7, 0.0)
    arch(p, 1.15)
    moc_nguoc(p, 2.55, 1.0)
    return [p], []


def _m():
    p = Pen(0.0, 1.5)
    moc_xuoi_head(p, 0.7)
    p.line(0.7, 0.0)
    arch(p, 1.15)
    p.line(1.85, 0.0)
    arch(p, 1.15)
    moc_nguoc(p, 3.7, 1.0)
    return [p], []


def _v():
    p = Pen(0.0, 1.5)
    moc_xuoi_head(p, 0.7)
    p.line(0.7, 0.5)
    # Round bottom, up the right side, small nét thắt at the top right.
    p.curve((0.85, 0.08), (1.2, 0.0), (1.55, 0.55), (1.65, 1.55),
            (1.55, 2.0), (1.32, 1.8), (1.55, 1.6), (2.05, 1.75), smooth=True)
    return [p], []


def _r():
    p = Pen(0.0, 1.0)
    # Nét hất up to 2.5 ô li, a small nét thắt (eyelet) at the top, the
    # shoulder, then nét móc ngược.
    p.curve((0.5, 1.75), (0.88, 2.5), (0.66, 2.32), (0.74, 2.1), (1.0, 2.12),
            (1.32, 2.1), (1.5, 1.8), (1.52, 1.5), end=(0, -1))
    moc_nguoc(p, 2.2, 1.0)
    return [p], []


def _s():
    p = Pen(0.05, 0.05)
    # Nét xiên up to 2.5 ô li, a small nét thắt, then nét cong phải closing
    # back in toward the start.
    p.curve((0.45, 1.25), (0.85, 2.5), (0.66, 2.3), (0.76, 2.08), (1.05, 2.0),
            (1.32, 1.3), (1.2, 0.4), (0.75, 0.0), (0.3, 0.12), (0.4, 0.42))
    return [p], []


def _o_pen(cu=0.75):
    return cong_kin_pen(cu)


def _o():
    return [_o_pen()], []


def _oo():
    return [_o_pen()], [mu(0.75)]


def _ow():
    return [_o_pen()], [rau(1.42, 1.62)]


def _c():
    p = Pen(1.25, 1.65)
    p.curve((0.95, 2.0), (0.3, 1.85), (0.0, 1.0), (0.3, 0.12), (0.85, 0.0),
            (1.35, 0.35))
    return [p], []


def _x():
    a = Pen(0.0, 1.75)
    a.curve((0.35, 2.0), (0.75, 1.55), (0.85, 1.0), (0.7, 0.35), (0.35, 0.0),
            (0.0, 0.25))
    b = Pen(1.7, 1.75)
    b.curve((1.35, 2.0), (0.95, 1.55), (0.85, 1.0), (1.0, 0.35), (1.35, 0.0),
            (1.7, 0.25))
    return [a, b], []


def _e_pen():
    p = Pen(0.15, 0.85)
    p.curve((0.75, 1.05), (1.25, 1.55), (0.95, 2.0), (0.4, 1.85), (0.03, 1.1),
            (0.25, 0.25), (0.75, 0.0), (1.35, 0.4))
    return p


def _e():
    return [_e_pen()], []


def _ee():
    return [_e_pen()], [mu(0.7)]


def _a_body():
    return [_o_pen(), Pen(1.5, 2.0)]


def _a():
    o, p = _a_body()
    moc_nguoc(p, 2.2, 1.0)
    return [o, p], []


def _aw():
    body, _ = _a()
    return body, [breve(0.85)]


def _aa():
    body, _ = _a()
    return body, [mu(0.85)]


def _d():
    o = _o_pen()
    p = Pen(1.5, 4.0)
    moc_nguoc(p, 2.2, 1.0)
    return [o, p], []


def _dd():
    body, _ = _d()
    return body, [bar(1.0, 2.0, 3.0)]


def _q():
    o = _o_pen()
    p = Pen(1.5, 2.0).line(1.5, -2.0)
    return [o, p], []


def _l():
    p = Pen(0.0, 1.0)
    khuyet_tren(p, 0.7)
    moc_nguoc(p, 1.45, 1.0)
    return [p], []


def _b():
    p = Pen(0.0, 1.0)
    khuyet_tren(p, 0.7)
    # Móc ngược round the bottom, up the right side, nét thắt at line 3.
    p.line(0.7, 0.5)
    p.curve((0.85, 0.08), (1.2, 0.0), (1.6, 0.5), (1.72, 1.5), (1.55, 2.0),
            (1.3, 1.8), (1.55, 1.6), (2.05, 1.75), smooth=True)
    return [p], []


def _h():
    p = Pen(0.0, 1.0)
    khuyet_tren(p, 0.7)
    p.line(0.7, 0.0)
    arch(p, 1.15)
    moc_nguoc(p, 2.55, 1.0)
    return [p], []


def _k():
    p = Pen(0.0, 1.0)
    khuyet_tren(p, 0.7)
    p.line(0.7, 0.0)
    # Móc hai đầu with a clear nét thắt (a round loop under line 2, about
    # 0.8 ô li across) between the shoulder and the hook. The loop must be
    # this pronounced or a drawn h is graded as k (review I3).
    p.line(0.7, 0.9)
    p.curve((0.85, 1.75), (1.4, 2.1), (1.95, 1.85), (1.9, 1.35), (1.35, 1.15),
            (0.9, 1.1), (0.82, 0.6), (1.25, 0.4), (1.6, 0.8), (1.4, 1.18),
            (1.7, 1.12), (1.95, 0.75), (2.0, 0.45), smooth=True, end=(0, -1))
    moc_nguoc(p, 2.8, 1.0, r=0.4)
    return [p], []


def _g():
    o = _o_pen()
    p = Pen(1.5, 2.0)
    khuyet_duoi(p, 2.05, 0.9)
    return [o, p], []


def _y():
    return [_u_body(lambda p: khuyet_duoi(p, 2.4, 0.9))], []


def _p():
    p = Pen(0.0, 1.0)
    hat(p, 0.65, 2.0)
    p.line(0.65, -2.0)
    # Rê bút back up the stem to line 2, then nét móc hai đầu.
    arch(p, 1.15, branch=1.0)
    moc_nguoc(p, 2.5, 1.0)
    return [p], []


LETTERS = [
    ('i', 'i', _i), ('t', 't', _t), ('u', 'u', _u), ('uw', 'ư', _uw),
    ('n', 'n', _n), ('m', 'm', _m), ('v', 'v', _v), ('r', 'r', _r),
    ('s', 's', _s), ('o', 'o', _o), ('oo', 'ô', _oo), ('ow', 'ơ', _ow),
    ('c', 'c', _c), ('x', 'x', _x), ('e', 'e', _e), ('ee', 'ê', _ee),
    ('a', 'a', _a), ('aw', 'ă', _aw), ('aa', 'â', _aa), ('d', 'd', _d),
    ('dd', 'đ', _dd), ('q', 'q', _q), ('l', 'l', _l), ('b', 'b', _b),
    ('h', 'h', _h), ('k', 'k', _k), ('g', 'g', _g), ('y', 'y', _y),
    ('p', 'p', _p),
]

SOUND = {'a': 'a', 'ă': 'á', 'â': 'ớ', 'b': 'bờ', 'c': 'cờ', 'd': 'dờ', 'đ': 'đờ',
         'e': 'e', 'ê': 'ê', 'g': 'gờ', 'h': 'hờ', 'i': 'i', 'k': 'ca', 'l': 'lờ',
         'm': 'mờ', 'n': 'nờ', 'o': 'o', 'ô': 'ô', 'ơ': 'ơ', 'p': 'pờ', 'q': 'quờ',
         'r': 'rờ', 's': 'sờ', 't': 'tờ', 'u': 'u', 'ư': 'ư', 'v': 'vờ', 'x': 'xờ',
         'y': 'i dài'}


# Tone marks, written over "a" (ô li, relative to the centre of a's oval and
# the top of the letter at v = 2).
def _huyen(c):
    return Pen(c - 0.3, 3.5).line(c + 0.3, 2.6)


def _sac(c):
    return Pen(c + 0.3, 3.5).line(c - 0.3, 2.6)


def _hoi(c):
    return Pen(c - 0.35, 3.15).curve((c - 0.05, 3.42), (c + 0.32, 3.2), (c + 0.12, 2.92),
                                     (c - 0.02, 2.78), (c - 0.02, 2.5))


def _nga(c):
    return Pen(c - 0.55, 2.75).curve((c - 0.27, 3.2), (c, 3.0), (c + 0.25, 2.8),
                                     (c + 0.55, 3.25))


def _nang(c):
    return dot(c, -0.9)


MARKS = [
    ('huyen', 'Dấu huyền', _huyen), ('sac', 'Dấu sắc', _sac),
    ('nang', 'Dấu nặng', _nang), ('hoi', 'Dấu hỏi', _hoi), ('nga', 'Dấu ngã', _nga),
]

# ------------------------------------------------------------------ assembly


def _pts(stroke):
    return stroke.points() if isinstance(stroke, Pen) else list(stroke)


def frame(points, du):
    return [((u + du) * CELL, BASELINE - v * CELL) for u, v in points]


def _window(points):
    """Tight square window on whole ô li around points (design §6b: bao chữ +
    lề ~0,5 ô li): side = extent + 1 ô li rounded up (at least 3), grown only
    until every point keeps >= 0.5 ô li margin on the grid."""
    us = [p[0] / CELL for p in points]
    vs = [p[1] / CELL for p in points]
    lo_u, hi_u, lo_v, hi_v = min(us), max(us), min(vs), max(vs)
    side = max(3, math.ceil(max(hi_u - lo_u, hi_v - lo_v) + 1 - 1e-3))
    while True:
        x0 = round((lo_u + hi_u - side) / 2)
        y0 = round((lo_v + hi_v - side) / 2)
        if (x0 <= lo_u - 0.5 and x0 + side >= hi_u + 0.5 and
                y0 <= lo_v - 0.5 and y0 + side >= hi_v + 0.5):
            break
        side += 1
    x0 = min(max(x0, 0), 12 - side)
    y0 = min(max(y0, 0), 12 - side)
    return [round(x0 * CELL, 6), round(y0 * CELL, 6), round(side * CELL, 6)]


def _ruling(points):
    return {'cell': round(CELL, 6), 'baseline': round(BASELINE, 6),
            'window': _window(points)}


def letters():
    """All 34 glyphs in ladder order.

    Each item: id, label, speech, ruling, [context], strokes (frame
    coordinates, unrounded), body (number of leading body strokes).
    """
    out = []
    a_shift = None
    for key, ch, build in LETTERS:
        body, extra = build()
        body_pts = [_pts(s) for s in body]
        us = [p[0] for s in body_pts for p in s]
        du = CENTER_U - (min(us) + max(us)) / 2
        if key == 'a':
            a_shift = du
        strokes = [frame(s, du) for s in body_pts] + [frame(_pts(s), du) for s in extra]
        out.append({'id': 'chu-' + key, 'label': 'Chữ ' + ch, 'speech': 'chữ ' + SOUND[ch],
                    'ruling': _ruling([p for s in strokes for p in s]),
                    'strokes': strokes, 'body': len(body)})
    a = next(g for g in out if g['id'] == 'chu-a')
    a_pts = [p for s in a['strokes'] for p in s]
    for key, label, build in MARKS:
        stroke = frame(_pts(build(0.75)), a_shift)
        out.append({'id': 'dau-' + key, 'label': label, 'speech': label[0].lower() + label[1:],
                    'ruling': _ruling(stroke + a_pts), 'context': 'chu-a',
                    'strokes': [stroke], 'body': 0})
    ladder = ('chu-i chu-t chu-u chu-uw chu-n chu-m chu-v chu-r chu-s chu-o chu-oo '
              'chu-ow chu-c chu-x chu-e chu-ee chu-a chu-aw chu-aa chu-d chu-dd chu-q '
              'chu-l chu-b chu-h chu-k chu-g chu-y chu-p dau-huyen dau-sac dau-nang '
              'dau-hoi dau-nga').split()
    index = {g['id']: g for g in out}
    return [index[i] for i in ladder]


def to_json(g):
    data = {'id': g['id'], 'label': g['label'], 'speech': g['speech'],
            'ruling': g['ruling']}
    if 'context' in g:
        data['context'] = g['context']
    data['strokes'] = [{'points': [[round(x, 4), round(y, 4)] for x, y in s]}
                       for s in g['strokes']]
    return data
