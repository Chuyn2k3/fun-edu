# Chíp Chíp — Tình trạng dự án và hướng dẫn tiếp nhận

> **Đọc file này trước tiên** nếu bạn (người hoặc AI) mới tiếp nhận dự án. Nó tóm tắt: app là gì, vì sao làm như vậy, giao diện trông ra sao, code tổ chức thế nào, đã làm tới đâu, còn gì dở, và làm gì tiếp.
> Cập nhật lần cuối: 2026-11-13, sau khi xong giai đoạn 1D (chờ chủ dự án thử trên máy thật). Nhánh làm việc: `chipchip`.
> Khi xong một phần việc, **cập nhật mục 6 (Đã làm), 7 (Còn dở) và 8 (Làm gì tiếp)** của file này.

---

## 1. App là gì

**ChipChip** — tên trên kho `ChipChip: Bé Tập Viết, Học Chữ`, nhà phát triển FunEdu (mã gói `com.ibme.funedu`, Dart package `funedu`; nội dung trang kho: `docs/store-listing.md`). Đây là app học cho bé **3–6 tuổi**, thay thế hoàn toàn app "Fun Edu" cũ. Linh vật trong app vẫn gọi "Chíp Chíp" (có dấu, để giọng đọc đọc đúng).

- **Điểm khác biệt chính: tập viết bằng ngón tay, app chấm từng nét** (đúng thứ tự, đúng chiều, không lệch đường mẫu). Các app cùng loại (ví dụ StarJar Quiz) chủ yếu chỉ "nhìn câu hỏi, chạm đáp án".
- **Theo trình độ, không theo tuổi.** Mỗi môn là một thang cấp; bài thử xếp cấp lúc đầu; app tự lên/lùi cấp.
- **4 môn lõi:** Viết, Tiếng Việt, Toán, Tiếng Anh. Sau này thêm Sinh học, Địa lý, Lịch sử.
- **Vòng giữ chân:** bé mở app → "Bài hôm nay" (~10 phút) → nhận sao → linh vật Chíp Chíp, sticker → ba mẹ thấy tiến bộ, đổi sao lấy phần thưởng thật → hôm sau học tiếp.
- **Không quảng cáo, không SDK theo dõi, không thu thông tin cá nhân của bé** (chỉ tên gọi ở nhà, ảnh đại diện có sẵn, tuổi; lưu trên máy). Không cơ chế gây áp lực (không mất chuỗi ngày, không trừ sao).
- **Thu tiền (giai đoạn 2):** gói năm (có thể thêm gói tháng) mở toàn bộ cấp; bản miễn phí học được vài cấp đầu mỗi môn. Giới hạn giờ là tính năng miễn phí cho ba mẹ, không dùng để thu tiền.

Nguồn đầy đủ: **spec** `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` (đã được chủ dự án duyệt). Khi file này và spec mâu thuẫn về *ý tưởng sản phẩm*, spec thắng; về *tình trạng code*, file này và git thắng.

## 2. Phong cách giao diện (đã chốt)

- **Phong cách lai:** khung giao diện phẳng (thẻ trắng, nút, nhãn) + **nhân vật/biểu tượng 3D mềm kiểu đồ chơi** (ảnh do Gemini sinh, cắt nền bằng script).
- **Màu (chỉ dùng qua `lib/ui/theme/tokens.dart`, không viết mã màu trong màn hình):**
  - Chính `AppColors.primary` `#C8460F` (nút chính, chữ trắng đạt 4.5:1); nhấn `accent` `#E8590C`.
  - Nền kem `background` `#FBF5EC` có chấm bi `dot` `#EADFCF`; thẻ trắng `card`; chữ navy `text` `#22284A`, chữ phụ `textMuted` `#5B6385`.
  - Màu môn (enum `Subject`): Viết cam, Tiếng Việt tím, Toán xanh dương, Tiếng Anh xanh lá — mỗi môn có `color` và `tint`.
