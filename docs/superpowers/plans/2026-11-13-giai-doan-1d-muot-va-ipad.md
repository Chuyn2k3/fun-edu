# Giai đoạn 1D — Mượt, có chiều sâu, màn chờ, iPad — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the kid app feel smooth and tactile (raised "candy" cards), start with a branded splash, and lay out properly on iPad in both orientations.

**Architecture:** Rendering hot spots get their own repaint layers (dotted background, writing-pad guide). Depth comes from one decoration helper (`raisedDecoration`) used by every card instead of the flat `AppShadows.card`. Tablets get their own layouts (not a scaled phone UI): a left navigation rail, wider multi-column screens and tablet-sized type and targets, chosen through one `FormFactor` helper. Native launch screens and a Flutter `SplashView` replace the white flash and the bare spinner.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6, go_router 15. No new packages.

**Spec:** owner requests of 2026-11-13 (chat), recorded in `docs/PROJECT_STATE.md`; base design `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` §8 (UI). Decisions made with the owner:
- Depth style: **coloured bottom lip + coloured soft shadow + faint gradient** ("Gờ màu + bóng màu").
- Orientation: **phones portrait only; iPad rotates freely**.
- iPad: **a separate tablet design**, approved from wireframes (`docs/superpowers/specs/assets/ipad-wireframes.png`): left nav rail; home = big "Bài hôm nay" hero + "Tuần này" panel side by side in landscape, 4 subjects in one row (2×2 in portrait); writing = big pad left, Chip + vertical buttons right (landscape) / buttons row under the pad (portrait); math = picture left, answers column right (landscape); maps 5 columns landscape / 4 portrait; parent corner = list-detail; message screens = one centred card ≤ 640 with a larger Chip. Uniform scaling of the phone UI was rejected by the owner.
- The owner saw jank while running **debug** builds; performance must be judged with `flutter run --profile`.

## Global Constraints

- Flutter 3.24.5 / Dart 3.5: `withOpacity` (not `withValues`), no new dependencies, `drift_flutter` stays 0.2.4.
- Colours, radii, shadows only from `lib/ui/theme/tokens.dart` (plus the new `lib/ui/theme/depth.dart`); images only through `lib/ui/assets.dart`.
- A card is ONE `BoxDecoration` carrying both its fill (colour or gradient) and its shadows — never a colourless shadow box over a `Material`.
- Kid touch targets ≥ 64 logical px, parent ≥ 48, text contrast ≥ 4.5:1 against every fill it can sit on (including the bottom of a gradient).
- UI strings Vietnamese, code comments English. `flutter analyze` clean and `flutter test` all green before each commit.
- Commit trailer on every commit:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01AFB1tQYUFMHGwNRJqmZrar`.
- Tablet = `MediaQuery` shortest side ≥ 600 logical px. Phone layouts must stay pixel-identical to today (except the depth change of Task 2).
- Tablet sizes: kid touch targets ≥ 80, body text +20% via `FormFactor`, never by scaling the whole tree.

## Review Focus

1. **Rotating an iPad mid-session** (writing pad half-drawn, math drag in progress) — layout switches between the landscape and portrait variants without an exception; a half-drawn stroke is cleared or kept consistently, never drawn at the wrong place. Test in Task 5.
2. **iPad split view / Slide Over** (app at 320–500 px wide on an iPad) — the phone layout must be used because the *window* is narrow; `FormFactor` reads the window size, not the device model. Test in Task 4.
3. **System text size set to largest** on a phone — raised cards grow, do not clip; the lip stays at the bottom. Test in Task 2.
4. **Keyboard on iPad** (parent corner kid-name field in the detail pane) — the field stays visible above the keyboard. Test in Task 6.
5. **Very long writing session** (hundreds of points per stroke) — the guide layer does not repaint per move. Test in Task 1.

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

### Task 4: Tablet shell — form factor and navigation rail

**Files:**
- Create: `lib/ui/layout/form_factor.dart`
- Create: `lib/ui/widgets/nav_rail.dart`
- Modify: `lib/features/home/home_screen.dart` (only the shell: rail vs floating bar; content unchanged in this task)
- Modify: `lib/features/dev/gallery_screen.dart` (show the rail)
- Test: `test/ui/form_factor_test.dart`, `test/ui/widgets_test.dart`, `test/features/home_screen_test.dart`

**Interfaces:**
- Produces in `form_factor.dart`:
  - `enum FormFactor { phone, tabletPortrait, tabletLandscape }`
  - `FormFactor formFactorOf(Size windowSize)` — `phone` when shortest side < 600; otherwise `tabletLandscape` when width > height, else `tabletPortrait`.
  - `extension FormFactorX on BuildContext { FormFactor get formFactor; bool get isTablet; }` — reads `MediaQuery.sizeOf(this)`.
  - `abstract final class TabletSizes { static const kidTarget = 80.0; static const textScale = 1.2; static const railWidth = 104.0; static const messageMaxWidth = 640.0; }`
- Produces: `class NavRail extends StatelessWidget { const NavRail({required List<NavItem> items, required int selected, required ValueChanged<int> onSelect}) }` — same `NavItem` type as `FloatingNavBar`, vertical white raised pill (uses `raisedDecoration` from Task 2), each item ≥ 80×80 with icon above label, selected item on `Color(0xFFFFECDE)` with `AppColors.accent` icon and label.

- [ ] **Step 1: Write failing tests**
  - `formFactorOf`: 390×844 → phone; 844×390 → phone; 500×1366 (split view) → phone; 1024×1366 → tabletPortrait; 1366×1024 → tabletLandscape; 744×1133 → tabletPortrait.
  - `NavRail shows every item at least 80×80 and calls onSelect with the index`.
  - `home shows NavRail and no FloatingNavBar on 1024×1366 and 1366×1024; FloatingNavBar and no NavRail on 390×844`.
- [ ] **Step 2: Run** the three files — expected FAIL.
- [ ] **Step 3: Implement.** Home on tablet: `Row(NavRail (left, 24 px margin, full height minus safe area), Expanded(content))`; on phone the existing `Stack` with the floating bar, untouched.
- [ ] **Step 4: Run** `flutter analyze && flutter test` — PASS.
- [ ] **Step 5: Commit** `feat: tablet form factor and navigation rail`

---

### Task 5: Tablet home, writing and math

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/writing/writing_screen.dart`
- Modify: `lib/features/math/math_session_screen.dart`
- Create: `lib/features/home/week_panel.dart`
- Modify: `lib/progress/progress_repository.dart` (expose the weekdays set in `HomeSummary` if the panel needs it: `final Set<int> learnedWeekdays` default `{}`)
- Test: `test/features/home_screen_test.dart`, `test/features/writing_screen_test.dart`, `test/features/math_session_screen_test.dart`, `test/features/week_panel_test.dart`

