# Chíp du lịch + kệ trò chơi — kế hoạch làm

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm trò "Chíp du lịch" vào Góc Chơi. Chíp đi hành trình 30 trạm địa danh, mỗi câu trả lời đúng là đi tới; tới trạm thì bé nhận bưu thiếp dán vào Sổ tem. Đồng thời biến thẻ Đua tên lửa thành một kệ trò chơi. Tất cả nằm sau công tắc `EXPLORE_ISLAND`.

**Architecture:**
- Engine thuần Dart ở `lib/game/travel/` gồm danh sách trạm, phép tính bước và bưu thiếp, và cách ghép câu hỏi.
- Vị trí lưu bằng bộ đếm `trip.step` trong `game_counters` (đồng bộ cộng dồn theo từng máy). Không đổi schema, không sửa máy chủ.
- Màn chơi dùng lại thẻ câu hỏi và phím của đua tên lửa; hai phần này được tách khỏi `raceControllerProvider` trước.

**Tech Stack:** Flutter 3.24.5, Riverpod 2.6, go_router 15, drift (không đổi bảng), `CustomPainter`.

**Spec:** `docs/superpowers/specs/2026-11-25-chip-du-lich-design.md`. Chủ dự án đã duyệt: sao +1 cho mỗi câu đúng ngay lần đầu, tối đa 10 mỗi lần chơi; bưu thiếp không kèm sao.

## Global Constraints

- Flutter 3.24.5; dùng `withOpacity`; không thêm gói. Chỉ dùng Riverpod.
- Màu lấy từ `tokens.dart` (`GameColors` cho cảnh chơi; thêm token nếu cần, không viết mã màu trong màn); ảnh chỉ qua `AppImages`.
- Nút bé ≥ 64, tablet ≥ 80. Tablet rẽ nhánh ngay trong file. Chuỗi giao diện tiếng Việt.
- Engine trò chơi không gọi mạng; dữ liệu trò chơi tách khỏi dữ liệu học; lần chơi du lịch **không** ghi vào `race_results`.
- 30 trạm = `geographyLevels.skip(3)`, theo thứ tự; 4 bước giữa hai trạm; trạm *k* (1..30) ở bước `4k`; hành trình dài 120 bước.
- Đúng ngay lần đầu đi 2 bước, sai rồi đúng đi 1 bước, sai thì không lùi. 10 câu mỗi lần, xen kẽ Toán (câu chẵn) và Tiếng Việt (câu lẻ), không có sao chổi.
- Đi qua trạm thì Chíp dừng lại cho xem bưu thiếp, rồi đi nốt bước còn lại.
- Đọc giá trị `trip.step` luôn kẹp về 0..120, và **không bao giờ ghi giá trị đã kẹp ngược lại**.
- Mốc "đã cho xem tới đâu" chỉ lưu trên máy: setting `tripShown.<kidId>` (không nằm trong danh sách setting được đồng bộ).
- Công tắc tắt thì Góc Chơi không đổi; mọi test cũ của Góc Chơi và đua tên lửa phải đạt nguyên.
- Trước mỗi commit: `flutter analyze` sạch, `flutter test` đạt hết.

## Review Focus

1. **Giá trị bộ đếm sau đồng bộ lớn hơn 120** (hai máy chơi offline). Vị trí hiện 120, có đủ 30 bưu thiếp, màn chơi vẫn mở được (ở trạng thái "đã đi hết"), và không có lần ghi nào làm giảm tổng. Test ở Task 3.
2. **Bỏ ngang giữa lượt** (nút quay lại, back hệ thống, hoặc tắt app sau câu thứ 3). Các bước và sao của câu đã trả lời vẫn còn. Test ở Task 4.
3. **Bấm liên tục** (hai lần vào đáp án đúng, hoặc bấm phím trong lúc Chíp đang nhảy hay đang hiện bưu thiếp). Mỗi câu chỉ được tính một lần. Test ở Task 4.
4. **Ảnh địa danh hỏng** trên bàn cờ, bưu thiếp hay sổ tem. Hiện ô màu kèm tên, không văng lỗi. Test ở Task 4 và Task 5.
5. **Góc Chơi khi bật công tắc** trên 375×667 và iPad ngang, cỡ chữ ×1.3. Không tràn. Test ở Task 6.

---

### Task 1: Tách thẻ câu hỏi và nhãn phím khỏi bàn trả lời của trận đua

