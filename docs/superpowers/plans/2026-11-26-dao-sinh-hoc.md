# Đảo Sinh học + khung đảo chung — kế hoạch làm

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Biến Địa lý thành một khai báo trên khung đảo dùng chung, thêm dạng câu ghép đôi, và thêm đảo Sinh học "Khám phá sự sống" 9 cấp. Sinh học để cờ `ready = false` cho tới khi có ảnh thật và chữ đã duyệt.

**Architecture:**
- `ExploreIsland` gồm `id` (khóa lưu và đường dẫn), `prefix` ảnh, tên, màu, ảnh đảo, danh sách cấp, `ready`.
- `GeoItem` giữ tên cũ (Chíp du lịch đang dùng), thêm `prefix` để tra ảnh.
- Cấp có thêm danh sách `pairs` cho dạng ghép đôi.
- Màn học, bản đồ, màn luyện, provider và thẻ đều nhận vào một đảo. Đường dẫn được sinh cho từng đảo; đường dẫn của Địa lý giữ nguyên.

**Tech Stack:** Flutter 3.24.5, Riverpod 2.6, go_router 15, drift (không đổi bảng).

**Spec:** `docs/superpowers/specs/2026-11-26-dao-sinh-hoc-design.md`

## Global Constraints

- Không đổi schema. Khóa lưu là `'dia-ly'` và `'sinh-hoc'`; mỗi đảo có 9 cấp, giá trị đọc ra luôn kẹp về 0..8.
- Địa lý giữ nguyên: đường dẫn `/subject/dia-ly`, `/practice-dia-ly/:levelIndex`; ảnh `assets/images/explore/geo-<id>.png`; mọi test Địa lý và Chíp du lịch hiện có phải đạt.
- Sinh học: đường dẫn `/subject/sinh-hoc`, `/practice-sinh-hoc/:levelIndex`; ảnh `assets/images/explore/bio-<id>.png`; tên bản đồ "Khám phá sự sống"; tên trong sảnh "Sinh học".
- Màu mới `Subject.sinhHoc`, chữ trắng trên màu chính đạt tương phản ≥ 4.5:1, khác các màu môn đang có.
- Cờ `ready`: Địa lý `true`, Sinh học `false`. Ghi đè được qua `exploreReadyProvider` để test.
  - Đảo chưa `ready`: sảnh hiện "Sắp có", không có thẻ Góc ba mẹ, không tính vào vòng tiến độ trên trang chủ.
- Vòng tiến độ trang chủ = tổng `(cấp + 1)` của các đảo `ready` / tổng số cấp của các đảo đó.
- Ghép đôi: ảnh đề và 3 ảnh đáp. Lựa chọn sai là ảnh đáp của các cặp khác cùng cấp, trừ `alsoRight`. Chọn đúng thì Chíp đọc `'${answer.speech}! ${fact}'`.
- Câu kể ≤ 15 từ, không chữ số, không nhắc tên đáp án. Sinh học không có "ăn thịt", "săn", "chết", "máu".
- Sang câu kế bằng `SpeechWait` (Chíp nói xong mới sang câu).
- Trước mỗi commit: `flutter analyze` sạch, `flutter test` đạt hết.

## Review Focus

1. **Tiến độ Địa lý sau khi đổi khung.** Bé đang ở cấp 5 Địa lý thì sau khi cập nhật app vẫn ở cấp 5, và đồng bộ vẫn đúng. Test ở Task 2.
2. **Sinh học chưa `ready` lọt ra ngoài** qua sảnh, Góc ba mẹ hoặc vòng trang chủ. Test ở Task 4.
3. **Ghép đôi có đáp án cũng đúng.** Ví dụ hỏi "Thỏ thích ăn gì?" mà lựa chọn có cỏ; câu như vậy không bao giờ được xuất hiện. Test ở Task 1 và Task 5.
4. **Màn ghép đôi ở 375×667, cỡ chữ ×2.0, và trên iPad ngang.** Không tràn, ảnh đề và ảnh đáp đủ lớn. Test ở Task 3.
5. **Cấp lưu của Sinh học vượt khoảng** (12 hoặc -1). Bản đồ và thẻ đều kẹp lại. Test ở Task 2 và Task 3.

