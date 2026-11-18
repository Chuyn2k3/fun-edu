# Rocket Race — Free-Flight Space Chase Design

**Date:** 2026-11-18
**Branch:** `chipchip`
**Status:** Approved for implementation

## 1. Problem Statement

User review of the previous 2.5D track + Mario Kart rivalry implementation identified five visual flaws that made the scene feel fake and pasted together:
1. **Flat purple trapezoid "carpet" + ground shadows:** Rockets flying in space appeared to slide on a flat purple striped ramp with dark elliptical shadows underneath.
2. **Double-pasted Chíp mascot:** `assets/images/game/rocket-chip.png` already depicts 3D Chíp sitting inside the white rocket cockpit; drawing `stickerPilotGoggles` on top created an obvious cut-and-paste double overlay.
3. **Oversized rigid exhaust flame & goofy 360° spin:** At `flameLength = width * 1.75` (up to `3.5×` width on boost), rotating Chíp's rocket 360° swept a giant carrot-shaped flame sideways across the screen.
4. **Overtake banner occluding rockets:** "VƯỢT LÊN!" popped directly on top of both rockets, covering Chíp's reaction.
5. **Static world / creeping rockets:** The sky and planet stood still while tiny rockets crept upward along the trapezoid, lacking real flying speed.

## 2. Design Goals

Replace the static trapezoid ramp with a **Free-Flight Space Chase** camera:
- Both rockets fly freely in deep scrolling space at a large, readable size (~86–96 pt wide on phones, ~110–124 pt on tablets), showing the original 3D `rocket-chip.png` cleanly without overlays.
- The universe scrolls downward continuously with multi-layer parallax and surges into warp speed when the child answers correctly or activates Nitro.
- Chíp's vertical position is **relative to the child** (`chipPos - kidPos`), creating close, dynamic dogfight tension; the finish planet (Saturn) grows and approaches from ahead as the race nears completion, accompanied by a compact **mini space progress bar** on the right edge.
- Flames, overtake turbulence wobble, wrong-answer sputter, lucky stars, and the "VƯỢT LÊN!" banner all obey believable cartoon physics and clean visual hierarchy.

## 3. Visual Architecture & Layers

The scene retains a single `Ticker` driving `SceneClock` with `RepaintBoundary` layers and zero per-frame `Paint`/`Path` allocations.

### Layer 1: Deep Space Sky (`_SkyPainter` — static `RepaintBoundary`)
- Richer deep-space vertical gradient using `GameColors.spaceTop` → `GameColors.spaceMid` → `GameColors.spaceBottom` (no horizon pink band or bottom flat clouds).

### Layer 2: Multi-Layer Scrolling Universe (`SpaceMotionPainter` — repaints on `SceneClock`)
Driven by an accumulated `scrollOffset` updated each tick (`scrollSpeed` increases smoothly during kid boost / Nitro warp):
- **Nebula glows (0.15× scroll speed):** 3 soft radial-gradient cosmic clouds (violet, magenta-purple, cyan-indigo tint from `GameColors`) wrapping seamlessly vertically.
- **Far stars & sparkles (0.4× scroll speed):** Twinkling dots and 4-point sparkles drawn via single `drawRawAtlas` call on `ParticleSprites`, wrapping vertically across the entire viewport.
- **Near star streaks / space dust (1.0× scroll speed, elongating up to 3.0× during boost):** Crisp thin light streaks rushing downward past the rockets to convey real forward velocity.
- When `reduceMotion` is true: `scrollOffset` stays fixed at 0 and streaks remain static dots.

### Layer 3: Approaching Finish Planet & Foreground Actors (`_RaceForegroundPainter`)
No trapezoid track slab, no lane dashes, no ground oval shadows.

#### A. Approaching Finish Planet (Saturn)
- Drawn behind the rockets with a soft radial warm halo (`GameColors.planetHalo`).
- Scales and descends smoothly as `max(kidPos, chipPos)` advances from `0.0 → 1.0`:
  - At `0.0..0.5`: small distant target (`~64 * u` wide) near the upper space region (safely below the top "Câu N/10" pill).
  - At `0.5..1.0`: smoothly approaches and scales up to `~156 * u` wide, giving an unmistakable feeling of arriving at the destination planet.

