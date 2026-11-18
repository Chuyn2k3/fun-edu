# Thiết kế Giai đoạn 3B — Tab "Sưu tập" (Offline 100%)

Ngày: 2026-11-18  
Nhánh: `chipchip`  
Phạm vi: Mở khóa tab **Sưu tập** trên thanh điều hướng chính của bé (`/collection`), 100% offline, dùng dữ liệu học tập sẵn có (tách biệt hoàn toàn khỏi dữ liệu trò chơi `lib/game/`), không thay đổi schema Drift.

---

## 1. Mục tiêu

Theo spec tổng thể (`2026-11-12-fun-edu-overhaul-design.md`, mục 5.1):
- **Album sticker học tập**: Mở khóa sticker theo các cột mốc học thật (bài học đầu tiên, số ngày học, ngôi sao học tập, 4 môn Tập viết / Toán / Tiếng Việt / Tiếng Anh).
- **Lịch chuyên cần**: Mỗi ngày bé hoàn thành ít nhất 1 bài học được dán một dấu sao trên lịch tháng. Bỏ lỡ ngày không mất chuỗi, không gây áp lực — Chíp chỉ "nhớ bé" và mời bé học nhẹ nhàng.
- **Giấy khen của bé**: Các cột mốc học tập mở khóa giấy khen mang **tên gọi ở nhà của bé** (`KidProfile.nickname`), xem đẹp toàn màn hình kèm lời khen của Chíp và có thể xuất/chia sẻ bản **PDF khổ ngang A4** hoàn toàn offline.

---

## 2. Nguyên tắc kiến trúc & tách dữ liệu

- **Tách dữ liệu trò chơi:** `lib/collection/` và `lib/features/collection/` **không import** bất kỳ file nào trong `lib/game/`, không đọc `race_results` hay `game_*`.
- **Không đổi Drift schema (giữ `schemaVersion = 7`):** Toàn bộ trạng thái Sưu tập được tính thuần túy và xác định từ các bảng học hiện có (`lesson_completions`, `glyph_progress`, `subject_levels`, `kid_profiles`).
- **Tái sử dụng hạ tầng sẵn có:**
  - Hình ảnh qua `AppImages` (`lib/ui/assets.dart`).
  - Màu sắc, bo góc, độ nổi từ `lib/ui/theme/tokens.dart` (bổ sung `CollectionColors`) và `lib/ui/theme/depth.dart`.
  - Giọng đọc Chíp qua `speakerProvider` (`lib/voice/speaker.dart`).
  - Xuất PDF offline qua `WorksheetPdfFonts` + `worksheetPrinterProvider` (`pdf` & `printing` đã có từ 2C).

---

## 3. Mô hình dữ liệu (`lib/collection/collection_model.dart`)

### 3.1 `LearningSnapshot`
Dữ liệu học tổng hợp của bé hiện tại:
- `kidName`: tên gọi ở nhà (mặc định `'Bé'`).
- `totalStars`: tổng sao học tập (`ProgressRepository.totalStars`).
- `totalLessons`: tổng số bài học đã xong (`ProgressRepository.totalLessons`).
- `totalLearnedDays`: tổng số ngày lịch khác nhau bé từng học (`ProgressRepository.totalLearnedDays`).
- `learnedDaysThisWeek`: số ngày học tuần này.
- `masteredWriting`: số nét/chữ đã thuộc (`cleanCompletions >= 1`).
- `mathLevelIndex`, `vietnameseLevelIndex`, `englishLevelIndex`: cấp độ hiện tại (0..8) của 3 môn.
- `viewedYear`, `viewedMonth`, `learnedDaysInMonth`: tháng đang xem trên lịch chuyên cần và tập các ngày (1..31) bé có học trong tháng đó.
- `learnedToday`: bé đã học hôm nay hay chưa (để Chíp chọn lời chào phù hợp).

### 3.2 12 Sticker học tập (`buildLearningStickers`)
| # | ID | Tên sticker | Điều kiện mở | Ảnh (`AppImages`) |
|---|---|---|---|---|
| 1 | `first_lesson` | Bước đầu tiên | 1 bài học | `chipJoy` |
| 2 | `three_days` | Ong chăm chỉ | 3 ngày học | `icFlame` |
| 3 | `seven_days` | Tuần lễ rực rỡ | 7 ngày học | `stickerHugHeart` |
| 4 | `ten_stars` | Hái sao nhỏ | 10 ngôi sao | `icStar` |
| 5 | `thirty_stars` | Thợ săn sao | 30 ngôi sao | `stickerHugStar` |
| 6 | `sixty_stars` | Vương miện sao | 60 ngôi sao | `icCrown` |
| 7 | `writing_5` | Nét bút xinh | Thuộc 5 nét/chữ | `chipWrite` |
| 8 | `writing_20` | Họa sĩ chữ | Thuộc 20 nét/chữ | `stickerCrayon` |
| 9 | `math_lv3` | Bé giỏi Toán | Đạt cấp 3 Toán | `icToan` |
| 10 | `vn_lv3` | Đọc hay Tiếng Việt | Đạt cấp 3 Tiếng Việt | `icTiengViet` |
| 11 | `en_lv3` | Hello Tiếng Anh | Đạt cấp 3 Tiếng Anh | `icTiengAnh` |
| 12 | `all_rounder` | Trạng nguyên nhí | Cả 4 môn đều có tiến bộ (`writing ≥ 5`, `math/vn/en ≥ cấp 2`) | `stickerGradCap` |

