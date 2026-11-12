# Giai đoạn 0 — Thử bộ chấm nét và nền móng: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng dự án Flutter mới `app/` có bộ chấm nét chạy trên máy (kèm công cụ ghi nét mẫu và màn tô thử để thử với bé thật), bộ giao diện chung theo bảng màu đã chốt, và script làm hình từ ảnh Gemini.

**Architecture:** App Flutter mới nằm trong thư mục `app/` của nhánh `chipchip`. Bộ chấm nét là Dart thuần (`lib/stroke/`), không phụ thuộc Flutter, test bằng `dart test` logic qua `flutter test`. Giao diện dùng Riverpod cho trạng thái, go_router cho điều hướng, drift (SQLite) để ghi lại các lần chấm nét phục vụ buổi thử với bé. Script làm hình là Python độc lập trong `tools/assets/`.

**Tech Stack:** Flutter (stable mới nhất lúc làm), Dart ≥ 3.5, flutter_riverpod, go_router, drift + drift_flutter, build_runner, Python 3 + Pillow + numpy + pytest.

**Spec:** `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` (mục 8.2, 8.2a, 8.4, 9.1, 10 — Giai đoạn 0)

## Global Constraints

- Chỉ một thư viện quản lý trạng thái: Riverpod. Không thêm Provider, Bloc, GetX, states_rebuilder.
- App chạy đầy đủ không cần mạng: font, ảnh, dữ liệu nét đều đóng kèm trong `assets/`. Không tải font lúc chạy.
- Không SDK quảng cáo, theo dõi hay phân tích của bên thứ ba.
- Không khóa API hay bí mật nào trong mã nguồn hoặc trong `assets/`.
- Màu (mục 8.2a, giữ nguyên giá trị): chính `#C8460F`; nhấn `#E8590C`; nền `#FBF5EC`, chấm bi `#EADFCF`; thẻ `#FFFFFF`; chữ `#22284A`; chữ phụ `#5B6385`; Viết `#E8590C`/`#FFF0E4`; Tiếng Việt `#7C3AED`/`#F3EDFF`; Toán `#2563EB`/`#E8F1FF`; Tiếng Anh `#0F8A5F`/`#E5F7EF`.
- Font Nunito, tiêu đề và nút đậm 800–900. Thẻ bo 24–28 px. Nút cho bé ≥ 64 pt. Chữ đạt tương phản ≥ 4.5:1.
- Tọa độ nét luôn chuẩn hóa về ô vuông đơn vị `[0,1]×[0,1]`, gốc ở góc trên trái, y hướng xuống.
- Mã định danh ứng dụng (đã chốt): `com.ibme.funedu` cho cả Android (applicationId) và iOS (bundle id).
- Code mới chỉ nằm trong `app/` và `tools/`; tài liệu trong `docs/`.

## Review Focus

1. **Bé nhấc tay giữa chừng** (một nét vẽ thành hai đoạn): đoạn đầu phải ra `tooShort`, phiên không nhảy sang nét sau, không lỗi. → test trong Task 3.
2. **Chạm một điểm cho nét không phải dấu chấm** (độ dài 0): ra `tooShort`, không chia cho 0, không NaN. → test trong Task 2.
3. **Hai ngón tay hoặc lòng bàn tay chạm cùng lúc**: chỉ ngón chạm đầu tiên được tính. → test trong Task 5.
4. **Vẽ tràn ra ngoài khung**: điểm bị kẹp về `[0,1]`, không ngoại lệ. → test trong Task 4.
5. **Màn hình khác kích thước** (điện thoại và máy tính bảng): cùng một nét vẽ trên khung 300 px và 600 px cho cùng tọa độ chuẩn hóa. → test trong Task 4.

---

## Cấu trúc file

