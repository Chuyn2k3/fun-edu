# Giai đoạn 1B — Môn Toán và bài thử xếp cấp: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm môn Toán (câu hỏi sinh bằng code, ba dạng bài chạm-đếm / chọn đáp án / kéo thả, thang cấp tự lên xuống), bài thử xếp cấp lần đầu mở app cho Viết và Toán, và "Bài hôm nay" gồm 1 chữ mới + 1 lượt Toán + 1 chữ ôn.

**Architecture:** Logic Toán thuần Dart trong `lib/math/` (cấp độ, sinh câu hỏi, luật lên xuống cấp) test riêng. Cấp hiện tại của từng môn lưu trong drift (schema v3). "Bài hôm nay" chuyển từ danh sách id chữ sang danh sách `LessonItem` (Viết hoặc Toán). Giao diện dùng lại bộ giao diện chung, ảnh 3D và cách phản ứng của Chíp Chíp như màn tập viết.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, flutter_riverpod 2.6, go_router 15, drift 2.23 + drift_flutter 0.2.4 (ghim).

**Spec:** `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` (mục 3, 4, 5.1, 7, 10 — Giai đoạn 1, 12). Kế hoạch trước: `docs/superpowers/plans/2026-11-12-giai-doan-1a-giao-dien-be.md`.

## Global Constraints

- Chạy được với Flutter 3.24 (Dart 3.5); `import 'package:flutter/material.dart'`; `withOpacity` (không `withValues`); Riverpod 2.x; không đổi phiên bản gói đã ghim.
- Một thư viện trạng thái (Riverpod); không SDK bên thứ ba; chạy không cần mạng.
- Màu, bo góc, bóng, ảnh chỉ qua `AppColors`, `AppRadii`, `AppShadows`, `AppImages`. Thẻ trắng = một `BoxDecoration` có cả `color: AppColors.card` và bóng (không để bóng không màu phủ lên nền `Material`).
- Nút cho bé cao ≥ 64; tương phản chữ ≥ 4.5:1.
- Không cơ chế gây áp lực: sai không bị trừ sao, không đếm ngược thời gian, lùi cấp không thông báo "bị hạ cấp" với bé.
- Câu hỏi Toán: đáp án luôn đúng; không số âm; các lựa chọn không trùng nhau và luôn chứa đáp án đúng.
- Chữ hiển thị cho bé đúng nguyên văn kế hoạch.

## Review Focus

1. **Sinh câu hỏi ở biên** (đếm 1, phạm vi 20, phép trừ ra 0) → không âm, không vượt phạm vi, 3 lựa chọn khác nhau có chứa đáp án. → test Task 1 (chạy 1000 lần mỗi cấp).
2. **Lên/lùi cấp ở hai đầu thang** (cấp 1 làm sai, cấp cuối làm đúng hết) → không ra ngoài thang. → test Task 2.
3. **Bé thoát giữa bài thử xếp cấp** → lần mở sau vẫn vào bài thử, không lưu cấp dở dang. → test Task 6.
4. **Bấm nhanh hai lần vào đáp án** → chỉ chấm một lần. → test Task 3.
5. **Màn nhỏ và màn lớn** (375×667, 1024×1366) → màn Toán, bài thử, bản đồ Toán không tràn. → test Task 4, 6.

---

## Cấu trúc file

```
lib/math/math_level.dart         # MathLevel, mathLevels (thang 9 cấp)
lib/math/math_question.dart      # MathQuestion và các kiểu
lib/math/question_generator.dart # generateQuestions (thuần Dart, Random truyền vào)
lib/math/level_rule.dart         # nextLevelIndex
lib/progress/subject_level_table.dart
lib/progress/level_repository.dart
lib/features/math/exercise/{choice_answers,object_grid,tap_count_board,compare_groups,drag_number_match}.dart
lib/features/math/math_session_screen.dart
lib/learning/lesson_item.dart
lib/features/placement/placement_screen.dart
lib/features/subject/math_map_screen.dart
```

---

### Task 1: Cấp Toán và sinh câu hỏi

**Files:**
- Create: `lib/math/math_level.dart`, `lib/math/math_question.dart`, `lib/math/question_generator.dart`
- Test: `test/math/question_generator_test.dart`

**Interfaces:**
- Produces:
  - `enum MathKind { count, compare, match, add, subtract, addSubtract }`
  - `class MathLevel { final String id; final String title; final MathKind kind; final int max; }` và `const List<MathLevel> mathLevels` đúng thứ tự:

