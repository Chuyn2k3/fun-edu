import json
import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest
from PIL import Image

from cut_sheet import cutout

SCRIPT = Path(__file__).with_name("cut_sheet.py")
SHADOW_COLOR = (90, 70, 56)


def make_image() -> Image.Image:
    """200x200 white; red 60x60 square with a white hole; light-grey streak below."""
    img = Image.new("RGB", (200, 200), (255, 255, 255))
    px = img.load()
    for x in range(70, 130):
        for y in range(60, 120):
            px[x, y] = (220, 30, 30)
    for x in range(95, 105):  # 10x10 white hole at the square's center
        for y in range(85, 95):
            px[x, y] = (255, 255, 255)
    for x in range(75, 125):  # grey streak 50x6 right under the square
        for y in range(120, 126):
            px[x, y] = (230, 230, 230)
    return img


@pytest.fixture
def result() -> Image.Image:
    return cutout(make_image(), (0, 0, 200, 200))


def test_background_is_transparent_and_object_opaque(result):
    assert result.mode == "RGBA"
    assert result.getpixel((0, 0))[3] == 0
    assert result.getpixel((result.width - 1, result.height - 1))[3] == 0
    cx, cy = 30, 20  # inside the square (not the hole): crop origin is (70, 60)
    assert result.getpixel((cx, cy)) == (220, 30, 30, 255)


def test_output_is_tightly_cropped(result):
    assert 60 <= result.width <= 70


def test_grey_streak_becomes_soft_shadow(result):
    # Streak spans rows 120-126 of the source; crop top is y=60.
    a = np.asarray(result)
    shadow = (a[:, :, :3] == SHADOW_COLOR).all(axis=2) & (a[:, :, 3] > 0)
    assert shadow.any()
    assert a[:, :, 3][shadow].min() >= 1
    assert a[:, :, 3][shadow].max() <= 150
    # center of the streak: x=100 -> 30, y=123 -> 63
    r, g, b, al = result.getpixel((30, 63))
    assert (r, g, b) == SHADOW_COLOR
    assert 1 <= al <= 150


def test_enclosed_white_stays_opaque(result):
    # hole center (100, 90) -> (30, 30)
    assert result.getpixel((30, 30)) == (255, 255, 255, 255)


def run_cli(*args):
    return subprocess.run([sys.executable, str(SCRIPT), *map(str, args)],
                          capture_output=True, text=True)


def test_cli_exports_three_densities(tmp_path):
    src = tmp_path / "sheet.png"
    make_image().save(src)
    cfg = tmp_path / "cfg.json"
    cfg.write_text(json.dumps({
        "items": [{"name": "thing", "box": [0, 0, 200, 200]}],
        "export_widths": [120, 240, 360],
    }))
    out = tmp_path / "out"
    proc = run_cli(src, cfg, out)
    assert proc.returncode == 0, proc.stderr
    for sub, width in (("", 120), ("2.0x", 240), ("3.0x", 360)):
        p = out / sub / "thing.png"
        assert p.exists(), p
        assert Image.open(p).width == width


def test_cli_missing_image_fails(tmp_path):
    cfg = tmp_path / "cfg.json"
    cfg.write_text(json.dumps({"items": [], "export_widths": [1, 2, 3]}))
    proc = run_cli(tmp_path / "nope.png", cfg, tmp_path / "out")
    assert proc.returncode != 0
    assert "nope.png" in proc.stderr


def test_cli_box_outside_image_fails(tmp_path):
    src = tmp_path / "sheet.png"
    make_image().save(src)
    cfg = tmp_path / "cfg.json"
    cfg.write_text(json.dumps({
        "items": [{"name": "bad", "box": [0, 0, 500, 500]}],
        "export_widths": [120, 240, 360],
    }))
    proc = run_cli(src, cfg, tmp_path / "out")
    assert proc.returncode != 0
    assert "bad" in proc.stderr


def test_cli_requires_three_widths(tmp_path):
    src = tmp_path / "sheet.png"
    make_image().save(src)
    cfg = tmp_path / "cfg.json"
    cfg.write_text(json.dumps({
        "items": [{"name": "a", "box": [0, 0, 200, 200]}],
        "export_widths": [120, 240],
    }))
    proc = run_cli(src, cfg, tmp_path / "out")
    assert proc.returncode != 0
    assert "export_widths" in proc.stderr