```
app/
  pubspec.yaml
  lib/main.dart                      # khởi động ProviderScope + App
  lib/app.dart                       # MaterialApp.router, theme
  lib/router.dart                    # go_router: /, /trace/:glyphId, /dev/recorder, /dev/gallery
  lib/stroke/geometry.dart           # Point2, độ dài, lấy mẫu lại, khoảng cách
  lib/stroke/glyph.dart              # Stroke, Glyph, JSON
  lib/stroke/grader.dart             # GradeConfig, StrokeError, StrokeResult, gradeStroke
  lib/stroke/glyph_session.dart      # GlyphSession: thứ tự nét
  lib/stroke/glyph_repository.dart   # đọc assets/glyphs/*.json
  lib/data/app_database.dart         # drift: bảng StrokeAttempts
  lib/features/dev/recorder_controller.dart
  lib/features/dev/recorder_screen.dart
  lib/features/dev/gallery_screen.dart
  lib/features/trace/trace_pad.dart  # khung vẽ dùng chung (thu nét, kẹp tọa độ, một ngón)
  lib/features/trace/trace_screen.dart
  lib/ui/theme/tokens.dart           # AppColors, AppRadii, AppShadows
  lib/ui/theme/contrast.dart         # contrastRatio
  lib/ui/theme/app_theme.dart        # buildAppTheme()
  lib/ui/widgets/app_card.dart
  lib/ui/widgets/info_pill.dart
  lib/ui/widgets/primary_button.dart
  lib/ui/widgets/progress_ring.dart
  lib/ui/widgets/floating_nav_bar.dart
  assets/fonts/Nunito-{Regular,SemiBold,Bold,ExtraBold,Black}.ttf
  assets/glyphs/*.json
  test/...                           # gương theo lib/
tools/assets/cut_sheet.py
tools/assets/test_cut_sheet.py
docs/phase0/stroke-test.md           # quy trình và kết quả thử với bé
docs/phase0/asset-list.md            # danh sách ảnh cần tạo cho giai đoạn 1
```

---

### Task 1: Dựng dự án Flutter `app/`

**Files:**
- Create: `app/` (bằng `flutter create`), `app/lib/main.dart`, `app/lib/app.dart`, `app/lib/router.dart`, `app/README.md`
- Test: `app/test/app_smoke_test.dart`

**Interfaces:**
- Produces: `class App extends StatelessWidget` trong `lib/app.dart`; `final GoRouter appRouter` trong `lib/router.dart` với route `/` (màn tạm `HomePlaceholder` hiện chữ `Chíp Chíp`). Các task sau thêm route vào `appRouter`.

- [ ] **Step 1: Cài Flutter nếu máy chưa có** — `git clone https://github.com/flutter/flutter.git -b stable ~/flutter && export PATH=$HOME/flutter/bin:$PATH && flutter --version`. Ghi phiên bản Flutter/Dart vào `app/README.md`.
- [ ] **Step 2: Tạo dự án** — `flutter create --org com.ibme --project-name funedu --platforms android,ios app`. Kiểm tra applicationId Android và bundle id iOS đều là `com.ibme.funedu`.
- [ ] **Step 3: Thêm phụ thuộc** — `flutter pub add flutter_riverpod go_router drift drift_flutter path_provider` và `flutter pub add --dev drift_dev build_runner`. Xóa `cupertino_icons` nếu không dùng.
- [ ] **Step 4: Viết test khói**

```dart
testWidgets('app khởi động và hiện tên Chíp Chíp', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: App()));
  await tester.pumpAndSettle();
  expect(find.text('Chíp Chíp'), findsOneWidget);
});
```

- [ ] **Step 5: Chạy, thấy FAIL** — `cd app && flutter test test/app_smoke_test.dart` → lỗi chưa có `App`.
- [ ] **Step 6: Viết `main.dart`, `app.dart` (MaterialApp.router dùng `appRouter`), `router.dart`.**
- [ ] **Step 7: Chạy lại, thấy PASS** — cùng lệnh, `All tests passed!`. Thêm `flutter analyze` → `No issues found!`.
- [ ] **Step 8: Commit** — `git add app && git commit -m "feat(app): dựng dự án Flutter chipchip"`

---

### Task 2: Hình học nét và chấm một nét

**Files:**
- Create: `app/lib/stroke/geometry.dart`, `app/lib/stroke/glyph.dart`, `app/lib/stroke/grader.dart`
- Test: `app/test/stroke/geometry_test.dart`, `app/test/stroke/glyph_test.dart`, `app/test/stroke/grader_test.dart`