---

### Task 1: Mô hình đảo chung + câu ghép đôi

**Files:**
- Create: `lib/explore/explore_island.dart` (`ExploreIsland`, `geographyIsland`, `exploreIslands`)
- Modify: `lib/explore/geography_level.dart` (`GeoItem.prefix`, `PairItem`, `GeographyLevel.pairs`)
- Modify: `lib/explore/geography_question.dart` (`GeoQuestionKind.pairPick`, `focus`, `fact`)
- Modify: `lib/explore/geography_generator.dart`
- Modify: `lib/ui/theme/tokens.dart` (`Subject.sinhHoc`), `lib/features/dev/gallery_screen.dart`, `lib/ui/assets.dart`
- Test: `test/explore/explore_island_test.dart`, `test/explore/pair_generator_test.dart`, `test/ui/contrast_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class ExploreIsland { const ExploreIsland({required String id, required String prefix, required String name, required String mapTitle, required Subject subject, required String islandImage, required List<GeographyLevel> levels, required bool ready}); }
  const geographyIsland; // id 'dia-ly', prefix 'geo', name 'Địa lý', mapTitle 'Khám phá Việt Nam', levels geographyLevels, ready true
  final List<ExploreIsland> exploreIslands; // [geographyIsland, biologyIsland] (biology added in Task 5; until then [geographyIsland])
  ExploreIsland? exploreIslandById(String id);
  // GeoItem gains `final String prefix` (default 'geo'); image => AppImages.exploreArt['$prefix-$id']!
  class PairItem { const PairItem({required String id, required GeoItem ask, required GeoItem answer, required String question, String? questionSpeech, required String fact, List<String> alsoRight = const []}); }
  // GeographyLevel gains `final List<PairItem> pairs` (default const []); a level with pairs asks only pairPick.
  // GeographyQuestion gains `final GeoItem? focus` (the ask picture) and `final String? fact` (pair fact); `String get praise` → pair: '${answer.speech}! ${fact}', else '${answer.speech}. ${answer.fact}'
  ```
- `AppImages.exploreArt`: `Map<String, String>` gồm mọi khóa `geo-<id>` (hiện có) cộng `bio-<id>` (Task 5), tra ra đường dẫn ảnh.
- `AppImages.geography` giữ nguyên cho test hiện có.

- [ ] **Step 1: Viết test lỗi.**
  - `explore_island_test`:
    - `geographyIsland.id == 'dia-ly'`, `prefix == 'geo'`, `ready`;
    - `exploreIslandById('dia-ly')` đúng đảo; `exploreIslandById('x') == null`;
    - mọi `GeoItem.image` của Địa lý không đổi so với `AppImages.geography[id]`.
  - `pair_generator_test`, với một cấp thử có 5 cặp và `thỏ.alsoRight = ['co']`:
    - 5 câu, mọi câu là `pairPick`, có `focus`, có 3 lựa chọn khác nhau;
    - đáp án đúng là `answer` của cặp;
    - không câu nào có lựa chọn sai nằm trong `alsoRight` của cặp đó (chạy 50 seed);
    - 5 đáp án đúng khác nhau;
    - `praise` của câu ghép đôi là `'${answer.speech}! ${fact}'`;
    - `prompt` là `question`, `speech` là `questionSpeech ?? question`.
  - `contrast_test`: `contrastRatio(AppColors.card, Subject.sinhHoc.color) >= 4.5`.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/explore/ test/ui/contrast_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
  - Thêm các khai báo ở Interfaces.
  - `Subject.sinhHoc(Color(0xFF4D7C0F), Color(0xFFF0F7E2))`.
  - Bộ sinh câu ghép đôi: xáo các cặp, lấy `count` cặp khác nhau. Lựa chọn sai lấy từ `answer` của các cặp khác, loại id có trong `alsoRight`, rồi lấy 2 cái và xáo cả 3.