**Files:**
- Create: `lib/features/game/race_question_card.dart`
- Modify: `lib/features/game/race_answer_desk.dart` (bỏ `_QuestionCard`, `_ListenButton`, `_GlyphKey`, `_keyLabel`, `_keySemantics`; dùng các widget và hàm mới)
- Modify: `lib/features/game/race_screen.dart` (import)
- Test: `test/features/game/race_question_card_test.dart`

**Interfaces:**
- Produces, không phụ thuộc controller:
  ```dart
  class RaceQuestionCard extends StatelessWidget { const RaceQuestionCard({Key? key, required RaceQuestion question, required VoidCallback onListen}); }
  Widget raceKeyLabel(RaceQuestion q, int i, Color ink, bool tablet);
  String raceKeySemantics(RaceQuestion q, int i);
  ```

- [ ] **Step 1: Viết test lỗi.**
  - `'card renders a math question without a race controller'`: pump `RaceQuestionCard` (một `MathRaceQuestion` cộng) trong `ProviderScope` + `MaterialApp`; thấy được chữ của phép tính; không có lỗi.
  - `'listen button calls back'`: chạm vào nút có nhãn semantics "Nghe lại" (dùng đúng nhãn hiện có của `_ListenButton`) thì `onListen` được gọi.
  - `'key semantics'`: với câu Toán có `choices [4,5,6]`, `raceKeySemantics(q, 1) == '5'`.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/game/race_question_card_test.dart`. Mong đợi: FAIL (thiếu thư viện).
- [ ] **Step 3: Viết code.** Chuyển nguyên văn các lớp và hàm sang file mới, đổi tên thành công khai. `AnswerDesk` gọi các tên mới. Không đổi giao diện.
- [ ] **Step 4: Chạy lại test.** Chạy: `flutter test test/features/game/`. Mong đợi: PASS, gồm cả mọi test đua hiện có.
- [ ] **Step 5: Commit.** `git commit -m "refactor(game): race question card and key labels without the race controller"`

### Task 2: Engine hành trình

**Files:**
- Create: `lib/game/travel/trip.dart`
- Test: `test/game/travel/trip_test.dart`

**Interfaces:**
- Consumes: `geographyLevels`, `GeoItem` (`lib/explore/geography_level.dart`); `buildRaceQuestions`, `RaceQuestion` (`lib/game/engine/`).
- Produces:
  ```dart
  const int tripStepsPerStop = 4;
  final List<GeoItem> tripStops;              // 30
  int get tripLength;                         // 120
  int tripStopStep(int stopIndex);            // 0-based index → 4*(index+1)
  int tripClamp(int raw);                     // clamp 0..tripLength
  int tripPostcards(int step);                // stops reached at clamped step
  List<GeoItem> tripNewStops(int from, int to); // stops with from < stopStep <= to (clamped)
  int tripStepsFor({required bool firstTry}); // 2 or 1
  /// Hops of one move: split at every stop crossed, so the screen pauses there.
  List<int> tripHops(int from, int steps);    // e.g. (3,2) -> [1,1]; (0,2) -> [2]; capped at tripLength
  List<RaceQuestion> buildTripQuestions({required int mathLevelIndex, required Map<String, GlyphStat> glyphStats, required int writingStartIndex, required Map<String, String> speechByGlyph, required Random rng}); // 10, even=math, odd=Vietnamese, comet=false
  ```

- [ ] **Step 1: Viết test lỗi.**
  - `tripStops.length == 30`; `tripStops.first.id == 'ho-guom'`; `tripStops.last.id == 'thac-niagara'`; `tripLength == 120`; `tripStopStep(0) == 4`; `tripStopStep(29) == 120`.
  - `tripPostcards(0) == 0`, `(3) == 0`, `(4) == 1`, `(119) == 29`, `(120) == 30`, `(500) == 30`, `(-5) == 0`.
  - `tripNewStops(3, 9)` có id `['ho-guom', 'vinh-ha-long']`; `tripNewStops(120, 130)` rỗng.
  - `tripStepsFor(firstTry: true) == 2`; `tripStepsFor(firstTry: false) == 1`.
  - `tripHops(3, 2) == [1, 1]`; `tripHops(0, 2) == [2]`; `tripHops(2, 2) == [2]`; `tripHops(119, 2) == [1]`; `tripHops(120, 2) == []`.
  - `buildTripQuestions` (seed 1, cấp 0, không có glyph stat):
    - có 10 câu;
    - câu chẵn là `MathRaceQuestion`, câu lẻ không phải;
    - không câu nào có `comet`.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/game/travel/trip_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.** Gọi `buildRaceQuestions` hai lần (`count: 5`, `RaceSubject.toan` và `RaceSubject.tiengViet`), xen kẽ hai danh sách, rồi `withComet(false)` từng câu.
- [ ] **Step 4: Chạy lại test.** Chạy lệnh ở Step 2. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(travel): trip engine — stops, steps, postcards, questions"`

