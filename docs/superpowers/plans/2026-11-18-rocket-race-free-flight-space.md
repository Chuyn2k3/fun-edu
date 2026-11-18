# Rocket Race — Free-Flight Space Chase Implementation Plan

> **For agentic workers:** Implement task-by-task with TDD, clean commits, zero regressions, and visual screenshot verification.

**Goal:** Transform the rocket race scene from a static trapezoid ramp with overlaid stickers into a smooth, natural **Free-Flight Space Chase** with multi-layer scrolling deep space, clean 3D Chíp rocket, relative chase camera, approaching destination planet, balanced exhaust flames, turbulence overtake wobble, upper non-occluding banner, and a mini vertical progress bar.

**Architecture:**
- `lib/ui/theme/tokens.dart`: Add deep-space gradient, nebula, star-streak, and mini progress bar color tokens to `GameColors`.
- `lib/game/scene/rocket_sprite.dart`: Remove the redundant `pilotAsset` overlay so `RocketSprite.chip` renders `AppImages.rocketChip` cleanly as authored.
- `lib/game/scene/space_track.dart`: Extend `SceneClock` with `scrollOffset` and `warp`; redesign `TrackGeometry` for free-flight camera-follow layout (large foreground rockets, relative vertical spacing, approaching planet rect, mini progress bar rect); replace flat clouds + static stars in `SkyMotionPainter` with a 3-layer parallax scrolling universe (soft nebulae, twinkling far stars, near warp star streaks).
- `lib/game/scene/race_scene.dart`: Remove `TrackPainter` trapezoid ramp, ground shadows, and flat clouds; drive relative chase positioning, balanced flame sizing (`0.44w × 0.96w`), overtake turbulence wobble (`±18°`, 0.55s), approaching lucky stars, upper non-occluding "VƯỢT LÊN!" banner, and right-edge mini progress bar.

**Tech Stack:** Flutter 3.24.5, Dart 3.5, Riverpod, CustomPainter + single `Ticker` (`SceneClock`), `drawRawAtlas`.

---

### Task 1: Deep-Space Color Tokens & Clean Chíp Sprite

**Files:**
- Modify: `lib/ui/theme/tokens.dart`
- Modify: `lib/game/scene/rocket_sprite.dart`
- Test: `test/game/scene/race_scene_test.dart`

- [ ] Add `spaceTop`, `spaceMid`, `spaceBottom`, `nebulaViolet`, `nebulaMagenta`, `nebulaCyan`, `streakLight`, `progressTrack`, `progressBorder`, `progressKid`, `progressChip`, `stallSmoke` to `GameColors` in `lib/ui/theme/tokens.dart`.
- [ ] Remove `pilotAsset` from `RocketSprite` in `lib/game/scene/rocket_sprite.dart` so `RocketSprite.chip` renders `AppImages.rocketChip` cleanly without double-pasting a sticker over Chíp's face.
- [ ] Verify with `flutter analyze`.

---

### Task 2: Free-Flight Geometry & Multi-Layer Scrolling Universe

**Files:**
- Modify: `lib/game/scene/space_track.dart`
- Test: `test/game/scene/space_track_test.dart`

- [ ] Extend `SceneClock` with `scrollOffset`, `warp` (0..1), and `advance(dt, {double warp = 0})` so scrolling accelerates smoothly into warp speed during boost/Nitro and stays still under `reduceMotion`.
- [ ] Update `TrackGeometry` for free-flight layout:
  - Safe vertical flight area between `topSafeY` (below top pill) and `bottomSafeY` (above floating cockpit HUD).
  - Large foreground `rocketWidth` (`~84 * u`, clamped cleanly for small phones & tablets).
  - Clean left/right `laneX(lane)` with zero artificial vanishing-point tilt (`laneTilt(lane) == 0`).
  - Relative vertical mapping `kidAnchorY` and `relativeY(pos, anchorPos)` clamped safely inside the flight zone.
  - Approaching destination planet `planetRectFor(progress)` growing and descending smoothly as `progress` nears `1.0`.
  - Compact `progressBarRect` along the right edge of the flight zone.
- [ ] Upgrade `SkyMotionPainter` to paint 3 scrolling space layers: soft parallax nebulae (0.15×), wrapping twinkling stars via `drawRawAtlas` (0.4×), and near star streaks (1.0×, elongating smoothly with `clock.warp`). Remove flat clouds from the race sky.
- [ ] Rewrite `test/game/scene/space_track_test.dart` to verify phone & tablet layouts, approaching planet growth, relative vertical ordering, and safe bounds.
- [ ] Run `flutter test test/game/scene/space_track_test.dart`.

---

### Task 3: Relative Chase Camera, Balanced Flames, Turbulence Wobble & Mini Progress Bar

**Files:**
- Modify: `lib/game/scene/race_scene.dart`
- Test: `test/game/scene/race_scene_test.dart`

- [ ] Remove trapezoid `TrackPainter`, ground shadows (`_shadow`), flat mid/front clouds, and `pilotAsset` image loading/painting from `RaceScene`.
- [ ] Update `Racer`:
  - Recalibrate `flameWidth = width * 0.44` and `flameLength = width * 0.96`; clamp `intensity` smoothly (`0.55` during stall or turbulence wobble, up to `1.55` on boost).
  - Replace rigid 360° `spinOut()` with natural turbulence `wobble()` (`±18°` damped sway + slight sideways slip over `0.55s`, keeping flame angled naturally behind nozzle).
  - Update `pose` to use free-flight relative camera coordinates (`kidAnchorY` with gentle boost lift, Chíp positioned relative to `kid.pos`), and smoke particles drifting downward with space scroll speed.
- [ ] Update `_RaceForegroundPainter`:
  - Paint approaching destination planet (`AppImages.planet`) with warm radial halo behind rockets.
  - Paint approaching lucky stars (milestones 4 & 8) relative to `kid.pos`, appearing from above as kid nears each milestone.
  - Paint both rockets (clean `rocket-chip.png` & kid rocket) without oval ground shadows.
  - Position "VƯỢT LÊN!" banner cleanly in upper clear space (`topSafeY + 26 * u`, directly under "Câu N/10") so it never overlaps rockets.
  - Paint the compact vertical mini space progress bar on the right edge with planet cap and kid/Chíp glowing markers.
- [ ] Update `test/game/scene/race_scene_test.dart` for all new behaviors (clean chip asset, turbulence wobble, upper non-occluding banner, warp scrolling, stall sputter, reduceMotion).
- [ ] Run `flutter test test/game/scene/race_scene_test.dart test/features/game/`.

---

### Task 4: Visual Verification, Full Test Suite & Docs

- [ ] Generate visual screenshots (`toan`, `comet`, `flyby`) via `tools/shot/game_shot_test.dart` and inspect every screenshot carefully with `read_file`.
- [ ] Run `flutter analyze` and full `flutter test`.
- [ ] Update `docs/PROJECT_STATE.md`, commit, and push to `origin chipchip`.