**Interfaces:**
- Produces:
  - `class Point2 { final double x, y; const Point2(this.x, this.y); }` (có `==`, `hashCode`)
  - `double pathLength(List<Point2> pts)`
  - `List<Point2> resample(List<Point2> pts, int n)` — n điểm cách đều theo độ dài cung; độ dài 0 → n bản sao của điểm đầu; danh sách rỗng → ném `ArgumentError`.
  - `double meanDistance(List<Point2> a, List<Point2> b)`, `double maxDistance(List<Point2> a, List<Point2> b)` — hai danh sách cùng độ dài.
  - `class Stroke { final List<Point2> points; }`, `class Glyph { final String id; final String label; final List<Stroke> strokes; }`, `Glyph.fromJson(Map<String, dynamic>)`, `Map<String, dynamic> toJson()`. JSON: `{"id":"b","label":"b","strokes":[{"points":[[0.4,0.1],[0.4,0.95]]}]}`.
  - `enum StrokeError { tooShort, wrongDirection, offPath, wrongOrder }`
  - `class StrokeResult { final bool ok; final StrokeError? error; final double deviation; }`
  - `class GradeConfig { const GradeConfig({this.samples = 32, this.tolerance = 0.12, this.directionRatio = 0.6, this.minLengthRatio = 0.6, this.maxPointDistance = 0.25, this.dotRadius = 0.1, this.dotLength = 0.02}); final int samples; final double tolerance, directionRatio, minLengthRatio, maxPointDistance, dotRadius, dotLength; }`
  - `StrokeResult gradeStroke(Stroke drawn, Stroke reference, [GradeConfig config = const GradeConfig()])`

- [ ] **Step 1: Viết test hình học** — `resample` một đoạn thẳng `(0,0)→(1,0)` với n=5 cho x = 0, 0.25, 0.5, 0.75, 1; `resample` một điểm duy nhất cho 5 điểm trùng; `pathLength` đường gấp khúc `(0,0)→(0,1)→(1,1)` = 2.0; `meanDistance` của hai danh sách trùng = 0. Test JSON: `Glyph.fromJson(g.toJson()) == g` về nội dung (id, label, số nét, điểm).
- [ ] **Step 2: Viết test chấm nét** — tham chiếu nét thẳng đứng `ref = (0.5,0.1)→(0.5,0.9)` lấy 20 điểm:

```dart
test('nét trùng mẫu → ok', () => expect(gradeStroke(ref, ref).ok, isTrue));
test('nét rung ±0.03 (Random(42)) → ok', ...);            // ok == true
test('nét ngược chiều → wrongDirection', ...);             // error == StrokeError.wrongDirection
test('nét dời sang phải 0.3 → offPath', ...);              // error == StrokeError.offPath
test('nửa nét đầu → tooShort', ...);                        // error == StrokeError.tooShort
test('chạm một điểm cho nét dài → tooShort, deviation hữu hạn', ...); // !deviation.isNaN
test('dấu chấm: mẫu 1 điểm (0.5,0.2), chạm (0.55,0.22) → ok; chạm (0.8,0.8) → offPath', ...);
```

- [ ] **Step 3: Chạy, thấy FAIL** — `flutter test test/stroke` → chưa có các hàm.
- [ ] **Step 4: Viết `geometry.dart`, `glyph.dart`, `grader.dart`.** Thuật toán `gradeStroke`, theo đúng thứ tự:
  1. Mẫu là dấu chấm (1 điểm hoặc `pathLength < dotLength`): lấy trọng tâm nét vẽ; cách điểm mẫu ≤ `dotRadius` → ok, ngược lại `offPath`.
  2. `pathLength(drawn) < minLengthRatio * pathLength(ref)` → `tooShort`.
  3. `fwd = meanDistance(resample(drawn), resample(ref))`, `rev = meanDistance(resample(drawn đảo ngược), resample(ref))`.
  4. `rev < fwd * directionRatio && rev <= tolerance` → `wrongDirection`.
  5. `fwd > tolerance` hoặc `maxDistance(...) > maxPointDistance` → `offPath`.
  6. Còn lại → ok. `deviation` luôn là `fwd` (hoặc khoảng cách tới điểm với dấu chấm).