- **Font Nunito** (đóng kèm trong `assets/fonts/`), tiêu đề đậm 800–900.
- **Thẻ nổi (candy)** = `raisedDecoration(accent:, tint:)` trong `lib/ui/theme/depth.dart` (nền chuyển màu, gờ màu dày 5px ở đáy, bóng có màu). Thẻ bé bấm được bọc `Pressable` để lún xuống khi chạm; góc ba mẹ giữ `InkWell`. Thẻ vẫn là MỘT `BoxDecoration` có cả nền và bóng. **Không** để một Container chỉ có bóng (không màu) phủ lên `Material` trắng — sẽ ra màu xám (lỗi đã gặp nhiều lần). Nút trắng: `Material(transparency) > Ink(decoration có màu) > InkWell`.
- **Màn chào + khóa dọc:** `lib/features/splash/splash_view.dart` (nền kem, logo thở, nạp sẵn ảnh trong lúc chờ); ảnh khởi động native Android/iOS cùng nền kem. Điện thoại khóa dọc; iPad xoay tự do.
- **Nút cho bé ≥ 64 pt**, góc ba mẹ ≥ 48. Chữ đạt tương phản ≥ 4.5:1 (có `contrastRatio` và test).
- **Icon app:** minh họa phẳng nét sáp màu (chim sẻ cầm bút sáp trên nền vàng), nguồn `docs/superpowers/specs/assets/generated/app-icon-source.webp`, tạo lại bằng `python3 tools/assets/make_app_icons.py`. Đã bỏ kiểu 3D bóng cho icon vì trông "giả AI"; ảnh 3D trong app vẫn giữ (có thể đổi sang phong cách phẳng sau).
- **Linh vật Chíp Chíp:** chim sẻ con nâu kem, khăn quàng cam, cầm bút sáp cam. 7 tư thế: chính, vui, giơ ngón cái, ngạc nhiên, động viên, ngủ (mũ ngủ), đang viết. Ảnh nguồn đã duyệt: `docs/superpowers/specs/assets/generated/` (bản độ phân giải cao) và `docs/superpowers/specs/assets/` (bản mẫu ban đầu).
- Ảnh trong app chỉ truy cập qua `lib/ui/assets.dart` (`AppImages`). Tạo lại ảnh: `bash tools/assets/build_app_images.sh` (cấu hình ở `tools/assets/configs/hd/`). Danh sách ảnh cần làm và mẹo dùng Gemini: `docs/phase0/asset-list.md`.

## 3. Công nghệ và quy ước bắt buộc

- **Flutter 3.24.5 / Dart 3.5** (chạy được với Flutter ≥ 3.24). `environment.sdk: '>=3.5.0 <4.0.0'`.
  - Dùng `import 'package:flutter/material.dart'` (không dùng gói `material_ui`), `Color.withOpacity` (không `withValues`).
- Gói (không tự đổi phiên bản): `flutter_riverpod` 2.6 (API 2.x), `go_router` 15, `drift` 2.23 + `drift_flutter` **0.2.4 ghim cứng** (bản mới hơn đòi drift mới hơn), `path_provider`, `flutter_tts` 4.2.5. Dev: `drift_dev`, `build_runner`, `flutter_lints`.
- **Một thư viện trạng thái duy nhất: Riverpod.** Không thêm Provider/Bloc/GetX.
- **Không gọi mạng** trong app hiện tại (thống kê ẩn danh đã được chủ dự án hoãn lại).
- Sửa bảng drift → chạy `dart run build_runner build --delete-conflicting-outputs` và **commit file `.g.dart`**. Đổi schema → tăng `schemaVersion` và thêm bước migration; giữ mọi đường nâng cấp cũ (có test trong `test/data/migration_test.dart`).
- Chuỗi hiển thị cho bé/ba mẹ bằng **tiếng Việt**; chú thích code bằng tiếng Anh.
- **iPad/máy tính bảng:** `context.formFactor` (`lib/ui/layout/form_factor.dart`): tablet = cạnh ngắn cửa sổ ≥ 600. Không phóng to bố cục điện thoại; chỉ trang chủ và Góc ba mẹ có bố cục tablet ở file anh em (`home_tablet.dart`, `parent_home_tablet.dart`), các màn khác rẽ nhánh tablet ngay trong cùng file. Nút bé ≥ 80 trên tablet (`TabletSizes.kidTarget`), chữ ×1.2 (`TabletTextScale`), thanh điều hướng dọc `NavRail`, thẻ thông báo giữa màn `MessageCard`.
- **Hiệu năng:** chỉ kết luận bằng `flutter run --profile` trên máy thật (xem `docs/perf.md`). Chụp màn hình để rà bố cục: `tools/shot/home_shot_test.dart` (cách chạy trong `docs/perf.md`).
- Lệnh kiểm tra (phải sạch trước khi commit):
  ```
  flutter pub get
  flutter analyze
  flutter test
  cd tools/assets && python3 -m pytest -q
  ```
