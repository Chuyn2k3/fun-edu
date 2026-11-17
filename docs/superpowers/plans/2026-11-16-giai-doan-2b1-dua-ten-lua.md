# Giai đoạn 2B-1 — Đua tên lửa (một mình) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An offline "Đua tên lửa" game in the "Chơi" tab: the child picks Toán or Tiếng Việt, races Chíp Chíp over 10 questions on a smooth 2.5D/3D space track, earns cosmic stars that unlock rockets/trails/stickers (pick 1 of 2 at each milestone), earns 8 badges, and sees game-only stats — none of it touches the home screen.

**Architecture:** Pure-Dart race engine (`lib/game/engine/`) produces questions, steps, Chíp pacing and rewards; a drift-backed game repository (`lib/game/data/`, schema v7) stores per-kid results, cosmic stars, owned items and badges; rendering (`lib/game/scene/`) is CustomPainter-based (track, multi-layer flame + smoke particles, parallax clouds) driven by one Ticker; screens live in `lib/features/game/`. 3D art is pre-rendered images cut out by `tools/assets`.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6, go_router 15, drift 2.23 (schema v7); Python 3 + Pillow + numpy for asset cut-out.

**Spec:** `docs/superpowers/specs/2026-11-16-giai-doan-2b1-dua-ten-lua-mot-minh-design.md` (read §2, §6, §6b — the tables there are binding). Approved visuals: Design canvas row "Bản 7" (https://claude.ai/artifact/4ARDzEvtmu8NuYNJtuEq4o) — the owner's reference; implementers may not be able to open it, the text below describes what matters.

## Global Constraints

- Everything in `AGENTS.md`: Flutter 3.24.5, **no new packages**, `withOpacity`, tokens only (`lib/ui/theme/tokens.dart`; add game tokens there), `raisedDecoration`/`Pressable` for cards and kid tappables, tablet branches via `context.formFactor` (kid targets ≥ 80 on tablet, ≥ 64 phone), contrast ≥ 4.5, Vietnamese UI strings, drift change ⇒ `schemaVersion` 7 + migration + build_runner + committed `.g.dart`, analyze + all tests green, commit trailer.
- Game data is **separate**: never write to `lesson_completions`, `subject_levels`, `glyph_progress`, `daily_usage` from the game; home screen and parent corner show nothing about the game.
- Screen time: game routes are ordinary kid routes (counted, bedtime/limit block them). Placement redirect applies.
- Offline only. No network.
- Reduce motion: when `MediaQuery.of(context).disableAnimations` is true — flame drawn static, no shake, no confetti/fireworks motion (show final frame), rockets move without overshoot.
- Performance target: 60 fps on a mid-range phone and iPad in `flutter run --profile`; every animated layer in its own `RepaintBoundary`; one `Ticker` per scene; no per-frame allocations in paint hot paths (reuse `Paint`/`Path`, pre-allocated particle pool).
- Race rules (spec §6.1–6.2): 10 questions; questions 3, 6, 9 (1-based) are comet questions: correct = +2 steps, others +1; finish at 10 steps; wrong ⇒ shake, child retries the same question, no step lost; Chíp advances 1 step every `interval` ms where `interval = 1.25 × mean(kid answer time in this race)`, initial mean = stored mean of past races or 6000 ms; Chíp never leads the child by more than 2 steps (pauses instead); after a lost race the next race's interval × 1.15 (that race only); Chíp has no comets.
- Cosmic stars (spec §6.4): win 5, lose 3, +1 per comet question answered correctly on the first try, +2 when the race beats the child's own best finish time for that subject (not on the first race of that subject). Never subtracted.
- Milestones: 10, 25, 40, 60, 85, 115, 150, 190, then every +50. Reward pool order: `rocket_blue, trail_rainbow, sticker_clap, rocket_green, trail_sparkle, sticker_laugh, rocket_purple, trail_blue_flame`. At a milestone the child is offered the first two unowned pool items and picks one; the other stays first in line. Owned from the start: `rocket_orange`, `trail_flame`. Pool empty ⇒ milestone gives no offer.
- Badges (spec §6.4b) — id, name, rule, sticker id:
  `speed_king` "Vua Thần Tốc" — beat own best time 3 times (any subject) — `sticker_pilot_goggles`;
  `scholar` "Nhà Thông Thái" — a won race with no question missed (every answer right on the first try; a perfect race ends at question 8 because comets give +2) — `sticker_grad_cap`;
  `comet_hunter` "Thợ Săn Sao Chổi" — 10 comet questions correct (first try, cumulative) — `sticker_hug_star`;
  `never_give_up` "Không Bỏ Cuộc" — 3 times: pressed "Đua lại!" on a lost result and finished that next race — `sticker_fist`;
  `chip_buddy` "Bạn Thân Chíp Chíp" — 5 wins — `sticker_hug_heart`;
  `math_whiz` "Siêu Toán Học" — 50 first-try-correct Toán answers — `sticker_abacus`;
  `letter_master` "Bậc Thầy Chữ Cái" — 50 first-try-correct Tiếng Việt answers — `sticker_crayon`;
  `pilot` "Phi Công Chăm Chỉ" — 20 finished races — `sticker_wave_rocket`.
- Abandoned race (left before finish): nothing stored.

## Review Focus

1. **Kid leaves mid-race** (back button, app backgrounded, bedtime screen covers it) — no result, no stars, no badge progress; returning to Góc Chơi works. Test in Task 5.
2. **Milestone crossed by more than one step in a single race** (e.g. 22 → 41 stars crosses 25 and 40) — the child gets two offers in sequence, none lost. Test in Task 3.
3. **Kid with no letters reached yet** picks Tiếng Việt — falls back to the first group (i t u ư n m v r s); never an empty question list or duplicate choices. Test in Task 2.
4. **Kid switch** (another kid profile) — game profile, owned items, badges and stats are per kid. Test in Task 3.
5. **Rotation / split view mid-race on iPad** — race state kept (engine outside widget tree, `ValueKey` on the scene), no exception. Test in Task 5.

---

### Task 1: Game art pipeline

**Files:**
- Create: `tools/assets/chroma_key.py`, `tools/assets/test_chroma_key.py`, `tools/assets/configs/game/*.json`
- Modify: `tools/assets/build_app_images.sh`, `lib/ui/assets.dart`, `pubspec.yaml` (only if assets are listed per folder: add `assets/images/game/`)
- Create (generated, committed): `assets/images/game/*.png` (+ `2.0x/`, `3.0x/` variants as the existing images do)
- Test: `test/ui/assets_test.dart`

**Interfaces:**
- Produces `AppImages` constants (and add them to `AppImages.all`): `rocketOrange, rocketBlue, rocketGreen, rocketPurple, rocketChip` (Chíp in white rocket, `chip_chip_in_rocket_v2…`), `planet, comet, finsBolt, noseStar, trailRainbow`, and badges `badgeSpeedKing, badgeScholar, badgeCometHunter, badgeNeverGiveUp, badgeChipBuddy, badgeMathWhiz, badgeLetterMaster, badgePilot`. Asset files under `assets/images/game/` named by the constant in kebab-case (`rocket-orange.png`, `badge-speed-king.png`, …).
- Source images: `docs/superpowers/specs/assets/generated/game-rocket/` (white background) and `docs/superpowers/specs/assets/generated/medals/` (green #00C853 background). Use the "v2" medal where the gallery marks a main file (`nha_thong_thai_badge_v2…`, `friendship_medal_badge_v2…`).

- [ ] **Step 1: Write failing tests**
  - `test_chroma_key.py`: a synthetic 64×64 image with a green (#00C853) background and a red disc → output alpha 0 at the corners, alpha 255 at the disc centre, and no green fringe (edge pixels' green channel ≤ red channel + 30 after despill).
  - `assets_test.dart`: every new `AppImages` constant exists on disk with 2.0x and 3.0x variants and has an alpha channel.
- [ ] **Step 2: Run** `cd tools/assets && python3 -m pytest -q` and `flutter test test/ui/assets_test.dart` — expected FAIL.
- [ ] **Step 3: Implement** `chroma_key.py` (key on distance to the sampled corner colour, soft edge, despill) with the same CLI shape as `cut_sheet.py` (image + config + out dir); white-background rockets use the existing `cut_sheet.py` with a `thr` that keeps their white parts (the Chíp rocket's white body must stay opaque — check by rendering on dark navy). Add the build lines to `build_app_images.sh`. Rockets exported at a width giving ≥ 3× density for a 120-pt-tall rocket; badges for 140 pt.
- [ ] **Step 4: Run** both test commands → PASS; render a contact sheet of all new PNGs on #2A2766 and look at it (no holes, no halos); list the PNG path in the report.
- [ ] **Step 5: Commit** `feat: game art (rockets, planet, comet, badges)`

---

### Task 2: Race engine (pure Dart)

**Files:**
- Create: `lib/game/engine/race_question.dart`, `lib/game/engine/question_source.dart`, `lib/game/engine/race.dart`, `lib/game/engine/chip_pacer.dart`, `lib/game/engine/rewards.dart`
- Test: `test/game/engine/*_test.dart`

**Interfaces:**
- Consumes: `generateQuestions(...)` and `MathQuestion` subclasses (`lib/math/`), `mathLevels`, `writingLadder`, `GlyphStat` (`lib/progress/progress_repository.dart`).
- Produces:
  - `enum RaceSubject { toan, tiengViet }`
  - `sealed class RaceQuestion { String get spoken; int get correctIndex; bool get comet; }` with `MathRaceQuestion(MathQuestion q, List<int> choices)`, `LetterRaceQuestion(String targetGlyphId, List<String> choiceGlyphIds)` (spoken = target glyph's `speech`), `ToneRaceQuestion(String targetMarkId, List<String> choiceMarkIds)` (spoken = "dấu …"). Exactly 3 choices, no duplicates.
  - `List<RaceQuestion> buildRaceQuestions({required RaceSubject subject, required int mathLevelIndex, required Map<String, GlyphStat> glyphStats, required int writingStartIndex, required Map<String, String> speechByGlyph, required Random rng})` — 10 questions; indexes 2, 5, 8 have `comet = true`. Toán: only questions whose answer is an int (skip `CompareQuestion`), choices = 3 ints incl. the answer. Tiếng Việt: letter pool = `chu-*` ladder entries up to (highest ladder index with completions > 0, or `writingStartIndex − 1`, whichever is larger) + 3 more; if the pool has < 3 letters use `chu-i chu-t chu-u chu-uw chu-n chu-m chu-v chu-r chu-s`. Distractors prefer the same confusable group: `{b d h l k}`, `{n m u uw v r}`, `{o oo ow a aw aa c e ee}`, `{g y p q d}`, `{t i dd s x}` (ids `chu-…`), filled from the pool otherwise. Tone questions (30 %) only when the kid's progress has reached `dau-huyen`; else all letter questions.
  - `class Race` — `Race({required List<RaceQuestion> questions, required ChipPacer pacer})`; `int kidSteps`, `int chipSteps`, `int questionIndex`, `bool get finished`, `RaceOutcome? outcome`; `AnswerResult answer(int choiceIndex, Duration elapsed)` (correct ⇒ +1, or +2 on a comet question; a comet still gives +2 if answered correctly after a wrong try, but only first-try comets count for stars/badges; `firstTry` tracked per question); `void tick(Duration now)` advances Chíp via the pacer; finish at 10 steps (clamped). `RaceOutcome { bool won; Duration kidTime; int firstTryCorrect; int cometsFirstTry; List<RaceQuestion> missed }`.
  - `class ChipPacer` — `ChipPacer({Duration initialMean = const Duration(milliseconds: 6000), double slowdown = 1.0})`; interval = 1.25 × running mean of kid answer times (initial mean until the first answer) × slowdown; `bool shouldStep(Duration now, {required int chipSteps, required int kidSteps})` false when `chipSteps >= kidSteps + 2`.
  - `int cosmicStarsFor(RaceOutcome o, {required bool beatRecord})` per Global Constraints.

- [ ] **Step 1: Write failing tests**
  - comet questions at indexes 2, 5, 8; correct comet ⇒ +2, other ⇒ +1; wrong ⇒ steps unchanged and same question remains; finish clamps at 10; kid can finish before question 10.
  - pacer: with kid answers of 2 s each Chíp steps every 2.5 s; Chíp never exceeds kid + 2; slowdown 1.15 lengthens the interval by 15 %; initial mean used before the first answer.
  - cosmic stars: win 5 / lose 3; +1 per first-try comet; +2 with `beatRecord`.
  - Toán questions never contain `CompareQuestion`; every question has 3 distinct choices with the answer at `correctIndex`; across 200 seeded builds per level.
  - Tiếng Việt: kid with no progress ⇒ all targets in the first-group list; kid with progress up to `chu-a` ⇒ targets ⊆ ladder up to `chu-a` + 3; distractor for `chu-b` comes from `{d h l k}` when those are in the pool; no tone questions before `dau-huyen` is reached; 3 distinct choices always.
- [ ] **Step 2: Run** `flutter test test/game/engine/` — expected FAIL.
- [ ] **Step 3: Implement** the engine (no Flutter imports except `foundation` if needed; injectable `Random` and clock).
- [ ] **Step 4: Run** the tests → PASS; `flutter analyze && flutter test`.
- [ ] **Step 5: Commit** `feat: rocket race engine`

---

### Task 3: Game data — results, cosmic stars, rewards, badges (schema v7)

**Files:**
- Create: `lib/game/data/game_tables.dart`, `lib/game/data/game_repository.dart`, `lib/game/data/badges.dart`, `lib/game/data/reward_pool.dart`
- Modify: `lib/data/app_database.dart` (tables, `schemaVersion` 7, migration `from < 7`), regenerated `app_database.g.dart`, `lib/profile/kid_repository.dart` (delete a kid ⇒ delete game rows; "xóa toàn bộ dữ liệu" too)
- Test: `test/game/data/*_test.dart`, `test/data/migration_test.dart`

**Interfaces:**
- Tables (all with `kid_id`): `race_results(id, kid_id, subject, finished_at, won, kid_time_ms, first_try_correct, comets_first_try, stars)`; `game_profile(kid_id PK, cosmic_stars, selected_rocket, selected_trail, mean_answer_ms, slow_next_race, retry_after_loss_pending)`; `game_items(kid_id, item_id, PK(kid_id,item_id))`; `game_badges(kid_id, badge_id, earned_at, PK)`; `game_counters(kid_id, key, value, PK)` for badge progress (`records_beaten`, `comets_first_try`, `retry_after_loss`, `wins`, `math_correct`, `tv_correct`, `races`).
- `reward_pool.dart`: `const rewardPool = [...]` (Global Constraints order), `const starterItems = {'rocket_orange', 'trail_flame'}`, `List<int> milestones()` (10,25,40,60,85,115,150,190 then +50), `List<String> nextOffer(Set<String> owned)` (first two unowned).
- `badges.dart`: `enum GameBadge { speedKing, scholar, cometHunter, neverGiveUp, chipBuddy, mathWhiz, letterMaster, pilot }` with `id`, `title` (exact Vietnamese names), `howTo` (one-line Vietnamese hint), `stickerId`, `image` (AppImages from Task 1).
- `GameRepository` (per kid, same provider pattern as `ProgressRepository`): `Future<RaceRecordResult> recordRace(RaceSubject subject, RaceOutcome o, {required bool wasRetryAfterLoss})` → returns `RaceRecordResult { int starsEarned; bool beatRecord; Duration? previousBest; int totalStars; List<int> milestonesCrossed; List<GameBadge> newBadges }`; `Future<List<String>> pendingOffer()`; `Future<void> pick(String itemId)` (owns it; if more milestones are pending, next offer becomes available); `Future<Set<String>> owned()`; `Future<void> select({String? rocket, String? trail})`; `Future<GameStats> stats(RaceSubject s)` (races, wins, best time, first-try correct); `Future<Set<GameBadge>> badges()`; `Future<Duration> meanAnswer()`; `Future<double> nextSlowdown()`.
- Providers: `gameRepositoryProvider` (FutureProvider, per current kid), `gameSummaryProvider` for the hub.

- [ ] **Step 1: Write failing tests**
  - Migration v6 → v7 keeps all existing data and creates empty game tables (extend `migration_test.dart` with a v6 fixture).
  - `recordRace` win ⇒ 5 stars (+comets, +2 on record after the first race of the subject); never touches `lesson_completions` (row count unchanged) — **assert this**.
  - Crossing 25 and 40 in one race ⇒ `milestonesCrossed == [25, 40]`; offers come one after another: first offer = first two unowned; after `pick`, the second offer is the next two unowned; the not-picked item appears again first.
  - Each badge earned exactly once at its threshold; `scholar` needs a won race with no question missed; `never_give_up` only counts races recorded with `wasRetryAfterLoss: true`.
  - Kid A's data invisible to kid B; deleting kid A removes its game rows.
- [ ] **Step 2: Run** `flutter test test/game/data/ test/data/migration_test.dart` — expected FAIL.
- [ ] **Step 3: Implement** tables, migration, repository; run build_runner.
- [ ] **Step 4: Run** tests → PASS; `flutter analyze && flutter test`.
- [ ] **Step 5: Commit** `feat: game data, cosmic stars, rewards and badges (schema v7)`

---

### Task 4: Space scene and flame (rendering)

**Files:**
- Create: `lib/game/scene/flame_painter.dart`, `lib/game/scene/smoke_particles.dart`, `lib/game/scene/space_track.dart`, `lib/game/scene/rocket_sprite.dart`, `lib/game/scene/race_scene.dart`, `lib/game/scene/trails.dart`
- Modify: `lib/ui/theme/tokens.dart` (game colours: sky gradient #2A2766 → #4B3C93 → #8E6BC2 → #F2A9B8, track #7B66C9 / sides #43358A / lane line #B9A9F0, flame core #FFFDF2, mid #FFE27A, outer #FFD24A → #FF7A1A → #E8380C, glow #FFB547, smoke #F6EEFF)
- Test: `test/game/scene/*_test.dart`

**Interfaces:**
- `class RaceScene extends StatefulWidget { RaceScene({required int kidSteps, required int chipSteps, required String kidRocket /* item id */, required String kidTrail, required bool boosting, required bool won /* nullable state handled by caller */, int lanes = 2}) }` — draws: sky gradient + stars, 2.5D perspective track narrowing to the planet (`AppImages.planet`) at the top, kid rocket (`AppImages.rocket*` by item id) in lane 1 and Chíp (`AppImages.rocketChip`) in lane 2, positions = steps/10 along the track with spring animation (critically damped, ~450 ms; overshoot only when not reduce-motion), flame under each rocket, 2–3 parallax cloud layers drawn in code (2.5D: light top, lilac shade bottom), comet flyby when `boosting` turns true.
- `FlamePainter(time, intensity)` — layers from the design (core, mid, outer gradient fading to transparent, blurred glow) with low-frequency noise on length/width for flicker; `intensity` 1.0 normal, 1.8 boost (longer flame for ~600 ms after a correct answer); `SmokeParticles` fixed pool (≤ 24 particles per rocket) spawned at the nozzle, drift down, grow, fade. Trails: `trail_flame` (default), `trail_rainbow` (rainbow smoke particles), `trail_sparkle` (star sparkles), `trail_blue_flame` (blue palette).
- One `Ticker` in `RaceScene`; flame/smoke layer in a `RepaintBoundary` separate from the static track layer.

- [ ] **Step 1: Write failing tests**
  - `FlamePainter.shouldRepaint` true when time changes; painting at t=0 and t=1 s on a test canvas produces different flame lengths within ±25 % of base (flicker exists, bounded).
  - Particle pool never exceeds 24 per rocket over 10 s of simulated ticks; particles fade to alpha 0 before reuse.
  - `RaceScene` with `MediaQuery(disableAnimations: true)`: after pumping one frame and advancing 2 s, the flame painter's time does not change (static) and rocket positions jump to targets.
  - Rocket y position for steps 0/5/10 is monotonic (10 at the planet).
- [ ] **Step 2: Run** `flutter test test/game/scene/` — expected FAIL.
- [ ] **Step 3: Implement.** Pre-allocate `Paint`/`Path`/gradients; no allocation per frame in paint.
- [ ] **Step 4: Run** tests → PASS. Render the scene (tools/shot, docs/perf.md) at 390×844 and 1366×1024 at t=0, 0.5 s, 1 s; look at it; list paths. If possible run the app in profile mode and record frame timings; otherwise state that it could not be measured here.
- [ ] **Step 5: Commit** `feat: space race scene with animated flame and smoke`

---

### Task 5: Race screen and results

**Files:**
- Create: `lib/features/game/race_screen.dart`, `lib/features/game/race_controller.dart` (Riverpod notifier owning `Race`), `lib/features/game/answer_keys.dart`, `lib/features/game/glyph_view.dart`, `lib/features/game/race_result_screen.dart`, `lib/features/game/reward_offer_sheet.dart`, `lib/features/game/badge_popup.dart`, `lib/features/game/subject_picker.dart`
- Modify: `lib/router.dart` (routes `/game`, `/game/race/:subject`, `/game/result`, `/game/garage`, `/game/badges`, `/game/stickers`)
- Test: `test/features/game/*_test.dart`

**Interfaces:**
- Consumes: Task 2 engine, Task 3 repository/providers, Task 4 `RaceScene`, `Speaker` (`speakerProvider`), `glyphProvider`/`Glyph.inWindow()`.
- `GlyphView(String glyphId, {Color color})` draws a glyph's windowed reference strokes as solid ink (for letter keys and tone keys; tone keys draw only the mark).
- Race flow: subject picker (2 big raised cards "Toán" / "Tiếng Việt") → race: top = `RaceScene`, bottom = question card (prompt text for Toán; big speaker button for Tiếng Việt; spoken on show via `Speaker`), 3 answer keys (`Pressable`, colours orange #FFB77A/edge #D9803E, blue #9EC0FA/#5E86D1, green #93DDB7/#4DAA7D; dark text ≥ 4.5 contrast) with Toán numbers or `GlyphView`s; comet questions show the banner "Câu sao chổi! Đúng là bay vọt 2 nấc" and the comet flyby; wrong ⇒ key shake (skipped under reduce motion) + Chíp line "Thử lại nhé!".
- Results: win ⇒ landing cut-scene (~3 s, tap to skip), "Kỷ lục mới!" with "nhanh hơn N giây" when `beatRecord`; lose ⇒ "Suýt nữa thôi! Chỉ còn K nấc!" (K = 10 − kidSteps at Chíp's finish), "Bí kíp của Chíp": first missed question with its correct answer, spoken gently; both ⇒ "+S sao vũ trụ", next-reward bar (stars to next milestone + blurred next item), new badges via `BadgePopup` (badge image flies in, fireworks unless reduce motion, Chíp speaks the title), then `RewardOfferSheet` for each crossed milestone (two item cards, pick one), buttons "Đua lại!" (big) and "Về Góc Chơi". "Đua lại!" after a loss starts the next race with `slowdown 1.15` and `wasRetryAfterLoss: true`.
- Tablet: landscape = scene left (flex 3), question right (flex 2); portrait = phone layout scaled to tablet sizes.

- [ ] **Step 1: Write failing tests**
  - Full race with a seeded engine: answering all correctly wins, stores one result, shows "+5 sao vũ trụ" (+ comets) and the win scene; skipping the cut-scene by tap works.
  - Losing path shows "Suýt nữa thôi!", the missed question and its answer, and "Đua lại!" starts a new race with slowdown applied (assert via controller).
  - Leaving mid-race (system back, and `ScreenTimeGuard` covering) records nothing (repository has 0 results).
  - Milestone crossing shows the offer sheet; picking an item makes it owned; two crossings ⇒ two sheets.
  - Badge earned ⇒ `BadgePopup` with the exact title.
  - Tiếng Việt race shows `GlyphView` keys and speaks `chữ …`.
  - iPad 1366×1024 → 1024×1366 rotation mid-race keeps `kidSteps` and question index.
  - No home data changed: `homeSummaryProvider` totals equal before and after a race.
- [ ] **Step 2: Run** `flutter test test/features/game/` — expected FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** tests → PASS; render race (Toán, Tiếng Việt, comet), win, lose, offer, badge at 390×844 and 1366×1024; look; list paths. `flutter analyze && flutter test`.
- [ ] **Step 5: Commit** `feat: rocket race screen and results`

---

### Task 6: Góc Chơi hub, garage, badge cabinet, sticker album

**Files:**
- Create: `lib/features/game/game_hub_screen.dart`, `lib/features/game/garage_screen.dart`, `lib/features/game/badge_cabinet_screen.dart`, `lib/features/game/sticker_album_screen.dart`, `lib/features/game/achievements_card.dart`
- Modify: `lib/features/home/home_screen.dart`, `lib/features/home/home_tablet.dart` (nav "Chơi" opens `/game` instead of the "Sắp có" snackbar; other non-home tabs unchanged)
- Test: `test/features/game/hub_test.dart`, `test/features/game/garage_test.dart`, `test/features/home_screen_test.dart`

**Interfaces:**
- Hub (Bản 7): header "Chơi" + cosmic stars pill (game stars, not home stars); hero card "Đua tên lửa" (sky gradient, Chíp-in-rocket image, planet, comet) with "Đua với Chíp" → subject picker; two cards "Mời bạn đua" / "Nhập mã" → snackbar "Sắp có"; "Xưởng độ tên lửa" card with count of unequipped new items; "Tủ huy hiệu" and "Album sticker" entries; `AchievementsCard` with per-subject races, wins, best time (m:ss), first-try correct.
- Garage: selected rocket on a pedestal with its trail animating (reuse Task 4 flame/trail), tabs "Tên lửa" / "Vệt", owned items selectable, locked items greyed with "Còn N sao vũ trụ"; "Bay thử!" plays a 2 s take-off preview.
- Badge cabinet: 8 badges grid; earned = full colour + earned date; not earned = greyed + `howTo`.
- Sticker album: owned stickers; not owned = silhouette + how to get. Until sticker art exists, show the existing Chíp 3D poses (`AppImages.chip*`) as placeholders mapped per sticker id (document mapping in code).
- Phone + tablet layouts (tablet: hub uses two columns in landscape).

- [ ] **Step 1: Write failing tests**
  - Tapping nav "Chơi" on phone and tablet opens the hub; "Học" returns home.
  - Hub shows cosmic stars from the game repository and not the home total (seed different values).
  - "Mời bạn đua" shows "Sắp có".
  - Garage: selecting an owned rocket persists (`select`) and the next race uses it; locked item shows "Còn N sao vũ trụ".
  - Cabinet: earned vs not earned rendering with exact titles.
  - Achievements show per-subject numbers from `stats()`.
- [ ] **Step 2: Run** the tests — expected FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** tests → PASS; render hub, garage, cabinet, album at 390×844, 1024×1366, 1366×1024; look; list paths. `flutter analyze && flutter test`.
- [ ] **Step 5: Commit** `feat: game hub, garage, badge cabinet and sticker album`

---

### Task 7: Docs

**Files:** `docs/PROJECT_STATE.md` (§4 map: `lib/game/`, `lib/features/game/`, schema v7 tables; §6 2B-1 row; §7 known limitations incl. sticker art placeholders, clouds drawn in code, performance measured or not; §8 next: owner tries the game on devices → sticker art → 2B-2 design), `AGENTS.md` (game data is separate from learning data; game art via `tools/assets` chroma key).

- [ ] **Step 1:** Update docs (Vietnamese).
- [ ] **Step 2:** `flutter analyze && flutter test`, `cd tools/assets && python3 -m pytest -q`.
- [ ] **Step 3: Commit** `docs: record phase 2B-1`
