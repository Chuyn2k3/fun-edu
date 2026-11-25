# Đảo Khám phá — Địa lý: kế hoạch làm

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm thẻ "Đảo Khám phá" trên trang chủ, dẫn tới một sảnh có 3 đảo. Đảo Địa lý ("Khám phá Việt Nam") mở được với 9 cấp; mỗi câu bé chọn 1 trong 3 ảnh.

**Architecture:**
- Môn mới làm đúng theo môn Tiếng Anh: danh sách cấp và bộ sinh câu hỏi bằng Dart (`lib/explore/`), màn bản đồ, màn học, cấp lưu ở `subject_levels` với khóa `'dia-ly'`. Không đổi schema.
- Thẻ trang chủ và thẻ trong Góc ba mẹ chỉ hiện khi bật hằng số `kExploreIslandEnabled`.
- Ảnh tạm sinh bằng `make_placeholders.py`; ảnh thật thay ở Task 9.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6, go_router 15, drift 2.23 (không đổi bảng), Pillow cho script ảnh.

**Spec:** `docs/superpowers/specs/2026-11-25-dao-kham-pha-dia-ly-design.md`. Chủ dự án đã duyệt (2026-11-25); đợt này không có sticker hay giấy khen cho Địa lý.

## Global Constraints

- Flutter 3.24.5; dùng `withOpacity`, không dùng `withValues`; không thêm hay nâng gói.
- Chỉ dùng Riverpod. Màu, bo góc lấy từ `lib/ui/theme/tokens.dart`; ảnh chỉ qua `lib/ui/assets.dart`.
- Thẻ dùng `raisedDecoration` (`lib/ui/theme/depth.dart`); thứ bé bấm được bọc `Pressable`; một `BoxDecoration` có cả màu và bóng.
- Nút bé ≥ 64, tablet ≥ 80 (`TabletSizes.kidTarget`); thẻ ảnh chọn ≥ 96 (điện thoại), ≥ 140 (tablet). Chữ đạt tương phản ≥ 4.5:1.
- Tablet = `context.formFactor`; rẽ nhánh tablet ngay trong file (riêng trang chủ dùng `home_tablet.dart`).
- Chuỗi giao diện tiếng Việt; chú thích code tiếng Anh. Không gọi mạng.
- Mỗi câu 3 ảnh khác nhau cùng cấp; 5 câu mỗi lượt; cấp 1–3 chỉ dạng `pickImage`; cấp 4–9 trộn `pickImage` và `listenClue`.
- Câu kể: ≤ 15 từ, chỉ điều nhìn thấy được và ở đâu; không số năm, chiến tranh, chính trị, tôn giáo được nhấn mạnh.
- Bản đồ chữ S phải có quần đảo Hoàng Sa và Trường Sa.
- Ảnh mới: 3D đồ chơi, nền xanh lá, tách bằng `tools/assets/chroma_key.py`, xuất 1x/2.0x/3.0x.
- Trước mỗi commit: `flutter analyze` sạch và `flutter test` đạt hết. Commit trên nhánh `chipchip`.

## Review Focus

1. **Cấp lưu vượt khoảng.** Một máy khác đồng bộ về cấp `'dia-ly'` lớn hơn 8 (bản app mới hơn), hoặc giá trị âm. Bản đồ, thẻ trang chủ và thẻ ba mẹ phải kẹp về 0..8, không văng lỗi. Test ở Task 3 và Task 7.
2. **Ảnh hỏng hoặc thiếu lúc chạy.** Thẻ ảnh hiện ô màu `Subject.diaLy.tint` kèm tên mục, không văng lỗi, bé vẫn chọn được. Test ở Task 4.
3. **Bấm liên tục.** Bé bấm hai lần vào ảnh đúng, hoặc bấm ảnh khác trong lúc chờ chuyển câu. Chỉ được tính một lần và chỉ sang một câu. Test ở Task 4.
4. **Không nạp ảnh Địa lý lúc mở app.** Ảnh mục không nằm trong `AppImages.all` (danh sách nạp sẵn ở màn chào). Màn học chỉ nạp sẵn ảnh của câu kế. Test ở Task 1.
5. **Chữ hệ thống ×2.0 trên 375×667, và iPad ngang có 5 thẻ môn.** Không tràn (`takeException` là null). Test ở Task 4 và Task 7.

