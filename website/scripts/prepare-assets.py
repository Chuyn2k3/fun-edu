"""Cuts Nunito down to Latin + Vietnamese (WOFF2) and turns the app's PNG
art into small WebP files (needs `pip install fonttools brotli pillow`)."""
import os
import sys

from fontTools import subset
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.join(HERE, "..", "..")
OUT = os.path.join(HERE, "..", "public", "generated", "fonts")
UNICODES = ("U+0000-00FF,U+0102-0103,U+0110-0111,U+0128-0129,U+0168-0169,"
            "U+01A0-01B0,U+1EA0-1EF9,U+20AB,U+2013-2014,U+2018-201D,U+2026")
os.makedirs(OUT, exist_ok=True)
for src, name in [("Nunito-Bold.ttf", "nunito-bold"), ("Nunito-ExtraBold.ttf", "nunito-extrabold")]:
    subset.main([
        os.path.join(REPO, "assets", "fonts", src),
        f"--unicodes={UNICODES}",
        "--flavor=woff2",
        "--layout-features=*",
        f"--output-file={os.path.join(OUT, name + '.woff2')}",
    ])
print("fonts:", sorted(os.listdir(OUT)), file=sys.stderr)

IMG_OUT = os.path.join(HERE, "..", "public", "generated", "img")
os.makedirs(IMG_OUT, exist_ok=True)
# name -> (source, width in px at 2x)
IMAGES = {
    "chip-main": ("2.0x/chip-main.png", 360),
    "chip-joy": ("2.0x/chip-joy.png", 240),
    "chip-encourage": ("2.0x/chip-encourage.png", 240),
    "chip-thumb": ("2.0x/chip-thumb.png", 240),
    "ic-star": ("2.0x/ic-star.png", 120),
    "logo": ("logo.png", 192),
}
for name, (src, width) in IMAGES.items():
    with Image.open(os.path.join(REPO, "assets", "images", src)) as im:
        im = im.convert("RGBA")
        h = round(im.height * width / im.width)
        im.resize((width, h), Image.LANCZOS).save(
            os.path.join(IMG_OUT, name + ".webp"), "WEBP", quality=82, method=6)
print("images:", sorted(os.listdir(IMG_OUT)), file=sys.stderr)
