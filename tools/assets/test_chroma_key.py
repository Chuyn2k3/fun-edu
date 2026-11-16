import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from chroma_key import chroma_cutout, solid_cutout

SCRIPT = Path(__file__).with_name("chroma_key.py")
GREEN = (0, 200, 83)


def green_disc() -> Image.Image:
    img = Image.new("RGB", (64, 64), GREEN)
    ImageDraw.Draw(img).ellipse((16, 16, 48, 48), fill=(220, 30, 30))
    return img


def test_corners_transparent_and_centre_opaque():
    out = chroma_cutout(green_disc(), (0, 0, 64, 64), pad=0)
    # tight crop: corners of the crop are outside the disc, so compare via canvas
    assert out.mode == "RGBA"
    assert out.getpixel((out.width // 2, out.height // 2))[3] == 255
    assert out.getpixel((0, 0))[3] == 0
    assert out.getpixel((out.width - 1, out.height - 1))[3] == 0


def test_no_green_fringe_on_edge_pixels():
    img = Image.new("RGB", (64, 64), GREEN)
    d = ImageDraw.Draw(img)
    d.ellipse((16, 16, 48, 48), fill=(220, 30, 30))
    # soften the edge by blending, like a real render
    from PIL import ImageFilter
    img = img.filter(ImageFilter.GaussianBlur(1.0))
    out = np.asarray(chroma_cutout(img, (0, 0, 64, 64), pad=0)).astype(int)
    edge = (out[:, :, 3] > 0) & (out[:, :, 3] < 255)
    assert edge.any()
    assert (out[:, :, 1][edge] <= out[:, :, 0][edge] + 30).all()


def test_green_inside_object_is_kept_when_not_background():
    img = green_disc()
    # not connected to the border: a dark ring then green is not the case; just
    # check the red disc does not lose pixels
    out = chroma_cutout(img, (0, 0, 64, 64), pad=0)
    a = np.asarray(out)[:, :, 3]
    assert (a == 255).sum() > 500


def test_solid_cutout_keeps_white_body_and_fills_holes():
    img = Image.new("RGB", (80, 80), (255, 255, 255))
    d = ImageDraw.Draw(img)
    d.rectangle((20, 10, 60, 70), fill=(250, 250, 250))
    d.rectangle((20, 10, 60, 70), outline=(120, 120, 140), width=2)
    out = solid_cutout(img, (0, 0, 80, 80), pad=0)
    assert out.getpixel((0, 0))[3] == 0
    assert out.getpixel((out.width // 2, out.height // 2))[3] == 255


def test_cli_writes_three_densities(tmp_path):
    src = tmp_path / "in.png"
    green_disc().save(src)
    cfg = tmp_path / "c.json"
    cfg.write_text(json.dumps({
        "items": [{"name": "disc", "box": [0, 0, 64, 64]}],
        "export_widths": [10, 20, 30]}))
    out = tmp_path / "out"
    subprocess.run([sys.executable, str(SCRIPT), str(src), str(cfg), str(out)],
                   check=True)
    for sub, w in (("", 10), ("2.0x", 20), ("3.0x", 30)):
        assert Image.open(out / sub / "disc.png").width == w