| # | id | title | kind | max |
|---|---|---|---|---|
| 1 | dem-5 | Đếm đến 5 | count | 5 |
| 2 | dem-10 | Đếm đến 10 | count | 10 |
| 3 | so-sanh-10 | So sánh | compare | 10 |
| 4 | ghep-so-10 | Ghép số | match | 10 |
| 5 | cong-5 | Cộng trong 5 | add | 5 |
| 6 | tru-5 | Trừ trong 5 | subtract | 5 |
| 7 | cong-10 | Cộng trong 10 | add | 10 |
| 8 | tru-10 | Trừ trong 10 | subtract | 10 |
| 9 | cong-tru-20 | Cộng trừ trong 20 | addSubtract | 20 |

  - `sealed class MathQuestion { MathKind get kind; String get prompt; }` với:
    - `CountQuestion(int n, List<int> choices)` — prompt `Có bao nhiêu ngôi sao?`; `1 ≤ n ≤ max`.
    - `CompareQuestion(int left, int right, CompareAsk ask)` với `enum CompareAsk { more, less }` — prompt `Bên nào nhiều hơn?` hoặc `Bên nào ít hơn?`; `left != right`, cả hai trong `1..max`; đáp án là `Side.left`/`Side.right` (`enum Side { left, right }`, getter `Side answer`).
    - `MatchQuestion(int n, List<int> choices)` — prompt `Kéo số đúng vào ô nhé!`.
    - `ArithmeticQuestion(int a, int b, bool plus, List<int> choices)` — prompt `{a} + {b} = ?` hoặc `{a} − {b} = ?` (dấu trừ U+2212); với cộng `a + b ≤ max`, `a,b ≥ 1`; với trừ `a ≤ max`, `0 ≤ b ≤ a`; getter `int answer`.
  - Mọi câu có `choices` gồm đúng 3 số khác nhau, trong `0..max`, có chứa đáp án, thứ tự xáo.
  - `List<MathQuestion> generateQuestions(MathLevel level, Random rng, {int count = 5})` — không có hai câu giống hệt liền nhau. Với `addSubtract`, trộn cộng và trừ.

- [ ] **Step 1: Viết test** — `mathLevels` đúng 9 cấp theo bảng; với mỗi cấp, `generateQuestions(level, Random(seed), count: 5)` chạy với seed 0..199 (tổng 1000 câu): mọi số trong phạm vi, không âm, `choices` 3 phần tử khác nhau có đáp án; `CompareQuestion` không bằng nhau; cùng seed cho cùng kết quả; không có hai câu liên tiếp trùng nhau.
- [ ] **Step 2: Chạy, thấy FAIL** — `flutter test test/math`.
- [ ] **Step 3: Viết code** (Dart thuần, không import Flutter).
- [ ] **Step 4: Chạy, thấy PASS.**
- [ ] **Step 5: Commit** — `feat(math): thang cấp Toán và sinh câu hỏi`

---

### Task 2: Lưu cấp từng môn và luật lên xuống cấp

**Files:**
- Create: `lib/math/level_rule.dart`, `lib/progress/subject_level_table.dart`, `lib/progress/level_repository.dart`
- Modify: `lib/data/app_database.dart` (`schemaVersion` 3; migration `from < 3` tạo bảng mới; giữ nhánh `from < 2`), sinh lại `app_database.g.dart`
- Test: `test/math/level_rule_test.dart`, `test/progress/level_repository_test.dart`, bổ sung `test/data/migration_test.dart` (v2 → v3)

**Interfaces:**
- Produces:
  - `int nextLevelIndex({required int current, required int firstTryCorrect, required int total, required int levelCount})` — `firstTryCorrect * 5 >= total * 4` → `current + 1`; `firstTryCorrect * 5 <= total * 2` → `current - 1`; còn lại giữ; luôn kẹp trong `0..levelCount-1`.
  - Bảng `SubjectLevels(subject text PK, levelIndex int, placedAt dateTime)`.
  - `class LevelRepository { LevelRepository(AppDatabase db, {Clock now}); Future<int?> levelOf(String subject); Future<void> setLevel(String subject, int index); Future<bool> isPlaced(); Future<int> recordMathSession({required int firstTryCorrect, required int total}); }` — `subject` là `'viet'` hoặc `'toan'`; `isPlaced()` đúng khi đã có cả hai môn; `recordMathSession` đọc cấp Toán (mặc định 0), áp `nextLevelIndex`, lưu và trả cấp mới. Provider `levelRepositoryProvider`, `mathLevelIndexProvider` (FutureProvider<int>, mặc định 0), `isPlacedProvider` (FutureProvider<bool>).
  - `HomeSummary` thêm `mathLevelIndex` (int) — `homeSummaryProvider` điền giá trị.

