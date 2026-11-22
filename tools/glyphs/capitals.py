"""Provisional Vietnamese capital letters (phase 2G).

Shapes follow the primary-school capital model (chữ hoa kiểu 1) simplified
for children of 3-6: upright, 5 ô li tall (2.5 units) with the baseline at
y = 8/12, G and Y with a 3 ô li loop below. The characteristic strokes of
the model (móc ngược trái/phải, cong trái/phải, cong kín, lượn, khuyết dưới)
are kept; the decorative curls of the adult model are left out.

Coordinates are ô li, origin on the baseline, v up (see letters.py).
Machine-generated placeholder data until the owner approves the sheet
(docs/superpowers/specs/assets/capitals-sheet.png).
"""
import math

import letters
from letters import Pen, khuyet_duoi

H = 5.0  # cap height (ô li)


# Diacritics over a capital (apex at v = 5). Each stays shorter than 2.5 ô li
# so the grader checks where it starts and ends; the cup of Ă floats higher
# than the cap of Â, so their ends are 1.3 ô li apart (beyond the endpoint
# tolerance of a capital's window) and one is never taken for the other.
def mu_hoa(cu, base=5.5, apex=6.55, half=0.45):
    return Pen(cu - half, base).line(cu, apex).line(cu + half, base)


def breve_hoa(cu, top=6.8, bottom=5.85, half=0.4):
    return Pen(cu - half, top).curve((cu - half * 0.75, bottom + 0.2), (cu, bottom),
                                     (cu + half * 0.75, bottom + 0.2), (cu + half, top))


def rau_hoa(stem_u, stem_v=H):
    """Râu on a capital (Ơ, Ư): small hook ending on the top right."""
    return Pen(stem_u + 0.35, stem_v + 1.0).curve(
        (stem_u + 0.75, stem_v + 0.55), (stem_u + 0.5, stem_v + 0.12),
        (stem_u + 0.1, stem_v - 0.02))


def bar_hoa(u0, u1, v):
    return Pen(u0, v).line(u1, v)


# ------------------------------------------------------------------ shapes
# Each returns (body pens, extra pens).

def _A_body():
    # Nét móc ngược trái up to the apex, rê bút down the right leg into a
    # small móc ngược phải; then the lượn ngang crossbar.
    p = Pen(0.0, 0.35)
    p.curve((0.35, 0.05), (0.75, 1.2), (1.35, 3.6), (1.75, H))
    p.curve((2.15, 3.6), (2.75, 1.2), (3.05, 0.25), (3.45, 0.05), (3.75, 0.4))
    bar = Pen(0.85, 2.05).curve((1.45, 2.3), (2.1, 1.95), (2.75, 2.15))
    return p, bar


def _A():
    p, bar = _A_body()
    return [p, bar], []


def _AW():
    p, bar = _A_body()
    return [p, bar], [breve_hoa(1.75)]


def _AA():
    p, bar = _A_body()
    return [p, bar], [mu_hoa(1.75)]


def _stem(u=0.9, top=H):
    """Móc ngược trái: straight down from the top, small hook to the left at
    the bottom (the first stroke of B D P R)."""
    p = Pen(u, top)
    p.line(u, 0.55)
    p.curve((u - 0.2, 0.08), (u - 0.6, 0.0), (u - 0.85, 0.35), smooth=True)
    return p


def _B():
    s = _stem()
    # Cong trên then cong phải, joined by a small thắt in the middle.
    b = Pen(0.9, H)
    b.curve((1.9, 5.0), (2.65, 4.5), (2.55, 3.4), (1.6, 2.7), (1.05, 2.6),
            (1.6, 2.55), (2.85, 2.1), (2.95, 1.0), (2.2, 0.1), (0.9, 0.05))
    return [s, b], []


def _C_pen():
    p = Pen(2.75, 4.2)
    p.curve((2.35, 4.95), (1.4, 5.0), (0.45, 4.1), (0.0, 2.5), (0.35, 0.8),
            (1.3, 0.0), (2.35, 0.15), (3.0, 0.9))
    return p


def _C():
    return [_C_pen()], []


def _D_body():
    s = _stem()
    b = Pen(0.9, H)
    b.curve((2.2, 4.85), (3.2, 3.6), (3.25, 1.7), (2.45, 0.35), (0.9, 0.05))
    return s, b


def _D():
    s, b = _D_body()
    return [s, b], []


def _DD():
    s, b = _D_body()
    return [s, b], [bar_hoa(0.2, 1.7, 2.5)]