### Task 3: Lưu tiến độ hành trình

**Files:**
- Modify: `lib/game/data/game_repository.dart`
- Create: `lib/game/travel/trip_progress.dart` (provider + mốc đã cho xem)
- Test: `test/game/travel/trip_repository_test.dart`; `test/online/sync_engine_test.dart` (thêm một ca)

**Interfaces:**
- Consumes: Task 2 (`tripClamp`, `tripNewStops`, `tripLength`).
- Produces:
  ```dart
  class TripAdvance { final int from; final int to; final List<GeoItem> newStops; }
  Future<int> GameRepository.tripStep();                       // clamped
  Future<TripAdvance> GameRepository.advanceTrip(int steps);   // one transaction; no-op past tripLength
  Future<int> GameRepository.addTripStar();                    // +1 cosmic star, returns total
  final tripProgressProvider = FutureProvider.autoDispose<TripProgress>; // watches gameDataRevisionProvider
  class TripProgress { final int step; final int postcards; final GeoItem? nextStop; final int unseen; }
  Future<void> markTripShown(WidgetRef/Ref, int step);         // setting 'tripShown.<kidId>' = step (device only)
  ```

- [ ] **Step 1: Viết test lỗi.**
  - `advanceTrip(2)` từ 0 cho `from 0`, `to 2`, không có trạm mới; tiếp `advanceTrip(2)` cho `newStops == [ho-guom]`; `tripStep() == 4`.
  - Đặt bộ đếm 119, `advanceTrip(2)` cho `to == 120` và `newStops` là trạm cuối; lại `advanceTrip(2)` thì `to == 120`, không có trạm mới, và giá trị thô của bộ đếm không giảm.
  - Ghi thô `trip.step = 150` (giả lập sau đồng bộ): `tripStep() == 120`; sau `advanceTrip(2)`, giá trị thô vẫn ≥ 150.
  - `addTripStar()` tăng `totalStars()` thêm 1; `race_results` vẫn rỗng.
  - Đồng bộ: điện thoại `advanceTrip(10)`, iPad `advanceTrip(8)` (cùng một bé, đã đồng bộ trước), rồi đồng bộ cả hai, thì `tripStep()` trên cả hai máy bằng 18.
  - Mốc đã cho xem không bị gửi đi: sau `markTripShown(...)`, `exportAll()` không chứa khóa nào có `tripShown`.
  - `TripProgress.unseen` = `tripPostcards(step) - tripPostcards(shown)`, không âm.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/game/travel/ test/online/sync_engine_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
  - Dùng `_bumpCounter(kid, uuid, 'trip.step', n)` với `n = min(steps, tripLength - clamped)`; khi `n <= 0` thì không ghi gì.
  - Sao dùng `_addCosmicStars`.
  - Ghi xong thì tăng `gameDataRevisionProvider` ở tầng gọi (màn chơi), giống đua tên lửa.
- [ ] **Step 4: Chạy lại test.** Chạy lệnh ở Step 2. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(travel): trip progress in a synced game counter"`

### Task 4: Màn chơi `/game/travel`

