#!/usr/bin/env python3
from __future__ import annotations
import json
import subprocess
import sys
from pathlib import Path

import pytest
from PIL import Image

SCRIPT = Path(__file__).resolve().parent / "make_placeholders.py"


def test_make_placeholders_generates_all_files(tmp_path: Path):
    from make_placeholders import generate_placeholders, ANIMAL_AVATARS, TEASE_STICKERS, PARTY_STICKER

    avatar_dir = tmp_path / "avatars"
    game_dir = tmp_path / "game"

    generated = generate_placeholders(avatar_dir=avatar_dir, game_dir=game_dir)

    # 12 avatars * 3 scales + (7 + 1) stickers * 3 scales = 36 + 24 = 60 files
    expected_total = (len(ANIMAL_AVATARS) + len(TEASE_STICKERS) + 1) * 3
    assert len(generated) == expected_total

    # Verify avatars
    for name in ANIMAL_AVATARS:
        for scale, sub in [(1, ""), (2, "2.0x"), (3, "3.0x")]:
            target = avatar_dir / sub / f"{name}.png" if sub else avatar_dir / f"{name}.png"
            assert target.exists(), f"Missing avatar {target}"
            with Image.open(target) as img:
                assert img.mode == "RGBA"
                expected_dim = 128 * scale
                assert img.size == (expected_dim, expected_dim)
                # Check corners are transparent and center is non-transparent
                corner_alpha = img.getpixel((0, 0))[3]
                center_alpha = img.getpixel((expected_dim // 2, expected_dim // 2))[3]
                assert corner_alpha == 0, f"Corner should be transparent for {target}"
                assert center_alpha > 0, f"Center should be opaque for {target}"

    # Verify tease stickers and party sticker
    sticker_names = [f"sticker-tease-{s}" for s in TEASE_STICKERS] + [PARTY_STICKER]
    for s_name in sticker_names:
        for scale, sub in [(1, ""), (2, "2.0x"), (3, "3.0x")]:
            target = game_dir / sub / f"{s_name}.png" if sub else game_dir / f"{s_name}.png"
            assert target.exists(), f"Missing sticker {target}"
            with Image.open(target) as img:
                assert img.mode == "RGBA"
                expected_dim = 128 * scale
                assert img.size == (expected_dim, expected_dim)
                corner_alpha = img.getpixel((0, 0))[3]
                assert corner_alpha == 0, f"Corner should be transparent for {target}"


def test_does_not_overwrite_existing_files(tmp_path: Path):
    from make_placeholders import generate_placeholders

    avatar_dir = tmp_path / "avatars"
    game_dir = tmp_path / "game"
    avatar_dir.mkdir(parents=True, exist_ok=True)

    # Create a pre-existing custom file
    custom_fox = avatar_dir / "fox.png"
    sentinel_bytes = b"CUSTOM_GEMINI_IMAGE_DATA_DO_NOT_OVERWRITE"
    custom_fox.write_bytes(sentinel_bytes)

    # Run placeholder generation
    generated = generate_placeholders(avatar_dir=avatar_dir, game_dir=game_dir)

    # Verify custom_fox was skipped and its content unchanged
    assert custom_fox not in generated
    assert custom_fox.read_bytes() == sentinel_bytes

    # Running a second time should generate 0 files (everything already exists)
    second_run = generate_placeholders(avatar_dir=avatar_dir, game_dir=game_dir)
    assert len(second_run) == 0


def test_cli_execution(tmp_path: Path):
    avatar_dir = tmp_path / "avatars"
    game_dir = tmp_path / "game"

    cmd = [
        sys.executable,
        str(SCRIPT),
        "--avatar-dir",
        str(avatar_dir),
        "--game-dir",
        str(game_dir),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    assert res.returncode == 0
    assert (avatar_dir / "fox.png").exists()
    assert (game_dir / "sticker-party.png").exists()


def test_explore_placeholders_generate_and_never_overwrite(tmp_path: Path):
    from make_placeholders import generate_explore_placeholders, EXPLORE

    explore_dir = tmp_path / "explore"
    root_dir = tmp_path / "images"
    generated = generate_explore_placeholders(explore_dir=explore_dir, root_dir=root_dir)
    assert len(generated) == (len(EXPLORE) + 1) * 3
    for sub in ["", "2.0x", "3.0x"]:
        for target in [
            explore_dir / sub / "geo-nui.png",
            explore_dir / sub / "island-dia-ly.png",
            root_dir / sub / "ic-kham-pha.png",
        ]:
            assert target.exists(), target
            with Image.open(target) as img:
                assert img.mode == "RGBA"
    marker = explore_dir / "geo-nui.png"
    marker.write_bytes(b"real art")
    again = generate_explore_placeholders(explore_dir=explore_dir, root_dir=root_dir)
    assert again == []
    assert marker.read_bytes() == b"real art"