def _E_pen():
    # Cong trên, a small thắt at mid height, then a bigger cong trái.
    p = Pen(2.6, 4.4)
    p.curve((2.1, 5.0), (1.0, 4.9), (0.7, 4.05), (1.3, 2.95), (2.0, 2.7),
            (1.25, 2.55), (0.2, 1.9), (0.25, 0.6), (1.3, 0.0), (2.45, 0.2),
            (3.0, 0.8))
    return p


def _E():
    return [_E_pen()], []


def _EE():
    return [_E_pen()], [mu_hoa(1.65)]


def _G():
    # The model's G starts with the C curve (so C ⊂ G, like o ⊂ a), then a
    # khuyết dưới from mid height, 3 ô li below the baseline.
    c = _C_pen()
    k = Pen(2.75, 2.6)
    khuyet_duoi(k, 3.4, 0.6, depth=3.0, w=0.9)
    return [c, k], []


def _H():
    a = Pen(0.4, H).line(0.4, 0.0)
    b = Pen(3.0, H).line(3.0, 0.0)
    c = Pen(0.4, 2.5).line(3.0, 2.5)
    return [a, b, c], []


def _I():
    # Cong trái lượn over the top into a stem, small hook to the left.
    p = Pen(0.2, 4.3)
    p.curve((0.55, 4.95), (1.2, 5.0), end=(1, -0.6))
    p.line(1.45, 0.55)
    p.curve((1.25, 0.08), (0.85, 0.0), (0.55, 0.35), smooth=True)
    return [p], []


def _K():
    s = Pen(0.2, 4.3)
    s.curve((0.55, 4.95), (1.0, 5.0), end=(1, -0.6))
    s.line(1.2, 0.55)
    s.curve((1.0, 0.08), (0.6, 0.0), (0.35, 0.35), smooth=True)
    # Arm in to a small thắt touching the stem (as in the model: this also
    # keeps K's second stroke far from H's right stem), then the leg out.
    k = Pen(3.1, H)
    k.curve((2.3, 3.75), (1.3, 2.6))
    k.curve((2.2, 2.2), (2.65, 1.0), (3.0, 0.15), (3.45, 0.35))
    return [s, k], []


def _L():
    p = Pen(1.9, 4.4)
    p.curve((1.5, 5.0), (0.95, 4.65), (1.2, 3.6), (1.2, 1.4), (0.9, 0.35),
            (0.3, 0.1), (0.55, 0.55), (1.3, 0.25), (2.4, 0.0), (3.2, 0.3))
    return [p], []


def _M():
    p = Pen(0.0, 0.3)
    p.curve((0.25, 0.05), (0.45, 1.5), (0.7, H))
    p.line(1.9, 1.3)
    p.line(3.1, H)
    p.curve((3.25, 2.8), (3.3, 0.6), (3.7, 0.15), (4.0, 0.4))
    return [p], []


def _N():
    p = Pen(0.0, 0.3)
    p.curve((0.25, 0.05), (0.45, 1.5), (0.7, H))
    p.line(2.55, 0.0)
    p.curve((2.65, 1.8), (2.75, 4.3), (3.2, 5.0))
    return [p], []


def _O_pen(cu=1.6):
    # Cong kín, started on the upper right, counter-clockwise like "o".
    a0 = 60.0
    rx, ry = 1.6, 2.5
    start = (cu + rx * math.cos(math.radians(a0)), 2.5 + ry * math.sin(math.radians(a0)))
    return Pen(*start).ellipse(cu, 2.5, rx, ry, a0, a0 + 362.0)


def _O():
    return [_O_pen()], []


def _OO():
    return [_O_pen()], [mu_hoa(1.6)]


def _OW():
    return [_O_pen()], [rau_hoa(2.95, 4.35)]


def _P_bowl():
    b = Pen(0.9, H)
    b.curve((2.15, 4.95), (2.95, 4.3), (2.85, 3.0), (2.0, 2.4), (0.9, 2.35))
    return b


def _P():
    return [_stem(), _P_bowl()], []


def _Q():
    o = _O_pen()
    # Lượn ngang tail across the bottom.
    t = Pen(1.2, 0.55).curve((1.9, -0.15), (2.7, -0.2), (3.6, 0.1))
    return [o, t], []


def _R():
    b = _P_bowl()
    b.curve((2.1, 1.6), (2.65, 0.4), (3.05, 0.05), (3.45, 0.3))
    return [_stem(), b], []


def _S():
    p = Pen(2.75, 4.3)
    p.curve((2.3, 4.95), (1.2, 5.0), (0.45, 4.25), (0.8, 3.2), (2.2, 2.4),
            (2.95, 1.35), (2.35, 0.15), (1.2, 0.0), (0.3, 0.45))
    return [p], []