**Files:**
- Create: `lib/game/travel/trip_board_painter.dart` (vẽ đường, ô, tem)
- Create: `lib/features/game/travel_screen.dart` (màn, controller dạng `StateNotifier`/`Notifier` cục bộ, thẻ bưu thiếp, tổng kết)
- Modify: `lib/router.dart`; `lib/ui/theme/tokens.dart` (token màu bàn cờ nếu cần)
- Test: `test/features/game/travel_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3; `geographyAnswerPause` (`lib/features/explore/geography_session_screen.dart`); `AnswerKeys`.
- Produces: `TravelScreen({Random? random})` ở route `/game/travel`. Key cho test:
  - `ValueKey('race-key-$i')` (từ `AnswerKeys`);
  - `ValueKey('trip-postcard')` (thẻ bưu thiếp hiện ra);
  - `ValueKey('trip-continue')` (nút "Đi tiếp");
  - `ValueKey('trip-summary')`, `ValueKey('trip-again')`, `ValueKey('trip-home')`;
  - `ValueKey('trip-done')` (màn "Hoàn thành chuyến du lịch!").

Hành vi:
- **Mở màn:**
  - Đọc `tripStep`, tạo 10 câu, đọc câu đầu.
  - Nếu `step == 120` thì hiện `trip-done`; nút "Chơi tiếp" vẫn chơi được và vẫn nhận sao, nhưng không đi thêm.
- **Chọn đúng:**
  - Khóa phím, ghi ngay: `addTripStar()` nếu đúng ngay lần đầu, rồi `advanceTrip(tripStepsFor(...))`, rồi tăng `gameDataRevisionProvider`.
  - Sau đó chạy `tripHops`: mỗi ô nhảy khoảng 250 ms.
  - Tới trạm: hiện `trip-postcard` gồm ảnh (`errorBuilder` hiện ô màu kèm tên) và tên. Chíp đọc `'Chíp tới ${speech} rồi! ${fact}'`. Bé chạm `trip-continue` thì đi nốt.
  - Xong thì sang câu kế.
- **Chọn sai:** phím rung (của `AnswerKeys`), câu đó không còn tính là đúng ngay lần đầu.
- **Hết 10 câu:** hiện `trip-summary` gồm các bưu thiếp mới trong lượt và số sao (bằng số câu đúng ngay lần đầu). `trip-again` tạo lượt mới; `trip-home` thì `go('/game')`.
- **Quay lại / back hệ thống:** `go('/game')`, không hỏi lại.
- **Bố cục:**
  - Điện thoại: bàn cờ khoảng 45% chiều cao ở trên, `RaceQuestionCard` + `AnswerKeys` ở dưới.
  - Tablet ngang: bàn cờ 60% bên trái, phần trả lời bên phải.
  - Bàn cờ cuộn ngang để Chíp ở khoảng 1/3 bên trái.

- [ ] **Step 1: Viết test lỗi.** Dùng `Random` cố định để biết đáp án; speaker giả; DB trong bộ nhớ.
  - `'right first try moves two steps and pays a star'`: sau câu 1 đúng thì `tripStep() == 2` và tổng sao +1.
  - `'wrong then right moves one step, no star'`.
  - `'reaching a stop shows the postcard and waits for Đi tiếp'`: đặt sẵn bước 2, trả lời đúng ngay thì thấy `trip-postcard` với "Hồ Gươm"; chưa sang câu 2; chạm `trip-continue` thì sang câu 2.
  - `'crossing a stop on a two-step move'`: đặt sẵn bước 3, trả lời đúng ngay thì thấy bưu thiếp; sau "Đi tiếp" thì `tripStep() == 5`.
  - `'double tap counts once'`: hai lần chạm vào đáp án đúng thì `tripStep() == 2` và sao chỉ +1.
  - `'keys are locked while Chíp hops'`: chạm phím trong lúc nhảy thì không có gì thay đổi.
  - `'leaving mid-round keeps progress'`: trả lời 3 câu rồi chạm nút quay lại thì về `/game`; `tripStep()` bằng số bước đã đi.
  - `'ten answers show the summary'`: thấy `trip-summary` với đúng số sao; `trip-again` mở câu 1 mới.
  - `'finished trip shows trip-done and still plays'`: đặt sẵn bước 120.
  - `'broken stop image shows the name'`: dùng bundle hỏng cho `/explore/geo-`, không có lỗi.
  - Không tràn ở 375×667 (×1.3), 390×844, 820×1180, 1180×820.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/game/travel_screen_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.** Viết painter, màn và route (`buildSmoothTransitionPage`, cạnh các route `/game/...`).
- [ ] **Step 4: Chạy lại test và chụp màn hình.**
  - Chạy lệnh ở Step 2. Mong đợi: PASS.
  - Chụp màn hình điện thoại và iPad ngang (cách trong `docs/perf.md`), rồi xem ảnh.
- [ ] **Step 5: Commit.** `git commit -m "feat(travel): Chíp du lịch screen"`

### Task 5: Sổ tem `/game/postcards`

**Files:**
- Create: `lib/features/game/postcard_book_screen.dart`
- Modify: `lib/router.dart`
- Test: `test/features/game/postcard_book_screen_test.dart`

**Interfaces:**
- Consumes: `tripProgressProvider`, `markTripShown`, `tripStops`, `geographyLevels` (tiêu đề nhóm = `title` của cấp 4–9).
- Produces: `PostcardBookScreen()` ở route `/game/postcards`. Key `ValueKey('postcard-$id')`, `ValueKey('postcard-reveal')`.

Hành vi:
- Lưới theo nhóm (điện thoại 3 cột, tablet 5 cột).
- Ô đã có: ảnh và tên. Chạm thì mở thẻ to; Chíp đọc `'${speech}. ${fact}'`.
- Ô chưa có: bóng mờ có "?". Chạm thì Chíp nói `'Chíp chưa tới đây, mình đi tiếp nhé!'`.
- Mở sổ khi `unseen > 0`: hiện `postcard-reveal` cho từng bưu thiếp mới (chạm để xem cái kế), rồi `markTripShown(step)`.
- Màn chơi (Task 4) cũng gọi `markTripShown` sau mỗi bưu thiếp đã cho xem.

- [ ] **Step 1: Viết test lỗi.**
  - Bước 9: ô `ho-guom` và `vinh-ha-long` có tên, ô `van-mieu` có "?".
  - Chạm ô chưa có thì speaker nhận câu "Chíp chưa tới đây…".
  - Mốc đã xem = 4 và bước = 9: mở sổ thì thấy `postcard-reveal` với "Vịnh Hạ Long"; chạm thì hết lớp lật; mốc đã xem thành 9.
  - Ảnh hỏng thì hiện tên, không văng lỗi.
  - Không tràn ở 375×667 (×1.3) và 1180×820.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/game/postcard_book_screen_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.** Viết màn, thêm route, và thêm lệnh gọi `markTripShown` trong màn chơi.
- [ ] **Step 4: Chạy lại test.** Chạy lệnh ở Step 2 và `flutter test test/features/game/travel_screen_test.dart`. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(travel): postcard book"`

