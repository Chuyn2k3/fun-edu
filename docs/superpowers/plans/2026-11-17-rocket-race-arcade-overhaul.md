# Rocket Race Arcade Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Rocket Race game into a high-energy, full-bleed arcade space racer with rubberbanding dogfight AI, explosive burst kinematics, warp speed lines, screen shake, and floating cockpit HUD.

**Architecture:** Extend the pure Dart `Race` and `ChipPacer` engine with rubberbanding, combo streak, and collectible tracking. In `lib/game/scene/`, implement `SpeedLinesPainter`, rocket anticipation dip, dynamic parallax acceleration, and micro screen shake. Overhaul `RaceScreen` into a full-bleed `Stack` with a floating glassmorphism cockpit HUD.

**Tech Stack:** Flutter 3.24.5, Dart 3.5, Riverpod, CustomPainter / drawRawAtlas, Canvas 2.5D projection.

---

### File Structure Map

| File | Purpose |
|---|---|
| `lib/game/engine/chip_pacer.dart` | Adaptive pacing with rubberbanding against `kidSteps` |
| `lib/game/engine/race.dart` | Combo streak counter, Nitro active state, and lucky star tracking |
| `test/game/engine/chip_pacer_test.dart` | Tests for rubberband speedups, slowdowns, and limits |
| `test/game/engine/race_test.dart` | Tests for combo streak, Nitro flags, and star pickups |
| `lib/game/scene/speed_lines.dart` | `SpeedLinesPainter` for warp speed visual streaks |
| `test/game/scene/speed_lines_test.dart` | Tests for speed lines rendering lifecycle |
| `lib/game/scene/race_scene.dart` | Integrate speed lines, screen shake, anticipation dip, and lucky star sprites |
| `test/game/scene/race_scene_test.dart` | Tests for anticipation, boost shake, and reduced motion safety |
| `lib/features/game/race_screen.dart` | Full-bleed layout and `FloatingCockpitHUD` with Nitro gauge |
| `test/features/game/race_screen_test.dart` | Widget tests for full-bleed HUD and key interactions |
| `lib/features/game/race_controller.dart` | Award bonus cosmic stars collected from track |
| `test/features/game/race_controller_test.dart` | Test star accounting from race outcome |

---

### Task 1: Rubberband AI & Combo Nitro in Pure Engine

**Files:**
- Modify: `lib/game/engine/chip_pacer.dart`
- Modify: `lib/game/engine/race.dart`
- Modify: `test/game/engine/chip_pacer_test.dart`
- Modify: `test/game/engine/race_test.dart`

- [ ] **Step 1: Write failing tests for rubberbanding and combo streak**

Add tests in `test/game/engine/chip_pacer_test.dart`:
```dart
test('rubberbanding: Chíp accelerates when kid is ahead', () {
  final pacer = ChipPacer(initialMean: const Duration(seconds: 4));
  // Standard interval is 4s * 1.25 = 5s.
  // With kid 2 steps ahead, interval should drop by 15% (rubberband acceleration)
  final normal = pacer.intervalFor(chipSteps: 2, kidSteps: 2);
  final catchingUp = pacer.intervalFor(chipSteps: 2, kidSteps: 4);
  expect(catchingUp.inMicroseconds, lessThan(normal.inMicroseconds));
});

test('rubberbanding: Chíp slows down in final 2 steps (steps 8-10)', () {
  final pacer = ChipPacer(initialMean: const Duration(seconds: 4));
  final early = pacer.intervalFor(chipSteps: 3, kidSteps: 3);
  final endgame = pacer.intervalFor(chipSteps: 8, kidSteps: 8);
  expect(endgame.inMicroseconds, greaterThan(early.inMicroseconds));
});
```

And in `test/game/engine/race_test.dart`:
```dart
test('consecutive first-try correct answers trigger comboStreak and Nitro', () {
  final race = makeTestRace(); // helper creating 10-question race
  final r1 = race.answer(race.current.correctIndex, const Duration(seconds: 2));
  expect(race.comboStreak, 1);
  expect(race.isNitroActive, isFalse);

  final r2 = race.answer(race.current.correctIndex, const Duration(seconds: 2));
  expect(race.comboStreak, 2);
  expect(race.isNitroActive, isTrue);

  // Wrong answer resets comboStreak
  race.answer((race.current.correctIndex + 1) % 3, const Duration(seconds: 2));
  expect(race.comboStreak, 0);
  expect(race.isNitroActive, isFalse);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/game/engine/chip_pacer_test.dart test/game/engine/race_test.dart`