- [ ] **Step 5: Chạy, thấy PASS** — `flutter test test/stroke` → `All tests passed!`
- [ ] **Step 6: Commit** — `git commit -m "feat(stroke): hình học nét và chấm một nét"`

---

### Task 3: Phiên viết một chữ (thứ tự nét)

**Files:**
- Create: `app/lib/stroke/glyph_session.dart`
- Test: `app/test/stroke/glyph_session_test.dart`

**Interfaces:**
- Consumes: `Glyph`, `Stroke`, `gradeStroke`, `GradeConfig`, `StrokeResult`, `StrokeError` (Task 2).
- Produces: `class GlyphSession { GlyphSession(Glyph glyph, {GradeConfig config}); int get currentIndex; bool get isComplete; List<StrokeResult> get history; StrokeResult submit(Stroke drawn); void reset(); }`

- [ ] **Step 1: Viết test** — glyph mẫu "b" trong test: nét 1 thẳng `(0.4,0.1)→(0.4,0.9)`, nét 2 cung tròn tâm `(0.55,0.72)` bán kính `0.15`, đi từ góc 180° qua 270° tới 540° (vẽ bằng 24 điểm).
  - Vẽ đúng nét 1 rồi nét 2 → cả hai ok, `isComplete == true`.
  - Vẽ nét 2 trước → `error == StrokeError.wrongOrder`, `currentIndex == 0`.
  - Vẽ nửa đầu nét 1 rồi nửa sau (bé nhấc tay) → lần đầu `tooShort`, `currentIndex == 0`; không ném lỗi.
  - Nét sai không làm tăng `currentIndex`; `history` ghi mọi lần nộp; `reset()` đưa về 0 và xóa `history`.
  - `submit` khi đã `isComplete` → ném `StateError`.
- [ ] **Step 2: Chạy, thấy FAIL** — `flutter test test/stroke/glyph_session_test.dart`.
- [ ] **Step 3: Viết `GlyphSession`.** `submit`: chấm với nét hiện tại; nếu không ok và nét vẽ chấm ok (hoặc chỉ sai chiều) với một nét **sau** nét hiện tại → trả kết quả `wrongOrder`; nếu ok thì tăng `currentIndex`.
- [ ] **Step 4: Chạy, thấy PASS.**
- [ ] **Step 5: Commit** — `git commit -m "feat(stroke): phiên viết chữ và bắt sai thứ tự nét"`

---

### Task 4: Khung vẽ dùng chung và công cụ ghi nét mẫu

**Files:**
- Create: `app/lib/features/trace/trace_pad.dart`, `app/lib/features/dev/recorder_controller.dart`, `app/lib/features/dev/recorder_screen.dart`
- Modify: `app/lib/router.dart` (thêm `/dev/recorder`, chỉ khi `kDebugMode`)
- Test: `app/test/features/trace_pad_test.dart`, `app/test/features/recorder_test.dart`

**Interfaces:**
- Consumes: `Point2`, `Stroke`, `Glyph` (Task 2).
- Produces:
  - `class TracePad extends StatefulWidget { const TracePad({required void Function(Stroke) onStrokeEnd, List<Stroke> guide = const [], List<Stroke> inked = const [], Key? key}); }` — khung vuông theo cạnh nhỏ của vùng được cấp; chuyển tọa độ màn hình về `[0,1]`, kẹp giá trị ngoài khung; chỉ theo con trỏ chạm đầu tiên, bỏ qua các con trỏ khác đến khi nhấc tay; vẽ `guide` nét đứt màu `#D9C6AA`, `inked` và nét đang vẽ màu `#E8590C` dày 0.06 cạnh khung.
  - `class RecorderController extends Notifier<List<Stroke>>` với `addStroke(Stroke)`, `undo()`, `clear()`, `String exportJson(String id, String label)`; provider `recorderProvider`.
  - `RecorderScreen`: ô nhập id/label, `TracePad`, nút Hoàn tác, Xóa, Xuất (sao chép JSON vào bộ nhớ tạm và `debugPrint`).

