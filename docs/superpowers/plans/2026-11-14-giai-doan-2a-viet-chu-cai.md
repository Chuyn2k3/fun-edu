# Giai đoạn 2A — Viết chữ cái — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Children practise the 29 Vietnamese lowercase letters (primary-school handwriting model) and the 5 tone marks on ô li paper, graded stroke by stroke, as the continuation of the existing writing ladder.

**Architecture:** A Python generator composes letters from ~10 basic school strokes and writes glyph JSON in one shared ô-li frame plus optional `ruling` / `context` / `speech` metadata, and renders a review sheet. On the Dart side a glyph with `ruling` is mapped into its square `window` before it reaches the pad, the grader and the sample animation, so grading thresholds are unchanged; the pad draws ô li lines for that window. The ladder, map, home and parent progress learn the new sections.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6; Python 3 (numpy, Pillow already used by tools/assets) for the generator.

**Spec:** `docs/superpowers/specs/2026-11-14-giai-doan-2a-viet-chu-cai-design.md` (read §3, §5, §6, §6b).

## Global Constraints

- Everything in `AGENTS.md` (Flutter 3.24.5, no new packages, `withOpacity`, tokens only, `raisedDecoration`/`Pressable`, tablet branches via `context.formFactor`, targets ≥ 64 phone / ≥ 80 tablet kid, contrast ≥ 4.5, Vietnamese UI strings, analyze + tests clean, commit trailer).
- Glyph JSON stays backward compatible: `id`, `label`, `strokes[].points` ([0,1], y down); new keys optional. The 15 existing glyph files must not change.
- Shared frame: 1 frame = 12 ô li (`cell = 1/12`), baseline at `y = 8/12`.
- Heights above / below baseline in ô li: a ă â c e ê i m n o ô ơ u ư v x = 2 / 0; r s = 2.5 / 0; t = 3 / 0; d đ = 4 / 0; b h k l = 5 / 0; g y = 2 / 3; p q = 2 / 2. Diacritics and tone marks sit within 1–1.5 ô li above the letter top.
- Stroke split: one stroke = one pen-down run of the 2002 model; i's dot, t's and đ's bar, diacritics and tone marks are separate strokes written after the body.
- Ladder order after `so-9`: `chu-i chu-t chu-u chu-uw chu-n chu-m chu-v chu-r chu-s chu-o chu-oo chu-ow chu-c chu-x chu-e chu-ee chu-a chu-aw chu-aa chu-d chu-dd chu-q chu-l chu-b chu-h chu-k chu-g chu-y chu-p dau-huyen dau-sac dau-nang dau-hoi dau-nga` (49 entries total).
- Labels: letters `Chữ <letter>` (e.g. `Chữ ă`), marks `Dấu huyền`, `Dấu sắc`, `Dấu nặng`, `Dấu hỏi`, `Dấu ngã`.
- Speech (`speech` field): `chữ <sound>` with sounds a→"a", ă→"á", â→"ớ", b→"bờ", c→"cờ", d→"dờ", đ→"đờ", e→"e", ê→"ê", g→"gờ", h→"hờ", i→"i", k→"ca", l→"lờ", m→"mờ", n→"nờ", o→"o", ô→"ô", ơ→"ơ", p→"pờ", q→"quờ", r→"rờ", s→"sờ", t→"tờ", u→"u", ư→"ư", v→"vờ", x→"xờ", y→"i dài"; marks speak their label.
- Tone marks are traced over a faint `chu-a` (`"context": "chu-a"`), which is drawn but never graded.
- Grader thresholds stay as they are (`GradeConfig` defaults); change one only if a self-grade test proves a correct reference stroke fails, and record why in the commit message.
- Map sections and their id prefixes: `net-` → "Nét cơ bản", `so-` → "Chữ số", `chu-` → "Chữ cái", `dau-` → "Dấu thanh".

## Review Focus

