# Rocket Race: Mario Kart Rivalry & Overtake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the rocket race into a thrilling, cartoonish Mario Kart-style dynamic chase where Chíp visibly leads as the rival pilot, the child accelerates to overtake Chíp upon answering correctly, Chíp spins out 360° with dizzy eyes, and the race feels like a genuine, dramatic arcade duel.

**Architecture:** 
1. Composite Chíp's mascot pilot with aviator goggles into Chíp's rocket cockpit for unmistakable rival identity.
2. Introduce a dynamic relative kinematics model in `_Racer` where Chíp holds a leading offset until the child surges ahead, triggering an `onOvertake` sequence.
3. Animate a 360° spin-out (`spinAngle`) on Chíp during overtakes with squash/stretch easing and a bold "VƯỢT LÊN!" banner.
4. Add wrong-answer stall/smoke puffs and playful lead taunts.

**Tech Stack:** Flutter 3.24.5, Dart 3.5, Riverpod, Canvas CustomPainter, Ticker/SceneClock, TDD.

---

### Task 1: Chíp Pilot Avatar Rendering & Visual Identity

**Files:**
- Modify: `lib/game/scene/rocket_sprite.dart:25-45`
- Modify: `lib/game/scene/race_scene.dart:140-150`, `310-330`
- Test: `test/game/scene/rocket_sprite_test.dart`

- [ ] **Step 1: Write the failing test for Chíp rocket pilot rendering**

Create or edit `test/game/scene/rocket_sprite_test.dart`:
```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/rocket_sprite.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  test('RocketSprite.chip defines asset and pilot asset', () {
    expect(RocketSprite.chip.asset, AppImages.rocketChip);
    expect(RocketSprite.chip.pilotAsset, AppImages.stickerPilotGoggles);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/scene/rocket_sprite_test.dart`
Expected: FAIL with `pilotAsset is not defined`.

- [ ] **Step 3: Implement pilotAsset on RocketSprite and resolve it in SceneImages**

In `lib/game/scene/rocket_sprite.dart`:
```dart
class RocketSprite {
  const RocketSprite._(this.asset, this.aspect, this.nozzle, {this.pilotAsset});

  final String asset;
  final double aspect;
  final double nozzle;
  final String? pilotAsset;

  static const orange = RocketSprite._(AppImages.rocketOrange, 171 / 96, 0.80);
  static const blue = RocketSprite._(AppImages.rocketBlue, 147 / 96, 0.81);
  static const green = RocketSprite._(AppImages.rocketGreen, 136 / 96, 0.81);
  static const purple = RocketSprite._(AppImages.rocketPurple, 144 / 96, 0.81);

  /// Chíp's rival rocket, carrying the Chíp pilot with goggles.
  static const chip = RocketSprite._(
    AppImages.rocketChip,
    148 / 96,
    0.82,
    pilotAsset: AppImages.stickerPilotGoggles,
  );
...
```

In `lib/game/scene/race_scene.dart`:
Add `AppImages.stickerPilotGoggles` to `_images.resolve(...)` and `Listenable.merge(...)` in `_RaceForegroundPainter`.
In `_paintRacer`:
```dart
    final pilotImg = racer.sprite.pilotAsset != null
        ? state._images[racer.sprite.pilotAsset!].value
        : null;
    if (pilotImg != null) {
      // Paint Chíp pilot sitting in the cockpit window
      final windowRect = Rect.fromCenter(
        center: Offset(r.center.dx, r.top + r.height * 0.38),
        width: r.width * 0.44,
        height: r.width * 0.44,
      );
      paintImageFitted(canvas, pilotImg, windowRect);
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/scene/rocket_sprite_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/game/scene/rocket_sprite.dart lib/game/scene/race_scene.dart test/game/scene/rocket_sprite_test.dart
git commit -m "feat(game): add Chíp mascot pilot with aviator goggles to rival rocket"
```

---

### Task 2: Relative Lead Offset & Spin-out Kinematics in `_Racer`