- Cách làm việc đã dùng: mỗi giai đoạn có **kế hoạch** trong `docs/superpowers/plans/`, làm theo từng task, viết test trước (TDD), mỗi task được rà soát; cuối giai đoạn rà soát toàn nhánh.

## 4. Kiến trúc và bản đồ code

```
lib/
  main.dart, app.dart          # App: MaterialApp.router; chuyển hướng (chưa có bé → /setup,
                               #   bé chưa xếp cấp → /placement); gắn ScreenTimeGuard; nút back riêng
  router.dart                  # appRouter (go_router) — danh sách route ở dưới
  router_location.dart         # theo dõi vị trí route kể cả khi pop (go_router 15 không báo khi pop)
  data/app_database.dart       # drift, schemaVersion 6, migration từ 1→6
  stroke/                      # BỘ CHẤM NÉT (Dart thuần): geometry, glyph (JSON), grader, glyph_session (thứ tự nét)
  features/trace/trace_pad.dart# khung vẽ ngón tay (chuẩn hóa [0,1], 1 ngón, kiểu sáp màu)
  features/writing/            # màn tập viết (ô li, Chíp phản ứng, Xem mẫu, Nghe, Xóa)
  math/                        # Toán (Dart thuần): 9 cấp, sinh câu hỏi, luật lên/lùi cấp
  features/math/               # màn làm Toán + dạng bài (chạm đếm, chọn, so sánh, kéo số)
  learning/                    # thang chữ Viết, soạn "Bài hôm nay" (Viết mới + Toán + Viết ôn)
  features/lesson/             # luồng bài học, màn "Xong bài hôm nay!"
  features/subject/            # bản đồ môn Viết và Toán
  features/placement/          # bài thử xếp cấp lần đầu
  features/setup/              # lần đầu mở app: cổng → đồng ý → tạo hồ sơ bé
  features/home/               # trang chủ, đổi bé
  profile/                     # hồ sơ bé (tối đa 4), cài đặt app (AppSettings), làm mới provider khi đổi bé
  progress/                    # tiến độ chữ, sao, ngày học, cấp từng môn — TẤT CẢ theo kidId
  screen_time/                 # giới hạn giờ, giờ ngủ, guard hiện màn "Chíp Chíp đi ngủ"
  features/sleep/              # màn đi ngủ
  parent/                      # cổng người lớn (phép nhân viết bằng chữ), góc ba mẹ (5 tab), chính sách
  rewards/                     # phần thưởng thật do ba mẹ đặt
  voice/                       # Speaker (giọng máy qua flutter_tts), số → chữ tiếng Việt
  ui/                          # tokens, theme (depth.dart: thẻ nổi), AppImages, layout/ (form_factor: tablet), widgets (Pressable, NavRail, MessageCard)
  features/splash/             # SplashView (màn chào)
  features/dev/                # công cụ cho người phát triển (chỉ bản debug)
tools/shot/                    # harness chụp màn hình (không thuộc test/), xem docs/perf.md
tools/assets/                  # cắt + tách nền ảnh Gemini (Python, có test)
tools/glyphs/make_glyphs.py    # sinh nét mẫu TẠM cho nét cơ bản và số 0–9
assets/glyphs/*.json           # nét mẫu (toạ độ [0,1], y hướng xuống)
```

**Route:** `/` trang chủ · `/lesson` · `/lesson/done` · `/subject/viet` · `/subject/toan` · `/practice/:glyphId` · `/practice-math/:levelIndex` · `/placement` · `/setup` · `/parent` (sau cổng) · `/trace/:glyphId` · debug: `/dev/glyphs`, `/dev/recorder` (ghi nét mẫu), `/dev/gallery` (xem linh kiện giao diện). Mở trực tiếp: `flutter run --route=/dev/recorder`.

**Dữ liệu (drift, mọi bảng tiến độ có `kid_id`):** `kid_profiles`, `app_settings` (key/value), `stroke_attempts` (mỗi nét chấm, kèm toạ độ), `glyph_progress`, `lesson_completions` (sao), `subject_levels`, `daily_usage`, `real_rewards`. Khoá cài đặt: `voiceEnabled`, `consentAt`, `currentKidId`, `dailyLimitMinutes.{kidId}` (mặc định 45), `bedtimeStart.{kidId}`/`bedtimeEnd.{kidId}` (`HH:mm`), `extraMinutes.{kidId}.{yyyy-MM-dd}`.