- [ ] **Step 4: Chạy lại test.** Chạy: `flutter test test/explore/ test/ui/`. Mong đợi: PASS, gồm cả test Địa lý cũ.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): shared island model and pair questions"`

### Task 2: Lưu cấp theo đảo, cờ ready, tiến độ trang chủ

**Files:**
- Modify: `lib/progress/level_repository.dart`, `lib/progress/progress_repository.dart`, `lib/online/sync/refresh_after_sync.dart`, `lib/app.dart`, `lib/explore/explore_flags.dart`
- Test: `test/progress/level_repository_test.dart`

**Interfaces:**
- Produces:
  ```dart
  Future<int> LevelRepository.recordExploreSession(ExploreIsland island, {required int firstTryCorrect, required int total}); // recordGeographySession delegates
  final exploreLevelIndexProvider = FutureProvider.family<int, String>; // by island id, clamped 0..levels-1
  // geographyLevelIndexProvider stays (reads exploreLevelIndexProvider('dia-ly'))
  final exploreReadyProvider = Provider.family<bool, String>((ref, id) => exploreIslandById(id)?.ready ?? false);
  // HomeSummary gains exploreDone (int) and exploreTotal (int) over ready islands
  ```

- [ ] **Step 1: Viết test lỗi.**
  - `recordExploreSession(geographyIsland, 5/5)` từ cấp 4 đưa `'dia-ly'` lên 5. Kết quả bằng đúng `recordGeographySession`.
  - Một đảo thử với id `'thu'` ghi vào khóa `'thu'` và không đụng `'dia-ly'`.
  - `exploreLevelIndexProvider('sinh-hoc')` với giá trị lưu 12 đọc ra 8; với -1 đọc ra 0.
  - `homeSummaryProvider`, khi `exploreReadyProvider` ghi đè: chỉ Địa lý `ready` (cấp 3) thì `(exploreDone, exploreTotal) == (4, 9)`; Sinh học cũng `ready` (cấp 1) thì `(6, 18)`.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/progress/`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
  - `refresh_after_sync` và `app.dart` invalidate/listen `exploreLevelIndexProvider` cho mọi đảo trong `exploreIslands`.
- [ ] **Step 4: Chạy lại test.** Chạy: `flutter test test/progress/ test/online/sync_engine_test.dart`. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): levels per island, ready flag, home total"`

### Task 3: Màn học, bản đồ, màn luyện dùng chung + giao diện ghép đôi

**Files:**
- Modify: `lib/features/explore/geography_session_screen.dart`
  - đổi thành `ExploreSessionScreen(island, level, …)`;
  - giữ `typedef GeographySessionScreen = ExploreSessionScreen` với `island` mặc định `geographyIsland`;
  - thêm bố cục ghép đôi.
- Modify: `lib/features/subject/geography_map_screen.dart`: `ExploreMapScreen(island)`, `PracticeExploreScreen(island, levelIndex, {random})`. Tên cũ giữ làm alias hoặc lớp con với Địa lý.
- Modify: `lib/router.dart`: với mỗi đảo trong `exploreIslands`, sinh hai route `/subject/${id}` và `/practice-${id}/:levelIndex`.
- Test: `test/features/explore/pair_session_screen_test.dart`; các test Địa lý hiện có giữ nguyên.

**Interfaces:**
- Consumes: Tasks 1–2.
- Produces:
  - `ExploreSessionScreen({ExploreIsland island = geographyIsland, required GeographyLevel level, required void Function(int,int) onCompleted, int questionCount = 5, Random? random})`
  - `ExploreMapScreen(ExploreIsland island)`
  - `PracticeExploreScreen(ExploreIsland island, int levelIndex, {Random? random})`
  - Key: `ValueKey('geo-focus')` cho ảnh đề; vẫn dùng `geo-choice-$i`, `geo-speaker`, `geo-level-$i`, `geo-done-$i`, `geo-locked-$i`.