### Task 6: Kệ trò chơi trong Góc Chơi (sau công tắc)

**Files:**
- Modify: `lib/features/game/game_hub_screen.dart`
- Test: `test/features/game/game_hub_screen_test.dart` (hoặc file test Góc Chơi hiện có)

**Interfaces:**
- Consumes: `exploreIslandEnabledProvider`, `tripProgressProvider`, `AppImages.islandDiaLy`.
- Produces: key `ValueKey('hub-travel')` (thẻ Chíp du lịch), `ValueKey('hub-postcards')` (thẻ Sổ tem), `ValueKey('hub-postcards-new')` (chấm "Bưu thiếp mới!").

Khi bật công tắc:
- `_RaceHero` thành kệ hai thẻ ngang nhau (`hub-race` vẫn là nút đua bên trong thẻ Đua tên lửa).
- Thẻ Chíp du lịch hiện "Chíp du lịch", `'${postcards}/30 bưu thiếp'`, và chạm thì `go('/game/travel')`.
- Hàng Huy hiệu | Sticker thêm Sổ tem (`'${postcards}/30'`, có chấm `hub-postcards-new` khi `unseen > 0`); chạm thì `go('/game/postcards')`.
- Điện thoại, tablet dọc và tablet ngang đều đổi theo; giữ đúng ngân sách chiều cao của tablet ngang.

Khi tắt công tắc: không đổi gì.

- [ ] **Step 1: Viết test lỗi.**
  - Tắt: không có `hub-travel` hay `hub-postcards`; các test Góc Chơi cũ vẫn đạt.
  - Bật, bước 9: `hub-travel` có "2/30 bưu thiếp"; chạm thì mở `/game/travel`; `hub-postcards` mở `/game/postcards`.
  - Bật, bước 9, đã xem 4: có `hub-postcards-new`.
  - Bật, không tràn ở 375×667 (×1.3), 390×844, 820×1180, 1180×820 (×1.3).
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/game/game_hub_screen_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy lại test và chụp màn hình.**
  - Chạy: `flutter test test/features/game/`. Mong đợi: PASS.
  - Chụp Góc Chơi khi bật công tắc (`tools/shot/hub_shot_test.dart`), điện thoại và iPad ngang, rồi xem ảnh.
- [ ] **Step 5: Commit.** `git commit -m "feat(travel): game shelf and postcard book entry in Góc Chơi"`

### Task 7: Tài liệu

**Files:**
- Modify: `docs/PROJECT_STATE.md` (mục 6–8)

- [ ] **Step 1: Cập nhật `PROJECT_STATE.md`.**
  - Mục 6: thêm dòng "Chíp du lịch + kệ trò chơi (sau công tắc `EXPLORE_ISLAND`)".
  - Mục 8: đổi mục "Trò chơi thứ hai" thành đã có code.
  - Mục 7: ghi trò này cần ảnh Địa lý thật trước khi bật công tắc.
- [ ] **Step 2: Kiểm tra và commit.** Chạy `flutter analyze && flutter test`. Mong đợi: sạch, đạt hết. Commit: `git commit -m "docs: Chíp du lịch state"`