**Luật quan trọng đã chốt:**
- Thuộc một chữ = viết xong với ≤ 1 nét sai. Sao: mỗi mục trong bài +1, xong bài +2. Đổi phần thưởng thật **không trừ sao**.
- Toán lên cấp khi đúng ngay lần đầu ≥ 4/5, lùi khi ≤ 2/5; phiên rỗng giữ nguyên. Bé chọn sai được chọn lại.
- Hết giờ: bé làm xong màn đang dở, màn ngủ hiện ở lần chuyển màn kế; thời gian ở góc ba mẹ/`/setup`/`/dev` không tính.

## 5. Tài liệu trong repo

| File | Nội dung |
|---|---|
| `docs/PROJECT_STATE.md` | File này — điểm bắt đầu |
| `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` | Spec sản phẩm đầy đủ (mục tiêu, chức năng, thu tiền, nội dung, lộ trình 0–5, an toàn trẻ em) |
| `docs/superpowers/plans/2026-11-12-giai-doan-0-nen-mong.md` | Kế hoạch giai đoạn 0 (đã xong) |
| `docs/superpowers/plans/2026-11-12-giai-doan-1a-giao-dien-be.md` | Kế hoạch 1A (đã xong) |
| `docs/superpowers/plans/2026-11-12-giai-doan-1b-toan-xep-cap.md` | Kế hoạch 1B (đã xong) |
| `docs/superpowers/plans/2026-11-13-giai-doan-1c-goc-ba-me.md` | Kế hoạch 1C (đã xong) |
| `docs/superpowers/plans/2026-11-13-giai-doan-1d-muot-va-ipad.md` | Kế hoạch 1D (đã xong, chờ thử máy thật) |
| `docs/perf.md` | Cách đo hiệu năng (profile), điểm nóng đã xử lý, cách chụp màn hình |
| `docs/phase0/stroke-test.md` | Cách ghi nét mẫu và thử bộ chấm nét với bé thật |
| `docs/phase0/asset-list.md` | Danh sách ảnh cần làm, mẹo dùng Gemini |
| `docs/superpowers/specs/assets/generated-assets-gallery.md` | Bộ ảnh 3D độ phân giải cao đã tạo |

## 6. Đã làm (tới 2026-11-13)

| Giai đoạn | Nội dung | Trạng thái |
|---|---|---|
| 0 | Dự án Flutter mới thay app cũ (ở gốc repo), bộ chấm nét + test, khung vẽ, công cụ ghi nét, màn tô thử có nhật ký, bộ giao diện chung, script ảnh, dọn mã cũ | Xong |
| 1A | Ảnh 3D, nét mẫu tạm (nét cơ bản + số 0–9), lưu sao/ngày học, "Bài hôm nay", trang chủ, màn tập viết, màn xong bài, bản đồ Viết | Xong |
| 1B | Toán 9 cấp, 3 dạng bài, màn Toán, bài xếp cấp lần đầu, bản đồ Toán, bài hôm nay gồm Viết + Toán | Xong |
| 1C | Giọng đọc (giọng máy), nhiều hồ sơ bé, cổng người lớn, lần đầu mở app có đồng ý, giới hạn giờ + giờ ngủ, góc ba mẹ 5 tab, phần thưởng thật, xóa toàn bộ dữ liệu, chính sách quyền riêng tư | Xong |
| 1D | Task 1: tách lớp vẽ nền chấm và nét gợi ý. Task 2: thẻ nổi `raisedDecoration` + `Pressable`, bỏ `AppShadows.card`. Task 3: màn chào `SplashView` (nền kem, logo thở), ảnh khởi động native Android/iOS, khóa dọc trên điện thoại. Task 5: bố cục iPad cho trang chủ (thẻ bài hôm nay + `WeekPanel` "Tuần này"), màn tập viết (khung tô vuông, cột Chíp + nút) và màn Toán (đáp án cột phải khi ngang); chữ trên iPad ×1.2 (`TabletTextScale`); xoay máy giữa nét thì bỏ nét đang vẽ. Task 6: bản đồ Viết trên iPad dạng lưới 5 cột (ngang) / 4 cột (dọc), bản đồ Toán là lưới 3×3 ở cả hai chiều (ô cao theo màn, không cuộn); Góc ba mẹ iPad dạng danh sách-chi tiết (trái 300: chip bé + 5 mục, phải ≤ 720); màn thông báo (xong bài, ngủ, chào/xong placement, lần đầu) là một thẻ nổi giữa màn ≤ 640 (`MessageCard`), Chíp ×1.4; cổng ba mẹ dùng `AppCard` (không phải `MessageCard`). Đợt sửa sau rà soát cuối: bố cục iPad chịu được chữ hệ thống lớn (`ScaleDownToFit`, `_fits` tính theo cỡ chữ), nhãn đang chọn trên `NavRail` đủ tương phản, khóa dọc chỉ quyết khi đã biết kích thước cửa sổ (`PortraitLock`), logo khởi động iOS 160pt khớp màn chào, nạp sẵn logo trước, `Pressable` là một nút (tắt khi không bấm được), màn xong bài/placement có chữ ×1.2 trên iPad, nhãn "Đang học" dùng `AppColors.primaryOnTint` | Xong (chờ thử máy thật) |
| 2A | Viết chữ cái thường + dấu thanh (đang làm). Task 1: 29 chữ + 5 dấu tạm `chu-*`/`dau-*` trên khung 12 ô li. Task 2: `GlyphRuling`, `Glyph.inWindow()`, `context`, `speech`. Task 3: màn tập viết (điện thoại + iPad) và màn tô thử dùng nét đã quy về vùng chữ (`inWindow`), giấy ô li `RuledPaper(ruling:)` (đường chân chữ và đường đầu chữ thường đậm hơn), dấu thanh tô trên chữ "a" mờ (`FaintLetter`, không chấm), nét chấm (chấm chữ i, dấu nặng) có chấm gợi ý và nhấp nháy khi "Xem mẫu", Chíp đọc tên chữ theo `spokenName` ("Mình viết chữ bờ nhé!") còn tiêu đề giữ nhãn | Đang làm |
| Ảnh | Thay 13 ảnh độ phân giải cao | Xong (trừ ngọn lửa) |

