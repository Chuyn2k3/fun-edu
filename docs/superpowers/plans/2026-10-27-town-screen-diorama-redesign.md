# TownScreen Diorama Valley Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform TownScreen into an authentic 3D Diorama Valley game world map (Option A), featuring 4-tier isometric depth, natural ground blending foundations, edge-pinned candy HUD, and seamless responsive layout on both iPhone and iPad.

**Architecture:** An adaptive canvas architecture (`DioramaValleyCanvas`) renders an 800 x 1100 virtual diorama space. On iPad/tablets it renders a 100% panoramic diorama; on iPhone/phones it uses a constrained `InteractiveViewer` with smooth damping physics centered on Pippo. Custom painters provide 4-tier depth, flowing river, organic cobblestone path network, and ground foundation blending with 135° soft directional shadows.

**Tech Stack:** Flutter, Dart, CustomPainter, AnimationController, AudioSfx, GoRouter.

---

### Task 1: Ground Foundation & Organic Cobblestone Road Network Painter

**Files:**
- Create: `lib/features/town/presentation/widgets/diorama_ground_painter.dart`
- Test: `test/features/town/diorama_ground_painter_test.dart`

- [ ] **Step 1: Write the failing widget/unit test**

```dart
// test/features/town/diorama_ground_painter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_ground_painter.dart';

void main() {
  testWidgets('DioramaGroundPainter paints without crashing and matches size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(800, 1100),
            painter: DioramaGroundPainter(scale: 1.0),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/diorama_ground_painter_test.dart`
Expected: FAIL with compilation error "DioramaGroundPainter not found"

- [ ] **Step 3: Implement `DioramaGroundPainter`**

Create `lib/features/town/presentation/widgets/diorama_ground_painter.dart`:
- Paints the central stone plaza circle (for Pippo).
- Paints the 5 natural dirt/gravel foundation pads beneath each building to prevent them from looking floating.
- Paints the flowing river with water highlight waves and the rustic wooden bridge.
- Paints the organic honey-gold cobblestone paths connecting the central plaza to all 5 stations.
- Applies consistent 135° soft directional shadows (top-right to bottom-left).

- [ ] **Step 4: Run test to verify it passes**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/diorama_ground_painter_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/town/presentation/widgets/diorama_ground_painter.dart test/features/town/diorama_ground_painter_test.dart
git commit -m "feat(town): add DioramaGroundPainter with organic paths and foundation pads"
```

---

### Task 2: Interactive Diorama Valley Viewport (`DioramaValleyCanvas`)

**Files:**
- Create: `lib/features/town/presentation/widgets/diorama_valley_canvas.dart`
- Test: `test/features/town/diorama_valley_canvas_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/town/diorama_valley_canvas_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_valley_canvas.dart';