- [ ] **Step 1: Viết test** — luật: 5/5 lên, 4/5 lên, 3/5 giữ, 2/5 xuống, 0/5 ở cấp 0 vẫn 0, 5/5 ở cấp cuối vẫn cấp cuối. Repository (DB bộ nhớ): chưa có dữ liệu → `isPlaced()` false, `levelOf('toan')` null; đặt cả hai → true; `recordMathSession(5,5)` từ cấp 2 → 3 và lưu. Migration v2 → v3: dữ liệu `lesson_completions` cũ còn nguyên, ghi được `subject_levels`.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết code, sinh lại drift.**
- [ ] **Step 4: Chạy, thấy PASS** — `flutter test` toàn bộ.
- [ ] **Step 5: Commit** — `feat(progress): lưu cấp từng môn, luật lên xuống cấp Toán`

---

### Task 3: Các dạng bài Toán

**Files:**
- Create: `lib/features/math/exercise/object_grid.dart`, `choice_answers.dart`, `tap_count_board.dart`, `compare_groups.dart`, `drag_number_match.dart`
- Test: `test/features/math_exercises_test.dart`

**Interfaces:**
- Consumes: `MathQuestion` các kiểu (Task 1), `AppImages`, tokens.
- Produces (mỗi widget nhận câu hỏi và `ValueChanged<bool> onAnswered` — `true` nếu đúng; sau khi gọi một lần thì khóa, bỏ qua mọi lần bấm thêm cho tới khi widget được dựng lại với câu khác):
  - `ObjectGrid({required int count, String image = AppImages.icStar, Set<int> marked = const {}, ValueChanged<int>? onTapObject})` — lưới ảnh, tối đa 5 mỗi hàng, ô ≥ 56.
  - `ChoiceAnswers({required List<int> choices, required int answer, required ValueChanged<bool> onAnswered})` — 3 nút trắng cao 72, số to (36, đậm 900); đúng → nút nền `AppColors.accent` chữ `AppColors.card`; sai → nút đó mờ đi và vô hiệu, các nút khác vẫn bấm được (bé được thử lại; chỉ lần đầu tính "đúng lần đầu"). `onAnswered(true)` khi chọn đúng, `onAnswered(false)` lần đầu chọn sai (chỉ gọi một lần false).
  - `TapCountBoard({required CountQuestion q, required ValueChanged<bool> onAnswered})` — `ObjectGrid` mà mỗi lần chạm vật chưa đánh dấu thì hiện số thứ tự trên vật đó (1, 2, 3…), dưới là `ChoiceAnswers`.
  - `CompareGroups({required CompareQuestion q, required ValueChanged<bool> onAnswered})` — hai thẻ trắng cạnh nhau, mỗi thẻ một `ObjectGrid`; chạm thẻ là chọn bên đó.
  - `DragNumberMatch({required MatchQuestion q, required ValueChanged<bool> onAnswered})` — trên là `ObjectGrid(count: n)` và một ô trống viền đứt; dưới là 3 ô số kéo được (`Draggable<int>`); thả vào ô trống là chấm; chạm một ô số cũng được coi như thả vào (cho bé chưa kéo giỏi).

- [ ] **Step 1: Viết test** — `ChoiceAnswers`: chạm đúng → `onAnswered(true)` một lần; chạm sai rồi đúng → `[false, true]`; chạm đúng hai lần nhanh → chỉ một `true`. `TapCountBoard`: chạm 3 vật → thấy `1`, `2`, `3` trên vật. `CompareGroups`: chạm bên có nhiều hơn với `ask: more` → `true`. `DragNumberMatch`: kéo ô đúng vào ô trống → `true`; chạm ô sai → `false`.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết widget.**
- [ ] **Step 4: Chạy, thấy PASS.**
- [ ] **Step 5: Commit** — `feat(math): các dạng bài chạm đếm, chọn, so sánh, kéo thả`

---

### Task 4: Màn làm bài Toán

**Files:**
- Create: `lib/features/math/math_session_screen.dart`
- Test: `test/features/math_session_screen_test.dart`

**Interfaces:**
- Consumes: `generateQuestions`, `MathLevel` (T1), widget dạng bài (T3), `AppImages`, `SpeechBubble`, `homeSummaryProvider` (viên sao).
- Produces: `MathSessionScreen({required MathLevel level, required void Function(int firstTryCorrect, int total) onCompleted, int? step, int? totalSteps, int questionCount = 5, Random? random})`.

