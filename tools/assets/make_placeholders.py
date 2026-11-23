#!/usr/bin/env python3
"""Generate placeholder circular badges for animal avatars and race stickers.

Creates transparent circular PNGs in 3 densities: 1x (128x128), 2x (256x256), 3x (384x384).
CRITICAL: Never overwrites existing files so real Gemini artwork is preserved.

Usage:
    python3 tools/assets/make_placeholders.py [--avatar-dir DIR] [--game-dir DIR] [--overwrite]
"""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Dict, List, Tuple

from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

ANIMAL_AVATARS: Dict[str, Tuple[str, str, str]] = {
    # name: (bg_color, rim_color, label)
    "fox": ("#FF7043", "#D84315", "Cáo"),
    "panda": ("#455A64", "#263238", "Gấu trúc"),
    "bunny": ("#EC407A", "#C2185B", "Thỏ"),
    "tiger": ("#FFA726", "#EF6C00", "Hổ"),
    "cat": ("#FFB74D", "#F57C00", "Mèo"),
    "dog": ("#8D6E63", "#5D4037", "Cún"),
    "elephant": ("#78909C", "#455A64", "Voi"),
    "dino": ("#66BB6A", "#2E7D32", "Khủng long"),
    "owl": ("#AB47BC", "#7B1FA2", "Cú"),
    "penguin": ("#26A69A", "#00695C", "Cánh cụt"),
    "bear": ("#A1887F", "#6D4C41", "Gấu"),
    "unicorn": ("#7E57C2", "#4527A0", "Kỳ lân"),
}

TEASE_STICKERS: Dict[str, Tuple[str, str, str]] = {
    # id: (bg_color, rim_color, label)
    "bubble": ("#29B6F6", "#0288D1", "Bọt"),
    "tongue": ("#FF4081", "#C51162", "Lè lưỡi"),
    "byebye": ("#FFA726", "#F57C00", "Vẫy tay"),
    "rain": ("#42A5F5", "#1565C0", "Mưa rào"),
    "sleepy": ("#5C6BC0", "#283593", "Buồn ngủ"),
    "turtle": ("#66BB6A", "#2E7D32", "Rùa bò"),
    "smoke": ("#78909C", "#37474F", "Xì khói"),
}

PARTY_STICKER = "sticker-party"
PARTY_CONFIG = ("#FFB300", "#FF6F00", "Pháo hoa")

SCALES = [(1, 128, ""), (2, 256, "2.0x"), (3, 384, "3.0x")]


def _hex_to_rgb(hex_str: str) -> Tuple[int, int, int]:
    hex_str = hex_str.lstrip("#")
    return int(hex_str[0:2], 16), int(hex_str[2:4], 16), int(hex_str[4:6], 16)


def _draw_badge(dim: int, bg_hex: str, rim_hex: str, label: str) -> Image.Image:
    # Render at 2x super-sampling for silky smooth anti-aliased edges
    supersample = 2
    render_dim = dim * supersample
    img = Image.new("RGBA", (render_dim, render_dim), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = 4 * supersample
    rim_w = 6 * supersample
    inner_margin = margin + rim_w

    bg_rgb = _hex_to_rgb(bg_hex)
    rim_rgb = _hex_to_rgb(rim_hex)

    # Outer circle (rim)
    draw.ellipse(
        [margin, margin, render_dim - margin, render_dim - margin],
        fill=(*rim_rgb, 255),
    )

    # Inner circle (main face)
    draw.ellipse(
        [inner_margin, inner_margin, render_dim - inner_margin, render_dim - inner_margin],
        fill=(*bg_rgb, 255),
    )

    # Subtle glossy top highlight
    highlight_box = [
        inner_margin + 6 * supersample,
        inner_margin + 4 * supersample,
        render_dim - inner_margin - 6 * supersample,
        render_dim // 2,
    ]
    draw.ellipse(highlight_box, fill=(255, 255, 255, 55))

    # Font setup
    font_path = REPO_ROOT / "assets/fonts/Nunito-Black.ttf"
    font_size = int(render_dim * 0.22)
    font = None
    if font_path.exists():
        try:
            font = ImageFont.truetype(str(font_path), size=font_size)
        except Exception:
            font = None
    if font is None:
        try:
            font = ImageFont.load_default(size=font_size)
        except Exception:
            font = ImageFont.load_default()

    # Center text
    bbox = draw.textbbox((0, 0), label, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    text_x = (render_dim - text_w) / 2 - bbox[0]
    text_y = (render_dim - text_h) / 2 - bbox[1]

    # Subtle text shadow
    draw.text(
        (text_x, text_y + 2 * supersample),
        label,
        font=font,
        fill=(0, 0, 0, 80),
    )
    # Text
    draw.text(
        (text_x, text_y),
        label,
        font=font,
        fill=(255, 255, 255, 255),
    )

    # Downscale with high-quality Lanczos filter
    final_img = img.resize((dim, dim), Image.Resampling.LANCZOS)
    return final_img


def generate_placeholders(
    avatar_dir: Path,
    game_dir: Path,
    overwrite: bool = False,
) -> List[Path]:
    """Generates placeholder PNGs for avatars and stickers across 3 scales."""
    generated: List[Path] = []

    # 1. Animal avatars
    for name, (bg, rim, label) in ANIMAL_AVATARS.items():
        for scale, dim, sub in SCALES:
            target_dir = avatar_dir / sub if sub else avatar_dir
            target_file = target_dir / f"{name}.png"
            if target_file.exists() and not overwrite:
                continue
            target_dir.mkdir(parents=True, exist_ok=True)
            badge = _draw_badge(dim, bg, rim, label)
            badge.save(target_file, format="PNG")
            generated.append(target_file)

    # 2. Tease stickers
    for id_name, (bg, rim, label) in TEASE_STICKERS.items():
        for scale, dim, sub in SCALES:
            target_dir = game_dir / sub if sub else game_dir
            target_file = target_dir / f"sticker-tease-{id_name}.png"
            if target_file.exists() and not overwrite:
                continue
            target_dir.mkdir(parents=True, exist_ok=True)
            badge = _draw_badge(dim, bg, rim, label)
            badge.save(target_file, format="PNG")
            generated.append(target_file)

    # 3. Party sticker
    bg, rim, label = PARTY_CONFIG
    for scale, dim, sub in SCALES:
        target_dir = game_dir / sub if sub else game_dir
        target_file = target_dir / f"{PARTY_STICKER}.png"
        if target_file.exists() and not overwrite:
            continue
        target_dir.mkdir(parents=True, exist_ok=True)
        badge = _draw_badge(dim, bg, rim, label)
        badge.save(target_file, format="PNG")
        generated.append(target_file)

    return generated


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument(
        "--avatar-dir",
        type=Path,
        default=REPO_ROOT / "assets/images/avatars",
        help="Target directory for animal avatars",
    )
    parser.add_argument(
        "--game-dir",
        type=Path,
        default=REPO_ROOT / "assets/images/game",
        help="Target directory for game stickers",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Force overwrite existing files",
    )
    args = parser.parse_args()

    created = generate_placeholders(
        avatar_dir=args.avatar_dir,
        game_dir=args.game_dir,
        overwrite=args.overwrite,
    )
    print(f"Generated {len(created)} placeholder asset files.")


if __name__ == "__main__":
    main()