**Interfaces:**
- Consumes: `FormFactor`, `TabletSizes`, `NavRail` (Task 4), `raisedDecoration`, `Pressable` (Task 2).
- Produces: `class WeekPanel extends StatelessWidget { const WeekPanel({required Set<int> learnedWeekdays, required int masteredWriting, required int writingTotal, required int mathLevel, required int mathTotal}) }` — title "Tuần này", 7 day dots labelled `T2 T3 T4 T5 T6 T7 CN` (filled `AppColors.accent` when learned), then "N ngày học", "Chữ đã thuộc: a/b", "Cấp Toán: c/d".

Layouts (from the approved wireframes):
- **Home, tabletLandscape:** top bar (greeting left, parent button right); row: hero lesson card (flex 62) + `WeekPanel` (flex 38), equal height ≥ 300; heading "Hôm nay học gì?"; 4 subject cards in ONE row. **tabletPortrait:** hero full width (≥ 320 tall); subjects 2×2; `WeekPanel` full width under the subjects. Chip image in the hero ≥ 260 tall; play button 110.
- **Writing, tabletLandscape:** pad on the left, square, side = available height minus header; right column (min 300, max 380): Chip reaction card (Chip ≥ 220 tall + message), then "Xem mẫu", "Nghe", "Xóa" as full-width raised buttons ≥ 80 tall, stroke progress at the bottom. **tabletPortrait:** pad centred, side = min(width − 96, height − 360); below it one row: Chip (160) + the three buttons.
- **Math, tabletLandscape:** question area left (flex 3), answers column right (flex 2), answer tiles ≥ 96 tall. **tabletPortrait:** current phone layout with max width 720 and tiles ≥ 96.
- Text on tablet: apply `TabletSizes.textScale` with a `MediaQuery(textScaler: …)` around kid screens' content only when `isTablet` (compose with the user's own scale: `TextScaler.linear(user.scale(1) * 1.2)`).