1. **A child who already mastered all 15 old entries** opens the app after the update — today's lesson must offer `chu-i`, not repeat old items or crash. Test in Task 4.
2. **One letter JSON missing or unreadable** — the map and the lesson skip that letter (existing `available` logic) instead of failing. Test in Task 4.
3. **Rotating an iPad mid-letter** — the windowed glyph and ô li lines re-flow; the half stroke is dropped (existing `_stale`). Test in Task 3.
4. **A sloppy "a"** — a circle of the right size drawn 1 ô li off to the side, and a "b" drawn without its loop, must be graded wrong. Test in Task 2.
5. **Old glyphs without `ruling`** keep exactly today's pad (5-line paper, full-square coordinates). Test in Task 2 and Task 3.

---

### Task 1: Letter generator, 34 glyph files and review sheet

**Files:**
- Create: `tools/glyphs/letters.py` (basic-stroke library + letter definitions), `tools/glyphs/test_letters.py`, `tools/glyphs/render_sheet.py`
- Modify: `tools/glyphs/make_glyphs.py` (call the letter generator; existing 15 outputs byte-identical)
- Create (generated, committed): `assets/glyphs/chu-*.json` (29), `assets/glyphs/dau-*.json` (5), `docs/superpowers/specs/assets/letters-sheet.png`

**Interfaces:**
- Produces JSON per glyph: `{"id", "label", "speech", "ruling": {"cell": 0.083333, "baseline": 0.666667, "window": [x, y, side]}, "context"?: "chu-a", "strokes": [{"points": [[x,y],...]}]}` with points rounded to 4 decimals. `window` is a square in frame coordinates that contains every point of the glyph (and of its `context` glyph) plus ≥ 0.5 ô li margin; side ≥ 5 ô li.
- Produces `python3 tools/glyphs/make_glyphs.py --out assets/glyphs` (all 49) and `python3 tools/glyphs/render_sheet.py --out docs/superpowers/specs/assets/letters-sheet.png`.

- [ ] **Step 1: Write failing tests** in `tools/glyphs/test_letters.py` (pytest):
  - `test_ids_and_labels`: the generator returns exactly the 34 ids in the Global Constraints order with the specified labels and speech strings.
  - `test_heights`: for each letter, (baseline − min y)/cell and (max y − baseline)/cell of the body strokes (excluding diacritic/dot/bar strokes) match the height table within ±0.3 ô li.
  - `test_separate_strokes_come_last`: i, t, đ, ă, â, ê, ô, ơ, ư have ≥ 2 strokes and the dot/bar/diacritic stroke is last; o, c, e, x… have the stroke count your 2002 reading gives (assert the counts you choose, as a table in the test).
  - `test_window_contains_glyph`: every point (and the `chu-a` context for marks) lies inside `window` with ≥ 0.5 ô li margin; side ≥ 5 cells; window inside [0,1].
  - `test_old_glyphs_unchanged`: generating into a temp dir reproduces the committed 15 old files byte-for-byte.
  - `test_smooth_points`: consecutive points in a stroke are ≤ 0.02 apart (frame units) so the grader's resampling is stable.
- [ ] **Step 2: Run** `cd tools/glyphs && python3 -m pytest -q` — expected FAIL (module missing).
- [ ] **Step 3: Implement** the basic strokes as parametric curves (Bézier/arc helpers already in `make_glyphs.py` may be moved to `letters.py`), each placed by (start x in ô li, top/bottom in ô li, width in ô li) relative to the baseline; define each letter as an ordered list of basic strokes per the 2002 model (adjacent pen-down segments joined into one stroke); compute `window`; write files. `render_sheet.py` draws all 34 glyphs in a grid on ô li paper (12-row frames, baseline and x-height lines heavier), numbers each stroke at its start point and draws a small arrow showing direction, labels each cell with the letter.
- [ ] **Step 4: Run** the pytest suite → PASS; run both commands to regenerate assets and the sheet; open the PNG and check by eye that every letter is recognisable and matches the stroke order you encoded; fix and regenerate until it does.
- [ ] **Step 5: Commit** `feat: generate provisional lowercase letters and tone marks` (include the 34 JSON files and the sheet).

---

### Task 2: Glyph metadata and windowing

**Files:**
- Modify: `lib/stroke/glyph.dart`
- Test: `test/stroke/glyph_test.dart`, `test/stroke/assets_self_grade_test.dart`