**Files:**
- Modify: `lib/game/scene/race_scene.dart:340-420`
- Test: `test/game/scene/race_scene_test.dart`

- [ ] **Step 1: Write the failing tests for Chíp's dynamic lead and spin-out animation**

In `test/game/scene/race_scene_test.dart`:
```dart
  testWidgets('Chíp starts with leading offset, spins out when overtaken', (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 0)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    await tester.pump(const Duration(milliseconds: 16));

    // Chíp is placed ahead of Kid at start of race (lead offset)
    expect(state.chipBaseY, lessThan(state.kidBaseY));
    expect(state.isChipSpinning, isFalse);

    // Kid advances past Chíp (kid = 2, chip = 0)
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0)));
    await tester.pump(const Duration(milliseconds: 100));

    // Chíp triggers spin-out during overtake
    expect(state.isChipSpinning, isTrue);
    expect(state.chipSpinAngle, greaterThan(0.0));

    // After spin-out completes (~500ms), spin angle returns to 0
    await tester.pump(const Duration(milliseconds: 500));
    expect(state.isChipSpinning, isFalse);
    expect(state.chipSpinAngle, 0.0);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: FAIL with `chipBaseY / isChipSpinning not found`.

- [ ] **Step 3: Implement lead offset, overtake detection, and spin-out animation in `_Racer`**

In `lib/game/scene/race_scene.dart`:
1. In `_Racer`:
```dart
  double _spinAge = double.infinity;
  static const _spinDuration = 0.48;

  bool get isSpinning => _spinAge < _spinDuration;
  double get spinAngle =>
      isSpinning ? (_spinAge / _spinDuration) * 2 * math.pi : 0.0;

  void spinOut() {
    _spinAge = 0.0;
  }
```
2. In `_Racer.pose`:
   - If lane is 1 (Chíp), apply `leadOffset`:
     ```dart
     final effectivePos = isChip && p < RaceScene.steps
         ? math.min(10.0, _pos + (_kidIsLeading ? -0.15 : 0.45))
         : _pos;
     ```
   - Advance `_spinAge += dt` when ticking.
3. In `_paintRacer`:
   - If `racer.spinAngle != 0`:
     ```dart
     canvas.save();
     canvas.translate(r.center.dx, r.center.dy);
     canvas.rotate(racer.spinAngle);
     canvas.translate(-r.center.dx, -r.center.dy);
     // paint rocket & pilot
     canvas.restore();
     ```
4. Expose test getters in `RaceSceneState`: `chipBaseY`, `isChipSpinning`, `chipSpinAngle`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/game/scene/race_scene.dart test/game/scene/race_scene_test.dart
git commit -m "feat(game): add relative lead offset and 360 spin-out on overtake"
```

---

### Task 3: "VƯỢT LÊN!" Overtake Banner Pop-Up

**Files:**
- Modify: `lib/game/scene/race_scene.dart:530-580`
- Test: `test/game/scene/race_scene_test.dart`

- [ ] **Step 1: Write the failing test for Overtake Banner**

In `test/game/scene/race_scene_test.dart`:
```dart
  testWidgets('Overtake banner appears when kid passes Chíp', (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 0)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.isOvertakeBannerVisible, isFalse);

    // Kid surges ahead
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0)));
    await tester.pump(const Duration(milliseconds: 100));

    // Banner is active
    expect(state.isOvertakeBannerVisible, isTrue);

    // Banner fades out after 700ms
    await tester.pump(const Duration(milliseconds: 700));
    expect(state.isOvertakeBannerVisible, isFalse);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: FAIL with `isOvertakeBannerVisible not found`.

- [ ] **Step 3: Implement Overtake Banner rendering in `_RaceForegroundPainter`**

In `lib/game/scene/race_scene.dart`:
```dart
  void _paintOvertakeBanner(Canvas canvas, Size size, double age, TrackGeometry g) {
    if (age >= 0.75) return;
    final progress = (age / 0.75).clamp(0.0, 1.0);
    final alpha = (1.0 - math.pow(progress, 3)).clamp(0.0, 1.0);
    final scale = (0.8 + 0.3 * math.sin(progress * math.pi)).clamp(0.8, 1.15);
    final center = Offset(size.width / 2, g.startY - 110 * g.u);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'VƯỢT LÊN! 🚀',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFF9C4),
          shadows: [
            Shadow(color: Color(0xCCFF6D00), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = Rect.fromCenter(
      center: Offset.zero,
      width: textPainter.width + 32,
      height: textPainter.height + 14,
    );

    final bgPaint = Paint()
      ..color = const Color(0xEEFF6D00).withOpacity(alpha * 0.92)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(20)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(20)), borderPaint);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/game/scene/race_scene.dart test/game/scene/race_scene_test.dart
