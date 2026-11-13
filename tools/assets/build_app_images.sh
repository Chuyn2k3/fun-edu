#!/usr/bin/env bash
# Rebuild app images from the approved high-resolution Gemini renders.
set -euo pipefail
cd "$(dirname "$0")/../.."
G=docs/superpowers/specs/assets/generated
C=tools/assets/configs
python3 tools/assets/cut_sheet.py "$G/bird_character_waving_1794496933829.jpg" "$C/hd/chip-main.json" assets/images
python3 tools/assets/cut_sheet.py "$G/sparrow_jumping_joy_1794496984033.jpg" "$C/hd/chip-joy.json" assets/images
python3 tools/assets/cut_sheet.py "$G/sparrow_thumbs_up_1794496985337.jpg" "$C/hd/chip-thumb.json" assets/images
python3 tools/assets/cut_sheet.py "$G/surprised_sparrow_character_1794497071327.jpg" "$C/hd/chip-surprise.json" assets/images
python3 tools/assets/cut_sheet.py "$G/encouraging_bird_character_tilted_1794497007067.jpg" "$C/hd/chip-encourage.json" assets/images
python3 tools/assets/cut_sheet.py "$G/sleepy_bird_crayon_1794496985338.jpg" "$C/hd/chip-sleep.json" assets/images
python3 tools/assets/cut_sheet.py "$G/cute_bird_drawing_orange_crayon_1794496981331.jpg" "$C/hd/chip-write.json" assets/images
python3 tools/assets/cut_sheet.py "$G/chunky_orange_crayon_1794496997229.jpg" "$C/hd/ic-viet.json" assets/images
python3 tools/assets/cut_sheet.py "$G/letter_blocks_a_a_b_1794497001524.jpg" "$C/hd/ic-tieng-viet.json" assets/images
python3 tools/assets/cut_sheet.py "$G/math_toy_blocks_abacus_1794496994158.jpg" "$C/hd/ic-toan.json" assets/images
python3 tools/assets/cut_sheet.py "$G/abc_toy_letters_1794496994279.jpg" "$C/hd/ic-tieng-anh.json" assets/images
python3 tools/assets/cut_sheet.py "$G/puffy_golden_star_1794497107824.jpg" "$C/hd/ic-star.json" assets/images
python3 tools/assets/cut_sheet.py "$G/chubby_golden_toy_crown_1794497019105.jpg" "$C/hd/ic-crown.json" assets/images
# ic-flame has no high-resolution render yet: cut from the old icon sheet.
python3 tools/assets/cut_sheet.py docs/superpowers/specs/assets/icons-sheet.webp "$C/flame.json" assets/images
