"""Builds the iOS and Android launcher icons from one square, full-bleed logo.

Usage: python3 tools/assets/make_app_icons.py [source_image]
Run from the repository root. The source must be square and opaque with a
plain background colour at its edges. Writes:
  ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png   (per Contents.json)
  android/app/src/main/res/mipmap-*/ic_launcher.png      (legacy)
  android/app/src/main/res/mipmap-*/ic_launcher_background.png (adaptive)
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (adaptive, empty)
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/drawable-*/launch_logo.png    (rounded, 160dp)
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png (168pt)
  assets/images/logo.png                                 (512px, rounded)
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

DEFAULT_SOURCE = "docs/superpowers/specs/assets/generated/app-icon-source.webp"
ANDROID_DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
# Adaptive icons are 108dp and launchers show about the central 72dp; the
# logo is drawn at this size so its edges stay visible under any mask.
ADAPTIVE_LOGO_DP = 84
CORNER_RADIUS = 0.22  # fraction of the side, for the in-app and launch logo
LAUNCH_LOGO_DP = 160
LAUNCH_LOGO_IOS_PT = 168
IN_APP_LOGO_PX = 512


def edge_colour(im: Image.Image) -> tuple:
    """Median colour of the outer 8px ring, used to extend the background."""
    w, h = im.size
    px = [im.getpixel((x, y)) for x in range(0, w, 8) for y in (2, h - 3)]
    px += [im.getpixel((x, y)) for y in range(0, h, 8) for x in (2, w - 3)]
    return tuple(sorted(c[i] for c in px)[len(px) // 2] for i in range(3))


def adaptive_background(icon: Image.Image, n: int) -> Image.Image:
    bg = Image.new("RGB", (n, n), edge_colour(icon))
    s = round(n * ADAPTIVE_LOGO_DP / 108)
    logo = icon.resize((s, s), Image.LANCZOS)
    bg.paste(logo, ((n - s) // 2, (n - s) // 2))
    return bg


def rounded_logo(icon: Image.Image, n: int) -> Image.Image:
    """The icon at n x n with rounded corners, transparent outside them."""
    ss = 4  # draw the mask supersampled for smooth edges
    mask = Image.new("L", (n * ss, n * ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, n * ss - 1, n * ss - 1), radius=round(n * ss * CORNER_RADIUS), fill=255
    )
    out = icon.resize((n, n), Image.LANCZOS).convert("RGBA")
    out.putalpha(mask.resize((n, n), Image.LANCZOS))
    return out


def main() -> None:
    run(Path(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCE), Path("."))


def run(src: Path, root: Path) -> None:
    """Writes every icon and launch image under [root] (the repo root)."""
    icon = Image.open(src).convert("RGB")
    if icon.width != icon.height:
        sys.exit(f"{src}: logo must be square, got {icon.size}")

    ios = root / Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
    for entry in json.loads((ios / "Contents.json").read_text())["images"]:
        name = entry.get("filename")
        if not name:
            continue
        pts = float(entry["size"].split("x")[0])
        px = round(pts * int(entry["scale"].rstrip("x")))
        icon.resize((px, px), Image.LANCZOS).save(ios / name)

    res = root / Path("android/app/src/main/res")
    for density, k in ANDROID_DENSITIES.items():
        d = res / f"mipmap-{density}"
        d.mkdir(exist_ok=True)
        icon.resize((round(48 * k),) * 2, Image.LANCZOS).save(d / "ic_launcher.png")
        layer = round(108 * k)
        adaptive_background(icon, layer).save(d / "ic_launcher_background.png")
        Image.new("RGBA", (layer, layer), (0, 0, 0, 0)).save(
            d / "ic_launcher_foreground.png"
        )
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )

    for density, k in ANDROID_DENSITIES.items():
        d = res / f"drawable-{density}"
        d.mkdir(exist_ok=True)
        rounded_logo(icon, round(LAUNCH_LOGO_DP * k)).save(d / "launch_logo.png")

    launch = root / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for suffix, k in (("", 1), ("@2x", 2), ("@3x", 3)):
        rounded_logo(icon, LAUNCH_LOGO_IOS_PT * k).save(launch / f"LaunchImage{suffix}.png")

    images = root / "assets/images"
    images.mkdir(parents=True, exist_ok=True)
    rounded_logo(icon, IN_APP_LOGO_PX).save(images / "logo.png")
    print("icons written")


if __name__ == "__main__":
    main()
