# Kế hoạch: sửa 4 lỗi nhỏ trước bản beta (2026-11-19)

> Người lập kế hoạch / rà soát: kỹ sư trưởng (AI). Người code: AI khác.
> Đọc `AGENTS.md` và `docs/PROJECT_STATE.md` trước. Làm trên nhánh `chipchip`, **mỗi task một commit**.
> Trước mỗi commit: `flutter analyze` sạch, `flutter test` đạt hết. Không nâng phiên bản gói.

Chủ dự án đã thử máy thật và chỉ thấy các lỗi nhỏ này. Không làm gì ngoài phạm vi dưới đây.

---

## Task 1 — Trang chủ iPhone nhỏ (375×667): thẻ Toán và Tiếng Anh bị thanh điều hướng che

**Hiện trạng (đã chụp lại bằng `tools/shot/home_shot_test.dart`, `W=375 H=667`):** màn hình đầu chỉ thấy thẻ Viết và Tiếng Việt; Toán và Tiếng Anh nằm dưới `FloatingNavBar` (`lib/features/home/home_screen.dart` khoảng dòng 163: `ListView` có `padding` đáy 120). Cuộn thì vẫn tới được, nhưng bé 3–6 tuổi không biết là phải cuộn, nên với bé là mất 2 môn.

**Mục tiêu:** ở 375×667 (cỡ chữ 1.0), cả 4 thẻ môn **hiện trọn trên màn hình mà không cần cuộn**, nằm trên thanh điều hướng.

**Cách làm đề xuất** (nếu có cách gọn hơn thì ghi lý do vào commit):
1. Đổi `padding` đáy cố định 120 thành *chiều cao thật của thanh điều hướng + `MediaQuery.padding.bottom` + 12*. Đặt chiều cao thanh thành hằng số dùng chung trong `floating_nav_bar.dart`, không đoán số.
2. Thêm chế độ gọn khi chiều cao an toàn của màn < 700:
   - Thẻ "Bài hôm nay": giảm chiều cao, bong bóng lời Chíp còn tối đa 2 dòng (`maxLines: 2`, `ellipsis`).
   - Thẻ "N ngày học tuần này" gộp lên cùng hàng tiêu đề "Hôm nay học gì?" (hoặc ẩn trên màn thấp; thông tin này đã có ở Góc ba mẹ).
   - Thẻ môn dùng biến thể thấp hơn: icon 48, vòng tiến độ 52, bỏ dòng phụ.
3. Nút cho bé vẫn ≥ 64 pt, chữ vẫn đạt tương phản ≥ 4.5:1.

**Kiểm tra:**
- Test widget mới ở `test/features/home/`: kích thước 375×667 → khung của thẻ Tiếng Anh nằm hoàn toàn phía trên khung của `FloatingNavBar`.
- Test cũ 390×844 không đổi bố cục (chế độ gọn không bật ở đó).
- Đính kèm ảnh chụp 375×667 và 390×844 trong báo cáo.

## Task 2 — Điện thoại: thẻ "Bài hôm nay" bị cắt khi cỡ chữ hệ thống lớn nhất

**Mục tiêu:** ở 390×844 với `textScaler` 1.3, 1.6 và 2.0: không bị tràn (không có sọc vàng-đen), không cắt chữ giữa dòng, nút Play vẫn ≥ 64 và vẫn bấm được.

**Cách làm:**
1. Thêm biến môi trường `TEXT_SCALE` vào `tools/shot/home_shot_test.dart` (bọc `MediaQuery` có `textScaler: TextScaler.linear(...)`), ghi cách dùng vào `docs/perf.md`.
2. Trong thẻ bài hôm nay: bỏ chiều cao cố định, cho thẻ cao theo nội dung. Tiêu đề "Bài hôm nay" dùng `FittedBox(fit: BoxFit.scaleDown)`. Bong bóng lời Chíp giới hạn số dòng. Ảnh Chíp co theo khoảng trống còn lại, không đẩy nút.
3. Không dùng `ScaleDownToFit` cho cả thẻ trên điện thoại (chữ sẽ nhỏ lại, đi ngược ý của cỡ chữ lớn).

**Kiểm tra:** test widget lặp qua 3 mức textScale, gọi `tester.takeException()` phải bằng `null`; kèm 3 ảnh chụp.

## Task 3 — Android 12+ chế độ tối: màn chào không đúng màu

**Nguyên nhân (đã xác định):** có `values-v31/styles.xml` (nền kem + icon) và `values-night/styles.xml` (mẫu mặc định của Flutter, `Theme.Black`). Khi máy ở chế độ tối, Android ưu tiên bộ định danh `night` hơn `v31`, nên Android 12+ dùng `values-night`. Kết quả: màn chào hệ thống nền tối mặc định, không có `windowSplashScreenBackground`.

**Cách làm:**
1. Tạo `android/app/src/main/res/values-night-v31/styles.xml`, giống `values-v31` nhưng `parent` là `@android:style/Theme.Black.NoTitleBar`. **Giữ nền kem** `@color/splash_bg` để khớp `SplashView` của Flutter (app không có giao diện tối, nên nền tối ở màn chào sẽ chớp đen → kem).
2. Sửa `values-night/styles.xml` (dưới API 31): `windowBackground` vẫn là `@drawable/launch_background` (đã là nền kem), chỉ dọn chú thích mẫu.

**Kiểm tra:** không có test tự động. Ghi vào báo cáo: chủ dự án cần thử trên máy Android 12+ bật chế độ tối, mở app từ trạng thái đã tắt hẳn.

## Task 4 — Màn kết quả đua: ô vuông "▯" trước "+2 Sao May Mắn!"

**Hiện trạng:** `lib/features/game/race_result_screen.dart` khoảng dòng 624 dùng emoji `Text('⭐')`. Trong ảnh chụp nó hiện thành ô vuông (tofu). Trên máy thật thì hiện emoji của hệ điều hành, lệch hẳn với ngôi sao 3D của app ngay phía trên.

**Cách làm:** thay bằng `Image.asset(AppImages.icStar, width: ..., height: ...)`, cỡ bằng 1,2 lần cỡ chữ. Rà toàn bộ `lib/` xem còn emoji trong chuỗi giao diện không (`grep -rnP '[\x{2600}-\x{27BF}]|[\x{1F300}-\x{1FAFF}]' lib` với `rg`/`grep -P` hỗ trợ Unicode). Có thì thay bằng ảnh hoặc icon.

**Kiểm tra:** chạy `tools/shot/game_shot_test.dart` (`ONLY=win,lose`), ảnh không còn ô vuông.

---

## Báo cáo khi xong (gửi lại kỹ sư trưởng rà soát)

- Danh sách commit (mỗi task một commit).
- Ảnh chụp trước/sau của Task 1, 2, 4.
- Kết quả `flutter analyze` và `flutter test` (số test đạt).
- Cập nhật `docs/PROJECT_STATE.md` mục 6–7: xóa 3 dòng tương ứng ở mục 7, thêm dòng vào mục 6.