**Interfaces:**
- Consumes: Task 1 JSON format.
- Produces in `glyph.dart`:
  - `class GlyphRuling { const GlyphRuling({required double cell, required double baseline, required double windowX, required double windowY, required double windowSide}); }` with `fromJson`/`toJson` (`window` as a 3-element list).
  - `Glyph` gains optional `GlyphRuling? ruling`, `String? context`, `String? speech` (JSON keys `ruling`, `context`, `speech`; omitted keys when null so old files round-trip unchanged; included in `==`/`hashCode`).
  - `Glyph inWindow()` — returns a glyph whose strokes are mapped from frame to window coordinates (`(p - windowOrigin) / windowSide`) and whose `ruling` is expressed in window coordinates (cell / side, baseline mapped); returns `this` when `ruling == null`.
  - `String get spokenName => speech ?? label;`

- [ ] **Step 1: Write failing tests**
  - `glyph_test.dart`: JSON round-trip with and without the new keys (old JSON produces identical `toJson`); `inWindow` maps a point at the window's top-left to (0,0) and bottom-right to (1,1); `inWindow` on a glyph without ruling returns the same instance; `spokenName` falls back to label.
  - `assets_self_grade_test.dart`: grade every asset through `glyph.inWindow()` (unchanged result for old glyphs); for every `chu-`/`dau-` glyph with ≥ 1 stroke longer than the dot length, a reversed copy of its first stroke is graded wrong; for multi-stroke glyphs, submitting stroke 2 first is graded wrong (existing order rule).
  - Sloppy input: `chu-a`'s body stroke shifted right by one ô li (in frame units, before windowing) is graded wrong; `chu-b`'s loop stroke replaced by a straight line between its endpoints is graded wrong.
- [ ] **Step 2: Run** `flutter test test/stroke/` — expected FAIL.
- [ ] **Step 3: Implement** the model changes in `glyph.dart`.
- [ ] **Step 4: Run** `flutter test test/stroke/` → PASS; then `flutter analyze && flutter test`.
- [ ] **Step 5: Commit** `feat: glyph ruling metadata and window mapping`

---

### Task 3: Writing pad on ô li

**Files:**
- Modify: `lib/features/writing/ruled_paper.dart`, `lib/features/writing/writing_screen.dart` (phone and tablet branches), `lib/features/trace/trace_screen.dart`, `lib/router.dart` (debug glyph list title) where they consume a glyph
- Test: `test/features/writing_screen_test.dart`, `test/features/trace_screen_test.dart`, `test/ui/widgets_test.dart`

**Interfaces:**
- Consumes: `Glyph.inWindow()`, `GlyphRuling`, `Glyph.context`, `Glyph.spokenName` (Task 2).
- Produces: `RuledPaper({GlyphRuling? ruling})` — null draws today's 5 lines; non-null draws a horizontal line every `cell` across the window, heavier lines at the baseline and at baseline − 2 cells (x-height), and light vertical lines every `cell` (ô li squares). Colours from tokens only.

- [ ] **Step 1: Write failing tests**
  - `RuledPaper(ruling: …)` paints `1 / cell` horizontal lines (count via a test painter hook or by exposing a `@visibleForTesting static List<double> horizontalLines(GlyphRuling)` and asserting it) with the baseline included; `RuledPaper()` keeps 5 lines.
  - Writing screen with `chu-b` (load the real asset): the TracePad guide equals `glyph.inWindow().strokes`; the RuledPaper receives the windowed ruling; completing the reference strokes in window coordinates finishes the glyph.
  - Writing screen with `dau-sac`: a faint `chu-a` layer is painted under the guide (find by key `ValueKey('glyph-context')`) and drawing the `chu-a` shape does not advance the mark.
  - Voice: the screen speaks `spokenName` (e.g. "chữ bờ") in its prompts instead of the label; titles keep the label ("Viết Chữ b").
  - Old glyph `so-2`: pad, paper and grading identical to today (existing tests unchanged and passing).
  - iPad rotation (1366×1024 → 1024×1366) mid-stroke on `chu-g`: no exception, paper re-laid out, half stroke dropped.