git commit -m "feat(game): add cartoon overtake banner VƯỢT LÊN when kid surges past Chíp"
```

---

### Task 4: Wrong-Answer Sputter Smoke & Chíp Playful Taunt

**Files:**
- Modify: `lib/game/scene/race_scene.dart:250-280`, `450-480`
- Modify: `lib/features/game/race_screen.dart:160-175`
- Test: `test/game/scene/race_scene_test.dart`

- [ ] **Step 1: Write the failing test for wrong-answer stall smoke**

In `test/game/scene/race_scene_test.dart`:
```dart
  testWidgets('wrong answer triggers kid sputter dip and smoke puff', (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 2)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));

    expect(state.isKidStalled, isFalse);

    // Wrong answer pulsed via stalled: true
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 2, stalled: true)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(state.isKidStalled, isTrue);

    // Recovers after 300ms
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.isKidStalled, isFalse);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: FAIL with `stalled parameter not defined`.

- [ ] **Step 3: Implement stalled parameter in `RaceScene` and hook to `race_screen.dart`**

In `lib/game/scene/race_scene.dart`:
- Add `final bool stalled;` to `RaceScene` (default `false`).
- In `didUpdateWidget`: if `widget.stalled && !oldWidget.stalled`, trigger kid rocket backward wobble and dark grey smoke puff.
In `lib/features/game/race_screen.dart`:
- In `_onState`: when `next.wrongSeq > prev.wrongSeq`, set `_stalled = true` for 350ms, pass to `_sceneOnly`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/game/scene/race_scene.dart lib/features/game/race_screen.dart test/game/scene/race_scene_test.dart
git commit -m "feat(game): add wrong-answer sputter stall and smoke puff"
```

---

### Task 5: End-to-End Verification, Screenshots & Documentation

**Files:**
- Modify: `docs/PROJECT_STATE.md:130-155`
- Run: `tools/shot/game_shot_test.dart`

- [ ] **Step 1: Render actual screenshots to verify visual polish**

Run:
```bash
mkdir -p test/_shot && cp tools/shot/game_shot_test.dart test/_shot/ && ONLY=toan,comet,flyby SHOT_OUT=/tmp/game flutter test test/_shot/game_shot_test.dart && rm -rf test/_shot
```
Inspect `/tmp/game-toan.png`, `/tmp/game-comet.png`, `/tmp/game-flyby.png` to verify:
1. Chíp is clearly visible in his rocket cockpit.
2. Chíp leads slightly ahead at start.
3. Kid surges past Chíp with Nitro flames and "VƯỢT LÊN!" banner.
4. Chíp spins out with `@_@` eyes.

- [ ] **Step 2: Run full test suite and analyze**

```bash
flutter analyze
flutter test
```
Expected: All 2513+ tests pass, 0 analyze issues.

- [ ] **Step 3: Update `docs/PROJECT_STATE.md`**

Add the Mario Kart Rivalry & Overtake feature completion to section 6.

- [ ] **Step 4: Commit and push to `origin chipchip`**

```bash
git add docs/PROJECT_STATE.md
git commit -m "docs: update PROJECT_STATE with Mario Kart rivalry overhaul"
git push origin chipchip
```
