# Giai đoạn 3A — Môn Tiếng Anh Implementation Plan

> **For agentic workers:** Build task-by-task with TDD, clean commits, zero regressions, and visual screenshot verification.

**Goal:** Unlock the 9-level offline English subject (A–M, N–Z, numbers 1–10, colors, animals, food/fruit, phonics, family/body, short greetings) with `en-US` TTS support, map screen, practice screen, Home unlock, and Parent Progress card.

**Architecture:**
- `lib/voice/speaker.dart`: add backward-compatible `MultilingualSpeaker` + `speakInLanguage` extension for `en-US` / `vi-VN` switching.
- `lib/english/`: pure Dart domain (`english_level.dart`, `english_question.dart`, `english_generator.dart`).
- `lib/progress/`: add `'tieng-anh'` level tracking (`recordEnglishSession`, `englishLevelIndexProvider`, `HomeSummary.englishLevelIndex`) with zero Drift migration.
- `lib/features/english/english_session_screen.dart` & `lib/features/subject/english_map_screen.dart`: phone & tablet kid screens matching `Subject.tiengAnh` teal theme.
- `lib/router.dart`, `lib/features/home/home_screen.dart`, `lib/parent/screens/progress_tab.dart`: wire full navigation and parent reporting.

**Tech Stack:** Flutter 3.24.5, Dart 3.5, Riverpod, go_router, Drift (schema v7), `flutter_tts`.

---

### Task 1: Multilingual Speaker & English 9-Level Generator (TDD)
- Update `lib/voice/speaker.dart` with `MultilingualSpeaker` & `speakInLanguage`.
- Add `EnglishSwatchColors` to `lib/ui/theme/tokens.dart`.
- Create `lib/english/english_level.dart`, `lib/english/english_question.dart`, `lib/english/english_generator.dart`.
- Create `test/english/english_generator_test.dart` and verify all 9 levels.

### Task 2: LevelRepository & HomeSummary
- Update `lib/progress/level_repository.dart`: add `recordEnglishSession` & `englishLevelIndexProvider`.
- Update `lib/progress/progress_repository.dart`: add `englishLevelIndex` to `HomeSummary`.

### Task 3: English Session Screen, Map Screen, Router, Home & Parent Progress
- Create `lib/features/english/english_session_screen.dart` (listen-pick, count-pick, color-pick with crisp color dots, phonics-build, phrase-fill; phone & iPad layouts).
- Create `lib/features/subject/english_map_screen.dart` (`EnglishMapScreen` + `PracticeEnglishScreen`).
- Wire `/subject/tieng-anh` and `/practice-english/:levelIndex` in `lib/router.dart`.
- Unlock **Tiếng Anh** `SubjectCard` in `lib/features/home/home_screen.dart`.
- Add **Tiếng Anh** progress card in `lib/parent/screens/progress_tab.dart`.

### Task 4: Tests, Visual Screenshots, Full Suite & Docs
- Create `test/features/english/english_screen_test.dart`.
- Update `test/features/home_screen_test.dart` (all 4 subject islands unlocked).
- Capture & visually inspect screenshots of `EnglishMapScreen` and `EnglishSessionScreen`.
- Run `flutter analyze` & full `flutter test`, update `docs/PROJECT_STATE.md`, commit & push to `origin chipchip`.