- [ ] **Step 1: Write failing tests**
  - Home landscape (1366×1024): hero and `WeekPanel` side by side (WeekPanel left edge > hero right edge, same top ±1); the four `SubjectCard`s share one top y (±1).
  - Home portrait (1024×1366): subject cards form 2 rows of 2; `WeekPanel` below the last subject row.
  - Home phone (390×844): no `WeekPanel`; layout unchanged (existing tests keep passing).
  - `WeekPanel` fills exactly the learned weekdays `{1,2,4}` → T2, T3, T5.
  - Writing landscape: pad's right edge < Chip card's left edge; pad is square; the three buttons are stacked vertically and each ≥ 80 tall.
  - Writing portrait: buttons in one row below the pad.
  - Writing rotation: draw half a stroke at 1366×1024, switch to 1024×1366, pump — no exception, the pad is square and the in-progress stroke is discarded (no stroke reported to the grader).
  - Math landscape: every answer tile's left edge > the question area's right edge; tiles ≥ 96 tall.
- [ ] **Step 2: Run** the test files — expected FAIL.
- [ ] **Step 3: Implement** per the layouts above; branch on `context.formFactor` at the top of each screen's body; keep the phone branch byte-for-byte the current widget tree.
- [ ] **Step 4: Run** `flutter analyze && flutter test` — PASS. Render each screen at 390×844, 1024×1366, 1366×1024 with the shot test (`docs/perf.md` §screenshots) and attach to the review.
- [ ] **Step 5: Commit** `feat: tablet layouts for home, writing and math`

---

### Task 6: Tablet maps, parent corner and message screens

**Files:**
- Modify: `lib/features/subject/{writing_map_screen,math_map_screen}.dart`
- Modify: `lib/parent/screens/parent_home.dart`
- Modify: `lib/features/lesson/lesson_done_screen.dart`, `lib/features/sleep/sleep_screen.dart`, `lib/features/placement/placement_screen.dart`, `lib/parent/parent_gate.dart`, `lib/features/setup/first_run_screen.dart`
- Test: `test/features/math_map_test.dart`, `test/features/writing_map_test.dart`, `test/parent/parent_home_test.dart`, `test/features/lesson_done_test.dart`

**Interfaces:**
- Consumes: `FormFactor`, `TabletSizes` (Task 4).

Layouts:
- **Maps:** grid columns = 5 (tabletLandscape) / 4 (tabletPortrait) / current (phone); tiles ≥ 120.
- **Parent corner on tablet:** list-detail. Left pane 300 wide: kid chips on top, then the 5 tabs as a vertical list (icon + label, ≥ 56 tall, selected row highlighted); right pane: the selected tab's content, max width 720, scrolls on its own; no bottom navigation. Phone unchanged.
- **Message screens** (lesson done, sleep, placement welcome/finish, parent gate, first run): content in one centred raised card, max width `TabletSizes.messageMaxWidth`, Chip image ×1.4 of its phone size.

- [ ] **Step 1: Write failing tests**
  - Maps: 1366×1024 → first row holds 5 tiles; 1024×1366 → 4; 390×844 → unchanged count.
  - Parent corner 1366×1024: no `NavigationBar`/bottom nav; the five tab labels are visible at the same time in a column (same x ±1); tapping "Thời gian" shows the time tab content in the right pane (its left edge ≥ 300).
  - Parent corner keyboard: on 1024×1366 with `viewInsets.bottom = 400`, focus the kid-name field in Hồ sơ; after `pumpAndSettle` the field's bottom ≤ 1366 − 400.
  - Lesson done on 1024×1366: the card width ≤ 640 and is horizontally centred (±1).
- [ ] **Step 2: Run** the files — expected FAIL.
- [ ] **Step 3: Implement** as above; phone branches unchanged.
- [ ] **Step 4: Run** `flutter analyze && flutter test` — PASS. Render the parent corner and a map at both iPad orientations for the review.
- [ ] **Step 5: Commit** `feat: tablet layouts for maps, parent corner and message screens`

---

### Task 7: Docs

**Files:** `docs/PROJECT_STATE.md` (sections 2, 3, 4, 6, 7, 8), `AGENTS.md` (add: use `raisedDecoration` for cards; tablet layouts branch on `context.formFactor` (never scale the phone UI); judge performance only in profile mode).

- [ ] **Step 1:** Update the docs to describe depth helper, splash, tablet scaling, orientation rules, how to profile; mark 1D done in §6; move any accepted limitation to §7.
- [ ] **Step 2:** `flutter analyze && flutter test` — PASS (no code change expected).
- [ ] **Step 3: Commit** `docs: record phase 1D`
