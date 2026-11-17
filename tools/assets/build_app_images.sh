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
# Game art (rocket race): rockets/planet/comet/upgrades on white, medals on green #00C853.
python3 tools/assets/chroma_key.py "$G/game-rocket/chunky_clay_rocket_1794798082689.jpg" "$C/game/rocket-orange.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/chunky_clay_rocket_1794798080456.jpg" "$C/game/rocket-blue.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/chunky_clay_rocket_1794798080306.jpg" "$C/game/rocket-green.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/clay_toy_purple_rocket_1794798171421.jpg" "$C/game/rocket-purple.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/chip_chip_in_rocket_v2_1794798205791.jpg" "$C/game/rocket-chip.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/clay_planet_1794798278577.jpg" "$C/game/planet.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/clay_comet_star_1794798280555.jpg" "$C/game/comet.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/lightning_rocket_fins_v2_1794800828826.jpg" "$C/game/fins-bolt.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/rocket_nose_cone_star_1794800359064.jpg" "$C/game/nose-star.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/game-rocket/rainbow_smoke_trail_1794798347386.jpg" "$C/game/trail-rainbow.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/clay_lightning_badge_1794815094045.jpg" "$C/game/badge-speed-king.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/nha_thong_thai_badge_v2_1794815178451.jpg" "$C/game/badge-scholar.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/comet_hunter_badge_1794815157174.jpg" "$C/game/badge-comet-hunter.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/medal_khong_bo_cuoc_1794815157707.jpg" "$C/game/badge-never-give-up.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/friendship_medal_badge_v2_1794815228873.jpg" "$C/game/badge-chip-buddy.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/sieu_toan_hoc_badge_1794815196337.jpg" "$C/game/badge-math-whiz.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/clay_medal_badge_crayon_1794815200501.jpg" "$C/game/badge-letter-master.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/medals/badge_rocket_teal_1794815213547.jpg" "$C/game/badge-pilot.json" assets/images/game
# Album stickers (Chíp poses) on green #00C853.
python3 tools/assets/chroma_key.py "$G/stickers/sticker_clap.jpg" "$C/game/sticker-clap.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_laugh.jpg" "$C/game/sticker-laugh.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_pilot_goggles.jpg" "$C/game/sticker-pilot-goggles.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_grad_cap.jpg" "$C/game/sticker-grad-cap.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_hug_star.jpg" "$C/game/sticker-hug-star.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_fist.jpg" "$C/game/sticker-fist.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_hug_heart.jpg" "$C/game/sticker-hug-heart.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_abacus.jpg" "$C/game/sticker-abacus.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_crayon.jpg" "$C/game/sticker-crayon.json" assets/images/game
python3 tools/assets/chroma_key.py "$G/stickers/sticker_wave_rocket.jpg" "$C/game/sticker-wave-rocket.json" assets/images/game
