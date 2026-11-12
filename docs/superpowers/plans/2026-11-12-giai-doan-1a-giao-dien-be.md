# Giai đoạn 1A — Giao diện cho bé: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Biến màn thử của giai đoạn 0 thành giao diện thật cho bé theo bản phác thảo thứ 2: trang chủ có Chíp Chíp, "Bài hôm nay" gồm 3 chữ, màn tập viết đẹp có Chíp Chíp phản ứng, màn "Xong bài" có sao và lịch tuần, bản đồ môn Viết; sao và ngày học lưu trên máy.

**Architecture:** Thêm vào dự án Flutter ở gốc repo (nhánh `chipchip`). Logic thuần Dart (soạn bài, tính sao/ngày học) tách khỏi giao diện để test riêng. Tiến độ lưu bằng drift (thêm bảng, schema v2 có migration). Ảnh 3D lấy từ ảnh Gemini đã duyệt, cắt bằng `tools/assets/cut_sheet.py`. Bộ chấm nét, `TracePad`, `GlyphSession`, bộ giao diện chung của giai đoạn 0 dùng lại nguyên.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, flutter_riverpod 2.6, go_router 15, drift 2.23 + drift_flutter 0.2.4 (ghim), Python 3 + Pillow cho script ảnh.

**Spec:** `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` (mục 4, 5.1, 8.2, 8.2a, 8.3, 10 — Giai đoạn 1, 12)

## Global Constraints

- Chạy được với Flutter 3.24 (Dart 3.5): `environment.sdk: '>=3.5.0 <4.0.0'`; import `package:flutter/material.dart`; không dùng API chỉ có ở Flutter mới hơn (ví dụ `Color.withValues`, dùng `withOpacity`). Không đổi phiên bản gói đã ghim.
- Một thư viện trạng thái: Riverpod (API 2.x). Không SDK quảng cáo/theo dõi bên thứ ba. Chạy không cần mạng.
- Màu, bo góc, bóng, font chỉ lấy từ `lib/ui/theme/tokens.dart` và `buildAppTheme()`; không viết mã màu mới trong màn hình.
- Nút cho bé cao ≥ 64; chữ đạt tương phản ≥ 4.5:1 (đã có `contrastRatio`).
- Không có cơ chế gây áp lực: không "mất chuỗi ngày", không trừ sao. Hiển thị "N ngày học tuần này", không hiển thị chuỗi liên tiếp.
- Đường dẫn ảnh chỉ qua hằng số trong `lib/ui/assets.dart`.
- Chữ hiển thị cho bé đúng nguyên văn trong kế hoạch.
- Không xóa `TraceScreen` và công cụ ghi nét: chúng chuyển sang route debug.

## Review Focus

1. **Bé đã thuộc hết mọi chữ** → "Bài hôm nay" vẫn có đủ 3 chữ (ôn lại), không rỗng. → test Task 4.
2. **Thang chữ có ít hơn 3 chữ hoặc thiếu file glyph** → bài gồm những chữ có thật, không lỗi. → test Task 4.
3. **Bé bấm quay lại giữa bài** → không ghi hoàn thành, không cộng sao thưởng bài. → test Task 7.
4. **Ranh giới ngày và tuần** (23:59 → 00:01, Chủ nhật → thứ Hai) → lịch tuần và "N ngày học tuần này" đúng theo giờ máy. → test Task 3.
5. **Màn nhỏ và màn lớn** (375×667 và 1024×1366) → trang chủ, màn tập viết, màn xong bài không tràn. → test Task 5, 6, 7.

---

## Cấu trúc file

```
assets/images/{chip-*,ic-*}.png (+ 2.0x/, 3.0x/), assets/images/bg-sky.jpg
assets/glyphs/{net-xien,net-cong,net-moc,so-0..so-9}.json        # mới (tạm)
tools/assets/configs/{chip-main,chip-expressions,icons}.json        # cấu hình cắt
lib/ui/assets.dart                      # AppImages: hằng số đường dẫn ảnh
lib/ui/widgets/dotted_background.dart   # nền kem chấm bi (tách từ gallery)
lib/ui/widgets/subject_card.dart        # thẻ môn: ảnh, tên, mô tả, vòng tiến độ / "Sắp có"
lib/ui/widgets/speech_bubble.dart
lib/learning/writing_ladder.dart        # thứ tự chữ môn Viết
lib/learning/lesson_composer.dart       # soạn Bài hôm nay (thuần Dart)
lib/progress/progress_tables.dart       # bảng drift mới
lib/progress/progress_repository.dart   # ghi/đọc tiến độ, sao, ngày học
lib/features/home/home_screen.dart
lib/features/writing/writing_screen.dart
lib/features/writing/ruled_paper.dart   # nền ô li
lib/features/lesson/lesson_flow_screen.dart
lib/features/lesson/lesson_done_screen.dart
lib/features/subject/writing_map_screen.dart
```