Màn học:
- Màu theo `island.subject`.
- Câu ghép đôi: ảnh đề to ở giữa (điện thoại ≥ 160, tablet ≥ 220, có `errorBuilder` hiện tên), 3 ảnh đáp bên dưới.
- Chọn đúng thì đọc `q.praise`; nút loa sau khi trả lời đọc lại `q.praise`.
- Tiêu đề bản đồ là `island.mapTitle`. Bản đồ quay về `/kham-pha`. Màn luyện xong thì quay về `/subject/${island.id}`.

- [ ] **Step 1: Viết test lỗi.** Dùng một đảo thử có một cấp ghép đôi, ảnh hỏng thì hiện tên.
  - Thấy `geo-focus`; đọc câu hỏi đầu là `question`; chọn đúng thì speaker nhận `praise`.
  - `onCompleted(5, 5)` khi trả lời đúng hết.
  - Không tràn ở 375×667 (×2.0), 390×844, 820×1180, 1180×820. Ảnh đề ≥ 160 trên điện thoại, ≥ 220 trên tablet.
  - Đường dẫn: `/subject/dia-ly` có tiêu đề "Khám phá Việt Nam"; `/practice-dia-ly/99` hiện "Chưa có cấp này".
  - Bản đồ đảo thử ở `/subject/thu` với cấp lưu 12: ô 8 là ô đang học.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/explore/`. Mong đợi: FAIL ở test mới.
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy lại test.** Chạy: `flutter test test/features/explore/ test/voice/`. Mong đợi: PASS (gồm các test Địa lý và chờ giọng nói cũ).
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): shared session/map screens, pair layout, routes per island"`

### Task 4: Sảnh, trang chủ, Góc ba mẹ theo đảo

**Files:**
- Modify: `lib/features/explore/explore_hub_screen.dart`, `lib/features/home/home_screen.dart`, `lib/parent/screens/progress_tab.dart`
- Test: `test/features/explore/explore_hub_screen_test.dart`, `test/features/home_screen_test.dart`, `test/parent/progress_tab_test.dart`

**Interfaces:**
- Consumes: `exploreIslands`, `exploreReadyProvider`, `exploreLevelIndexProvider`, `HomeSummary.exploreDone/exploreTotal`.
- Produces: key `ValueKey('island-${id}')` cho mỗi đảo (`island-dia-ly`, `island-sinh-hoc`), và `island-lich-su` cho thẻ Lịch sử.

Hành vi:
- **Sảnh:**
  - đảo `ready`: hiện `'${cấp+1}/${số cấp}'`, chạm thì `push('/subject/$id')`;
  - đảo chưa `ready` và Lịch sử: hiện "Sắp có", chạm thì hiện toast.
- **Trang chủ:** thẻ "Đảo Khám phá" hiện `exploreDone/exploreTotal`.
- **Góc ba mẹ:** mỗi đảo `ready` một thẻ, tiêu đề `island.name`.

- [ ] **Step 1: Viết test lỗi.**
  - Sảnh, Sinh học chưa `ready`: chạm `island-sinh-hoc` thì có toast "Sắp có", đường dẫn không đổi.
  - Sảnh, Sinh học `ready` (ghi đè), cấp 1: thẻ hiện "2/9"; chạm thì mở `/subject/sinh-hoc`.
  - Trang chủ, công tắc bật:
    - chỉ Địa lý `ready`, cấp 3: thẻ "4/9";
    - cả hai `ready`, Sinh học cấp 1: "6/18".
  - Góc ba mẹ, công tắc bật:
    - Sinh học chưa `ready`: không có chữ "Sinh học";
    - Sinh học `ready`: thấy "Sinh học" và "Đang học: Con vật trong nhà".
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy các test ở mục Files. Mong đợi: FAIL ở test mới.
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy lại test.** Chạy: `flutter test test/features/ test/parent/`. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): hub, home and parent cards per island with ready gating"`