def _T():
    top = Pen(0.0, 4.7).curve((0.9, 5.15), (2.1, 4.85), (3.2, 5.05))
    s = Pen(1.7, 4.95)
    s.line(1.7, 0.55)
    s.curve((1.5, 0.08), (1.1, 0.0), (0.8, 0.35), smooth=True)
    return [top, s], []


def _U_body():
    p = Pen(0.0, 4.6)
    p.curve((0.35, 5.0), (0.55, 4.6), end=(0, -1))
    p.line(0.55, 1.3)
    p.curve((0.75, 0.15), (1.6, 0.0), (2.45, 0.35), (2.85, 1.4), end=(0, 1))
    p.line(2.85, H)
    p.line(2.85, 0.55)
    p.curve((3.05, 0.08), (3.4, 0.0), (3.65, 0.35), smooth=True)
    return p


def _U():
    return [_U_body()], []


def _UW():
    return [_U_body()], [rau_hoa(2.85)]


def _V():
    p = Pen(0.0, 4.6)
    p.curve((0.35, 5.0), (0.6, 4.4), (1.3, 1.6), (1.75, 0.0))
    p.curve((2.3, 2.3), (2.9, 4.3), (3.25, 5.0), (3.6, 4.7))
    return [p], []


def _X():
    a = Pen(0.2, H).curve((1.2, 3.2), (2.4, 1.4), (3.4, 0.0))
    b = Pen(3.4, H).curve((2.4, 3.2), (1.2, 1.4), (0.2, 0.0))
    return [a, b], []


def _Y():
    # Móc hai đầu (like U's first half), then up the right stem and down into
    # a khuyết dưới 3 ô li below the baseline.
    p = Pen(0.0, 4.6)
    p.curve((0.35, 5.0), (0.55, 4.6), end=(0, -1))
    p.line(0.55, 2.2)
    p.curve((0.75, 1.2), (1.6, 1.0), (2.45, 1.4), (2.85, 2.4), end=(0, 1))
    p.line(2.85, H)
    khuyet_duoi(p, 3.6, 0.6, depth=3.0, w=0.9)
    return [p], []


CAPITALS = [
    ('a', 'A', _A), ('aw', 'Ă', _AW), ('aa', 'Â', _AA), ('b', 'B', _B),
    ('c', 'C', _C), ('d', 'D', _D), ('dd', 'Đ', _DD), ('e', 'E', _E),
    ('ee', 'Ê', _EE), ('g', 'G', _G), ('h', 'H', _H), ('i', 'I', _I),
    ('k', 'K', _K), ('l', 'L', _L), ('m', 'M', _M), ('n', 'N', _N),
    ('o', 'O', _O), ('oo', 'Ô', _OO), ('ow', 'Ơ', _OW), ('p', 'P', _P),
    ('q', 'Q', _Q), ('r', 'R', _R), ('s', 'S', _S), ('t', 'T', _T),
    ('u', 'U', _U), ('uw', 'Ư', _UW), ('v', 'V', _V), ('x', 'X', _X),
    ('y', 'Y', _Y),
]

# Teaching order: simple straight/round shapes first, close relatives next
# to each other, diacritic variants right after their base letter.
ORDER = ('hoa-o hoa-oo hoa-ow hoa-c hoa-i hoa-l hoa-t hoa-h hoa-u hoa-uw '
         'hoa-v hoa-x hoa-n hoa-m hoa-a hoa-aw hoa-aa hoa-e hoa-ee hoa-s '
         'hoa-p hoa-r hoa-b hoa-d hoa-dd hoa-k hoa-q hoa-g hoa-y').split()


def capitals():
    """All 29 capital glyphs in teaching order (same dict shape as
    letters.letters())."""
    out = []
    for key, ch, build in CAPITALS:
        body, extra = build()
        body_pts = [letters._pts(s) for s in body]
        us = [p[0] for s in body_pts for p in s]
        du = letters.CENTER_U - (min(us) + max(us)) / 2
        strokes = ([letters.frame(s, du) for s in body_pts] +
                   [letters.frame(letters._pts(s), du) for s in extra])
        sound = letters.SOUND[ch.lower()]
        out.append({'id': 'hoa-' + key, 'label': 'Chữ ' + ch + ' hoa',
                    'speech': 'chữ ' + sound + ' hoa',
                    'ruling': letters._ruling([p for s in strokes for p in s]),
                    'strokes': strokes, 'body': len(body)})
    index = {g['id']: g for g in out}
    return [index[i] for i in ORDER]
