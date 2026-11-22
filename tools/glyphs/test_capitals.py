"""Tests for the provisional capital letters (phase 2G).

Run: cd tools/glyphs && python3 -m pytest -q
"""
import json
import math
import os
import subprocess
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import capitals  # noqa: E402
import letters  # noqa: E402

CELL = 1 / 12
BASELINE = 8 / 12

CAP = {'a': 'A', 'aw': 'Ă', 'aa': 'Â', 'b': 'B', 'c': 'C', 'd': 'D', 'dd': 'Đ',
       'e': 'E', 'ee': 'Ê', 'g': 'G', 'h': 'H', 'i': 'I', 'k': 'K', 'l': 'L',
       'm': 'M', 'n': 'N', 'o': 'O', 'oo': 'Ô', 'ow': 'Ơ', 'p': 'P', 'q': 'Q',
       'r': 'R', 's': 'S', 't': 'T', 'u': 'U', 'uw': 'Ư', 'v': 'V', 'x': 'X',
       'y': 'Y'}

# Strokes (pen-down runs) of the simplified model; extras = diacritics/bar.
STROKES = {'A': 2, 'Ă': 3, 'Â': 3, 'B': 2, 'C': 1, 'D': 2, 'Đ': 3, 'E': 1,
           'Ê': 2, 'G': 2, 'H': 3, 'I': 1, 'K': 2, 'L': 1, 'M': 1, 'N': 1,
           'O': 1, 'Ô': 2, 'Ơ': 2, 'P': 2, 'Q': 2, 'R': 2, 'S': 1, 'T': 2,
           'U': 1, 'Ư': 2, 'V': 1, 'X': 2, 'Y': 1}
EXTRA = {'Ă': 1, 'Â': 1, 'Đ': 1, 'Ê': 1, 'Ô': 1, 'Ơ': 1, 'Ư': 1}
BELOW = {'G': 3, 'Y': 3}  # ô li under the baseline


@pytest.fixture(scope='module')
def glyphs():
    return capitals.capitals()


def ch(g):
    return CAP[g['id'][4:]]


def body_points(g):
    return [p for s in g['strokes'][:g['body']] for p in s]


def test_all_29_capitals_in_teaching_order(glyphs):
    assert len(glyphs) == 29
    assert [g['id'] for g in glyphs] == capitals.ORDER
    assert sorted(g['id'] for g in glyphs) == sorted('hoa-' + k for k in CAP)
    # Diacritic letters come right after their base letter.
    order = capitals.ORDER
    for base, vs in {'o': ['oo', 'ow'], 'a': ['aw', 'aa'], 'u': ['uw'], 'e': ['ee'], 'd': ['dd']}.items():
        i = order.index('hoa-' + base)
        assert order[i + 1:i + 1 + len(vs)] == ['hoa-' + v for v in vs]


def test_labels_and_speech(glyphs):
    for g in glyphs:
        c = ch(g)
        assert g['label'] == 'Chữ %s hoa' % c
        assert g['speech'] == 'chữ %s hoa' % letters.SOUND[c.lower()]
        assert 'context' not in g


def test_heights(glyphs):
    for g in glyphs:
        pts = body_points(g)
        above = (BASELINE - min(p[1] for p in pts)) / CELL
        below = (max(p[1] for p in pts) - BASELINE) / CELL
        assert abs(above - 5) <= 0.35, (g['id'], above)
        assert abs(below - BELOW.get(ch(g), 0)) <= 0.45, (g['id'], below)


def test_strokes_and_extras(glyphs):
    for g in glyphs:
        c = ch(g)
        assert len(g['strokes']) == STROKES[c], c
        extra = EXTRA.get(c, 0)
        assert len(g['strokes']) - g['body'] == extra, c
        if extra and c != 'Đ':
            # Diacritics sit above the letter (the horn may touch it).
            last = g['strokes'][-1]
            body_top = min(p[1] for p in body_points(g))
            assert min(p[1] for p in last) < body_top - 0.25 * CELL, c
        if c == 'Đ':
            bar = g['strokes'][-1]
            assert abs(bar[0][1] - bar[-1][1]) < 1e-6 and bar[-1][0] > bar[0][0]


def test_window_contains_glyph_on_grid(glyphs):
    for g in glyphs:
        x, y, side = g['ruling']['window']
        assert 0 <= x and 0 <= y and x + side <= 1 + 1e-9 and y + side <= 1 + 1e-9, g['id']
        m = 0.5 * CELL - 1e-6
        for px, py in (p for s in g['strokes'] for p in s):
            assert x + m <= px <= x + side - m, g['id']
            assert y + m <= py <= y + side - m, g['id']
        for v in (x, y, side):
            assert abs(v / CELL - round(v / CELL)) < 1e-3, g['id']


def test_smooth_points(glyphs):
    for g in glyphs:
        for s in g['strokes']:
            assert len(s) >= 2, g['id']
            for a, b in zip(s, s[1:]):
                assert math.hypot(b[0] - a[0], b[1] - a[1]) <= 0.02, g['id']


def test_no_two_capitals_share_a_shape(glyphs):
    # Rough check: different letters must not have the same strokes.
    seen = {}
    for g in glyphs:
        key = tuple(tuple((round(x, 2), round(y, 2)) for x, y in s[::8]) for s in g['strokes'])
        assert key not in seen, (g['id'], seen.get(key))
        seen[key] = g['id']


def test_make_glyphs_writes_the_capitals(tmp_path):
    subprocess.run([sys.executable, os.path.join(HERE, 'make_glyphs.py'),
                    '--out', str(tmp_path)], check=True)
    for gid in capitals.ORDER:
        with open(tmp_path / (gid + '.json'), encoding='utf-8') as f:
            data = json.load(f)
        assert list(data) == ['id', 'label', 'speech', 'ruling', 'strokes']
        assert data['id'] == gid