- [ ] **Step 1: Viết test TracePad** — bơm `TracePad` trong `SizedBox(300,300)`; kéo từ `(30,30)` tới `(270,30)` → `onStrokeEnd` nhận một `Stroke` có điểm đầu ≈ `(0.1,0.1)` và điểm cuối ≈ `(0.9,0.1)` (sai số 0.01). Cùng thao tác ở khung 600×600 với tọa độ gấp đôi → cùng kết quả. Kéo tới `(400,-50)` → mọi điểm nằm trong `[0,1]`.
- [ ] **Step 2: Viết test Recorder** — `addStroke` hai lần rồi `undo()` → còn 1 nét; `exportJson('b','b')` giải mã được bằng `Glyph.fromJson` với 1 nét.
- [ ] **Step 3: Chạy, thấy FAIL.**
- [ ] **Step 4: Viết `TracePad`, `RecorderController`, `RecorderScreen`, route `/dev/recorder`.** TracePad dùng `Listener` (pointer down/move/up), lưu `int? _activePointer`.
- [ ] **Step 5: Chạy, thấy PASS.**
- [ ] **Step 6: Commit** — `git commit -m "feat(dev): khung vẽ và công cụ ghi nét mẫu"`

---

### Task 5: Màn tô thử và ghi nhật ký chấm nét

**Files:**
- Create: `app/lib/stroke/glyph_repository.dart`, `app/lib/data/app_database.dart`, `app/lib/features/trace/trace_screen.dart`, `app/assets/glyphs/net-thang-dung.json`, `app/assets/glyphs/net-ngang.json`
- Modify: `app/pubspec.yaml` (khai báo `assets/glyphs/`), `app/lib/router.dart` (thêm `/trace/:glyphId`; màn `/` liệt kê các glyph để chọn)
- Test: `app/test/features/trace_screen_test.dart`, `app/test/data/app_database_test.dart`

**Interfaces:**
- Consumes: `TracePad` (Task 4), `GlyphSession` (Task 3), `Glyph.fromJson` (Task 2).
- Produces:
  - `class GlyphRepository { Future<List<String>> listIds(); Future<Glyph> load(String id); }` đọc `AssetManifest` lấy các file `assets/glyphs/*.json`; provider `glyphRepositoryProvider`.
  - drift `AppDatabase` (schemaVersion 1) với bảng `StrokeAttempts(id autoIncrement, glyphId text, strokeIndex int, ok bool, error text nullable, deviation real, createdAt dateTime)`; `Future<void> logAttempt(...)`, `Future<({int total, int ok})> summary(String glyphId)`; provider `databaseProvider`.
  - `TraceScreen(glyphId)`: TracePad với `guide` là các nét mẫu, mỗi lần nhấc tay gọi `GlyphSession.submit` và `logAttempt`; đúng → nét được giữ lại màu cam và hiện "Đúng rồi!"; sai → nét biến mất, hiện thông báo theo lỗi: `tooShort` "Vẽ dài thêm chút nữa nhé", `wrongDirection` "Bé vẽ ngược chiều rồi", `offPath` "Đi theo đường chấm nhé", `wrongOrder` "Nét này vẽ sau nhé"; xong chữ → "Giỏi quá!" và nút Làm lại.
  - Hai file glyph viết tay: thẳng đứng `(0.5,0.1)→(0.5,0.9)`, ngang `(0.1,0.5)→(0.9,0.5)`, mỗi nét 11 điểm.