Expected: FAIL (compilation errors: `intervalFor`, `comboStreak`, `isNitroActive` not defined).

- [ ] **Step 3: Implement rubberband pacer and combo streak in engine**

In `lib/game/engine/chip_pacer.dart`:
```dart
/// Calculates interval dynamically with rubberbanding.
Duration intervalFor({required int chipSteps, required int kidSteps}) {
  double factor = 1.25 * slowdown;
  // If kid is ahead by 2 or more steps, Chíp speeds up by 15% to keep tension.
  if (kidSteps > chipSteps + 1) {
    factor *= 0.85;
  }
  // In the endgame (steps >= 8), Chíp slows down by 35% so kid takes the win.
  if (chipSteps >= 8) {
    factor *= 1.35;
  }
  return Duration(microseconds: (mean.inMicroseconds * factor).round());
}
```
Update `shouldStep`:
```dart
bool shouldStep(Duration now, {required int chipSteps, required int kidSteps}) {
  if (chipSteps >= kidSteps + 1 && chipSteps >= 2) return false;
  final needed = intervalFor(chipSteps: chipSteps, kidSteps: kidSteps);
  return now - _lastStepAt >= needed;
}
```

In `lib/game/engine/race.dart`:
Add fields:
```dart
int comboStreak = 0;
bool get isNitroActive => comboStreak >= 2;
int luckyStarsCollected = 0;
final Set<int> _starMilestones = {4, 8};
```
In `answer()`:
```dart
if (choiceIndex != q.correctIndex) {
  comboStreak = 0;
  if (firstTry) _missed.add(q);
  _triedCurrent = true;
  return AnswerResult(
      correct: false, gained: 0, firstTry: firstTry, finished: false);
}
if (firstTry) {
  comboStreak++;
}
final gained = q.comet ? 2 : (isNitroActive ? 2 : 1);
final prevSteps = kidSteps;
kidSteps = (kidSteps + gained).clamp(0, raceLength);
for (final m in _starMilestones) {
  if (prevSteps < m && kidSteps >= m) {
    luckyStarsCollected++;
  }
}
```
Update `RaceOutcome` and `AnswerResult` to expose `comboStreak` and `luckyStarsCollected`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/game/engine/chip_pacer_test.dart test/game/engine/race_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/game/engine/ test/game/engine/
git commit -m "feat(game): add rubberband pacing, combo streak, and lucky star tracking to race engine"
```

---

### Task 2: Warp Speed Lines & Micro Screen Shake

**Files:**
- Create: `lib/game/scene/speed_lines.dart`
- Create: `test/game/scene/speed_lines_test.dart`
- Modify: `lib/game/scene/race_scene.dart`
- Modify: `test/game/scene/race_scene_test.dart`

- [ ] **Step 1: Write test for SpeedLines**

Create `test/game/scene/speed_lines_test.dart`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/speed_lines.dart';

void main() {
  test('SpeedLines calculates opacity and active state over duration', () {
    final lines = SpeedLines(duration: 0.45);
    expect(lines.isActive(0.1), isTrue);
    expect(lines.opacityAt(0.1), greaterThan(0.0));
    expect(lines.isActive(0.5), isFalse);
    expect(lines.opacityAt(0.5), 0.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/scene/speed_lines_test.dart`
Expected: FAIL (`speed_lines.dart` does not exist).

- [ ] **Step 3: Implement `SpeedLines` and `SpeedLinesPainter`**