- [ ] **Step 2: Run** the three test files — expected FAIL.
- [ ] **Step 3: Implement**: the writing screen (and trace screen) works on `widget.glyph.inWindow()` everywhere it uses strokes (guide, session, sample animation, next-stroke hint, stroke counter); passes `ruling` to `RuledPaper`; when `context != null` loads it via `glyphProvider` and paints its windowed strokes in `AppColors.dot` behind the guide (not graded, not in the session); uses `spokenName` for spoken lines.
- [ ] **Step 4: Run** `flutter analyze && flutter test` → PASS. Render `chu-a`, `chu-b`, `chu-g`, `dau-hoi` on 390×844 and 1366×1024 with `tools/shot` (see `docs/perf.md`), look, list PNG paths in the report.
- [ ] **Step 5: Commit** `feat: write letters on ô li paper`

---

### Task 4: Ladder, map sections, home, parent progress

**Files:**
- Modify: `lib/learning/writing_ladder.dart`, `lib/features/subject/writing_map_screen.dart`, `lib/features/home/home_screen.dart` (Viết subtitle) and `lib/features/home/home_tablet.dart` if it repeats it, `lib/parent/screens/progress_tab.dart`
- Create: `lib/learning/writing_sections.dart`
- Test: `test/learning/writing_ladder_test.dart`, `test/learning/lesson_composer_test.dart`, `test/features/writing_map_test.dart`, `test/parent/progress_tab_test.dart`, `test/features/home_screen_test.dart`

**Interfaces:**
- Produces: `writingLadder` = 15 existing ids + the 34 new ids in the Global Constraints order.
- Produces in `writing_sections.dart`: `enum WritingSection { strokes, digits, letters, marks }` with `String get title` ("Nét cơ bản", "Chữ số", "Chữ cái", "Dấu thanh"), `WritingSection sectionOf(String glyphId)` by prefix, `Map<WritingSection, List<String>> groupLadder(List<String> ids)` preserving ladder order and omitting empty sections.

- [ ] **Step 1: Write failing tests**
  - Ladder: length 49; first 15 unchanged; ids from index 15 equal the Global Constraints list; every ladder id has an asset file (`File('assets/glyphs/$id.json').existsSync()`).
  - `sectionOf` / `groupLadder`: prefixes map to the four sections; order preserved.
  - Lesson: with stats mastering all 15 old ids, `composeTodayLessonItems(...)` first writing item is `chu-i`; with `available` missing `chu-t`, it is skipped and `chu-u` follows.
  - Writing map (phone 390×844 and tablet 1366×1024): four section headings in order; tiles under "Chữ cái" are 29, under "Dấu thanh" 5; tapping a letter tile opens `/practice/chu-…`; no overflow at user text 1.3 on tablet.
  - Parent Tiến bộ tab: chips grouped under the four headings.
  - Home: the Viết card subtitle reads "Nét, số, chữ cái" and its progress total is 49.
- [ ] **Step 2: Run** the test files — expected FAIL.
- [ ] **Step 3: Implement**: the map renders one heading + grid per `groupLadder` section (same tile widget and tablet column rules as today); progress tab groups chips the same way; home subtitle text change.
- [ ] **Step 4: Run** `flutter analyze && flutter test` → PASS. Render the writing map on 390×844, 1024×1366, 1366×1024; look; list paths.
- [ ] **Step 5: Commit** `feat: letters in the writing ladder, map and progress`

---

### Task 5: Docs

**Files:** `docs/PROJECT_STATE.md` (§2 icon/glyph notes if needed, §4 map: new files, §6 add 2A row, §7 "nét chữ cái là dữ liệu tạm máy sinh — cần chủ dự án duyệt `docs/superpowers/specs/assets/letters-sheet.png`", §8 next: owner reviews the sheet, then 2B), `AGENTS.md` (one line: letters live in `tools/glyphs/letters.py`; regenerate with `make_glyphs.py`; never hand-edit generated JSON).

- [ ] **Step 1:** Update the docs (Vietnamese).
- [ ] **Step 2:** `flutter analyze && flutter test` and `cd tools/glyphs && python3 -m pytest -q` — PASS.
- [ ] **Step 3: Commit** `docs: record phase 2A`
