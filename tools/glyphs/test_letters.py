"""Tests for the provisional lowercase letters and tone marks (phase 2A).

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
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))

import letters  # noqa: E402

CELL = 1 / 12
BASELINE = 8 / 12

ORDER = ('chu-i chu-t chu-u chu-uw chu-n chu-m chu-v chu-r chu-s chu-o chu-oo '
         'chu-ow chu-c chu-x chu-e chu-ee chu-a chu-aw chu-aa chu-d chu-dd chu-q '
         'chu-l chu-b chu-h chu-k chu-g chu-y chu-p dau-huyen dau-sac dau-nang '
         'dau-hoi dau-nga').split()

LETTER = {'i': 'i', 't': 't', 'u': 'u', 'uw': 'ư', 'n': 'n', 'm': 'm', 'v': 'v',
          'r': 'r', 's': 's', 'o': 'o', 'oo': 'ô', 'ow': 'ơ', 'c': 'c', 'x': 'x',
          'e': 'e', 'ee': 'ê', 'a': 'a', 'aw': 'ă', 'aa': 'â', 'd': 'd', 'dd': 'đ',
          'q': 'q', 'l': 'l', 'b': 'b', 'h': 'h', 'k': 'k', 'g': 'g', 'y': 'y',
          'p': 'p'}

SOUND = {'a': 'a', 'ă': 'á', 'â': 'ớ', 'b': 'bờ', 'c': 'cờ', 'd': 'dờ', 'đ': 'đờ',
         'e': 'e', 'ê': 'ê', 'g': 'gờ', 'h': 'hờ', 'i': 'i', 'k': 'ca', 'l': 'lờ',
         'm': 'mờ', 'n': 'nờ', 'o': 'o', 'ô': 'ô', 'ơ': 'ơ', 'p': 'pờ', 'q': 'quờ',
         'r': 'rờ', 's': 'sờ', 't': 'tờ', 'u': 'u', 'ư': 'ư', 'v': 'vờ', 'x': 'xờ',
         'y': 'i dài'}

MARKS = {'dau-huyen': 'Dấu huyền', 'dau-sac': 'Dấu sắc', 'dau-nang': 'Dấu nặng',
         'dau-hoi': 'Dấu hỏi', 'dau-nga': 'Dấu ngã'}

# Ô li above / below the baseline.
HEIGHTS = {}
for _l in 'a ă â c e ê i m n o ô ơ u ư v x'.split():
    HEIGHTS[_l] = (2, 0)
HEIGHTS.update({'r': (2.5, 0), 's': (2.5, 0), 't': (3, 0), 'd': (4, 0), 'đ': (4, 0),
                'b': (5, 0), 'h': (5, 0), 'k': (5, 0), 'l': (5, 0),
                'g': (2, 3), 'y': (2, 3), 'p': (2, 2), 'q': (2, 2)})

# Pen-down runs of the 2002 model as read for this generator:
# "rê bút" (pen stays on paper) joins parts, "lia bút" (pen lifted) splits them.
# Dots, bars, diacritics and tone marks are separate strokes after the body.
STROKES = {
    'i': 2, 't': 2, 'u': 1, 'ư': 2, 'n': 1, 'm': 1, 'v': 1, 'r': 1, 's': 1,
    'o': 1, 'ô': 2, 'ơ': 2, 'c': 1, 'x': 2, 'e': 1, 'ê': 2,
    'a': 2, 'ă': 3, 'â': 3, 'd': 2, 'đ': 3, 'q': 2,
    'l': 1, 'b': 1, 'h': 1, 'k': 1, 'g': 2, 'y': 1, 'p': 1,
}
# How many trailing strokes are dot / bar / diacritic (not part of the body).
EXTRA = {'i': 1, 't': 1, 'đ': 1, 'ă': 1, 'â': 1, 'ê': 1, 'ô': 1, 'ơ': 1, 'ư': 1}

OLD_IDS = ['net-ngang', 'net-thang-dung', 'net-xien', 'net-cong', 'net-moc'] + [
    'so-%d' % i for i in range(10)]


@pytest.fixture(scope='module')
def glyphs():
    return letters.letters()


def by_id(glyphs):
    return {g['id']: g for g in glyphs}


def test_ids_and_labels(glyphs):
    assert [g['id'] for g in glyphs] == ORDER
    for g in glyphs:
        if g['id'].startswith('chu-'):
            ch = LETTER[g['id'][4:]]
            assert g['label'] == 'Chữ ' + ch
            assert g['speech'] == 'chữ ' + SOUND[ch]
            assert 'context' not in g
        else:
            assert g['label'] == MARKS[g['id']]
            assert g['speech'] == g['label'][0].lower() + g['label'][1:]
            assert g['context'] == 'chu-a'
        assert g['ruling']['cell'] == 0.083333
        assert g['ruling']['baseline'] == 0.666667


def body_points(g):
    return [p for s in g['strokes'][:g['body']] for p in s]


def test_heights(glyphs):
    for g in glyphs:
        if not g['id'].startswith('chu-'):
            continue
        ch = LETTER[g['id'][4:]]
        pts = body_points(g)
        above = (BASELINE - min(p[1] for p in pts)) / CELL
        below = (max(p[1] for p in pts) - BASELINE) / CELL
        want_above, want_below = HEIGHTS[ch]
        assert abs(above - want_above) <= 0.3, (ch, above)
        assert abs(below - want_below) <= 0.3, (ch, below)


def test_separate_strokes_come_last(glyphs):
    for g in glyphs:
        if not g['id'].startswith('chu-'):
            continue
        ch = LETTER[g['id'][4:]]
        assert len(g['strokes']) == STROKES[ch], ch
        extra = EXTRA.get(ch, 0)
        assert len(g['strokes']) - g['body'] == extra, ch
        if extra:
            assert len(g['strokes']) >= 2
            body = body_points(g)
            body_top = min(p[1] for p in body)
            last = g['strokes'][-1]
            if ch in ('t', 'đ'):
                # The bar crosses the stem: horizontal, drawn left to right.
                assert abs(last[0][1] - last[-1][1]) < 1e-6
                assert last[-1][0] > last[0][0]
            else:
                # Dot and diacritics sit above the body (ư/ơ horn may touch it).
                assert min(p[1] for p in last) < body_top - 0.25 * CELL, ch
    marks = by_id(glyphs)
    for mid in MARKS:
        assert len(marks[mid]['strokes']) == 1
        assert marks[mid]['body'] == 0


def test_marks_placed_on_context(glyphs):
    a = by_id(glyphs)['chu-a']
    a_top = min(p[1] for p in body_points(a))
    a_bottom = max(p[1] for p in body_points(a))
    xs = [p[0] for p in body_points(a)]
    for mid in MARKS:
        pts = by_id(glyphs)[mid]['strokes'][0]
        cx = sum(p[0] for p in pts) / len(pts)
        assert min(xs) < cx < max(xs), mid
        if mid == 'dau-nang':
            assert min(p[1] for p in pts) > a_bottom
        else:
            # Within 1.5 ô li above the top of "a", not touching it.
            assert max(p[1] for p in pts) < a_top
            assert min(p[1] for p in pts) >= a_top - 1.5 * CELL - 1e-9


def test_window_contains_glyph(glyphs):
    ids = by_id(glyphs)
    for g in glyphs:
        x, y, side = g['ruling']['window']
        assert side >= 3 * CELL - 1e-9
        assert 0 <= x and 0 <= y and x + side <= 1 + 1e-9 and y + side <= 1 + 1e-9
        pts = [p for s in g['strokes'] for p in s]
        if 'context' in g:
            pts += [p for s in ids[g['context']]['strokes'] for p in s]
        m = 0.5 * CELL - 1e-6
        for px, py in pts:
            assert x + m <= px <= x + side - m, (g['id'], px)
            assert y + m <= py <= y + side - m, (g['id'], py)


def test_window_is_tight(glyphs):
    # Design §6b: window = glyph (+ context) + ~0.5 ô li margin, so small
    # letters fill the pad instead of floating in a 5-ô-li window. One extra
    # ô li is allowed for landing on the grid.
    ids = by_id(glyphs)
    for g in glyphs:
        pts = [p for s in g['strokes'] for p in s]
        if 'context' in g:
            pts += [p for s in ids[g['context']]['strokes'] for p in s]
        w = (max(p[0] for p in pts) - min(p[0] for p in pts)) / CELL
        h = (max(p[1] for p in pts) - min(p[1] for p in pts)) / CELL
        side = g['ruling']['window'][2] / CELL
        assert side <= max(3, math.ceil(max(w, h) + 1 - 1e-3)) + 1 + 1e-3, (g['id'], side)
    for key in 'a c e n o u v x'.split():
        assert abs(ids['chu-' + key]['ruling']['window'][2] / CELL - 4) < 1e-4, key


def test_window_on_grid(glyphs):
    # Whole ô li so the pad's ruling lines land on the baseline.
    for g in glyphs:
        for v in g['ruling']['window']:
            assert abs(v / CELL - round(v / CELL)) < 1e-3, g['id']


def test_smooth_points(glyphs):
    for g in glyphs:
        for s in g['strokes']:
            for a, b in zip(s, s[1:]):
                assert math.hypot(b[0] - a[0], b[1] - a[1]) <= 0.02, g['id']


def test_json_files(tmp_path):
    subprocess.run([sys.executable, os.path.join(HERE, 'make_glyphs.py'),
                    '--out', str(tmp_path)], check=True)
    names = sorted(os.listdir(tmp_path))
    assert len(names) == 49
    for gid in ORDER:
        with open(tmp_path / (gid + '.json'), encoding='utf-8') as f:
            data = json.load(f)
        keys = ['id', 'label', 'speech', 'ruling'] + (
            ['context'] if gid.startswith('dau-') else []) + ['strokes']
        assert list(data) == keys
        assert len(data['ruling']['window']) == 3
        for s in data['strokes']:
            for p in s['points']:
                assert p == [round(p[0], 4), round(p[1], 4)]


def test_old_glyphs_unchanged(tmp_path):
    subprocess.run([sys.executable, os.path.join(HERE, 'make_glyphs.py'),
                    '--out', str(tmp_path)], check=True)
    for gid in OLD_IDS:
        committed = subprocess.run(
            ['git', 'show', 'HEAD:assets/glyphs/%s.json' % gid], cwd=REPO,
            check=True, capture_output=True).stdout
        with open(tmp_path / (gid + '.json'), 'rb') as f:
            assert f.read() == committed, gid