Trạng thái kiểm tra cuối: `flutter analyze` sạch, **553 test đạt** trên Flutter 3.24.5. **Chưa** có lần build/chạy kiểm chứng trên máy thật bởi AI; hiệu năng 1D chưa đo bằng `--profile` trên iPhone/iPad (chủ dự án đã chạy thử iPhone ở giai đoạn 0).

## 7. Còn dở / việc của chủ dự án / điểm biết là chưa hoàn hảo

**Việc của chủ dự án (chưa xác nhận xong):**
- Thu hồi khóa OpenAI cũ (nằm trong lịch sử git của app cũ).
- Điền `[EMAIL LIÊN HỆ]` trong `lib/parent/screens/privacy_screen.dart`.
- Ghi lại nét mẫu thật bằng `/dev/recorder` (hiện nét cơ bản và số 0–9 là **dữ liệu tạm máy sinh**) và thử với bé theo `docs/phase0/stroke-test.md`.
- Tạo ảnh ngọn lửa độ phân giải cao (`ic-flame` vẫn là ảnh cũ).

**Điểm biết là chưa hoàn hảo (nhỏ, có thể sửa sau):**
- iPhone màn nhỏ 375×667: thẻ Toán trên trang chủ bị thanh điều hướng che một phần cho tới khi cuộn.
- Hết giờ đúng lúc chuyển màn: màn mới có thể hiện thoáng qua trước khi màn ngủ phủ lên. Nếu kiểm tra giờ bị lỗi DB thì mặc định cho chơi (fail open).
- Tiến độ Viết trên trang chủ chưa tính các chữ được bỏ qua nhờ xếp cấp.
- Bé bị lùi cấp Toán thì ô trên bản đồ khóa lại (không thông báo, nhưng bé thấy).
- Giọng đọc: chuyển hẳn sang route khác có thể cắt câu đầu của màn mới (hiện chưa xảy ra vì các màn nói đều đổi tại chỗ); "Đúng rồi!" có thể bị câu hỏi kế cắt ngang.
- `CNAME` (tên miền web `hocvui.ibme.edu.vn`) đã bị xóa trên nhánh `chipchip` — **không gộp `chipchip` vào `new-web` hay nhánh GitHub Pages** khi chưa khôi phục.
- iPad: còn khoảng trống dưới câu hỏi Toán ngắn; màn viết dọc còn khoảng trống dưới hàng nút.
- Điện thoại: thẻ bài hôm nay trên trang chủ có thể bị cắt khi cỡ chữ hệ thống lớn nhất.
- Android 12+: chưa có theme màn chào cho chế độ tối (`values-night-v31`).
- iPad ngang: trang chủ vẫn giả định thanh trên ~120pt; ngân sách `_fits` nhân theo cỡ chữ hệ thống nên chữ lớn sẽ chuyển sang bố cục cuộn, các khối có chiều cao cố định (thẻ bài hôm nay, `WeekPanel`, thẻ môn, ô bản đồ Toán) thu nhỏ nội dung thay vì tràn. Ở cỡ chữ hệ thống 2.0 trên iPad ngang nhỏ, thẻ môn dạng gọn vẫn tràn ngang vài chục điểm (thẻ dùng chung với điện thoại, chưa sửa).
- Màn Toán: xoay iPad giữa bài thì các lần chạm/kéo đang dở của câu hiện tại bị đặt lại (điểm vẫn giữ).
- Màn "lần đầu" (cổng, đồng ý, hồ sơ) là cho ba mẹ nên không phóng chữ ×1.2 trên iPad, giống Góc ba mẹ.
- Góc ba mẹ: hàng tab không có hiệu ứng chạm (ripple).
- 2A: câu Chíp đọc chèn nguyên `speech` nên dấu thanh nghe/hiện "Mình viết Dấu hỏi nhé!" (chữ D hoa giữa câu) — sửa dữ liệu `speech` của `dau-*` hoặc viết thường khi chèn.
- Nút "Chơi", "Sưu tập", "Nhà Chíp" trên trang chủ và môn Tiếng Việt, Tiếng Anh còn hiện "Sắp có".