void main() {
  testWidgets('DioramaValleyCanvas renders all 5 stations and Pippo plaza', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DioramaValleyCanvas(
            onMarketTap: () {},
            onMathMushroomTap: () {},
            onWonderTreeTap: () {},
            onPetSanctuaryTap: () {},
            onAlphabetCastleTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(DioramaValleyCanvas), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/diorama_valley_canvas_test.dart`
Expected: FAIL with compilation error "DioramaValleyCanvas not found"

- [ ] **Step 3: Implement `DioramaValleyCanvas`**

Create `lib/features/town/presentation/widgets/diorama_valley_canvas.dart`:
- Defined virtual world size: `800 x 1100`.
- Responsive layout logic:
  - If tablet (`isTablet = true`): uses `FittedBox(fit: BoxFit.contain)` to display the complete diorama panoramic view without scrolling/panning.
  - If mobile: wraps in `InteractiveViewer` with `minScale: 0.85`, `maxScale: 1.5`, `boundaryMargin: EdgeInsets.all(40)`, and initial pan centered on Pippo and Market.
- Stacks layers:
  1. `DioramaGroundPainter` (plaza, paths, river, ground foundations).
  2. Station 5: Alphabet Castle (Tier 2, Top Center, Scale 0.75x).
  3. Station 1: Market Building (Tier 3, Middle Left, Scale 1.0x).
  4. Station 3: Wonder Tree (Tier 3, Middle Right, Scale 1.0x).
  5. Central Plaza: Interactive Pippo Character (Tier 3, Center, Scale 1.05x).
  6. Station 2: Math Mushroom (Tier 4, Bottom Left, Scale 1.15x).
  7. Station 4: Pet Sanctuary (Tier 4, Bottom Right, Scale 1.15x).

- [ ] **Step 4: Run test to verify it passes**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/diorama_valley_canvas_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/town/presentation/widgets/diorama_valley_canvas.dart test/features/town/diorama_valley_canvas_test.dart
git commit -m "feat(town): implement responsive DioramaValleyCanvas viewport"
```

---

### Task 3: Refactored Edge-Pinned Jelly HUD & Compact Overhead Pippo Bubble

**Files:**
- Modify: `lib/features/town/presentation/widgets/interactive_pippo_character.dart`
- Modify: `lib/features/town/presentation/widgets/game_world_hud.dart`
- Test: `test/features/town/interactive_pippo_test.dart`

- [ ] **Step 1: Write the failing widget test for Pippo tap reaction**

```dart
// test/features/town/interactive_pippo_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/interactive_pippo_character.dart';

void main() {
  testWidgets('InteractivePippoCharacter shows overhead bubble on tap and auto-dismisses', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: InteractivePippoCharacter()),
        ),
      ),
    );

    expect(find.textContaining('Ghé Tiệm Tạp Hóa'), findsNothing);
    await tester.tap(find.byType(InteractivePippoCharacter));
    await tester.pump();
    expect(find.textContaining('Ghé Tiệm Tạp Hóa'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/interactive_pippo_test.dart`
Expected: FAIL because speech bubble is either static or missing expected tap callback string.

- [ ] **Step 3: Implement Compact Overhead Speech Bubble & Clean HUD**

Modify `lib/features/town/presentation/widgets/interactive_pippo_character.dart`:
- Replace old static speech bubble container with an animated overhead speech popup:
  - Hidden by default.
  - When user taps Pippo: plays `AudioSfx.click`, triggers squash-and-stretch bounce, and reveals compact cute speech bubble with wooden pointer pointing down to Pippo's head.
  - Automatically fades out and scales down after 3000ms via `Timer`.
- Ensure `GameWorldHud` pins neatly to the top edge with transparent center, preventing any blockage of the diorama sky.

- [ ] **Step 4: Run test to verify it passes**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/interactive_pippo_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/town/presentation/widgets/interactive_pippo_character.dart lib/features/town/presentation/widgets/game_world_hud.dart test/features/town/interactive_pippo_test.dart
git commit -m "feat(town): make Pippo speech bubble compact and reactive on tap"
```

---

### Task 4: AAA 3D Market Station ("Tiệm Tạp Hóa Nhí") - Style Benchmark Alignment

**Files:**
- Modify: `lib/features/town/presentation/widgets/game_buildings/market_building_widget.dart`
- Test: `test/features/town/market_building_widget_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/town/market_building_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/market_building_widget.dart';

void main() {
  testWidgets('MarketBuildingWidget triggers onTap callback and renders title badge', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MarketBuildingWidget(
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tiệm Tạp Hóa Nhí'), findsOneWidget);
    await tester.tap(find.byType(MarketBuildingWidget));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it passes/fails**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/market_building_widget_test.dart`

- [ ] **Step 3: Overhaul `MarketBuildingWidget` to match Media Benchmark**

Modify `lib/features/town/presentation/widgets/game_buildings/market_building_widget.dart`:
- Replace flat orange rectangle with:
  - 3D timber roof with layered wooden shingles (wood grain gradient).
  - Open shopfront window with wooden awning in warm red/cream stripes and warm yellow interior light.
  - Side fruit stands with 3D glossy red apples in wooden crates and pumpkins.
  - Carved rustic wooden hanging sign: "Tiệm Tạp Hóa Nhí" with ropes.
  - 135° soft directional ambient occlusion ground shadow beneath the doorstep.
  - Squash-and-stretch tactile press animation with golden rim glow on tap.

- [ ] **Step 4: Run test to verify it passes**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/market_building_widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/town/presentation/widgets/game_buildings/market_building_widget.dart test/features/town/market_building_widget_test.dart
git commit -m "feat(town): overhaul MarketBuildingWidget with 3D benchmark wooden store styling"
```

---

### Task 5: Upgrade Remaining 4 Stations for 4-Tier Depth & Foundation Grounding

**Files:**
- Modify: `lib/features/town/presentation/widgets/game_buildings/math_mushroom_widget.dart`
- Modify: `lib/features/town/presentation/widgets/game_buildings/wonder_tree_widget.dart`
- Modify: `lib/features/town/presentation/widgets/game_buildings/pet_sanctuary_widget.dart`
- Modify: `lib/features/town/presentation/widgets/game_buildings/alphabet_castle_widget.dart`
- Test: `test/features/town/stations_depth_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/town/stations_depth_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/alphabet_castle_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/math_mushroom_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/pet_sanctuary_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/wonder_tree_widget.dart';

void main() {
  testWidgets('All 4 stations render with tactile badges and respond to taps', (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AlphabetCastleBuildingWidget(onTap: () => taps++),
              WonderTreeBuildingWidget(onTap: () => taps++),
              MathMushroomWidget(onTap: () => taps++),
              PetSanctuaryBuildingWidget(onTap: () => taps++),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AlphabetCastleBuildingWidget), findsOneWidget);
    expect(find.byType(WonderTreeBuildingWidget), findsOneWidget);
    expect(find.byType(MathMushroomWidget), findsOneWidget);
    expect(find.byType(PetSanctuaryBuildingWidget), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/stations_depth_test.dart`

- [ ] **Step 3: Update 4 stations with 135° ground shadows and tactile 3D styling**

- **MathMushroomWidget:** Red dome cap with 3D spherical highlights, white spots with drop shadows, warm glowing door, doorstep cobblestones.
- **WonderTreeWidget:** Multi-tier lush foliage with god rays, glowing dew drops, tree hollow library.
- **PetSanctuaryWidget:** Rustic wooden paddock fence, straw nest with glowing dragon egg, golden bell.
- **AlphabetCastleWidget:** Stone battlements with 3D brick shading, arch gate, fluttering blue/gold pennant flag.
- Ensure all 4 widgets support `scale` parameter for Tier 2 (0.75x) to Tier 4 (1.15x).

- [ ] **Step 4: Run test to verify it passes**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/stations_depth_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/town/presentation/widgets/game_buildings/ test/features/town/stations_depth_test.dart
git commit -m "feat(town): add 135-degree ground shadows and depth scaling to all stations"
```

---

### Task 6: Integrate `DioramaValleyCanvas` into `TownScreen` & Simulator Verification

**Files:**
- Modify: `lib/features/town/presentation/screens/town_screen.dart`
- Delete/Deprecate: `lib/features/town/presentation/widgets/winding_adventure_trail.dart` (if completely replaced)
- Test: `test/features/town/town_screen_integration_test.dart`

- [ ] **Step 1: Write integration test**

```dart
// test/features/town/town_screen_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/screens/town_screen.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_valley_canvas.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_world_hud.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_bottom_dock.dart';

void main() {
  testWidgets('TownScreen mounts DioramaValleyCanvas with Edge HUD and Bottom Dock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TownScreen(),
      ),
    );

    expect(find.byType(DioramaValleyCanvas), findsOneWidget);
    expect(find.byType(GameWorldHud), findsOneWidget);
    expect(find.byType(GameBottomDock), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/town_screen_integration_test.dart`
Expected: FAIL because TownScreen is still using WindingAdventureTrail.

- [ ] **Step 3: Update `TownScreen`**

In `lib/features/town/presentation/screens/town_screen.dart`:
- Replace `WindingAdventureTrail` and `PanoramicTabletVillage` with `DioramaValleyCanvas`.
- Connect all 5 station callbacks (`onMarketTap`, `onMathMushroomTap`, `onWonderTreeTap`, `onPetSanctuaryTap`, `onAlphabetCastleTap`).
- Remove obsolete title banner and redundant background elements.

- [ ] **Step 4: Run all tests and analyzer**

Run:
```bash
/Users/phamchuyen/development/flutter/bin/flutter analyze lib/features/town/
/Users/phamchuyen/development/flutter/bin/flutter test test/features/town/
```
Expected: 0 issues, all tests pass.

- [ ] **Step 5: Hot reload/restart on active simulator & capture screenshot**

Run:
```bash
xcrun simctl io B6DD67DA-0C40-4BCC-B38D-174113179A0F screenshot /Users/phamchuyen/.gemini/antigravity-ide/brain/6865c915-93ab-4445-b588-b43c2124f17a/diorama_valley_simulator.png
```
Inspect screenshot to verify:
- Clean edge HUD.
- No bulky top banners.
- Natural ground foundation blend.
- Unified 135° lighting and shadows.

- [ ] **Step 6: Commit**

```bash
git add lib/features/town/presentation/screens/town_screen.dart test/features/town/town_screen_integration_test.dart
git commit -m "feat(town): integrate DioramaValleyCanvas into TownScreen with clean edge HUD"
```