---

### Task 1: Màu môn, đường dẫn ảnh và ảnh tạm

**Files:**
- Modify: `lib/ui/theme/tokens.dart` (enum `Subject`)
- Modify: `lib/features/dev/gallery_screen.dart:35` (map nhãn môn: thêm `Subject.diaLy: 'Địa lý'`)
- Modify: `lib/ui/assets.dart`
- Modify: `pubspec.yaml` (thêm `- assets/images/explore/`)
- Modify: `tools/assets/make_placeholders.py`, `tools/assets/test_make_placeholders.py`
- Create: `assets/images/explore/**` (ảnh tạm sinh ra)
- Test: `test/ui/contrast_test.dart`, `test/ui/assets_test.dart`

**Interfaces:**
- Produces:
  - `Subject.diaLy`: `Color(0xFF0E7490)` và tint `Color(0xFFE3F4F8)`.
  - `AppImages.icKhamPha = 'assets/images/ic-kham-pha.png'`, nằm trong `AppImages.all`.
  - `AppImages.islandDiaLy`, `islandSinhHoc`, `islandLichSu`, dạng `'assets/images/explore/island-<dia-ly|sinh-hoc|lich-su>.png'`.
  - `static const Map<String, String> geography`: id mục → `'assets/images/explore/geo-<id>.png'`, đủ 47 id ở danh sách dưới.
  - `static const explore = [islandDiaLy, islandSinhHoc, islandLichSu, ...geography.values]`. `explore` **không** nằm trong `all`.
- 47 id mục, theo thứ tự cấp:
  - `nui, song, bien, rung, dong-lua, hang-dong`
  - `nang, mua, gio, may, cau-vong, sam-set`
  - `co-viet-nam, ban-do-chu-s, non-la, ao-dai, hoa-sen`
  - `ho-guom, vinh-ha-long, van-mieu, chua-mot-cot, ruong-bac-thang`
  - `co-do-hue, chua-cau, cau-rong, dong-phong-nha, cau-vang`
  - `cho-ben-thanh, cho-noi-cai-rang, nha-tho-duc-ba, buu-dien-sai-gon, mui-ca-mau`
  - `van-ly-truong-thanh, nui-phu-si, taj-mahal, angkor-wat, thap-petronas`
  - `thap-eiffel, kim-tu-thap, thap-pisa, big-ben, dau-truong-la-ma`
  - `tuong-nu-than-tu-do, nha-hat-opera-sydney, machu-picchu, tuong-chua-cuu-the, thac-niagara`

- [ ] **Step 1: Viết test lỗi.**
  - `contrast_test.dart`: `contrastRatio(AppColors.card, Subject.diaLy.color) >= 4.5`.
  - `assets_test.dart`, test `'explore images are bundled with 2.0x and 3.0x, kept out of the splash precache'`:
    - mỗi đường dẫn trong `AppImages.explore` có trong manifest, có bản `2.0x` và `3.0x`, PNG có kênh alpha;
    - `AppImages.geography.length == 47`;
    - `AppImages.all` không chứa phần tử nào của `AppImages.explore`;
    - `AppImages.all` chứa `AppImages.icKhamPha`.
  - `test_make_placeholders.py`: `generate_placeholders(..., explore_dir=tmp)` tạo `geo-nui.png`, `island-dia-ly.png` và `ic-kham-pha.png` ở cả 3 độ phân giải, và không ghi đè file đã có.
- [ ] **Step 2: Chạy để thấy lỗi.**
  - Chạy: `flutter test test/ui/contrast_test.dart test/ui/assets_test.dart`. Mong đợi: FAIL (thiếu `Subject.diaLy` và `AppImages.explore`).
  - Chạy: `cd tools/assets && python3 -m pytest -q test_make_placeholders.py`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
  - Thêm `Subject.diaLy` và các hằng `AppImages` ở trên.
  - Mở rộng `make_placeholders.py`:
    - thêm dict `EXPLORE` (id → nhãn tiếng Việt ngắn) và tham số `--explore-dir` (mặc định `assets/images/explore`);
    - `ic-kham-pha` ghi vào `assets/images/`;
    - giữ nguyên luật không ghi đè.