---

### Task 1: Ảnh 3D vào app

**Files:**
- Create: `tools/assets/configs/chip-main.json`, `tools/assets/configs/chip-expressions.json`, `tools/assets/configs/icons.json`, `assets/images/...`, `lib/ui/assets.dart`
- Modify: `pubspec.yaml` (khai báo `assets/images/`)
- Test: `test/ui/assets_test.dart`

**Interfaces:**
- Produces: `abstract final class AppImages` với hằng `chipMain, chipJoy, chipThumb, chipSurprise, chipEncourage, chipSleep, chipWrite, icViet, icTiengViet, icToan, icTiengAnh, icStar, icFlame, icCrown, bgSky` (giá trị `assets/images/<tên>.png`, riêng `bgSky` = `assets/images/bg-sky.jpg`), và `static const all = [...]`.

Nguồn (đã duyệt, có trong repo): `docs/superpowers/specs/assets/chipchip-main.webp` (1024²), `chipchip-expressions.webp` (lưới 3×2, có chữ nhãn dưới mỗi ô), `icons-sheet.webp` (lưới 3×3), `bg-sky.webp`.

| Cấu hình | Mục (tên: box [l,t,r,b]) | export_widths |
|---|---|---|
| chip-main | chip-main: [0,0,1024,1024] | [200,400,600] |
| chip-expressions | chip-joy [0,40,341,415]; chip-thumb [341,40,682,415]; chip-surprise [682,40,1024,415]; chip-encourage [0,600,341,965]; chip-sleep [341,600,682,965]; chip-write [682,600,1024,965] | [100,200,300] |
| icons | ic-viet [0,0,341,341]; ic-tieng-viet [341,0,682,341]; ic-toan [682,0,1024,341]; ic-tieng-anh [682,341,1024,682]; ic-star [0,682,341,1024]; ic-flame [341,682,682,1024]; ic-crown [682,682,1024,1024] | [64,128,192] |

`bg-sky.jpg`: cắt `bg-sky.webp` vùng `[0,0,1024,700]`, lưu JPEG chất lượng 88 (một độ phân giải, không qua script).

- [ ] **Step 1: Viết test** — mỗi đường dẫn trong `AppImages.all` có trong `AssetManifest` (dùng `AssetManifest.loadFromAssetBundle(rootBundle)`), và với ảnh `.png` có cả biến thể `2.0x`, `3.0x`.
- [ ] **Step 2: Chạy, thấy FAIL** — `flutter test test/ui/assets_test.dart`.
- [ ] **Step 3: Viết 3 file cấu hình, chạy script** — `python3 tools/assets/cut_sheet.py <ảnh> <cấu hình> assets/images` cho từng cấu hình; tạo `bg-sky.jpg`; viết `lib/ui/assets.dart`; khai báo `assets/images/` trong pubspec.
- [ ] **Step 4: Kiểm tra bằng mắt** — ghép các PNG lên nền `#FBF5EC` thành một ảnh tạm (không commit), xem không bị khuyết nền hay viền trắng lớn. Ghi nhận xét vào báo cáo.
- [ ] **Step 5: Chạy, thấy PASS**, rồi `flutter test` toàn bộ.
- [ ] **Step 6: Commit** — `feat(assets): ảnh 3D Chíp Chíp và biểu tượng`

---

### Task 2: Nét mẫu tạm cho nét cơ bản và số 0–9

**Files:**
- Create: `tools/glyphs/make_glyphs.py`, `assets/glyphs/{net-xien,net-cong,net-moc,so-0,...,so-9}.json`, `lib/learning/writing_ladder.dart`
- Test: `test/learning/writing_ladder_test.dart` (test tự chấm `test/stroke/assets_self_grade_test.dart` đã có sẽ tự quét file mới)