Bố cục giống màn tập viết: hàng trên nút ‹ (nhãn trợ năng `Quay lại`), tiêu đề `Toán · {level.title}`, thanh tiến độ bài (`step/totalSteps`, ẩn nếu null), viên sao; dưới là dòng tiến độ câu `Câu {i}/{n}`; thẻ trắng lớn chứa câu hỏi (prompt to, đậm) và dạng bài theo `kind` (`count`→TapCountBoard, `compare`→CompareGroups, `match`→DragNumberMatch, `add`/`subtract`/`addSubtract`→ phép tính to + `ObjectGrid` minh họa vế đầu + `ChoiceAnswers`); dưới thẻ là Chíp Chíp + `SpeechBubble`.

Hành vi: bắt đầu Chíp `chipMain`, lời `Mình cùng làm Toán nhé!`; đúng → `chipJoy`, `Đúng rồi!`, sau 0.9 giây sang câu kế; lần đầu sai → `chipEncourage`, `Thử lại nhé!` (bé chọn lại, không sang câu); hết `questionCount` câu → `chipThumb`, `Bé giỏi quá!`, sau 1.2 giây gọi `onCompleted(số câu đúng ngay lần đầu, tổng)` đúng một lần; hủy hẹn giờ khi `dispose`.

- [ ] **Step 1: Viết test** — với cấp `cong-5` và `Random(1)`: trả lời đúng cả 5 câu (đọc đáp án từ câu sinh với cùng seed) → `onCompleted(5, 5)` một lần; sai câu 1 rồi đúng → `onCompleted(4, 5)`; thấy `Câu 1/5` rồi `Câu 2/5`; dựng ở 375×667 và 1024×1366 không tràn với cả 4 nhóm `kind`.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết màn.**
- [ ] **Step 4: Chạy, thấy PASS.**
- [ ] **Step 5: Commit** — `feat(math): màn làm bài Toán có Chíp Chíp`

---

### Task 5: "Bài hôm nay" gồm Viết và Toán

**Files:**
- Create: `lib/learning/lesson_item.dart`
- Modify: `lib/learning/lesson_composer.dart`, `lib/learning/today_lesson_provider.dart`, `lib/features/lesson/lesson_flow_screen.dart`, `lib/progress/progress_repository.dart` (`recordLessonCompleted({required int itemsCompleted})`), `lib/features/home/home_screen.dart` (lời Chíp và số bài), các test liên quan
- Test: `test/learning/lesson_composer_test.dart`, `test/features/lesson_flow_test.dart`, `test/features/home_screen_test.dart`

**Interfaces:**
- Consumes: `LevelRepository` (T2), `MathSessionScreen` (T4), `mathLevels`.
- Produces:
  - `sealed class LessonItem` với `WritingItem(String glyphId)` và `MathItem(int levelIndex)`.
  - `List<LessonItem> composeTodayLessonItems({required List<String> ladder, required Map<String, GlyphStat> stats, required Set<String> available, required int writingStartIndex, required int mathLevelIndex})` — dùng `composeTodayLesson` cũ với `size: 3` (coi các chữ đứng trước `writingStartIndex` trong thang là đã thuộc), rồi trả `[Writing(chữ mới 1), Math(mathLevelIndex), Writing(chữ thứ ba)]`; thiếu chữ thì bỏ mục Viết tương ứng, mục Toán luôn có.
  - `todayLessonProvider` đổi kiểu thành `FutureProvider<List<LessonItem>>`; `writingStartIndex` = `levelOf('viet') ?? 0`.
  - `LessonFlowScreen` chạy lần lượt: `WritingItem` → `WritingScreen` như cũ; `MathItem` → `MathSessionScreen(level: mathLevels[i])`, xong thì `LevelRepository.recordMathSession`. Cuối bài `recordLessonCompleted(itemsCompleted: số mục)` (sao = số mục + 2).
  - Trang chủ: lời Chíp `Hôm nay mình viết {label chữ đầu} và làm Toán nhé!`; dòng số bài `0/{số mục} bài`.

- [ ] **Step 1: Sửa/viết test** — composer: người mới → `[Writing(net-ngang), Math(0), Writing(net-thang-dung)]`; `writingStartIndex: 5` → chữ mới đầu là `so-0`; không có chữ nào → `[Math(i)]`. Luồng: bài `[Writing, Math, Writing]` đi hết → `recordMathSession` 1 lần, `recordLessonCompleted(itemsCompleted: 3)` → `+5`. Trang chủ thấy lời mới.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết code; sửa mọi chỗ gọi API cũ.**
- [ ] **Step 4: Chạy, thấy PASS** — `flutter test` toàn bộ, `flutter analyze` sạch.
- [ ] **Step 5: Commit** — `feat(lesson): bài hôm nay gồm Viết và Toán`