Create `lib/game/scene/speed_lines.dart`:
```dart
import 'dart:math' as math;
import 'package:flutter/widgets.dart';

class SpeedLines {
  const SpeedLines({this.duration = 0.45});

  final double duration;

  bool isActive(double age) => age >= 0 && age < duration;

  double opacityAt(double age) {
    if (!isActive(age)) return 0.0;
    final progress = age / duration;
    // Rises quickly in first 20%, then fades out
    if (progress < 0.2) return progress / 0.2;
    return (1.0 - progress).clamp(0.0, 1.0);
  }

  void paint(Canvas canvas, Size size, double age, {required int seed}) {
    final opacity = opacityAt(age);
    if (opacity <= 0.01) return;

    final paint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rand = math.Random(seed);
    const countPerSide = 6;
    final edgeWidth = size.width * 0.15;

    // Paint streaks on left and right borders
    for (int i = 0; i < countPerSide; i++) {
      final alpha = (rand.nextDouble() * 0.5 + 0.3) * opacity;
      paint.color = Color.fromRGBO(255, 255, 255, alpha);

      final lineLength = size.height * (0.15 + rand.nextDouble() * 0.25);
      final y = (size.height + lineLength) * ((age * 2.5 + rand.nextDouble()) % 1.0) - lineLength;

      // Left side
      final xLeft = rand.nextDouble() * edgeWidth;
      canvas.drawLine(Offset(xLeft, y), Offset(xLeft, y + lineLength), paint);

      // Right side
      final xRight = size.width - rand.nextDouble() * edgeWidth;
      canvas.drawLine(Offset(xRight, y), Offset(xRight, y + lineLength), paint);
    }
  }
}
```

- [ ] **Step 4: Integrate SpeedLines & ScreenShake into `RaceScene`**

In `lib/game/scene/race_scene.dart`:
- Add `SpeedLines _speedLines = const SpeedLines();` and `double _speedLinesAge = double.infinity;`.
- Add screen shake offset in `_onTick`:
```dart
double _shakeAge = double.infinity;
Offset get _shakeOffset {
  if (_reduceMotion || _shakeAge > 0.25) return Offset.zero;
  final intensity = (1.0 - _shakeAge / 0.25) * 3.0;
  final dx = math.sin(_shakeAge * 60) * intensity;
  final dy = math.cos(_shakeAge * 45) * intensity;
  return Offset(dx, dy);
}
```
- In `didUpdateWidget`, when `kidUp` or `cometNow` or `isNitro`, trigger:
```dart
_speedLinesAge = 0;
_shakeAge = 0;
```
- Wrap canvas render in `canvas.translate(_shakeOffset.dx, _shakeOffset.dy);`.
- Paint speed lines on the foreground layer.

- [ ] **Step 5: Run tests and verify**

Run: `flutter test test/game/scene/speed_lines_test.dart test/game/scene/race_scene_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/game/scene/ test/game/scene/
git commit -m "feat(game): add warp speed lines and micro screen shake to race scene"
```

---

### Task 3: Rocket Anticipation Dip & Lucky Star Collectibles on Track

**Files:**
- Modify: `lib/game/scene/race_scene.dart`
- Modify: `test/game/scene/race_scene_test.dart`

- [ ] **Step 1: Write failing test for anticipation dip and lucky stars**

In `test/game/scene/race_scene_test.dart`:
```dart
testWidgets('kid rocket dips backward for 80ms anticipation on boost', (tester) async {
  // Setup RaceScene with 0 steps
  // Advance steps to 1
  // Verify vertical offset dips slightly during the first 50ms before moving forward
});

testWidgets('lucky stars are positioned on track at step 4 and step 8', (tester) async {
  // Verify lucky stars render on track
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement anticipation dip and lucky star rendering**

In `lib/game/scene/race_scene.dart`:
1. In `_Racer`:
   - Add `double _anticipationAge = double.infinity;`
   - In `startBoost`: set `_anticipationAge = 0;`
   - In `pose()`:
   ```dart
   if (_anticipationAge < 0.08) {
     final dip = math.sin((_anticipationAge / 0.08) * math.pi) * 6.0;
     baseY += dip; // dips downwards (backwards)
   }
   ```
2. Render Lucky Star on Track:
   - For steps `[4, 8]`: calculate track base point `g.basePoint(s / RaceScene.steps, 0)`.
   - If `kidSteps < s`: draw glowing golden star icon from `AppImages.star` or styled particle.
   - When kid crosses `s`: trigger a starburst sparkle particle burst.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/game/scene/race_scene_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/game/scene/race_scene.dart test/game/scene/race_scene_test.dart
git commit -m "feat(game): add rocket anticipation dip and track lucky star collectibles"
```

