# Giai đoạn 2F — Môn Tiếng Việt Implementation Plan

> **For agentic workers:** Build task-by-task with TDD, clean commits, zero regressions, and visual screenshot verification.

**Goal:** Unlock the 9-level offline Vietnamese subject (vowels, consonants, tones, syllable building, digraphs, open/closed rhymes, words, phrase completion) with map, practice screen, Today's Lesson integration, Home card progress, and Parent Progress card.

**Architecture:**
- `lib/vietnamese/`: pure Dart domain (`vietnamese_level.dart`, `vietnamese_question.dart`, `vietnamese_generator.dart`).
- `lib/progress/level_repository.dart`, `lib/progress/progress_repository.dart`, `lib/learning/`: reuse existing `subject_levels` table under `'tieng-viet'` (no Drift migration), add `VietnameseItem` to `LessonItem` and `todayLessonProvider`.
- `lib/features/subject/vietnamese_map_screen.dart` & `lib/features/vietnamese/vietnamese_session_screen.dart`: full phone & tablet kid UI matching `MathMapScreen` and `MathSessionScreen`.
- `lib/router.dart`, `lib/features/home/home_screen.dart`, `lib/features/home/home_tablet.dart`, `lib/parent/screens/progress_tab.dart`, `lib/features/lesson/lesson_flow_screen.dart`: wire everything cleanly.

**Tech Stack:** Flutter 3.24.5, Dart 3.5, Riverpod, go_router, Drift (existing schema v7), `Speaker` (`flutter_tts`).

---

### Task 1: Vietnamese 9-Level Domain & Question Generator (TDD)
- Create `lib/vietnamese/vietnamese_level.dart` (9 levels, `VietnameseKind`, `vietnameseLevels`).
- Create `lib/vietnamese/vietnamese_question.dart` (`VietnameseQuestion`, `VietnameseDisplayKind`).
- Create `lib/vietnamese/vietnamese_generator.dart` (rich offline Vietnamese 1 curriculum pools across all 9 levels, deterministic seeded `generateVietnameseQuestions`).
- Create `test/vietnamese/vietnamese_generator_test.dart` and verify all 9 levels.

### Task 2: LevelRepository, HomeSummary & Today Lesson Integration
- Update `lib/progress/level_repository.dart`: add `recordVietnameseSession` and `vietnameseLevelIndexProvider`.
- Update `lib/progress/progress_repository.dart`: add `vietnameseLevel` to `HomeSummary` (default 0).
- Update `lib/learning/lesson_item.dart`, `lib/learning/lesson_composer.dart`, `lib/learning/today_lesson_provider.dart`: add `VietnameseItem` and include Vietnamese in `todayLessonProvider`.

### Task 3: Vietnamese Map Screen, Practice Session Screen & Routing
- Create `lib/features/vietnamese/vietnamese_session_screen.dart` (5-question session, phone + tablet layouts, big Speaker replay button ≥ 64/80pt, 3 raised choices, listen-pick / equation-build / phrase-fill boards, Chíp feedback).
- Create `lib/features/subject/vietnamese_map_screen.dart` (phone path + iPad 3×3 grid, `PracticeVietnameseScreen` wrapper).
- Wire `/subject/tieng-viet` and `/practice-vietnamese/:levelIndex` in `lib/router.dart` and `VietnameseItem` in `lib/features/lesson/lesson_flow_screen.dart`.

### Task 4: Home Unlock, Parent ProgressTab & Existing Test Updates
- Unlock **Tiếng Việt** `SubjectCard` on `HomeScreen` and `HomeTablet` with live `level/9` progress ring.
- Add **Tiếng Việt** progress card in `lib/parent/screens/progress_tab.dart`.
- Update any existing tests expecting 2 "Sắp có" subject cards on Home (`test/features/home_screen_test.dart`, etc.).

### Task 5: Widget Tests, Visual Screenshots, Full Test Suite & Docs
- Add `test/features/vietnamese/vietnamese_screen_test.dart` covering map, practice flow, wrong-then-right retry, level-up recording, and phone/iPad layouts.
- Capture and visually inspect screenshots of `VietnameseMapScreen` and `VietnameseSessionScreen` (phone & iPad).
- Run `flutter analyze` and full `flutter test`, update `docs/PROJECT_STATE.md`, commit & push to `origin chipchip`.