---

### Task 6: Bài thử xếp cấp, bản đồ Toán, thẻ Toán trên trang chủ

**Files:**
- Create: `lib/features/placement/placement_screen.dart`, `lib/features/subject/math_map_screen.dart`
- Modify: `lib/router.dart` (`/placement`, `/subject/toan`, `/practice-math/:levelIndex`; `redirect`: chưa `isPlaced` và không phải route `/dev/*` → `/placement`), `lib/features/home/home_screen.dart` (thẻ Toán bấm được, vòng tiến độ `mathLevelIndex + 1`/`9`, → `/subject/toan`), `test/app_smoke_test.dart`
- Test: `test/features/placement_test.dart`, `test/features/math_map_test.dart`

**Interfaces:**
- Consumes: `LevelRepository` (T2), `WritingScreen`, `MathSessionScreen`, `writingLadder`, `mathLevels`.
- Produces:
  - `PlacementScreen` — ba bước:
    1. Màn chào: Chíp `chipMain`, tiêu đề `Chào bé! Mình là Chíp Chíp`, dòng `Mình chơi thử một chút nhé!`, nút `Bắt đầu`.
    2. **Viết**: lần lượt các chữ `net-ngang`, `so-0`, `so-4` (vị trí 0, 5, 9 trong thang) bằng `WritingScreen`; chữ nào có quá 2 nét sai thì dừng. `writingStartIndex` = vị trí của chữ cuối cùng làm đạt (0 nếu chữ đầu đã không đạt; 9 nếu đạt cả ba).
    3. **Toán**: thử lần lượt cấp 0, 2, 4, 6 bằng `MathSessionScreen(questionCount: 3)`; dừng ở cấp đầu tiên có dưới 2 câu đúng lần đầu. Cấp bắt đầu = cấp cuối cùng đạt (0 nếu không đạt cấp nào).
    4. Lưu cả hai bằng `setLevel` **chỉ ở cuối**, rồi màn `Xong rồi! Mình cùng học nhé!` với nút `Vào học` → `/`. Thoát giữa chừng không lưu gì.
  - `MathMapScreen` — danh sách 9 cấp (thẻ trắng, `title`); cấp nhỏ hơn cấp hiện tại có ✓, cấp hiện tại viền cam và nhãn `Đang học`, cấp lớn hơn mờ và có ổ khóa (bấm không làm gì). Bấm cấp ✓ hoặc đang học → `/practice-math/:levelIndex` = `MathSessionScreen` đơn lẻ; xong thì `recordMathSession` **chỉ khi** đó là cấp hiện tại, rồi quay lại bản đồ.

- [ ] **Step 1: Viết test** — chưa xếp cấp: mở app (router thật, DB bộ nhớ) → thấy `Chào bé! Mình là Chíp Chíp`; đã xếp cấp → thấy `Bài hôm nay`. Xếp cấp: đạt `net-ngang`, trượt `so-0`; Toán đạt cấp 0 và 2, trượt cấp 4 → lưu `viet = 0`, `toan = 2`. Thoát ở bước Toán → `isPlaced()` false. Bản đồ Toán với cấp hiện tại 2: thấy 2 dấu ✓, `Đang học` ở cấp 3, cấp 4 có ổ khóa. Trang chủ: thẻ Toán không còn `Sắp có`, thấy `3/9`. Không tràn ở 375×667 và 1024×1366 (màn chào, bản đồ Toán).
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết code, route, redirect; smoke test đặt sẵn cấp trong DB bộ nhớ để vào thẳng trang chủ.**
- [ ] **Step 4: Chạy, thấy PASS** — `flutter test` toàn bộ, `flutter analyze` sạch.
- [ ] **Step 5: Commit** — `feat(placement): bài thử xếp cấp, bản đồ Toán`

---

## Xong giai đoạn 1B khi

- `flutter analyze` sạch, mọi test PASS trên Flutter 3.24.5.
- Cài mới: app mở vào bài thử xếp cấp; xong thì vào trang chủ; "Bài hôm nay" có một lượt Toán ở giữa; thẻ Toán mở được bản đồ 9 cấp; làm tốt thì lên cấp.
- Chủ dự án chạy thử trên máy thật và xác nhận.