- [ ] **Step 1: Viết test DB** — dùng `AppDatabase(NativeDatabase.memory())`; ghi 3 lần (2 ok) cho `net-ngang` → `summary` trả `(total: 3, ok: 2)`.
- [ ] **Step 2: Viết test màn** — bơm `TraceScreen('net-ngang')` (ghi đè `databaseProvider` bằng DB bộ nhớ, `glyphRepositoryProvider` bằng repo trả glyph cố định); kéo theo nét mẫu → thấy "Giỏi quá!"; kéo ngược chiều → thấy "Bé vẽ ngược chiều rồi". Thêm: chạm ngón thứ hai trong khi ngón đầu đang kéo → chỉ một nét được nộp (đếm `summary.total` tăng 1).
- [ ] **Step 3: Chạy, thấy FAIL.**
- [ ] **Step 4: Viết code, chạy `dart run build_runner build --delete-conflicting-outputs`.**
- [ ] **Step 5: Chạy, thấy PASS** — `flutter test` toàn bộ.
- [ ] **Step 6: Commit** — `git commit -m "feat(trace): màn tô thử, nhật ký chấm nét"`

---

### Task 6: Ghi nét mẫu và thử với bé thật (người làm: chủ dự án)

**Files:**
- Create: `docs/phase0/stroke-test.md`, `app/assets/glyphs/{net-xien,net-cong,net-moc,so-0,so-1,so-2,so-3,chu-a,chu-b}.json`

Việc này cần người thật; người thực thi kế hoạch chuẩn bị tài liệu và bản build, chủ dự án ghi nét và chạy buổi thử.

- [ ] **Step 1: Viết `docs/phase0/stroke-test.md`** gồm: cách cài bản debug lên điện thoại và máy tính bảng; cách ghi nét mẫu bằng `/dev/recorder` (viết theo mẫu chữ tiểu học, đúng thứ tự và hướng, dùng bút cảm ứng nếu có); kịch bản buổi thử (mỗi bé tô 5 nét cơ bản, số 0–3, chữ a, b; người lớn ghi lại từng nét bé vẽ "đúng/sai theo mắt người"); bảng kết quả với cột: glyph, số nét, app chấm đúng, app chấm sai, người lớn thấy đúng nhưng app chấm sai; tiêu chí đạt của spec: nét hơi xấu nhưng đúng được chấp nhận, sai thứ tự hoặc chiều bị bắt, tỷ lệ chấm sai một nét đúng dưới khoảng 1/10.
- [ ] **Step 2: Chủ dự án ghi 9 file glyph** bằng công cụ và commit vào `app/assets/glyphs/`.
- [ ] **Step 3: Kiểm tra mỗi glyph tự chấm chính nó đạt** — thêm test `test/stroke/assets_self_grade_test.dart`: với mọi file trong `assets/glyphs/`, nộp đúng các nét mẫu theo thứ tự → `isComplete == true`. Chạy `flutter test` → PASS.
- [ ] **Step 4: Chạy buổi thử với bé**, điền bảng kết quả vào `stroke-test.md`. Nếu không đạt: chỉnh `GradeConfig` (chỉ các ngưỡng), thêm test tái hiện nét bé bị chấm sai, chạy lại toàn bộ test.
- [ ] **Step 5: Commit** — `git commit -m "test(stroke): nét mẫu và kết quả thử với bé"`

---

### Task 7: Bộ giao diện chung

**Files:**
- Create: `app/lib/ui/theme/tokens.dart`, `app/lib/ui/theme/contrast.dart`, `app/lib/ui/theme/app_theme.dart`, `app/lib/ui/widgets/{app_card,info_pill,primary_button,progress_ring,floating_nav_bar}.dart`, `app/lib/features/dev/gallery_screen.dart`, `app/assets/fonts/Nunito-{Regular,SemiBold,Bold,ExtraBold,Black}.ttf`
- Modify: `app/pubspec.yaml` (font Nunito trọng lượng 400/600/700/800/900), `app/lib/app.dart` (dùng `buildAppTheme()`), `app/lib/router.dart` (`/dev/gallery`)
- Test: `app/test/ui/contrast_test.dart`, `app/test/ui/widgets_test.dart`

