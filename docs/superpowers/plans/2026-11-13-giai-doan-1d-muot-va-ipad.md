# Giai đoạn 1D — Mượt, có chiều sâu, màn chờ, iPad — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the kid app feel smooth and tactile (raised "candy" cards), start with a branded splash, and lay out properly on iPad in both orientations.

**Architecture:** Rendering hot spots get their own repaint layers (dotted background, writing-pad guide). Depth comes from one decoration helper (`raisedDecoration`) used by every card instead of the flat `AppShadows.card`. Tablets get a uniform scale (`AdaptiveScale`) so the phone layouts grow proportionally, plus a two-column home in wide landscape. Native launch screens and a Flutter `SplashView` replace the white flash and the bare spinner.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6, go_router 15. No new packages.

**Spec:** owner requests of 2026-11-13 (chat), recorded in `docs/PROJECT_STATE.md`; base design `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` §8 (UI). Decisions made with the owner:
- Depth style: **coloured bottom lip + coloured soft shadow + faint gradient** ("Gờ màu + bóng màu").
- Orientation: **phones portrait only; iPad rotates freely**, landscape home uses two columns.
- The owner saw jank while running **debug** builds; performance must be judged with `flutter run --profile`.

## Global Constraints

- Flutter 3.24.5 / Dart 3.5: `withOpacity` (not `withValues`), no new dependencies, `drift_flutter` stays 0.2.4.
- Colours, radii, shadows only from `lib/ui/theme/tokens.dart` (plus the new `lib/ui/theme/depth.dart`); images only through `lib/ui/assets.dart`.
- A card is ONE `BoxDecoration` carrying both its fill (colour or gradient) and its shadows — never a colourless shadow box over a `Material`.
- Kid touch targets ≥ 64 logical px, parent ≥ 48, text contrast ≥ 4.5:1 against every fill it can sit on (including the bottom of a gradient).
- UI strings Vietnamese, code comments English. `flutter analyze` clean and `flutter test` all green before each commit.
- Commit trailer on every commit:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01AFB1tQYUFMHGwNRJqmZrar`.
- Tablet = `MediaQuery` shortest side ≥ 600 logical px (before scaling).

## Review Focus

1. **Rotating an iPad mid-session** (writing pad half-drawn, math drag in progress) — layout re-flows, no exception, the drawn stroke stays in place relative to the pad. Test in Task 4.
2. **Taps on a scaled tablet layout** must land on the widget drawn under the finger (hit-testing through the scale). Test in Task 4.
3. **System text size set to largest** on a phone — raised cards must grow, not clip; the lip must stay at the bottom. Test in Task 2.
4. **Keyboard on a tablet** (parent corner kid-name field) — view insets are scaled with the layout, the field stays visible. Test in Task 4.
5. **Very long writing session** (hundreds of points per stroke) — painting cost must not grow with the number of finished strokes' guide work per frame. Test in Task 1.

---

### Task 1: Rendering hot spots

The writing pad re-dashes every guide stroke (`computeMetrics` + `extractPath`) on every pointer move and copies the point list each move; the dotted background redraws ~1,500–2,500 circles whenever anything above it repaints.

**Files:**
- Modify: `lib/ui/widgets/dotted_background.dart`
- Modify: `lib/features/trace/trace_pad.dart`
- Modify: `lib/app.dart` (precache)
- Create: `lib/ui/precache.dart`
- Create: `docs/perf.md`
- Test: `test/ui/widgets_test.dart`, `test/features/trace_pad_test.dart` (create if missing; keep existing TracePad tests green)

**Interfaces:**
- Produces: `Future<void> precacheAppImages(BuildContext context)` — precaches every path in `AppImages.all` (add a `static const List<String> all` to `AppImages` if it does not exist).
- `TracePad` public API unchanged.

- [ ] **Step 1: Write failing tests**
  - `DottedBackground wraps its painter in a RepaintBoundary`: `find.descendant(of: find.byType(DottedBackground), matching: find.byType(RepaintBoundary))` finds at least one, and the `CustomPaint` has `isComplex: true, willChange: false`.
  - `guide layer does not repaint while drawing`: pump a `TracePad` with a 2-stroke guide, drag 50 moves; assert the guide painter's `shouldRepaint` returned false for every frame (expose the guide painter as `@visibleForTesting class GuidePainter` with a static paint counter, or count via a test-only callback) — expected paint count of the guide layer: 1.
  - `ink keeps every point of a long stroke`: drag 600 moves; the stroke delivered to `onStrokeEnd` has ≥ 600 points.
- [ ] **Step 2: Run** `flutter test test/ui/widgets_test.dart test/features/trace_pad_test.dart` — expected FAIL.
- [ ] **Step 3: Implement**
  - `DottedBackground`: `RepaintBoundary(child: CustomPaint(isComplex: true, willChange: false, painter: ..., child: ...))` — the boundary wraps only the painter layer (use a `Stack` with the painted layer under `child`) so scrolling content does not repaint the dots.
  - `TracePad`: split into two `CustomPaint`s in a `Stack`, each in its own `RepaintBoundary`: `GuidePainter(guide, side)` with `shouldRepaint` true only when the guide list or size changes, dash paths computed once and cached in the painter; `_InkPainter` driven by a `ChangeNotifier` (`repaint:`) that appends points in place (no `[..._current, p]` copies, no `setState` per move).
  - `precacheAppImages` called once from the App's first frame (inside the splash, Task 3 will move it there — for now `WidgetsBinding.instance.addPostFrameCallback` in `App.build` guarded by a static bool).
  - `docs/perf.md`: how to measure (`flutter run --profile`, DevTools Performance tab, "Track widget rebuilds"), why debug builds stutter, target: no frame over 16 ms on the home scroll and while writing, on a mid-range Android and an iPad.
- [ ] **Step 4: Run** the two test files, then `flutter analyze && flutter test` — all PASS.
- [ ] **Step 5: Commit** `perf: cache writing guide and dotted background layers`

---

### Task 2: Raised "candy" cards

**Files:**
- Create: `lib/ui/theme/depth.dart`
- Modify: `lib/ui/theme/tokens.dart` (keep `AppShadows.card` only if something still needs a flat shadow; otherwise delete it)
- Modify every file that uses `AppShadows.card` (22 uses): `lib/ui/widgets/{app_card,subject_card,info_pill,speech_bubble,floating_nav_bar,session_header}.dart`, `lib/features/home/home_screen.dart`, `lib/features/subject/{writing_map_screen,math_map_screen}.dart`, `lib/features/writing/writing_screen.dart`, `lib/features/math/exercise/{choice_answers,drag_number_match,compare_groups}.dart`, `lib/parent/parent_gate.dart`, `lib/parent/screens/{parent_card,progress_tab,settings_tab}.dart`
- Create: `lib/ui/widgets/pressable.dart`
- Test: `test/ui/depth_test.dart`, `test/ui/contrast_test.dart`

**Interfaces:**
- Produces (in `depth.dart`):
  - `BoxDecoration raisedDecoration({Color accent = AppDepth.neutral, Color? tint, double radius = AppRadii.card, bool pressed = false})`
  - `abstract final class AppDepth { static const neutral = Color(0xFF8A5A2B); static const lip = 5.0; static const pressedLip = 2.0; }`
  - For subjects: call with `accent: subject.color, tint: subject.tint`.
- Produces: `class Pressable extends StatefulWidget { Pressable({required Widget Function(bool pressed) builder, VoidCallback? onTap, String? semanticsLabel}) }` — tracks pointer down/up/cancel, moves its child down by `AppDepth.lip - AppDepth.pressedLip` while pressed, calls `onTap` on up.

Exact decoration (values fixed by the owner-approved mock):
- `gradient`: top `AppColors.card` → bottom `Color.lerp(AppColors.card, tint ?? const Color(0xFFFFF4E6), 0.9)`, vertical.
- `border`: bottom only, width `pressed ? AppDepth.pressedLip : AppDepth.lip`, colour `accent.withOpacity(0.28)`.
- `boxShadow`: `[BoxShadow(color: accent.withOpacity(0.16), blurRadius: 22, offset: Offset(0, 12)), BoxShadow(color: Color(0x14503C28), blurRadius: 3, offset: Offset(0, 1))]`; when `pressed`, the first shadow uses `blurRadius: 12, offset: Offset(0, 5)`.
- `borderRadius`: `BorderRadius.circular(radius)`.

- [ ] **Step 1: Write failing tests** in `test/ui/depth_test.dart`:
  - `raisedDecoration has a gradient, a 5px tinted bottom lip and two shadows` (assert the exact values above for `accent: Subject.viet.color, tint: Subject.viet.tint`).
  - `pressed lowers the lip to 2px and tightens the shadow`.
  - `SubjectCard, AppCard, InfoPill, SpeechBubble, FloatingNavBar use raisedDecoration` — pump each, find the outer `DecoratedBox`/`Container` decoration, expect `gradient != null` and bottom border width 5.
  - `Pressable moves its child 3px while pressed and taps once` (gesture down → `tester.getTopLeft` +3; up → onTap called once; cancel → no tap).
  - `raised card grows with text scale 2.0 without overflow` (pump SubjectCard in a 180-wide box under `MediaQuery(textScaler: TextScaler.linear(2))`, expect no `FlutterError` and lip still the last 5 px of the box).
  - In `contrast_test.dart`: for every `Subject` and the neutral tint, `AppColors.textMuted` and `AppColors.text` against `Color.lerp(AppColors.card, tint, 0.9)` ≥ 4.5.
- [ ] **Step 2: Run** `flutter test test/ui/depth_test.dart test/ui/contrast_test.dart` — expected FAIL.
- [ ] **Step 3: Implement** `depth.dart` and `pressable.dart`, then migrate every `AppShadows.card` use to `raisedDecoration(...)`: subject-coloured places pass their subject (subject cards, map tiles, math answer tiles use `Subject.toan`, writing screen uses `Subject.viet`); everything else uses the neutral default. Kid-facing tappable cards (subject cards, lesson card, map tiles, math answer tiles) are wrapped in `Pressable` so they visibly sink on touch; parent screens keep `InkWell` (no sink).
- [ ] **Step 4: Run** `flutter analyze && flutter test` — all PASS. Render the home, writing and math screens with the scratch shot test (see `docs/perf.md` §screenshots, add that section) and attach the PNGs to the review package. Note: `flutter_tester` draws shadows without blur, so judge shadows on device.
- [ ] **Step 5: Commit** `feat: raised candy-style cards with press feedback`

---

### Task 3: Splash and fast start

**Files:**
- Modify: `tools/assets/make_app_icons.py` (also writes launch images)
- Create: `android/app/src/main/res/drawable*/launch_logo.png` (generated), `android/app/src/main/res/values-v31/styles.xml`, `android/app/src/main/res/values/colors.xml`
- Modify: `android/app/src/main/res/drawable/launch_background.xml`, `drawable-v21/launch_background.xml`
- Modify: `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `ios/Runner/Assets.xcassets/LaunchImage.imageset/*` (generated)
- Create: `lib/features/splash/splash_view.dart`
- Modify: `lib/app.dart` (replace the loading `CircularProgressIndicator` with `SplashView`; move precache there), `lib/ui/assets.dart` (add `logo`), `assets/images/logo.png` (generated, 512×512 from the icon source, rounded 22% corners, transparent outside)
- Test: `test/features/splash_view_test.dart`, `test/app_navigation_test.dart`