- [ ] **Step 4: Sinh ảnh tạm.** Chạy `python3 tools/assets/make_placeholders.py`. Mong đợi: có 51 ảnh mới, mỗi ảnh đủ 3 độ phân giải.
- [ ] **Step 5: Chạy lại test.** Chạy hai lệnh ở Step 2 và `flutter analyze`. Mong đợi: PASS, 0 issues.
- [ ] **Step 6: Commit.** `git commit -m "feat(explore): geography colour, image paths and placeholders"`

### Task 2: Nội dung 9 cấp và bộ sinh câu hỏi

**Files:**
- Create: `lib/explore/geography_level.dart`, `lib/explore/geography_question.dart`, `lib/explore/geography_generator.dart`
- Test: `test/explore/geography_content_test.dart`, `test/explore/geography_generator_test.dart`

**Interfaces:**
- Consumes: `AppImages.geography` (Task 1).
- Produces:
  ```dart
  class GeoItem { const GeoItem({required String id, required String name, required String speech, required String fact, required String clue});
    String get image; } // AppImages.geography[id]!
  class GeographyLevel { const GeographyLevel({required String id, required String title, required String subtitle, required List<GeoItem> items, required bool clues}); }
  const List<GeographyLevel> geographyLevels; // 9, ids & titles per spec §5.2
  enum GeoQuestionKind { pickImage, listenClue }
  class GeographyQuestion { String id; GeoQuestionKind kind; String prompt; String speech; List<GeoItem> choices; int correctIndex; GeoItem get answer; }
  List<GeographyQuestion> generateGeographyQuestions(GeographyLevel level, Random random, {int count = 5});
  ```
- Quy ước dữ liệu:
  - `name` là tên hiển thị, `speech` là cách đọc (`vi-VN`). Ví dụ `name: 'Tháp Eiffel'`, `speech: 'Tháp Ép-phen'`.
  - `fact` và `clue` không chứa tên mục; dùng "Nơi này…" hoặc "Đây là…" thay tên.
  - `clues` là `false` ở cấp 1–3 (`canh-vat`, `thoi-tiet`, `viet-nam`), `true` ở cấp 4–9.
  - Phụ đề cấp liệt kê vài mục, ví dụ `'Hồ Gươm, Vịnh Hạ Long…'`.
- Câu hỏi:
  - `pickImage`: `prompt = 'Đâu là ${name}?'`, `speech = 'Đâu là ${item.speech}?'`.
  - `listenClue`: `prompt = speech = clue`.

- [ ] **Step 1: Viết test lỗi.**
  - `geography_content_test.dart`:
    - có 9 cấp, id theo đúng thứ tự spec, không trùng id;
    - mỗi cấp có từ 5 mục trở lên; tổng 47 mục; mọi id mục đều có trong `AppImages.geography`;
    - `name`, `speech`, `fact`, `clue` không rỗng;
    - `fact` có ≤ 15 từ (`split(RegExp(r'\s+'))`);
    - `fact` và `clue` không chứa `name` (so không phân biệt hoa thường);
    - `fact` không chứa chữ số;
    - `clues` là false ở chỉ số 0–2, true ở 3–8.
  - `geography_generator_test.dart`, với mỗi cấp và seed `Random(42)`:
    - sinh đủ 5 câu; mỗi câu có 3 mục khác nhau thuộc cấp đó; `correctIndex` nằm trong 0..2;
    - 5 đáp án đúng khác nhau;
    - cấp 0–2 chỉ có `pickImage`;
    - cấp 3–8 có 2 hoặc 3 câu `listenClue`;
    - cùng seed cho cùng `id` câu;
    - câu `pickImage` có `speech` bắt đầu bằng `'Đâu là '`.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/explore/`. Mong đợi: FAIL (thiếu thư viện).
- [ ] **Step 3: Viết code.**
  - Viết 3 file. Nội dung 47 mục viết theo luật trong Global Constraints.
  - Bộ sinh câu:
    - xáo các mục rồi lấy `count` đáp án đúng khác nhau;
    - mỗi câu lấy thêm 2 mục khác từ cùng cấp làm lựa chọn sai, rồi xáo 3 lựa chọn;
    - với cấp `clues`, chọn ngẫu nhiên `count ~/ 2` hoặc `count ~/ 2 + 1` câu làm `listenClue`.
- [ ] **Step 4: Chạy lại test.** Chạy: `flutter test test/explore/`. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): geography ladder content and question generator"`

### Task 3: Lưu cấp và provider