### Task 5: Nội dung Sinh học, ảnh tạm, bảng duyệt, câu lệnh ảnh

**Files:**
- Create: `lib/explore/biology_level.dart` (`biologyLevels`, `biologyIsland`); thêm vào `exploreIslands`.
- Modify: `lib/ui/assets.dart` (`AppImages.biology` map, nằm trong `exploreArt` và `explore`), `tools/assets/make_placeholders.py` (mục `bio-*`)
- Create: `docs/superpowers/specs/assets/sinh-hoc-noi-dung.md`, cấu hình `tools/assets/configs/explore/bio-*.json`
- Modify: `docs/phase0/asset-list.md` (mục "Đảo Sinh học")
- Test: `test/explore/biology_content_test.dart`, `test/ui/assets_test.dart`

Nội dung theo spec §5.2:
- 9 cấp, id cấp theo bảng spec.
- Cấp 5 và 6 chỉ có `pairs`, mỗi cấp 5 cặp:
  - cấp 5: thỏ→cà rốt (`alsoRight` gồm cỏ), khỉ→chuối, mèo→đĩa cá, bò→bó cỏ (`alsoRight` gồm cà rốt), ong→hoa;
  - cấp 6: trứng→gà con, nòng nọc→ếch, sâu→bướm, hạt→cây mầm, bê con→bò.
- `clues` từ cấp 4 trở đi (trừ hai cấp ghép đôi).
- Ảnh dùng chung có ghi chú trong code: cà rốt (cấp 5 và 8), bướm (cấp 4 và 6), bò (cấp 6, dùng làm đáp).

- [ ] **Step 1: Viết test lỗi.**
  - Nội dung:
    - có 9 cấp, id theo spec;
    - cấp 5 và 6 có 5 cặp, các cấp còn lại có từ 5 mục trở lên;
    - mọi ảnh có trong `AppImages.exploreArt`;
    - `fact`/`clue` ≤ 15 từ, không chữ số, không chứa tên đáp án, không có "ăn thịt", "săn", "chết", "máu";
    - id trong `alsoRight` phải là `answer` của một cặp cùng cấp;
    - mỗi cặp còn ít nhất 2 lựa chọn sai hợp lệ;
    - `biologyIsland.id == 'sinh-hoc'`, `ready == false`.
  - Ảnh: `AppImages.explore` chứa ảnh `bio-*` và ảnh đảo; có đủ 2.0x, 3.0x và kênh alpha; không nằm trong `AppImages.all`.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/explore/ test/ui/assets_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
  - Viết nội dung.
  - Mở rộng `EXPLORE` trong `make_placeholders.py`, rồi chạy `python3 tools/assets/make_placeholders.py`.
  - Sinh bảng duyệt chữ từ code.
  - Viết câu lệnh Gemini cho từng ảnh. Con vật hiền, không có cảnh săn mồi. Cá trong cặp của mèo là cá nấu chín trong đĩa. Cây cỏ màu xanh rêu, không dùng `#00FF00`.
  - Viết cấu hình tách nền.
- [ ] **Step 4: Chạy lại test.** Chạy: `flutter test && (cd tools/assets && python3 -m pytest -q)`. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): Sinh học island content, placeholders, review sheet, prompts"`

### Task 6: Tài liệu

- [ ] **Step 1: Cập nhật `docs/PROJECT_STATE.md`.**
  - Mục 6: thêm dòng "Khung đảo chung + Đảo Sinh học (ready = false)".
  - Mục 7: chờ duyệt chữ Sinh học và ảnh; muốn mở Sinh học thì đổi `ready` thành `true` trong `biology_level.dart`.
  - Mục 8: Lịch sử chỉ còn nội dung và ảnh.
- [ ] **Step 2: Kiểm tra và commit.** Chạy `flutter analyze && flutter test`. Mong đợi: sạch, đạt hết. Commit: `git commit -m "docs: Sinh học state"`