Mỗi sticker có `current`, `target`, `unlocked`, `hint` (gợi ý ngắn) và `praise` (câu Chíp đọc khi bé chạm vào).

### 3.3 6 Giấy khen của bé (`buildLearningCertificates`)
| # | ID | Danh hiệu | Điều kiện mở | Ảnh |
|---|---|---|---|---|
| 1 | `cert_diligent` | Bé Chăm Học | Hoàn thành 3 bài học | `icFlame` |
| 2 | `cert_writing` | Bàn Tay Khéo Léo | Thuộc 10 nét/chữ Tập viết | `icViet` |
| 3 | `cert_math` | Sao Toán Học | Đạt cấp 3 môn Toán | `icToan` |
| 4 | `cert_vietnamese` | Đọc Giỏi Tiếng Việt | Đạt cấp 3 môn Tiếng Việt | `icTiengViet` |
| 5 | `cert_english` | Bé Giỏi Tiếng Anh | Đạt cấp 3 môn Tiếng Anh | `icTiengAnh` |
| 6 | `cert_star` | Ngôi Sao Chíp Chíp | Tích đủ 50 ngôi sao học tập | `icCrown` |

---

## 4. Giấy khen PDF offline (`lib/collection/certificate_pdf.dart`)

- Khổ ngang `PdfPageFormat.a4.landscape`, nền giấy kem ấm `CollectionColors.certPaper`, khung viền vàng đôi `CollectionColors.certFrameOuter` & `certFrameInner`.
- Font `Nunito` nạp từ `assets/fonts/` qua `WorksheetPdfFonts` (hỗ trợ đầy đủ dấu tiếng Việt).
- Nội dung: `"GIẤY KHEN"`, `"CHÍP CHÍP TRAO TẶNG BÉ"`, tên bé cỡ lớn, danh hiệu, lời khen ghi nhận nỗ lực, ngày cấp (`dd/MM/yyyy`), chữ ký `"Bạn nhỏ Chíp Chíp"`.

---

## 5. Giao diện & Bố cục (`lib/features/collection/collection_screen.dart`)

- **Điều hướng:** Route `/collection`, gán `kidNavCollection = 2` trong `lib/features/home/kid_nav.dart`. Điện thoại dùng `FloatingNavBar`, iPad dùng `NavRail` ở cạnh trái. Nút quay lại hệ thống đưa về `/`.
- **Nền:** `DottedBackground` + dải mây trời đầu trang đồng bộ Trang chủ (ấm áp, khác biệt hẳn nền vũ trụ của Góc Chơi).
- **Khối đầu trang:** Chíp + bong bóng thoại động viên theo trạng thái thực tế + 3 chỉ số gọn (`N sao`, `X/12 sticker`, `Y/6 giấy khen`).
- **3 thẻ chuyển mục lớn (≥ 64pt điện thoại / ≥ 72pt tablet):**
  1. **Sticker**: Lưới 2 cột (điện thoại) / 3 cột (iPad dọc) / 4 cột (iPad ngang). Sticker đã mở rực rỡ, chạm để mở thẻ phóng to & nghe Chíp khen; sticker chưa mở dạng mờ có thanh tiến độ `current/target` và gợi ý.
  2. **Lịch học**: Lịch tháng 7 cột (`T2`–`CN`) có nút lùi/tiến tháng (chặn không đi quá tháng hiện tại), ngày đã học dán dấu sao vàng `AppImages.icStar`, hôm nay có viền cam nhẹ. Kèm thẻ tổng kết tháng + lời nhắn nhẹ nhàng "Bỏ ngày không mất gì, Chíp luôn đợi bé!" (trên iPad ngang đặt song song 2 cột).
  3. **Giấy khen**: Lưới 1 cột (điện thoại) / 2–3 cột (iPad). Giấy khen đã mở có khung vàng + tên bé, chạm mở hộp thoại **Giấy khen toàn màn hình** kèm Chíp khen to và nút **"Lưu / In PDF"** (xuất PDF A4 ngang qua `worksheetPrinterProvider`).
- **Tiêu chuẩn tiếp cận:** Tương phản chữ ≥ 4.5:1 trên mọi thẻ, mọi nút bấm bé ≥ 64pt (điện thoại) / ≥ 80pt cho thẻ tương tác trên iPad.
