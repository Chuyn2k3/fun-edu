# Kế hoạch triển khai Giai đoạn 3B — Tab "Sưu tập" (Offline 100%)

Spec: `docs/superpowers/specs/2026-11-18-giai-doan-3b-suu-tap-design.md`

---

## Task 1: Màu sắc, truy vấn `ProgressRepository` & mô hình dữ liệu Sưu tập
1. Thêm `CollectionColors` vào `lib/ui/theme/tokens.dart` (tương phản chữ ≥ 4.5:1).
2. Mở rộng `ProgressRepository` (`lib/progress/progress_repository.dart`):
   - `totalLessons()`
   - `totalLearnedDays()`
   - `learnedDaysInMonth(int year, int month)`
3. Tạo `lib/collection/collection_model.dart`:
   - `LearningSnapshot`, `LearningSticker`, `LearningCertificate`
   - `buildLearningStickers(LearningSnapshot)`, `buildLearningCertificates(LearningSnapshot)`
   - `daysInMonth(int year, int month)`, `firstWeekdayOfMonth(int year, int month)`
4. Tạo `lib/collection/collection_provider.dart`:
   - `collectionMonthProvider` (`StateProvider<DateTime>`)
   - `collectionSnapshotProvider` (`FutureProvider.autoDispose<LearningSnapshot>`)
5. Viết unit test `test/collection/collection_model_test.dart` (kiểm tra đủ 12 sticker, 6 giấy khen, ranh giới mở khóa, lịch tháng nhuận/thường, và các hàm mới của `ProgressRepository`).

## Task 2: Bộ sinh Giấy khen PDF offline
1. Tạo `lib/collection/certificate_pdf.dart` với `buildCertificatePdf(...)` sinh file PDF A4 ngang 100% offline dùng `WorksheetPdfFonts`.
2. Viết test `test/collection/certificate_pdf_test.dart` kiểm tra header `%PDF-`, số byte hợp lệ, và không lỗi với tên bé có dấu tiếng Việt.

## Task 3: Giao diện `CollectionScreen`, điều hướng & kiểm thử toàn diện
1. Tạo `lib/features/collection/collection_screen.dart`:
   - Bố cục điện thoại (`FloatingNavBar`) & iPad (`NavRail`, 2 cột cho Lịch học ngang, 3–4 cột cho Sticker & Giấy khen).
   - 3 mục: **Sticker**, **Lịch học**, **Giấy khen**.
   - Tương tác chạm sticker (hiện chi tiết + Chíp đọc khen/gợi ý), chuyển tháng trên lịch, chạm giấy khen mở `CertificateModal` kèm Chíp khen và nút **Lưu / In PDF**.
2. Gắn route `/collection` trong `lib/router.dart` và mở khóa `kidNavCollection = 2` trong `lib/features/home/kid_nav.dart`.
3. Cập nhật `test/features/home_screen_test.dart` (chỉ còn `'Nhà Chíp'` hiện `'Sắp có'`, bấm `'Sưu tập'` mở `CollectionScreen`).
4. Viết widget test `test/features/collection/collection_screen_test.dart`:
   - Render điện thoại & iPad (dọc/ngang) không tràn khung.
   - Chuyển 3 tab Sticker / Lịch học / Giấy khen.
   - Bấm sticker mở chi tiết & gọi `Speaker`.
   - Lịch tháng hiển thị dấu sao đúng ngày đã học & chuyển tháng lùi/tiến hoạt động đúng.
   - Mở giấy khen có tên bé & bấm **Lưu / In PDF** gọi `WorksheetPrinter.sharePdf`.
5. Chụp màn hình thật (điện thoại & iPad) để kiểm duyệt thị giác.
6. Chạy `flutter analyze && flutter test`, cập nhật `docs/PROJECT_STATE.md`, commit & push lên `origin/chipchip`.
