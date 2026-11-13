import json
import sys
from pathlib import Path

from PIL import Image

import make_app_icons


def build_tree(root: Path) -> Path:
    """A temp copy of the folder layout the script writes into."""
    ios = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios.mkdir(parents=True)
    (ios / "Contents.json").write_text(
        json.dumps(
            {
                "images": [
                    {"size": "20x20", "scale": "2x", "filename": "i40.png"},
                ]
            }
        )
    )
    (root / "ios/Runner/Assets.xcassets/LaunchImage.imageset").mkdir(parents=True)
    (root / "android/app/src/main/res").mkdir(parents=True)
    (root / "assets/images").mkdir(parents=True)
    src = root / "src.png"
    Image.new("RGB", (64, 64), (254, 218, 130)).save(src)
    return src


def test_writes_launch_images_and_logo(tmp_path):
    src = build_tree(tmp_path)
    make_app_icons.run(src, tmp_path)

    res = tmp_path / "android/app/src/main/res"
    for density, px in {
        "mdpi": 160, "hdpi": 240, "xhdpi": 320, "xxhdpi": 480, "xxxhdpi": 640,
    }.items():
        f = res / f"drawable-{density}/launch_logo.png"
        assert f.exists(), f
        assert Image.open(f).size == (px, px)

    ios = tmp_path / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name, px in {
        "LaunchImage.png": 160, "LaunchImage@2x.png": 320, "LaunchImage@3x.png": 480,
    }.items():
        assert Image.open(ios / name).size == (px, px)

    logo = Image.open(tmp_path / "assets/images/logo.png")
    assert logo.size == (512, 512)
    assert logo.mode == "RGBA"
    assert logo.getpixel((0, 0))[3] == 0  # transparent outside the rounded corners
    assert logo.getpixel((256, 256))[3] == 255