**Files:**
- Modify: `lib/progress/level_repository.dart`, `lib/progress/progress_repository.dart` (`HomeSummary`, `homeSummaryProvider`)
- Modify: `lib/online/sync/refresh_after_sync.dart`, `lib/app.dart:123`
- Test: `test/progress/level_repository_test.dart` (thêm vào file có sẵn; tạo mới nếu chưa có), `test/online/sync/` (test đồng bộ `level` có sẵn: thêm một ca)

**Interfaces:**
- Produces:
  - `Future<int> LevelRepository.recordGeographySession({required int firstTryCorrect, required int total})`: khóa `'dia-ly'`, `levelCount: geographyLevels.length`.
  - `final geographyLevelIndexProvider = FutureProvider<int>`: trả `levelOf('dia-ly') ?? 0`, **kẹp về 0..8**.
  - `HomeSummary.geographyLevelIndex` (`int`, mặc định 0).

- [ ] **Step 1: Viết test lỗi.**
  - `recordGeographySession(firstTryCorrect: 5, total: 5)` từ cấp 0 trả về 1.
  - Từ cấp 0 với 2/5 thì giữ 0.
  - `setLevel('dia-ly', 12)` rồi đọc provider ra 8.
  - `setLevel('dia-ly', -3)` rồi đọc provider ra 0.
  - Đồng bộ: một bản ghi `level` của môn `'dia-ly'` đẩy lên rồi kéo về máy thứ hai vẫn giữ nguyên chỉ số. Dùng cùng fixture với test `level` hiện có.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/progress/ test/online/sync/`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.**
  - Thêm method, provider và trường như ở Interfaces; nối provider vào `homeSummaryProvider`.
  - Thêm `ref.invalidate(geographyLevelIndexProvider)` vào `refresh_after_sync.dart`.
  - Thêm `ref.listen(geographyLevelIndexProvider, (_, __) {})` vào `app.dart`.
- [ ] **Step 4: Chạy lại test.** Chạy lệnh ở Step 2. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): store and sync the geography level"`

### Task 4: Màn học Địa lý

**Files:**
- Create: `lib/features/explore/geography_session_screen.dart`
- Test: `test/features/explore/geography_session_screen_test.dart`

**Interfaces:**
- Consumes: `GeographyLevel`, `generateGeographyQuestions` (Task 2); `speakerProvider` (`Speaker.speak`).
- Produces:
  ```dart
  GeographySessionScreen({required GeographyLevel level, required void Function(int firstTryCorrect, int total) onCompleted, int questionCount = 5, Random? random, Key? key})
  ```
  Key cho test:
  - `ValueKey('geo-choice-$i')` cho 3 thẻ ảnh;
  - `ValueKey('geo-speaker')` cho nút loa.

Hành vi giống `english_session_screen.dart`, với các điểm sau:
- Đọc bằng `speak` (`vi-VN`).
- Chọn đúng: hiện `'${name}! ${fact}'` và đọc `'${speech}. ${fact}'`.
- Chọn sai: thẻ rung, hiện `'Thử lại nhé! Nghe Chíp đọc lại nào!'` và đọc lại câu hỏi.
- Có `_answered` chặn bấm thêm trong lúc chờ chuyển câu.
- Thẻ ảnh có `Image.asset(..., errorBuilder:)` hiện ô `Subject.diaLy.tint` kèm `name`.
- Sau mỗi câu, `precacheImage` 3 ảnh của câu kế.
- Bố cục:
  - điện thoại: 3 thẻ ảnh xếp một cột hoặc một hàng, mỗi thẻ ≥ 96;
  - tablet dọc: 3 thẻ một hàng, mỗi thẻ ≥ 140;
  - tablet ngang: Chíp bên trái, ảnh bên phải.