**Interfaces:**
- Produces:
  - `abstract final class AppColors` với hằng `primary, accent, background, dot, card, text, textMuted` và `enum Subject { viet, tiengViet, toan, tiengAnh }` kèm `Color Subject.color`, `Color Subject.tint` (giá trị trong Global Constraints).
  - `abstract final class AppRadii { static const card = 28.0; static const tile = 18.0; static const pill = 999.0; }`; `AppShadows.card` = `BoxShadow(color: Color(0x1F503C28), blurRadius: 32, offset: Offset(0, 14))`.
  - `double contrastRatio(Color a, Color b)` theo công thức WCAG 2.x.
  - `ThemeData buildAppTheme()` — `fontFamily: 'Nunito'`, `scaffoldBackgroundColor: AppColors.background`.
  - `AppCard({required Widget child, EdgeInsets padding})`; `InfoPill({required Widget leading, required String label})`; `PrimaryButton({required String label, required VoidCallback? onPressed})` cao 64, nền `primary`, chữ trắng 900; `ProgressRing({required int done, required int total, required Color color, double size = 40})` hiện `done/total`; `FloatingNavBar({required List<NavItem> items, required int selected, required ValueChanged<int> onSelect})`, `class NavItem { final IconData icon; final String label; }`.
  - `GalleryScreen` bày mọi linh kiện trên nền kem chấm bi, theo bố cục trang chính bản phác thảo thứ 2.

- [ ] **Step 1: Tải font** — từ trang Google Fonts gia đình Nunito (giấy phép OFL), lấy các file tĩnh `Nunito-Regular/SemiBold/Bold/ExtraBold/Black.ttf` vào `assets/fonts/`; thêm `OFL.txt` cạnh font.
- [ ] **Step 2: Viết test tương phản**

```dart
expect(contrastRatio(Colors.white, AppColors.primary), greaterThanOrEqualTo(4.5));
expect(contrastRatio(AppColors.text, AppColors.background), greaterThanOrEqualTo(4.5));
expect(contrastRatio(AppColors.textMuted, AppColors.card), greaterThanOrEqualTo(4.5));
expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
```

- [ ] **Step 3: Viết test linh kiện** — `PrimaryButton` có chiều cao ≥ 64; `onPressed: null` thì nhấn không gọi gì; `ProgressRing(done: 6, total: 14, ...)` hiện chữ `6/14`, `total: 0` không lỗi và hiện `0/0`; `FloatingNavBar` nhấn mục thứ 2 gọi `onSelect(1)`; `GalleryScreen` dựng được không lỗi tràn (bọc trong `MediaQuery` 390×844).
- [ ] **Step 4: Chạy, thấy FAIL.**
- [ ] **Step 5: Viết token, theme, linh kiện, GalleryScreen; dùng `buildAppTheme()` trong `App`.**
- [ ] **Step 6: Chạy, thấy PASS** — `flutter test` toàn bộ, `flutter analyze` sạch.
- [ ] **Step 7: Commit** — `git commit -m "feat(ui): bộ giao diện chung theo bảng màu cam"`

---

### Task 8: Script làm hình

**Files:**
- Create: `tools/assets/cut_sheet.py`, `tools/assets/test_cut_sheet.py`, `tools/assets/requirements.txt` (`Pillow`, `numpy`, `pytest`), `docs/phase0/asset-list.md`

**Interfaces:**
- Produces: CLI `python3 tools/assets/cut_sheet.py <ảnh> <cấu hình.json> <thư mục ra>`; cấu hình `{"items":[{"name":"chip-joy","box":[0,40,341,415]}], "export_widths":[120,240,360]}`; mỗi mục ra `<name>.png` (rộng `export_widths[0]`), `2.0x/<name>.png`, `3.0x/<name>.png` đúng quy ước ảnh theo mật độ của Flutter. Hàm thư viện `cutout(img: Image, box: tuple, thr: int = 238) -> Image` (RGBA, đã cắt sát).

- [ ] **Step 1: Viết test** với ảnh tổng hợp 200×200 nền trắng, một hình vuông đỏ 60×60 ở giữa và một vệt xám nhạt `(230,230,230)` dưới hình vuông:
  - góc ảnh ra có alpha 0; tâm hình vuông alpha 255;
  - ảnh ra được cắt sát (rộng trong khoảng 60–70 px);
  - vệt xám thành bóng mờ: alpha trong khoảng 1–150, màu tối `(90,70,56)`;
  - pixel trắng nằm **trong** hình (ô trắng 10×10 giữa hình vuông đỏ, không nối với viền) vẫn alpha 255;
  - CLI tạo đủ `name.png`, `2.0x/name.png`, `3.0x/name.png` với chiều rộng 120/240/360.