---

### Task 4: Full-Bleed Space Viewport & Floating Cockpit HUD

**Files:**
- Modify: `lib/features/game/race_screen.dart`
- Modify: `test/features/game/race_screen_test.dart`

- [ ] **Step 1: Write widget test for full-bleed HUD layout**

In `test/features/game/race_screen_test.dart`:
```dart
testWidgets('RaceScreen layout is full-bleed with floating cockpit HUD', (tester) async {
  await tester.pumpWidget(createTestRaceScreen());
  await tester.pumpAndSettle();
  // Check that RaceScene fills the background Stack
  // Check that FloatingCockpitHUD is aligned at the bottom
  // Check that answer keys meet accessibility height >= 64
});

testWidgets('Nitro streak badge displays when comboStreak >= 2', (tester) async {
  // Simulate 2 consecutive correct answers
  // Verify "NITRO x2" badge is visible
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/game/race_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement Full-Bleed Stack and FloatingCockpitHUD**

In `lib/features/game/race_screen.dart`:
- Replace the 50/50 `Column` with a `Stack`:
```dart
Stack(
  children: [
    // 1. Full-bleed background scene
    Positioned.fill(
      child: scene,
    ),
    // 2. Top bar: pause button & question counter
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _TopBar(...),
    ),
    // 3. Floating Cockpit HUD at bottom
    Align(
      alignment: Alignment.bottomCenter,
      child: _FloatingCockpitHUD(
        nitroActive: nitroActive,
        comboStreak: comboStreak,
        question: currentQuestion,
        onKey: (i) => _controller.answer(i),
      ),
    ),
  ],
)
```
- In `_FloatingCockpitHUD`:
  - Wrap in `ClipRRect(borderRadius: BorderRadius.circular(24))` with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))`.
  - Use container with translucent dark space gradient: `LinearGradient(colors: [Color(0xCC1A103C), Color(0xEE2A1B60)])`.
  - If `comboStreak >= 2`: show animated "⚡ NITRO x2" pill on top of the question card.
  - Buttons `AnswerKeys` remain chunky with `raisedKeyDecoration`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/game/race_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/game/race_screen.dart test/features/game/race_screen_test.dart
git commit -m "feat(game): overhaul race screen with full-bleed canvas and floating cockpit HUD"
```

---

### Task 5: Cosmic Star Rewards for Track Pickups

**Files:**
- Modify: `lib/features/game/race_controller.dart`
- Modify: `lib/features/game/race_result_screen.dart`
- Modify: `test/features/game/race_controller_test.dart`
- Modify: `test/features/game/race_result_screen_test.dart`

- [ ] **Step 1: Write test for rewarding lucky stars**

In `test/features/game/race_controller_test.dart`:
```dart
test('lucky stars collected during race add bonus cosmic stars in recordRace', () async {
  // Complete race collecting 2 lucky stars
  // Verify gameRepository.recordRace awards base stars + 2 lucky stars
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/game/race_controller_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement bonus star accounting**

In `lib/features/game/race_controller.dart`:
- When race finishes, calculate total stars = `baseStars + outcome.luckyStarsCollected`.
- Pass `luckyStarsCollected` to `RaceResultArgs`.
In `lib/features/game/race_result_screen.dart`:
- If `args.luckyStarsCollected > 0`, display a celebratory badge: `+${args.luckyStarsCollected} ⭐ Sao May Mắn!` with small sparkle animation.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/game/race_controller_test.dart test/features/game/race_result_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/game/ test/features/game/
git commit -m "feat(game): reward cosmic stars for in-race lucky star pickups"
```

---

### Task 6: Full Regression Verification & Performance Check

- [ ] **Step 1: Run flutter analyze**
Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 2: Run entire test suite**
Run: `flutter test`
Expected: All 2,490+ tests pass.

- [ ] **Step 3: Verify screen shots / multi-device layout**
Run: `flutter test tools/shot/race_shot_test.dart tools/shot/game_shot_test.dart`
Expected: Zero layout overflows on 375x667, 390x844, and iPad landscape/portrait.

- [ ] **Step 4: Final commit and push**
```bash
git push origin chipchip
```