- [ ] **Step 1: Viết test lỗi.** Dùng `Random(1)`, speaker giả ghi lại câu đã đọc.
  - `'wrong then right counts no first-try'`: chọn sai rồi chọn đúng ở câu 1, các câu sau chọn đúng ngay; `onCompleted(4, 5)`.
  - `'all right first time'`: `onCompleted(5, 5)`; câu đầu tiên đã đọc bắt đầu bằng `'Đâu là '`.
  - `'double tap on the right answer advances once'`: bấm hai lần vào đáp án đúng; sau `_nextDelay` thấy câu 2 chứ không phải câu 3; `onCompleted` chỉ được gọi một lần.
  - `'tap during transition is ignored'`: bấm đáp án sai trong lúc chờ chuyển câu; không hiện lời "Thử lại".
  - `'broken image shows the name tile'`: dùng `AssetBundle` ném lỗi khi nạp ảnh `geo-*`; thấy chữ tên mục, `takeException()` là null.
  - `'speaker button repeats the question'`.
  - Bố cục, mỗi ca kiểm `takeException()` là null:
    - 375×667 với `textScaler` 2.0;
    - 390×844;
    - iPad 820×1180;
    - iPad 1180×820.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/explore/geography_session_screen_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.** Viết `GeographySessionScreen` như trên.
- [ ] **Step 4: Chạy lại test.** Chạy lệnh ở Step 2. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): geography session screen"`

### Task 5: Bản đồ Địa lý và màn luyện

**Files:**
- Create: `lib/features/subject/geography_map_screen.dart`
- Modify: `lib/router.dart`
- Test: `test/features/explore/geography_map_screen_test.dart`

**Interfaces:**
- Consumes:
  - `geographyLevelIndexProvider`, `recordGeographySession` (Task 3);
  - `GeographySessionScreen` (Task 4);
  - `homeSummaryProvider`.
- Produces:
  - `GeographyMapScreen()` ở route `/subject/dia-ly`;
  - `PracticeGeographyScreen(int levelIndex)` ở route `/practice-dia-ly/:levelIndex`.
  - Key ô bản đồ: `ValueKey('geo-level-$i')`, `ValueKey('geo-done-$i')`.

Cả hai màn chép theo `english_map_screen.dart` và `PracticeEnglishScreen`, với các điểm sau:
- Màu lấy `Subject.diaLy`.
- Tiêu đề màn: "Khám phá Việt Nam".
- Nút quay về: `pop`, nếu không pop được thì `go('/kham-pha')`.
- Lưu cấp chỉ khi bé học đúng cấp hiện tại; lưu xong `invalidate(geographyLevelIndexProvider)` và `invalidate(homeSummaryProvider)`.
- Lỗi lưu: hiện toast `'Không lưu được kết quả'`.
- Chỉ số cấp ngoài 0..8 thì hiện `'Chưa có cấp này'`.

- [ ] **Step 1: Viết test lỗi.**
  - Bản đồ:
    - cấp đang lưu là 2: ô 0 và 1 có `geo-done`, ô 2 bấm được, ô 3 khóa;
    - cấp lưu 12: ô 8 đang học, không văng lỗi.
  - Màn luyện:
    - `levelIndex` 2 khi bé đang ở cấp 2, xong 5/5 thì cấp thành 3;
    - `levelIndex` 0 khi bé đang ở cấp 2 thì cấp không đổi;
    - `/practice-dia-ly/99` hiện `'Chưa có cấp này'`.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/explore/geography_map_screen_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.** Viết hai màn và thêm hai route (`buildSmoothTransitionPage`) cạnh các route Tiếng Anh.
- [ ] **Step 4: Chạy lại test.** Chạy lệnh ở Step 2. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): geography map and practice route"`

### Task 6: Sảnh Đảo Khám phá

**Files:**
- Create: `lib/features/explore/explore_hub_screen.dart`
- Modify: `lib/router.dart`
- Test: `test/features/explore/explore_hub_screen_test.dart`

**Interfaces:**
- Consumes: `AppImages.island*` (Task 1), `geographyLevelIndexProvider` (Task 3), `showAppToast`.
- Produces: `ExploreHubScreen()` ở route `/kham-pha`. Key: `ValueKey('island-dia-ly')`, `ValueKey('island-sinh-hoc')`, `ValueKey('island-lich-su')`.

Màn sảnh:
- Tiêu đề "Đảo Khám phá"; nút quay về `pop`, nếu không pop được thì `go('/')`.
- 3 thẻ dùng `raisedDecoration` + `Pressable`:
  - Địa lý: "Khám phá Việt Nam", hiện "n/9", chạm thì `push('/subject/dia-ly')`;
  - Sinh học và Lịch sử: hiện "Sắp có", chạm thì `showAppToast(context, 'Sắp có', kind: AppToastKind.info)`.
- Bố cục: điện thoại xếp dọc, tablet 3 thẻ một hàng.