**Interfaces:**
- Produces: `const List<String> writingLadder = ['net-ngang','net-thang-dung','net-xien','net-cong','net-moc','so-0','so-1','so-2','so-3','so-4','so-5','so-6','so-7','so-8','so-9'];`

Dữ liệu **tạm** do máy sinh (script Python thuần, không thư viện ngoài), theo mẫu chữ số tiểu học; chủ dự án sẽ ghi lại bằng công cụ sau. Khung chữ số: x 0.25–0.75, y 0.1–0.9. Mỗi nét ≥ 12 điểm; đường cong lấy mẫu dày (≥ 24 điểm/vòng). Làm tròn 4 chữ số.

| id | label | Số nét | Thứ tự và hướng |
|---|---|---|---|
| net-xien | Nét xiên | 1 | từ (0.7,0.1) xuống (0.3,0.9) |
| net-cong | Nét cong | 1 | cung chữ C: tâm (0.55,0.5), bán kính 0.35, từ góc −60° ngược chiều kim đồng hồ tới +60° (mở bên phải) |
| net-moc | Nét móc | 1 | thẳng xuống từ (0.4,0.1) tới (0.4,0.75), rồi cong móc sang phải lên kết thúc ở (0.62,0.72) |
| so-0 | Số 0 | 1 | hình bầu dục khép kín, bắt đầu ở đỉnh, đi ngược chiều kim đồng hồ (sang trái trước) |
| so-1 | Số 1 | 2 | (1) xiên ngắn từ (0.35,0.35) lên đỉnh (0.6,0.1); (2) thẳng đứng từ (0.6,0.1) xuống (0.6,0.9) |
| so-2 | Số 2 | 2 | (1) cong trên từ trái-trên vòng qua phải rồi xiên xuống góc dưới trái (0.27,0.9); (2) ngang đáy từ (0.27,0.9) sang (0.75,0.9) |
| so-3 | Số 3 | 1 | cong trên (bụng phải) rồi cong dưới (bụng phải), từ trái-trên tới trái-dưới |
| so-4 | Số 4 | 3 | (1) xiên từ (0.55,0.1) xuống (0.25,0.65); (2) ngang từ (0.25,0.65) sang (0.75,0.65); (3) thẳng đứng từ (0.6,0.35) xuống (0.6,0.9) |
| so-5 | Số 5 | 3 | (1) thẳng xiên từ (0.35,0.1) xuống (0.32,0.45); (2) cong phải (bụng dưới) từ (0.32,0.45) vòng qua phải tới (0.27,0.85); (3) ngang trên từ (0.35,0.1) sang (0.72,0.1) |
| so-6 | Số 6 | 1 | cong trái từ (0.68,0.15) xuống đáy rồi vòng kín ở nửa dưới, kết thúc ở giữa vòng (≈0.3,0.62) |
| so-7 | Số 7 | 2 | (1) ngang trên từ (0.25,0.1) sang (0.75,0.1); (2) xiên từ (0.75,0.1) xuống (0.4,0.9) |
| so-8 | Số 8 | 1 | bắt đầu (0.68,0.2), cong trái qua đỉnh xuống giữa, cong phải xuống đáy, vòng trái lên lại giữa và kết thúc gần điểm đầu |
| so-9 | Số 9 | 2 | (1) vòng kín nửa trên, bắt đầu (0.7,0.25) đi ngược chiều kim đồng hồ; (2) từ (0.7,0.25) thẳng xuống hơi cong tới (0.45,0.9) |

- [ ] **Step 1: Viết test thang chữ** — mọi id trong `writingLadder` có file `assets/glyphs/<id>.json`; với mỗi chữ có từ 2 nét trở lên, nộp nét 2 trước cho `GlyphSession` → `StrokeError.wrongOrder`; với mọi nét có độ dài > 0.05, nộp nét đảo ngược → không `ok`.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết `make_glyphs.py`** (sinh JSON theo bảng, `--out assets/glyphs`), chạy nó, viết `writing_ladder.dart`.
- [ ] **Step 4: Chạy, thấy PASS** — `flutter test` toàn bộ (gồm test tự chấm có sẵn). Nếu một nét đảo ngược vẫn `ok` (ví dụ đường cong khép kín đối xứng), ghi rõ trong báo cáo và để nét đó bắt đầu/kết thúc ở hai điểm khác nhau đủ xa, không sửa bộ chấm.
- [ ] **Step 5: Commit** — `feat(glyphs): nét mẫu tạm cho nét cơ bản và số 0–9`