**Interfaces:**
- Produces: `class SplashView extends StatelessWidget { const SplashView({super.key}); }` keyed `ValueKey('splash')`.
- Consumes: `precacheAppImages` (Task 1), `AppImages.logo`.

Look: background `AppColors.background` (#FBF5EC) everywhere (native and Flutter) so there is no colour jump; logo centred at 160 logical px; under it the word "ChipChip" in Nunito 900, 34 px, `AppColors.primary`; a gentle 900 ms scale "breathing" (0.96↔1.0) on the logo, repeating while loading. No artificial minimum duration: the splash leaves as soon as data is ready, with a 250 ms fade.

- [ ] **Step 1: Write failing tests**
  - `App shows SplashView, not a spinner, while the kid is loading` (override `currentKidIdProvider` with a never-completing future; expect `find.byKey(ValueKey('splash'))` and `find.byType(CircularProgressIndicator)` finds nothing).
  - `SplashView shows the logo and the word ChipChip`.
  - `splash fades out once data is ready` (complete the future; after `pump(300ms)` the splash is gone and home is shown).
  - `make_app_icons.py` writes the Android/iOS launch images — add a pytest in `tools/assets/test_make_app_icons.py` that runs `main()` on a 64×64 solid test image in a temp copy of the expected folder layout and checks the files exist with the expected sizes (Android launch_logo: mdpi 160, hdpi 240, xhdpi 320, xxhdpi 480, xxxhdpi 640; iOS LaunchImage 1x/2x/3x: 168/336/504).
- [ ] **Step 2: Run** `flutter test test/features/splash_view_test.dart test/app_navigation_test.dart` and `cd tools/assets && python3 -m pytest -q` — expected FAIL.
- [ ] **Step 3: Implement**
  - Native: Android `launch_background.xml` = cream colour item + centred `@drawable/launch_logo` bitmap; `values-v31/styles.xml` LaunchTheme sets `android:windowSplashScreenBackground` `@color/splash_bg` (#FBF5EC) and `android:windowSplashScreenAnimatedIcon` `@mipmap/ic_launcher`; iOS storyboard background #FBF5EC (sRGB 0.984, 0.961, 0.925) with the LaunchImage centred.
  - `main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, then on phones (shortest side of `PlatformDispatcher.instance.views.first` in logical px < 600) `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` before `runApp` (do not await anything else before `runApp`).
  - iOS `Info.plist` `UISupportedInterfaceOrientations` (iPhone key): portrait only. `~ipad` key unchanged.
- [ ] **Step 4: Run** `flutter analyze && flutter test && (cd tools/assets && python3 -m pytest -q)` — all PASS.
- [ ] **Step 5: Commit** `feat: branded splash and portrait lock on phones`

---

### Task 4: Tablet layout

**Files:**
- Create: `lib/ui/layout/adaptive_scale.dart`
- Modify: `lib/app.dart` (wrap the routed child, inside `ScreenTimeGuard`'s parent, with `AdaptiveScale`)
- Modify: `lib/features/home/home_screen.dart` (two-column layout when wide)
- Modify: `lib/features/subject/{writing_map_screen,math_map_screen}.dart` (column count by width)
- Test: `test/ui/adaptive_scale_test.dart`, `test/features/home_screen_test.dart`, `test/features/writing_screen_test.dart` (rotation case)

**Interfaces:**
- Produces: `double tabletScale(Size logicalSize)` — `1.0` when shortest side < 600, else `clamp(shortestSide / 600, 1.0, 1.5)` (iPad mini 744 → 1.24, iPad 820 → 1.37, iPad Pro 1024 → 1.5). Scaled landscape widths: iPad mini 914, iPad 863, iPad Pro 911 — all two-column.
- Produces: `class AdaptiveScale extends StatelessWidget { const AdaptiveScale({required Widget child}) }` — child sees a `MediaQuery` whose `size`, `padding`, `viewPadding`, `viewInsets` are divided by the scale, laid out in a box of `size / scale` and painted with `Transform.scale(scale, alignment: Alignment.topLeft)`.
- Produces: `const double wideLayoutMinWidth = 840;` in `home_screen.dart` — at or above this (scaled) width the home shows two columns.

- [ ] **Step 1: Write failing tests**
  - `tabletScale`: 390×844 → 1.0; 744×1133 → 1.24 (±0.01); 820×1180 → 1.37 (±0.01); 1024×1366 → 1.5; 1366×1024 → 1.5.
  - `AdaptiveScale gives the child a smaller logical size on tablets` (view 1024×1366 @2x: child's `MediaQuery.sizeOf` == 682.7×910.7 ±0.5).
  - `taps land on the scaled widget` (a 100×100 button at child-logical (300, 400); tap at physical-logical (450, 600) on a 1.5 scale → onTap called; tap at (300, 400) → not called).
  - `keyboard inset is scaled` (`viewInsets.bottom` 450 → child sees 300).
  - `home uses two columns in iPad landscape` (1366×1024 and 1180×820: the subject grid and the lesson card are side by side — `tester.getTopLeft` of the "Hôm nay học gì?" heading has x greater than the lesson card's right edge); `home stays single column on iPad portrait and phones`.
  - `writing pad survives rotation` (pump writing screen at 1024×1366, draw half a stroke, change view to 1366×1024, pump; no exception and the pad is still a square of side min(available width, available height)).
  - Map screens: 3 columns at scaled width ≥ 600, otherwise the current count.
- [ ] **Step 2: Run** the test files — expected FAIL.
- [ ] **Step 3: Implement** as specified. Home two-column: left column (max 460) = top row, Chip/lesson card, streak pill; right column = "Hôm nay học gì?" + subject grid; both scroll together in one `ListView`-free `Row` inside a `SingleChildScrollView`; floating nav bar unchanged, centred, max width 560. Keep phone layout code path identical to today.
- [ ] **Step 4: Run** `flutter analyze && flutter test` — all PASS. Render home at 390×844, 820×1180, 1180×820 with the shot test and attach to the review.
- [ ] **Step 5: Commit** `feat: scale kid layouts on tablets and two-column home in landscape`

---

### Task 5: Docs

**Files:** `docs/PROJECT_STATE.md` (sections 2, 3, 4, 6, 7, 8), `AGENTS.md` (add: use `raisedDecoration` for cards; tablet = `AdaptiveScale`; judge performance only in profile mode).

- [ ] **Step 1:** Update the docs to describe depth helper, splash, tablet scaling, orientation rules, how to profile; mark 1D done in §6; move any accepted limitation to §7.
- [ ] **Step 2:** `flutter analyze && flutter test` — PASS (no code change expected).
- [ ] **Step 3: Commit** `docs: record phase 1D`