#### B. Free-Flight Rocket Layout (`SpaceFlightGeometry`)
- Replaces perspective shrinking with a camera-follow layout computed from `(size, lanes, bottomInset)`:
  - Safe vertical flight area: `topSafeY` (below the top HUD bar, ~`88 * u`) to `bottomSafeY` (`size.height - bottomInset - 36 * u`).
  - **Rocket width:** large, consistent foreground scale (`~84 * u`, clamped gracefully for compact phones and tablets) so both rockets and Chíp's face are crisp and unmistakable.
  - **Horizontal lanes:** Kid on left (`cx - laneSpread`), Chíp on right (`cx + laneSpread`), where `laneSpread ≈ 0.20 * min(width, availableH)` so rockets stay well-framed and never collide horizontally.
  - **Vertical positions (relative chase camera):**
    - Kid anchor `kidAnchorY`: sits comfortably in the lower-middle of the flight area (`~68%` down the safe zone), lifting slightly forward (`up to -22 * u`) during active boost surges so the child feels their rocket punch forward.
    - Chíp relative Y: `chipY = kidBaseY - ((chipPos + chipLeadOffset) - kidPos) * stepPixels`, clamped cleanly within `[topSafeY + rocketHeight * 0.55, bottomSafeY - 6 * u]`.
    - At start (`kid = 0, chip = 0`), `chipLeadOffset = 0.04` (0.4 step) places Chíp clearly ahead of the kid on the right, inviting the child to catch up and pass.

#### C. Clean Chíp Sprite & Balanced Exhaust Flames
- Remove `pilotAsset` overlay from `RocketSprite.chip` and `RaceScene` image loading/painting. Use `AppImages.rocketChip` directly.
- Recalibrate exhaust proportions in `Racer`:
  - `flameWidth = width * 0.44`
  - `flameLength = width * 0.96`
  - `intensity` clamped to `[0.45, 1.65]` (cruising `1.0`, boosting up to `1.55`, temporarily dimmed to `0.55` during stall or overtake turbulence).
- Smoke particles emit from the nozzle and drift downward quickly with the ambient space scroll velocity.

#### D. Believable Overtake & Sputter Reactions
- **Overtake reaction (replacing 360° spin):**
  - When kid visual position crosses ahead of Chíp (`kidEffective > chipEffective` while previously `<=`), Chíp triggers `wobble()` (duration `0.55s`):
    - Damped side-to-side turbulence tilt `sin(age * 28) * 0.32 * (1 - progress)` (max `±18°`) and slight sideways slip (`±7 * u`), with flame intensity briefly dipping to `0.55` as the kid's wake pushes past.
    - No 360° rotation; the flame always points naturally downward-angled behind Chíp's nozzle.
  - **"VƯỢT LÊN!" banner:** Positioned in the open upper zone (`topSafeY + 28 * u`, directly below the "Câu N/10" pill), centered horizontally — never overlapping either rocket. Pops in with elastic bounce and fades out over `0.75s`.
- **Wrong-answer sputter (kid):**
  - Triggered cleanly via `stallSeq > old.stallSeq` (when `!reduceMotion`).
  - Kid rocket dips `~8px` (`sputterDip`), wobbles slightly, dims flame to `0.55`, and emits soft dark-gray smoke puffs drifting downward from the nozzle over `0.35s`.
- **Lucky Stars (milestones 4 and 8):**
  - Rendered as glowing golden 5-point stars in the kid's flight lane when `kidSteps < milestone`.
  - Positioned relative to kid's current progress (`kidBaseY - (milestone / 10 - kidPos) * stepPixels`), so each star smoothly **approaches from the top of the screen** as the child gets within ~2.5 steps and gets collected as the rocket reaches it.

#### E. Mini Space Progress Bar (Right Edge)
- Compact vertical pill bar anchored on the right edge of the flight zone (`width: 8 * u`, translucent deep-violet track with subtle border).
- Small Saturn icon / gold ring dot at the top (`1.0`).
- Two high-contrast glowing markers moving from bottom (`0.0`) to top (`1.0`):
  - Kid marker (bright orange dot with white border, `kidPos`).
  - Chíp marker (white dot with coral border, `chipPos`).
- Gives instant spatial awareness of overall race progress (0–10 steps) without cluttering the center flight view.

## 4. Compatibility, Constraints & Testing

- **Zero regressions to Garage / Hub:** `FlameRenderer` and `SmokeParticles` APIs remain backward-compatible for `rocket_stage.dart` and `garage_screen.dart`.
- **Tokens:** All new space/nebula/progress-bar colors are defined in `GameColors` inside `lib/ui/theme/tokens.dart`. No hardcoded `Color(0x...)` literals in painters.
- **Flutter 3.24.5 / Dart 3.5:** Use `withOpacity` (never `withValues`).
- **Accessibility & Semantics:** Keep the existing Vietnamese `Semantics` label reporting both `kidSteps` and `chipSteps`; honor `MediaQuery.disableAnimations` (`reduceMotion`).
- **Tests:**
  - Update `test/game/scene/space_track_test.dart` for `SpaceFlightGeometry` (relative positioning, approaching planet scaling, safe bounds on phone & iPad portrait/landscape).
  - Update `test/game/scene/race_scene_test.dart` for clean `RocketSprite.chip` (no double pilot overlay), overtake turbulence wobble, non-overlapping banner position, scrolling universe speed surge, and sputter/reduceMotion behavior.
  - Visual verification via `tools/shot/game_shot_test.dart` (`toan`, `comet`, `flyby`) inspecting rendered PNGs directly.