---

### Task 3: Lưu tiến độ, sao và ngày học

**Files:**
- Create: `lib/progress/progress_tables.dart`, `lib/progress/progress_repository.dart`
- Modify: `lib/data/app_database.dart` (thêm bảng, `schemaVersion` 2, `MigrationStrategy` tạo bảng mới khi nâng từ 1), `lib/data/app_database.g.dart` (sinh lại)
- Test: `test/progress/progress_repository_test.dart`, `test/data/migration_test.dart`

**Interfaces:**
- Produces:
  - Bảng `GlyphProgress(glyphId text PK, completions int, cleanCompletions int, lastPracticedAt dateTime)` và `LessonCompletions(id autoIncrement, completedAt dateTime, starsEarned int)`.
  - `typedef Clock = DateTime Function();`
  - `class ProgressRepository { ProgressRepository(AppDatabase db, {Clock now = DateTime.now}); Future<void> recordGlyphCompleted(String glyphId, {required int failedStrokes}); Future<int> recordLessonCompleted({required int glyphsCompleted}); Future<int> totalStars(); Future<Map<String, GlyphStat>> glyphStats(); Future<Set<int>> learnedWeekdaysThisWeek(); }`
  - `class GlyphStat { final int completions; final int cleanCompletions; bool get mastered => cleanCompletions >= 1; }`
  - Provider `progressRepositoryProvider`, và `homeSummaryProvider` (FutureProvider) trả `HomeSummary { int totalStars; int learnedDaysThisWeek; int masteredWriting; int level; }` với `level = 1 + masteredWriting ~/ 3`.
- Quy tắc: hoàn thành một chữ với `failedStrokes <= 1` là "sạch". Sao: `recordLessonCompleted` cộng `glyphsCompleted + 2` sao (1 sao mỗi chữ, thưởng 2 khi xong bài) và trả số sao vừa cộng. Ngày học = ngày (theo giờ máy) có ít nhất một `LessonCompletions`. Tuần tính từ thứ Hai (`DateTime.weekday` 1..7).

- [ ] **Step 1: Viết test repository** (DB bộ nhớ, đồng hồ giả):
  - 2 lần hoàn thành `so-1` (một lần `failedStrokes: 3`, một lần `0`) → `completions 2`, `cleanCompletions 1`, `mastered true`.
  - `recordLessonCompleted(glyphsCompleted: 3)` trả 5; gọi hai lần → `totalStars() == 10`.
  - Học lúc thứ Tư 23:59 và thứ Năm 00:01 → `learnedWeekdaysThisWeek() == {3, 4}`; đồng hồ chuyển sang thứ Hai tuần sau → tập rỗng.
  - Học Chủ nhật → thuộc tuần đó (weekday 7), thứ Hai kế tiếp là tuần mới.
- [ ] **Step 2: Viết test migration** — tạo DB schema v1 (chỉ `stroke_attempts`) bằng SQL thô trên `NativeDatabase.memory`, đặt `user_version = 1`, mở bằng `AppDatabase` → ghi được `LessonCompletions` và dữ liệu `stroke_attempts` cũ còn nguyên.
- [ ] **Step 3: Chạy, thấy FAIL.**
- [ ] **Step 4: Viết bảng, migration, repository, provider; sinh lại code** (`dart run build_runner build --delete-conflicting-outputs`).
- [ ] **Step 5: Chạy, thấy PASS** — `flutter test` toàn bộ.
- [ ] **Step 6: Commit** — `feat(progress): lưu tiến độ chữ, sao và ngày học`

---

### Task 4: Soạn "Bài hôm nay"

**Files:**
- Create: `lib/learning/lesson_composer.dart`
- Test: `test/learning/lesson_composer_test.dart`