- [ ] **Step 1: Viết test lỗi.**
  - Chạm `island-dia-ly` thì mở `/subject/dia-ly`.
  - Chạm `island-sinh-hoc` thì hiện toast "Sắp có" và route không đổi.
  - Không tràn ở 375×667 (chữ ×2.0) và iPad 1180×820.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/explore/explore_hub_screen_test.dart`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.** Viết màn và thêm route `/kham-pha`.
- [ ] **Step 4: Chạy lại test.** Chạy lệnh ở Step 2. Mong đợi: PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): explore island hub"`

### Task 7: Thẻ trang chủ, thẻ Góc ba mẹ và công tắc

**Files:**
- Create: `lib/explore/explore_flags.dart`
- Modify: `lib/features/home/home_screen.dart` (`_SubjectGrid`, chỗ gọi ở dòng 253 và 329)
- Modify: `lib/features/home/home_tablet.dart:214` (gọi `subjects`)
- Modify: `lib/parent/screens/progress_tab.dart` (`ProgressData`, `progressDataProvider`, thẻ `_GeographyCard`)
- Test: `test/features/home_screen_test.dart`, `test/parent/` (test tab Tiến bộ có sẵn)

**Interfaces:**
- Produces:
  ```dart
  // lib/explore/explore_flags.dart
  const bool kExploreIslandEnabled = bool.fromEnvironment('EXPLORE_ISLAND', defaultValue: false);
  ```
  - `_SubjectGrid` nhận thêm `bool showExplore` (truyền vào giá trị `kExploreIslandEnabled`) và `int geographyLevelIndex`.
  - `ProgressData.geographyLevel` (`int`).

Thẻ khám phá trên trang chủ:
- Dùng `SubjectCard(subject: Subject.diaLy, imagePath: AppImages.icKhamPha, title: 'Đảo Khám phá', subtitle: 'Địa lý, Sinh học, Lịch sử', done: geographyLevelIndex + 1, total: geographyLevels.length, onTap: () => context.push('/kham-pha'))`.
- Bố cục:
  - `_SubjectGrid` xếp thẻ theo hàng `columns` thẻ; hàng cuối thiếu thẻ thì các thẻ còn lại chia đều toàn bộ bề ngang (không còn đọc `cards[i + j]` vượt danh sách);
  - điện thoại và tablet dọc: thẻ khám phá là một hàng rộng dưới lưới 2×2;
  - tablet ngang: `home_tablet.dart` gọi `subjects(kExploreIslandEnabled ? 5 : 4, card)`, nên 5 thẻ nằm trên một hàng và không đổi ngân sách chiều cao `_fits`.

Góc ba mẹ:
- `_GeographyCard` giống `_EnglishCard`, tiêu đề "Địa lý"; chỉ hiện khi bật công tắc.
- Cấp kẹp về 0..8.

- [ ] **Step 1: Viết test lỗi.** Test dùng một tham số ở hàm dựng để ép bật/tắt, không phụ thuộc biến build.
  - Tắt: không có chữ "Đảo Khám phá"; mọi test trang chủ hiện có vẫn đạt, kể cả `'iPhone nhỏ 375x667: cả 4 thẻ môn học nằm hoàn toàn phía trên FloatingNavBar'`.
  - Bật, điện thoại 390×844:
    - thẻ "Đảo Khám phá" rộng bằng lưới;
    - chạm vào thì mở `/kham-pha`.
  - Bật, 375×667: 4 thẻ môn vẫn nằm trên `FloatingNavBar`; cuộn tới thấy thẻ khám phá; không tràn.
  - Bật, iPad 1180×820: 5 thẻ trên một hàng, không tràn, giữ bố cục không cuộn (`_fits`) như trước.
  - Bật, iPad 820×1180: không tràn.
  - Bật, cấp lưu 12: thẻ hiện `9/9`.
  - Góc ba mẹ:
    - bật: thấy "Địa lý" với `"Đang học: Cảnh vật quanh em"` và `"1/9"`;
    - tắt: không thấy thẻ.