## 8. Làm gì tiếp (theo spec, mục 10)

1. **Chủ dự án thử 1D trên iPhone và iPad thật** (bản profile/release: `flutter run --profile`), đo độ mượt, xem bố cục iPad dọc + ngang; gom lỗi/ý kiến → sửa trước.
2. **Chạy thử cả bản 1C trên máy thật**, gom lỗi/ý kiến cùng đợt.
3. **Giai đoạn 2 — bắt đầu thu tiền** (cần spec + kế hoạch riêng trước khi code):
   - Backend **Java Spring Boot + PostgreSQL** trên máy chủ Oracle (24 GB RAM, 100 GB SSD) — tài khoản gia đình, đồng bộ tiến độ, xác thực giao dịch Apple/Google, sao lưu ra nơi khác.
   - Gói năm/tháng (mua qua Apple/Google, khôi phục giao dịch); quyết định giá và số cấp miễn phí mỗi môn (**đang mở**).
   - Viết chữ cái (thường, hoa, dấu thanh); Tiếng Việt âm/vần theo sách Tiếng Việt 1 (có giáo viên rà); in phiếu tập tô PDF.
   - Trò chơi đầu tiên **Đua tên lửa** (một mình, 2 bé chung máy đối kháng/thay phiên; ảnh bìa đã có `docs/superpowers/specs/assets/cover-rocket.webp`).
   - Thống kê ẩn danh (đã hoãn ở 1C) — dịch vụ Java nhỏ.
   - Tùy chọn: đổi giọng máy sang file âm thanh tạo sẵn bằng Google Cloud TTS (lớp `Speaker` đã sẵn để thay).
4. **Giai đoạn 3–5:** Tiếng Anh, Toán đến 100, các trò Kéo co/Xây tháp/Tàu chở hàng/Bắn bóng bay, nuôi Chíp Chíp, Vở của bé, giấy khen, báo cáo tuần, trang quản trị + AI sinh nội dung, ba mẹ tự tạo bộ câu hỏi; giai đoạn 4 chơi qua mạng, "Bé khám phá" (vòng kín), web ba mẹ (React); giai đoạn 5 đảo Sinh học/Địa lý/Lịch sử.

## 9. Lịch sử quyết định quan trọng (tóm tắt)

- Làm lại app mới thay vì sửa app cũ (code cũ trộn 5 kiểu quản lý state). Code cũ còn ở nhánh `new-web`, `develop`.
- Hạ xuống Flutter 3.24 theo máy của chủ dự án (dự án ban đầu tạo bằng Flutter 3.50).
- Giọng đọc dùng giọng có sẵn của máy (B), có thể đổi sang Google Cloud TTS sau.
- Cổng người lớn: phép nhân viết bằng chữ. Thống kê ẩn danh: để sau.
- Màu chính cam (khác StarJar dùng xanh); "N ngày học tuần này" thay cho chuỗi ngày liên tiếp (không gây áp lực).
- Nhánh `chipchip` dành cho app mới; mã gói `com.ibme.funedu`.