**Interfaces:**
- Consumes: `writingLadder` (Task 2), `GlyphStat` (Task 3).
- Produces: `List<String> composeTodayLesson({required List<String> ladder, required Map<String, GlyphStat> stats, required Set<String> available, int size = 3})` (thuần Dart) và provider `todayLessonProvider` (FutureProvider<List<String>>; `available` = id glyph có trong assets).
- Quy tắc theo thứ tự: chỉ xét id có trong `available`, giữ thứ tự thang. (a) Lấy tối đa `size - 1` chữ **chưa thuộc** đầu tiên. (b) Thêm 1 chữ **ôn**: chữ đã thuộc có `completions - cleanCompletions` lớn nhất (hòa thì chữ đứng trước trong thang). (c) Nếu chưa đủ `size`, lấp bằng chữ chưa thuộc tiếp theo, rồi chữ đã thuộc theo thứ tự thang. Không lặp chữ. Trả ít hơn `size` chỉ khi `available ∩ ladder` ít hơn `size`.

- [ ] **Step 1: Viết test** — người mới (stats rỗng) → 3 chữ đầu thang; đã thuộc 2 chữ đầu → [chữ 3, chữ 4, chữ ôn]; chữ ôn là chữ sai nhiều nhất; thuộc hết → 3 chữ ôn khác nhau; `available` chỉ có 2 id → trả 2; `available` rỗng → trả rỗng; không bao giờ có id ngoài `available`.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết hàm và provider.**
- [ ] **Step 4: Chạy, thấy PASS.**
- [ ] **Step 5: Commit** — `feat(learning): soạn bài hôm nay`

---

### Task 5: Trang chủ

**Files:**
- Create: `lib/features/home/home_screen.dart`, `lib/ui/widgets/dotted_background.dart`, `lib/ui/widgets/subject_card.dart`, `lib/ui/widgets/speech_bubble.dart`
- Modify: `lib/router.dart` (`/` → `HomeScreen` mới; danh sách glyph cũ chuyển sang `/dev/glyphs` dưới `kDebugMode`), `lib/features/dev/gallery_screen.dart` (dùng `DottedBackground`), `test/app_smoke_test.dart` (tìm `Bài hôm nay` thay cho `Chíp Chíp`)
- Test: `test/features/home_screen_test.dart`

**Interfaces:**
- Consumes: `AppImages` (T1), `homeSummaryProvider` (T3), `todayLessonProvider` (T4), `glyphProvider` (giai đoạn 0), các widget giai đoạn 0.
- Produces: `DottedBackground({required Widget child})`; `SubjectCard({required Subject subject, required String imagePath, required String title, required String subtitle, int? done, int? total, VoidCallback? onTap})` — `onTap == null` thì hiện nhãn `Sắp có` thay vòng tiến độ; `SpeechBubble({required String text})`.

Bố cục theo bản phác thảo 2 (trang chủ), từ trên xuống, trong `SafeArea` và cuộn được:
- Nền kem chấm bi; ảnh `bgSky` phủ đầu trang (cao 300, mờ dần vào nền).
- Hàng trên: viên "Chào bé!" kèm dòng nhỏ có `icCrown` + `Cấp {level}`; viên `icStar` + tổng sao; nút tròn ổ khóa (nhãn trợ năng `Góc ba mẹ`) → SnackBar `Góc ba mẹ sắp có`.
- Khối Chíp Chíp: ảnh `chipMain` bên phải, `SpeechBubble` bên trái: `Hôm nay Chíp với bé tập viết {label chữ đầu} nhé!`; thẻ trắng `Bài hôm nay` với `{đã xong}/{tổng} bài` (1A: luôn `0/{tổng}`) và nút tròn cam ▶ (nhãn trợ năng `Bắt đầu bài hôm nay`) → `/lesson`.
- Hàng viên: `icFlame` + `{N} ngày học tuần này`.
- Tiêu đề `Hôm nay học gì?`; lưới 2 cột `SubjectCard`: Viết (`icViet`, `Nét và số`, `{masteredWriting}/{writingLadder.length}`, → `/subject/viet`), Tiếng Việt (`icTiengViet`, `Chữ, âm, vần`, Sắp có), Toán (`icToan`, `Đếm, cộng trừ`, Sắp có), Tiếng Anh (`icTiengAnh`, `Chữ cái, từ`, Sắp có).
- `FloatingNavBar` nổi dưới đáy: `Học` (đang chọn), `Chơi`, `Sưu tập`, `Nhà Chíp`; ba mục sau → SnackBar `Sắp có`.

