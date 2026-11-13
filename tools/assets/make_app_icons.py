"""Builds the iOS and Android launcher icons from one square character render.

Usage: python3 tools/assets/make_app_icons.py [source_image]
Run from the repository root. Writes:
  ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png  (opaque, per Contents.json)
  android/app/src/main/res/mipmap-*/ic_launcher.png     (legacy, opaque)
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (adaptive, transparent)
  android/app/src/main/res/mipmap-*/ic_launcher_background.png (adaptive)
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from cut_sheet import cutout  # noqa: E402

DEFAULT_SOURCE = "docs/superpowers/specs/assets/generated/app-icon-source.webp"
# Warm cream centre fading to soft peach: the orange scarf stays visible.
BG_CENTER = (255, 248, 236)
BG_EDGE = (250, 214, 170)
MASTER = 1024
ANDROID_DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def background(n: int) -> Image.Image:
    im = Image.new("RGB", (n, n), BG_EDGE)
    d = ImageDraw.Draw(im)
    cy = n * 0.42
    for r in range(n, 0, -2):
        t = r / n
        col = tuple(int(BG_CENTER[i] * (1 - t) + BG_EDGE[i] * t) for i in range(3))
        d.ellipse((n / 2 - r, cy - r, n / 2 + r, cy + r), fill=col)
    return im


def scaled(bird: Image.Image, height: int) -> Image.Image:
    s = height / bird.height
    return bird.resize((round(bird.width * s), round(bird.height * s)), Image.LANCZOS)


def full_icon(bird: Image.Image) -> Image.Image:
    """Bird standing on the bottom edge, filling most of the square."""
    im = background(MASTER)
    b = scaled(bird, int(MASTER * 0.84))
    im.paste(b, ((MASTER - b.width) // 2 + 10, MASTER - b.height), b)
    return im


def adaptive_foreground(bird: Image.Image) -> Image.Image:
    """Same framing as [full_icon] inside the 72dp visible area of the 108dp
    adaptive layer. The render is cut off at the bottom, so the bird runs on
    to the layer's bottom edge instead of floating."""
    im = Image.new("RGBA", (MASTER, MASTER), (0, 0, 0, 0))
    visible = MASTER * 72 / 108
    margin = (MASTER - visible) / 2
    b = scaled(bird, int(visible * 0.84 + margin))
    im.paste(b, ((MASTER - b.width) // 2 + 7, MASTER - b.height), b)
    return im


def main() -> None:
    src = Path(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCE)
    rgb = Image.open(src).convert("RGB")
    bird = cutout(rgb, (0, 0, rgb.width, rgb.height))
    bird = bird.crop(bird.getbbox())

    icon = full_icon(bird)

    ios = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
    for entry in json.loads((ios / "Contents.json").read_text())["images"]:
        name = entry.get("filename")
        if not name:
            continue
        pts = float(entry["size"].split("x")[0])
        px = round(pts * int(entry["scale"].rstrip("x")))
        icon.resize((px, px), Image.LANCZOS).save(ios / name)

    res = Path("android/app/src/main/res")
    fg = adaptive_foreground(bird)
    bg = background(MASTER)
    for density, k in ANDROID_DENSITIES.items():
        d = res / f"mipmap-{density}"
        d.mkdir(exist_ok=True)
        icon.resize((round(48 * k),) * 2, Image.LANCZOS).save(d / "ic_launcher.png")
        layer = round(108 * k)
        fg.resize((layer, layer), Image.LANCZOS).save(d / "ic_launcher_foreground.png")
        bg.resize((layer, layer), Image.LANCZOS).save(d / "ic_launcher_background.png")
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    print("icons written")


if __name__ == "__main__":
    main()
