#!/usr/bin/env python3
"""Cut flat-background Gemini renders into transparent PNGs (1x/2.0x/3.0x).

Two modes, same CLI shape as cut_sheet.py:
  chroma  (default) background is a flat green (#00C853-ish): flood the green
          from the edges, soften the edge, despill the green fringe.
  solid   background is white but the object itself has white parts (a white
          rocket): everything that is not near-white is the object, small gaps
          are closed and enclosed holes are filled.

Usage: python3 chroma_key.py <image> <config.json> <out_dir>

Config: {"items": [{"name": "badge-pilot", "box": [l, t, r, b],
                    "mode": "chroma"|"solid", "key_dist": 90, "trim_shadow": false|"run"|"band",
                    "min_hole": 40}],
         "export_widths": [w1x, w2x, w3x]}
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

DENSITY_DIRS = ("", "2.0x", "3.0x")
KEY_DIST = 90       # colour distance (L1) still counted as background
SEED_STEP = 8


def _seeds(w: int, h: int):
    for x in range(0, w, SEED_STEP):
        yield x, 0
        yield x, h - 1
    for y in range(0, h, SEED_STEP):
        yield 0, y
        yield w - 1, y


def _edge_connected(candidate: np.ndarray) -> np.ndarray:
    """Pixels of `candidate` (bool) connected to the image border."""
    h, w = candidate.shape
    m = Image.fromarray(np.where(candidate, 255, 0).astype("uint8"), "L").copy()
    for pt in _seeds(w, h):
        if m.getpixel(pt) == 255:
            ImageDraw.floodfill(m, pt, 128)
    return np.asarray(m) == 128


def _big_holes(inner: np.ndarray, min_area: int) -> np.ndarray:
    """Background seen through the object (e.g. inside a ring): enclosed
    background-coloured regions of at least `min_area` pixels."""
    work = Image.fromarray(np.where(inner, 255, 0).astype("uint8"), "L").copy()
    out = np.zeros(inner.shape, bool)
    for _ in range(100):
        pts = np.argwhere(np.asarray(work) == 255)
        if not len(pts):
            break
        y, x = pts[0]
        ImageDraw.floodfill(work, (int(x), int(y)), 1)
        region = np.asarray(work) == 1
        if region.sum() >= min_area:
            out |= region
        ImageDraw.floodfill(work, (int(x), int(y)), 2)  # mark as visited
    return out


def _corner_colour(arr: np.ndarray) -> np.ndarray:
    h, w, _ = arr.shape
    k = max(2, min(h, w) // 40)
    patches = [arr[:k, :k], arr[:k, -k:], arr[-k:, :k], arr[-k:, -k:]]
    return np.median(np.concatenate([p.reshape(-1, 3) for p in patches]), axis=0)


def _bleed(rgb: np.ndarray, known: np.ndarray, steps: int = 6) -> np.ndarray:
    """Fill unknown pixels' colour from known neighbours (so the soft alpha edge
    never shows the background colour)."""
    rgb = rgb.copy()
    known = known.copy()
    for _ in range(steps):
        acc = np.zeros_like(rgb)
        cnt = np.zeros(known.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            k = np.roll(known, (dy, dx), (0, 1))
            c = np.roll(rgb, (dy, dx), (0, 1))
            acc += c * k[:, :, None]
            cnt += k
        fill = ~known & (cnt > 0)
        rgb[fill] = acc[fill] / cnt[fill][:, None]
        known |= fill
    return rgb


def _finish(rgb: np.ndarray, is_bg: np.ndarray, despill_ref, pad: int) -> Image.Image:
    alpha = Image.fromarray(np.where(is_bg, 0, 255).astype("uint8"), "L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.0))
    out = rgb.astype(float)
    if despill_ref is not None:
        # Edge band, 4 px wide, just inside the object: pull the key colour out.
        band = np.asarray(
            Image.fromarray(np.where(is_bg, 255, 0).astype("uint8"), "L")
            .filter(ImageFilter.MaxFilter(9))) > 0
        close = np.abs(out - despill_ref).sum(axis=2) < 200
        fix = band & ~is_bg & close
        cap = np.maximum(out[:, :, 0], out[:, :, 2])
        out[:, :, 1] = np.where(fix, np.minimum(out[:, :, 1], cap), out[:, :, 1])
    out = _bleed(out, ~is_bg)
    rgba = Image.fromarray(out.astype("uint8"), "RGB").convert("RGBA")
    rgba.putalpha(alpha)
    bbox = rgba.getbbox()
    if bbox is None:
        raise ValueError("nothing left after removing the background")
    l, t, r, b = bbox
    rgba = rgba.crop((max(0, l - pad), max(0, t - pad),
                      min(rgba.width, r + pad), min(rgba.height, b + pad)))
    return rgba


def chroma_cutout(img: Image.Image, box: tuple, pad: int = 0,
                  key_dist: int = KEY_DIST,
                  min_hole: int | None = None) -> Image.Image:
    """Transparent-background cutout of `box` from a flat-colour background.

    Background seen through the object (inside a ring or a swirl) is removed
    when the enclosed patch has at least `min_hole` pixels; the default is
    max(200, area / 2500), so small green details of the art survive. Lower
    it per item when a small enclosed patch of key is left behind.
    """
    rgb = np.asarray(img.crop(box).convert("RGB")).astype(float)
    bg = _corner_colour(rgb)
    dist = np.abs(rgb - bg).sum(axis=2)
    cand = dist < key_dist
    if bg.max() - bg.min() > 100:
        # Strongly coloured key: its shadow is the same hue, only darker.
        g = np.maximum(rgb[:, :, 1], 1.0)
        chroma = np.abs(rgb[:, :, 0] / g - bg[0] / bg[1]) + np.abs(
            rgb[:, :, 2] / g - bg[2] / bg[1])
        cand |= (chroma < 0.12) & (rgb[:, :, 1] > 35)
        loose = ((chroma < 0.18) & (rgb[:, :, 1] > 35)) | (
            (rgb[:, :, 0] < 0.12 * g) & (rgb[:, :, 1] > 25) & (rgb[:, :, 1] < 110))
    is_bg = _edge_connected(cand)
    area = min_hole if min_hole is not None else max(200, cand.size // 2500)
    is_bg |= _big_holes(cand & ~is_bg, min_area=area)
    if bg.max() - bg.min() > 100:
        # Green slivers hugging the outline: same hue as the key, close to it.
        for _ in range(4):
            near = np.asarray(Image.fromarray(
                np.where(is_bg, 255, 0).astype("uint8"), "L")
                .filter(ImageFilter.MaxFilter(13))) > 0
            is_bg |= near & loose
    return _finish(rgb, is_bg, bg, pad)


def solid_cutout(img: Image.Image, box: tuple, pad: int = 0,
                 thr: int = 236) -> Image.Image:
    """Cutout for objects with white parts: mask = not near-white, closed+filled."""
    rgb = np.asarray(img.crop(box).convert("RGB")).astype(float)
    obj = rgb.min(axis=2) < thr
    m = Image.fromarray(np.where(obj, 255, 0).astype("uint8"), "L")
    m = m.filter(ImageFilter.MaxFilter(11)).filter(ImageFilter.MinFilter(11))
    closed = np.asarray(m) > 0
    is_bg = _edge_connected(~closed)  # anything not reachable from outside = object
    return _finish(rgb, is_bg, None, pad)


def keep_main_parts(rgba: Image.Image, min_frac: float = 0.02) -> Image.Image:
    """Drop stray specks/streaks: keep opaque parts at least `min_frac` of the
    largest one (soft edges of kept parts are preserved)."""
    alpha = np.asarray(rgba)[:, :, 3]
    solid = Image.fromarray(np.where(alpha > 40, 255, 0).astype("uint8"), "L").copy()
    sizes = {}
    label = 0
    while True:
        pts = np.argwhere(np.asarray(solid) == 255)
        if not len(pts) or label >= 200:
            break
        label += 1
        y, x = pts[0]
        ImageDraw.floodfill(solid, (int(x), int(y)), label)
        sizes[label] = int((np.asarray(solid) == label).sum())
    biggest = max(sizes.values(), default=0)
    lab = np.asarray(solid)
    keep = np.isin(lab, [k for k, v in sizes.items() if v >= biggest * min_frac])
    keep_img = Image.fromarray(np.where(keep, 255, 0).astype("uint8"), "L")
    keep = np.asarray(keep_img.filter(ImageFilter.MaxFilter(7))) > 0
    out = np.asarray(rgba).copy()
    out[:, :, 3] = np.where(keep, out[:, :, 3], 0)
    res = Image.fromarray(out, "RGBA")
    bbox = res.getbbox()
    return res.crop(bbox) if bbox else res


def _run_shadow(sat: np.ndarray, lum: np.ndarray, alpha: np.ndarray,
                warm: np.ndarray, max_run: float) -> np.ndarray:
    """Per column, from the bottom up: the run of opaque, light, low-saturation
    pixels before the first coloured one (capped at `max_run` of the height)."""
    h, w = sat.shape
    soft = (sat < 70) & (lum > 120) & (alpha > 0) & warm
    shadow = np.zeros((h, w), bool)
    alive = np.ones(w, bool)
    cap = int(h * max_run)
    steps = 0
    for y in range(h - 1, -1, -1):
        if alpha[y].max() == 0 and not shadow.any():
            continue  # empty rows under the object
        opaque = alpha[y] > 0
        alive &= ~opaque | soft[y]          # a coloured pixel ends the run
        shadow[y] = alive & opaque
        steps += 1
        if steps > cap or not alive.any():
            break
    return shadow


def trim_shadow(rgba: Image.Image, band: float = 0.12, sat_min: int = 40,
                method: str = "run", max_run: float = 0.2) -> Image.Image:
    """Remove the soft grey contact shadow under an object.

    Crop below the lowest coloured pixel, then in the bottom `band` (fraction of
    the height, measured up from that row) clear light, low-saturation pixels,
    which are the shadow; the object's own white parts sit above the band.
    """
    a = np.asarray(rgba).astype(float)
    rgb, alpha = a[:, :, :3], a[:, :, 3]
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    rows = np.where(((sat >= sat_min) & (alpha > 200)).any(axis=1))[0]
    if not rows.size:
        return rgba
    last = int(rows.max()) + 2
    a = a[:last]
    rgb, alpha, sat = rgb[:last], alpha[:last], sat[:last]
    top = last - int(last * band)
    lum = rgb.mean(axis=2)
    if method == "run":
        warm = rgb[:, :, 2] <= rgb[:, :, 0] + 10  # shadows are grey/warm, not lilac
        shadow = _run_shadow(sat, lum, alpha, warm, max_run)
        # Background that the shadow had closed off (gap between fins): it is
        # near-white and touches the shadow, so clear it too.
        white = (rgb.min(axis=2) >= 238) & (sat < 14) & (alpha > 0)
        for _ in range(400):
            grown = np.asarray(Image.fromarray(
                np.where(shadow, 255, 0).astype("uint8"), "L")
                .filter(ImageFilter.MaxFilter(3))) > 0
            grown = shadow | (grown & white)
            if grown.sum() == shadow.sum():
                break
            shadow = grown
        # Leftover pure-white specks in the bottom fifth are background too.
        shadow |= white & (np.arange(last)[:, None] >= last * 0.8)
    else:
        shadow = (np.arange(last)[:, None] >= top) & (sat < 45) & (lum > 120)
    alpha = np.where(shadow, 0, alpha)
    # Soften the cut and drop what is left of the fringe next to the shadow.
    img = Image.fromarray(alpha.astype("uint8"), "L")
    if method == "run":  # opening: thin leftover streaks of shadow disappear
        opened = img.filter(ImageFilter.MinFilter(11)).filter(ImageFilter.MaxFilter(11))
        img = Image.fromarray(np.minimum(np.asarray(img), np.asarray(opened)), "L")
    img = img.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    out = Image.fromarray(rgb.astype("uint8"), "RGB").convert("RGBA")
    out.putalpha(img)
    return keep_main_parts(out)


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
        mode = item.get("mode", "chroma")
        if mode not in ("chroma", "solid"):
            _fail(f"item '{name}': unknown mode {mode!r}")
        kw = {"key_dist": item["key_dist"]} if "key_dist" in item else {}
        if "min_hole" in item:
            if mode != "chroma" or not (isinstance(item["min_hole"], int) and item["min_hole"] > 0):
                _fail(f"item '{name}': min_hole must be a positive integer (chroma mode)")
            kw["min_hole"] = item["min_hole"]
        fn = chroma_cutout if mode == "chroma" else solid_cutout
        try:
            cut = fn(sheet, tuple(box), pad=0, **kw)
        except ValueError as e:
            _fail(f"item '{name}': {e}")
        if item.get("trim_shadow"):  # true, "run" or "band"
            how = item["trim_shadow"]
            cut = trim_shadow(cut, method=how if how in ("run", "band") else "run")
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