- [ ] **Step 1: Viết test** — với provider giả (`HomeSummary(totalStars: 12, learnedDaysThisWeek: 3, masteredWriting: 2, level: 1)`, bài `['net-xien','net-cong','net-ngang']`): thấy `Bài hôm nay`, `12`, `3 ngày học tuần này`, `Cấp 1`, `2/15`, `Hôm nay Chíp với bé tập viết Nét xiên nhé!`, đúng 3 lần `Sắp có` trên thẻ môn; bấm ▶ → điều hướng `/lesson` (dùng `GoRouter` thử); bấm ổ khóa → `Góc ba mẹ sắp có`. Dựng ở 375×667 và 1024×1366 không có ngoại lệ tràn.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết widget và màn; sửa router và smoke test.**
- [ ] **Step 4: Chạy, thấy PASS** — `flutter test` toàn bộ, `flutter analyze` sạch.
- [ ] **Step 5: Commit** — `feat(home): trang chủ có Chíp Chíp và bài hôm nay`

---

### Task 6: Màn tập viết

**Files:**
- Create: `lib/features/writing/writing_screen.dart`, `lib/features/writing/ruled_paper.dart`
- Modify: `lib/features/trace/trace_pad.dart` (thêm tùy chọn `bool crayon = false`: vẽ nét như sáp màu — nét chính cộng các nét mảnh lệch nhẹ, mờ hơn, theo hạt giống cố định để không nhấp nháy)
- Test: `test/features/writing_screen_test.dart`, bổ sung `test/features/trace_pad_test.dart`

**Interfaces:**
- Consumes: `TracePad`, `GlyphSession`, `databaseProvider.logAttempt` (giai đoạn 0), `AppImages`.
- Produces: `WritingScreen({required Glyph glyph, required void Function(int failedStrokes) onCompleted, int? step, int? totalSteps, Key? key})`; `RuledPaper` (nền ô li: 5 đường ngang, đường thứ 3 và đường đáy đậm hơn, màu lấy từ `AppColors.dot`).

Bố cục theo bản phác thảo 2 (tập viết): hàng trên có nút ‹ (nhãn trợ năng `Quay lại`), tiêu đề `Viết {label}`, thanh tiến độ `step/totalSteps` (ẩn nếu null), viên sao; thẻ trắng lớn: `RuledPaper` + `TracePad(crayon: true)` với `guide` là nét mẫu, chấm tròn navy đánh số `1..n` ở điểm đầu của **nét kế tiếp**; dưới thẻ: ảnh Chíp Chíp + `SpeechBubble`; hàng 3 nút trắng `Nghe`, `Xem mẫu`, `Xóa`.

Hành vi:
- Mỗi lần nhấc tay: `submit` vào `GlyphSession`, ghi `logAttempt` (như `TraceScreen`). Đúng → nét giữ lại, Chíp `chipJoy`, lời `Giỏi quá! Giờ tô nét {số} nhé.` (hoặc khi xong chữ: Chíp `chipThumb`, lời `Bé viết {label} đẹp lắm!`, gọi `onCompleted(số nét sai)` sau 1.2 giây). Sai → nét bỏ đi, Chíp `chipEncourage`, lời theo lỗi: `tooShort` `Vẽ dài thêm chút nữa nhé`, `wrongDirection` `Bé vẽ ngược chiều rồi`, `offPath` `Đi theo đường chấm nhé`, `wrongOrder` `Nét này vẽ sau nhé`.
- Lúc bắt đầu: Chíp `chipMain`, lời `Bé tô nét số 1 nhé!`.
- `Nghe` → SnackBar `Giọng đọc sắp có`. `Xem mẫu` → nét kế tiếp nhấp nháy cam 3 lần (tổng ≈1.5 giây). `Xóa` → xóa nét đã tô và bắt đầu lại chữ (`GlyphSession.reset`).