- [ ] **Step 2: Chạy, thấy FAIL** — `cd tools/assets && python3 -m pytest -q`.
- [ ] **Step 3: Viết `cut_sheet.py`.** Tách nền bằng tô loang (`ImageDraw.floodfill`, `thresh=22`) từ các điểm dọc 4 cạnh có độ sáng ≥ `thr` trên bản sao RGB, rồi làm mờ alpha bán kính 1.2. Chuyển bóng: pixel ở 30% dưới cùng, độ bão hòa < 14 và độ sáng > 185 → màu `(90,70,56)`, alpha `min(150, (255 - độ sáng) * 3.2)`. Cách này đã thử thành công trên ảnh Gemini của Chíp Chíp.
- [ ] **Step 4: Chạy, thấy PASS.**
- [ ] **Step 5: Viết `docs/phase0/asset-list.md`** — danh sách ảnh độ phân giải cao cần cho giai đoạn 1, mỗi ảnh tạo riêng (không dùng bảng lưới): Chíp Chíp chính và 6 biểu cảm (tư thế "đang viết" làm lại: cầm bút tự nhiên, có nét vẽ trên đất, ≥ 800 px), biểu tượng 4 môn, sao, lửa, vương miện (bỏ dấu ✦ trên vành), cảnh đầu trang tỷ lệ dọc ≥ 1170 px ngang, khoảng 30 sticker. Kèm đoạn mô tả phong cách cố định ở mục 8.4 của spec và lưu ý: luôn gửi kèm ảnh mẫu gốc, bật chế độ tạo ảnh (không để Gemini trả về code SVG), cắt bỏ dấu ✦ của Gemini.
- [ ] **Step 6: Commit** — `git commit -m "feat(tools): script cắt và tách nền ảnh Gemini"`

---

### Task 9: Dọn dẹp

**Files:**
- Modify: `app/README.md`
- Delete: mã app cũ ở gốc nhánh `chipchip` — `lib/`, `test/`, `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`, `assets/`, `library/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `devtools_options.yaml`, `CNAME`. Giữ `docs/`, `README.md` (viết lại ngắn), `app/`, `tools/`.

- [ ] **Step 1: Chủ dự án thu hồi khóa OpenAI cũ** trên trang OpenAI (khóa nằm trong lịch sử git ở `lib/feature/game_feature/game/sweep/game/data/envied/env.g.dart` và `lib/helper/global.dart`). Người thực thi chỉ ghi lại trong `app/README.md` là việc này đã xong hay chưa.
- [ ] **Step 2: Kiểm tra mã gói** — `git grep -n "com.example\|vn.chipchip" -- app` không có kết quả; applicationId và bundle id là `com.ibme.funedu`. Ghi vào `app/README.md`.
- [ ] **Step 3: Xóa mã app cũ ở gốc** theo danh sách trên; viết lại `README.md` gốc: dự án mới ở `app/`, spec và kế hoạch ở `docs/superpowers/`, mã cũ tra trong lịch sử git (nhánh `new-web`, `develop`).
- [ ] **Step 4: Kiểm tra** — `cd app && flutter analyze && flutter test` → không lỗi, mọi test PASS; `cd ../tools/assets && python3 -m pytest -q` → PASS; `git grep -n "sk-" -- app tools` → không có kết quả.
- [ ] **Step 5: Commit** — `git commit -m "chore: chốt mã gói, bỏ mã app cũ khỏi nhánh chipchip"`

---

## Xong giai đoạn 0 khi

- Mọi test trong `app/` và `tools/assets/` đều PASS, `flutter analyze` sạch.
- `docs/phase0/stroke-test.md` có kết quả buổi thử với bé **đạt** tiêu chí của spec.
- Khóa OpenAI cũ đã thu hồi.
- Bộ ảnh độ phân giải cao theo `docs/phase0/asset-list.md` đã tạo và cắt bằng script (có thể làm song song, là điều kiện để bắt đầu giai đoạn 1).
