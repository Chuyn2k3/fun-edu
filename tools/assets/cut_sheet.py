#!/usr/bin/env python3
"""Cut Gemini-generated images (white background, optionally grid sheets) into
transparent PNGs with soft shadows, exported at Flutter's 1x/2.0x/3.0x densities.

Usage: python3 cut_sheet.py <image> <config.json> <out_dir>

Config: {"items": [{"name": "chip-joy", "box": [l, t, r, b]}],
         "export_widths": [w1x, w2x, w3x]}
Output: <out>/<name>.png (w1x), <out>/2.0x/<name>.png, <out>/3.0x/<name>.png
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

FILL_MARKER = (255, 0, 255)
SHADOW_RGB = (90, 70, 56)
SHADOW_MAX_ALPHA = 150
DENSITY_DIRS = ("", "2.0x", "3.0x")  # Flutter: base, 2.0x/, 3.0x/


def _flood_from_edges(rgb: Image.Image, thr: int) -> None:
    """Flood-fill the background in place, seeding from bright edge points."""
    w, h = rgb.size
    seeds = [(x, y) for x in range(0, w, 6) for y in (0, h - 1)]
    seeds += [(x, y) for y in range(0, h, 6) for x in (0, w - 1)]
    for pt in seeds:
        if min(rgb.getpixel(pt)) >= thr and rgb.getpixel(pt) != FILL_MARKER:
            ImageDraw.floodfill(rgb, pt, FILL_MARKER, thresh=22)


def _soften_shadow(rgba: Image.Image) -> Image.Image:
    """Turn near-white, low-saturation pixels in the bottom 30% into a soft shadow."""
    r = np.asarray(rgba).astype(float)
    rgb = r[:, :, :3]
    lum = rgb.mean(axis=2)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    in_bottom = np.arange(r.shape[0])[:, None] >= r.shape[0] * 0.70
    shadow = in_bottom & (sat < 14) & (lum > 185) & (r[:, :, 3] > 0)
    shadow_alpha = np.clip((255 - lum) * 3.2, 0, SHADOW_MAX_ALPHA) * r[:, :, 3] / 255
    r[:, :, 3] = np.where(shadow, shadow_alpha, r[:, :, 3])
    r[:, :, :3] = np.where(shadow[:, :, None], np.array(SHADOW_RGB), rgb)
    return Image.fromarray(r.astype("uint8"), "RGBA")


def cutout(img: Image.Image, box: tuple, thr: int = 238) -> Image.Image:
    """Cut `box` out of `img`: transparent background, soft shadow, tight crop."""
    crop = img.crop(box).convert("RGB")
    work = crop.copy()
    _flood_from_edges(work, thr)
    arr = np.asarray(work)
    is_bg = (arr == np.array(FILL_MARKER)).all(axis=2)
    alpha = Image.fromarray(np.where(is_bg, 0, 255).astype("uint8"), "L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))
    rgba = crop.convert("RGBA")
    rgba.putalpha(alpha)
    bbox = rgba.getbbox()
    if bbox is None:
        raise ValueError("nothing left after removing the background")
    # Crop first so "bottom 30%" is relative to the object, not the cell.
    return _soften_shadow(rgba.crop(bbox))


def _fail(msg: str) -> None:
    sys.exit(f"error: {msg}")


def _load_config(path: Path) -> dict:
    try:
        cfg = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        _fail(f"cannot read config {path}: {e}")
    widths = cfg.get("export_widths")
    if not (isinstance(widths, list) and len(widths) == 3
            and all(isinstance(w, int) and w > 0 for w in widths)):
        _fail("export_widths must be exactly 3 positive integers (1x, 2.0x, 3.0x)")
    if not isinstance(cfg.get("items"), list):
        _fail("config needs an 'items' list")
    return cfg


def run(image_path: Path, config_path: Path, out_dir: Path) -> None:
    if not image_path.is_file():
        _fail(f"image not found: {image_path}")
    cfg = _load_config(config_path)
    try:
        sheet = Image.open(image_path)
        sheet.load()
    except OSError as e:
        _fail(f"cannot open image {image_path}: {e}")
    sw, sh = sheet.size
    for item in cfg["items"]:
        name, box = item.get("name"), item.get("box")
        if not name or not (isinstance(box, list) and len(box) == 4):
            _fail(f"bad item {item!r}: needs 'name' and 4-number 'box'")
        l, t, r, b = box
        if not (0 <= l < r <= sw and 0 <= t < b <= sh):
            _fail(f"item '{name}': box {box} is outside the image ({sw}x{sh})")
        try:
            cut = cutout(sheet, tuple(box))
        except ValueError as e:
            _fail(f"item '{name}': {e}")
        for sub, width in zip(DENSITY_DIRS, cfg["export_widths"]):
            height = max(1, round(cut.height * width / cut.width))
            dest = out_dir / sub / f"{name}.png"
            dest.parent.mkdir(parents=True, exist_ok=True)
            cut.resize((width, height), Image.LANCZOS).save(dest, optimize=True)
        print(f"{name}: {cut.size} -> {cfg['export_widths']}")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("image", type=Path)
    p.add_argument("config", type=Path)
    p.add_argument("out_dir", type=Path)
    a = p.parse_args()
    run(a.image, a.config, a.out_dir)


if __name__ == "__main__":
    main()