- [ ] **Step 1: Viết test** — với glyph 2 nét giả và DB bộ nhớ: vẽ đúng nét 1 → thấy `Giỏi quá! Giờ tô nét 2 nhé.`; vẽ ngược nét 2 → `Bé vẽ ngược chiều rồi`; vẽ đúng nét 2 → `Bé viết {label} đẹp lắm!` và sau `pump(1.2s)` `onCompleted` được gọi đúng một lần với `1`; `Xóa` đưa về `Bé tô nét số 1 nhé!`; dựng ở 375×667 và 1024×1366 không tràn. Test TracePad: `crayon: true` dựng không lỗi.
- [ ] **Step 2: Chạy, thấy FAIL.**
- [ ] **Step 3: Viết code.**
- [ ] **Step 4: Chạy, thấy PASS** — `flutter test` toàn bộ.
- [ ] **Step 5: Commit** — `feat(writing): màn tập viết có Chíp Chíp`

---

### Task 7: Luồng bài học, màn xong bài và bản đồ môn Viết

**Files:**
- Create: `lib/features/lesson/lesson_flow_screen.dart`, `lib/features/lesson/lesson_done_screen.dart`, `lib/features/subject/writing_map_screen.dart`
- Modify: `lib/router.dart` (`/lesson`, `/lesson/done`, `/subject/viet`, `/practice/:glyphId`), `docs/phase0/stroke-test.md` (màn thử chữ giờ ở `flutter run --route=/dev/glyphs`)
- Test: `test/features/lesson_flow_test.dart`, `test/features/writing_map_test.dart`

**Interfaces:**
- Consumes: `todayLessonProvider` (T4), `WritingScreen` (T6), `ProgressRepository` (T3), `glyphProvider`, `AppImages`.
- Produces: `LessonFlowScreen` (đi lần lượt các chữ của bài bằng `WritingScreen` với `step/totalSteps`; mỗi chữ xong gọi `recordGlyphCompleted`; xong chữ cuối gọi `recordLessonCompleted` rồi `go('/lesson/done', extra: starsEarned)`); `LessonDoneScreen(starsEarned)`; `WritingMapScreen` (lưới chữ theo `writingLadder`: ô có `label`, dấu ✓ nếu đã thuộc, bấm → `/practice/:glyphId` = `WritingScreen` đơn lẻ, xong thì ghi `recordGlyphCompleted` và quay lại bản đồ, không cộng sao bài).

Màn xong bài theo bản phác thảo 2: nền `bgSky` mờ dần, tiêu đề `Xong bài hôm nay!`, dòng `Chíp Chíp tự hào về bé lắm`, ảnh `chipThumb` giữa các ngôi sao `icStar`; thẻ trắng 3 cột: `icStar` `+{starsEarned}` `sao`; `icFlame` `{N}` `ngày học tuần này`; `icCrown` `Cấp {level}` `cấp độ`; thẻ `Tuần này của bé` 7 ô T2…CN (ô đã học có `icStar`, ô hôm nay nền cam); nút chính `Về trang chính` → `/`.

- [ ] **Step 1: Viết test luồng** — bài giả 2 chữ một nét; hoàn thành cả hai → `recordGlyphCompleted` 2 lần, `recordLessonCompleted(glyphsCompleted: 2)` 1 lần, đến màn `Xong bài hôm nay!` với `+4`; bấm `Về trang chính` → `/`. Bấm ‹ ở chữ đầu → về `/`, `totalStars()` vẫn 0 và không có `LessonCompletions`. Dựng màn xong bài ở 375×667 và 1024×1366 không tràn.
- [ ] **Step 2: Viết test bản đồ** — đã thuộc `net-ngang` → ô `Nét ngang` có ✓; bấm `Nét xiên` → mở màn `Viết Nét xiên`.
- [ ] **Step 3: Chạy, thấy FAIL.**
- [ ] **Step 4: Viết code, route; sửa tài liệu phase0.**
- [ ] **Step 5: Chạy, thấy PASS** — `flutter test` toàn bộ, `flutter analyze` sạch.
- [ ] **Step 6: Commit** — `feat(lesson): bài hôm nay, màn xong bài, bản đồ môn Viết`

---

## Xong giai đoạn 1A khi

- `flutter analyze` sạch, mọi test PASS trên Flutter 3.24.5; `tools/assets` pytest PASS.
- Mở app: trang chủ như bản phác thảo 2 với ảnh thật; "Bài hôm nay" chạy hết 3 chữ tới màn xong bài; sao và "ngày học tuần này" tăng đúng và còn sau khi tắt mở lại app.
- Chủ dự án chạy thử trên máy thật và xác nhận.