- [ ] **Step 2: Chạy để thấy lỗi.** Chạy: `flutter test test/features/home_screen_test.dart test/parent/`. Mong đợi: FAIL.
- [ ] **Step 3: Viết code.** Viết công tắc, sửa `_SubjectGrid` và hai chỗ gọi, thêm `_GeographyCard`.
- [ ] **Step 4: Chạy lại test và chụp màn hình.**
  - Chạy lệnh ở Step 2. Mong đợi: PASS.
  - Chạy `tools/shot/home_shot_test.dart` (cách chạy trong `docs/perf.md`) với công tắc bật, rồi xem ảnh điện thoại và iPad.
- [ ] **Step 5: Commit.** `git commit -m "feat(explore): home card and parent progress behind EXPLORE_ISLAND"`

### Task 8: Bảng duyệt chữ, câu lệnh ảnh, tài liệu

**Files:**
- Create: `docs/superpowers/specs/assets/dia-ly-noi-dung.md`
- Modify: `docs/phase0/asset-list.md`, `docs/PROJECT_STATE.md` (mục 6–8)

- [ ] **Step 1: Viết bảng duyệt chữ.** `dia-ly-noi-dung.md` là bảng 47 dòng, cột: cấp | id | tên | cách đọc | câu kể | gợi ý | đã duyệt (ô trống). Sinh bằng một test nhỏ có `// ignore` hoặc chép tay; nội dung phải khớp đúng `geographyLevels`.
- [ ] **Step 2: Viết câu lệnh ảnh.** Thêm vào `asset-list.md` phần "Đảo Khám phá":
  - một câu lệnh Gemini dùng chung kiểu ảnh: mô hình đồ chơi 3D thu nhỏ trên đế tròn, nhìn chéo từ trên, ánh sáng mềm, nền xanh lá `#00FF00` phẳng, không chữ, không người nhận diện được;
  - một dòng mô tả riêng cho từng id trong 51 ảnh;
  - dòng `ban-do-chu-s` ghi rõ: có quần đảo Hoàng Sa và Trường Sa;
  - tên file đích và lệnh `chroma_key.py`.
- [ ] **Step 3: Cập nhật `PROJECT_STATE.md`.**
  - Mục 6: thêm dòng "Đảo Khám phá — Địa lý (code, ảnh tạm, công tắc `EXPLORE_ISLAND` tắt)".
  - Mục 7: ghi chờ duyệt chữ, chờ ảnh thật, ảnh bản đồ cần kiểm riêng.
  - Mục 8: sửa các mục đã cũ (chữ hoa, Vở của bé, Toán nâng cao đã xong).
- [ ] **Step 4: Kiểm tra và commit.** Chạy `flutter analyze && flutter test`. Mong đợi: sạch, đạt hết. Commit: `git commit -m "docs(explore): content review sheet, image prompts, project state"`

### Task 9: Ảnh thật (cổng chủ dự án, ngoài vòng code)

Cách sinh ảnh do chủ dự án chọn: hoặc chủ dự án tự sinh trên Gemini, hoặc phiên AI dùng khóa Gemini API mà chủ dự án cấp qua form bảo mật. Task này chỉ chạy khi đã có ảnh. Không đổi code ngoài `assets/` và `tools/assets/configs/`.

- [ ] **Step 1: Ảnh mẫu.** Sinh 3 ảnh mẫu (`ho-guom`, `vinh-ha-long`, `thap-eiffel`) và gửi chủ dự án duyệt phong cách. **Dừng lại chờ duyệt.**
- [ ] **Step 2: Sinh cả bộ.** Sinh đủ 51 ảnh; tách nền bằng `python3 tools/assets/chroma_key.py`; xuất 1x/2.0x/3.0x vào đúng đường dẫn của Task 1, ghi đè ảnh tạm; thêm cấu hình vào `tools/assets/configs/hd/` và `build_app_images.sh`.
- [ ] **Step 3: Kiểm tra.** Chạy `flutter test test/ui/assets_test.dart`. Mong đợi: PASS (vẫn có kênh alpha). Xem ảnh `ban-do-chu-s` có Hoàng Sa và Trường Sa.
- [ ] **Step 4: Commit.** `git commit -m "art(explore): real geography images"`
- [ ] **Step 5: Bật công tắc.** Chỉ sau khi chủ dự án đánh dấu duyệt toàn bộ `dia-ly-noi-dung.md` và ảnh: đổi `defaultValue` của `EXPLORE_ISLAND` thành `true`, cập nhật test "tắt" để ép tắt, chạy `flutter test`, rồi commit.
