# Giai đoạn 2F — Môn Tiếng Việt (9 cấp độ, Offline)

**Ngày:** 2026-11-18
**Nhánh:** `chipchip`
**Trạng thái:** Đã duyệt thiết kế

## 1. Mục tiêu

Mở khóa đảo môn **Tiếng Việt** (màu tím `Subject.tiengViet`) trên Trang chủ, chạy **100% offline**, theo lộ trình 9 cấp độ bám sát sách Tiếng Việt 1 Việt Nam (nhận mặt chữ cái → dấu thanh → ghép tiếng → phụ âm ghép → vần xuôi → vần có âm cuối → đọc từ quen thuộc → hoàn thiện cụm từ), tích hợp đầy đủ vào **Bài hôm nay** và **Góc ba mẹ** mà **không cần đổi schema Drift**.

## 2. Thang 9 cấp độ (`lib/vietnamese/vietnamese_level.dart`)

| # | Id | Tên cấp | Nội dung | Dạng tương tác |
|---:|---|---|---|---|
| 0 | `nguyen-am` | Nguyên âm | `a, ă, â, e, ê, i, o, ô, ơ, u, ư, y` | Nghe đọc & chọn chữ (`listenPick`) |
| 1 | `phu-am-don` | Phụ âm đơn | `b, c, d, đ, g, h, k, l, m, n, p, q, r, s, t, v, x` | Nghe đọc & chọn chữ (`listenPick`) |
| 2 | `dau-thanh` | Dấu thanh | 6 thanh trên tiếng đơn (`ba/bà/bá/bả/bã/bạ`, `ca/cá/cà/cả`, `co/có/cò/cỏ`, `me/mẹ/mẻ`…) | Nghe tiếng & chọn tiếng mang đúng dấu (`listenPick`) |
| 3 | `ghep-tieng` | Ghép tiếng cơ bản | Phụ âm đầu + nguyên âm (`b + a → ba`, `m + e → me`, `c + ô → cô`…) | Ghép thẻ âm `[ b ] + [ ? ] = ba` (`equationBuild`) |
| 4 | `phu-am-ghep` | Phụ âm ghép | `ch, gh, gi, kh, ng, ngh, nh, ph, qu, th, tr` trong tiếng quen (`chó, ghế, khỉ, nhà, phở, thỏ, tre`…) | Ghép âm đầu `[ ? ] + [ ó ] = chó` (`equationBuild`) |
| 5 | `van-xuoi` | Vần xuôi | `ai, ao, au, âu, ay, ây, oi, ôi, ơi, ui, ưi` (`mai, sao, tàu, cây, voi, núi`…) | Ghép vần `[ m ] + [ ? ] = mai` (`equationBuild`) |
| 6 | `van-am-cuoi` | Vần có âm cuối | `an, ăn, ân, en, ên, in, on, ôn, ơn, am, em, om, ang, ong` (`bàn, đèn, chim, bóng, trăng`…) | Ghép vần `[ b ] + [ ? ] = bàn` (`equationBuild`) |
| 7 | `doc-tu` | Đọc từ quen thuộc | Từ 2 tiếng đời sống (`con mèo, quả cam, cái bàn, bông hoa, ngôi sao, xe đạp, mặt trời, cá vàng`…) | Nghe Chíp đọc & chọn đúng thẻ từ (`listenPick`) |
| 8 | `hoan-thien-cum` | Hoàn thiện cụm từ | Cụm 3–4 tiếng ngắn (`bé đi học`, `gà gáy sáng`, `chim hót hay`, `mèo bắt chuột`…) | Nghe cả câu & chọn tiếng điền vào chỗ trống (`phraseFill`) |

## 3. Luật lên cấp, lưu trữ & Bài hôm nay

- **Lưu trữ (`LevelRepository`):** Dùng bảng `subject_levels` sẵn có với khóa `'tieng-viet'` (mặc định `0` khi chưa có bản ghi; **không đổi `schemaVersion`**, không làm ảnh hưởng `isPlaced()`).
- **Lên/lùi cấp:** Dùng lại chính `nextLevelIndex` của môn Toán (`5` câu/buổi, đúng lần đầu `≥ 4/5` → lên cấp, `≤ 1/5` → lùi 1 cấp để ôn vững).
- **Bài hôm nay (`composeTodayLessonItems` & `todayLessonProvider`):**
  - Thêm `VietnameseItem(int levelIndex)` vào `sealed class LessonItem`.
  - Khi `todayLessonProvider` dựng bài hôm nay, danh sách gồm: `WritingItem` (chữ mới) → `VietnameseItem` (Tiếng Việt theo cấp hiện tại) → `MathItem` (Toán theo cấp hiện tại) → `WritingItem` (chữ ôn).
  - Trong `composeTodayLessonItems`, tham số `int? vietnameseLevelIndex` là tùy chọn để giữ tương thích hoàn toàn với các test cũ gọi không truyền `vietnameseLevelIndex`.

## 4. Màn hình & Trải nghiệm

### 4.1 Bản đồ Tiếng Việt (`VietnameseMapScreen`, route `/subject/tieng-viet`)
- Cùng bố cục với `MathMapScreen` (chủ đề màu tím `Subject.tiengViet`):
  - **Điện thoại:** con đường 9 trạm cuộn dọc; cấp đã xong/đang học bấm được (`Pressable`), cấp chưa mở có ổ khóa.
  - **iPad:** lưới 3×3 lấp đầy màn hình không cuộn, chữ ×1.2 (`TabletTextScale`), nút quay lại ≥ 80pt.

### 4.2 Màn luyện tập (`VietnameseSessionScreen` & `PracticeVietnameseScreen`, route `/practice-vietnamese/:levelIndex`)
- Dùng chung `SessionHeader`, `ChipSays`, `AppCard`, `Pressable`, `raisedDecoration`, `Speaker`.
- Nút loa nghe lại lớn (`≥ 64pt` điện thoại / `≥ 80pt` iPad), tự động đọc câu hỏi qua `Speaker` khi sang câu mới.
- 3 đáp án dạng thẻ nổi to (`height ≥ 72pt` điện thoại, `≥ 96pt` iPad), màu tương phản ≥ 4.5:1.
- Khi chọn đúng: thẻ sáng xanh (`AppColors.text` / `GameColors.correctRing`), ô trống ghép khớp đáp án, Chíp mừng rỡ đọc lại câu khen (ví dụ *"Đúng rồi! Bờ a ba!"*), chờ 900ms chuyển câu tiếp.
- Khi chọn sai: không phạt, Chíp hiện biểu cảm động viên kèm gợi ý nhẹ (*"Thử lại nhé!"* / đọc lại câu hỏi).
- Hỗ trợ bố cục iPad ngang (trái: Chíp + thẻ câu hỏi, phải: 3 đáp án) và iPad dọc (căn giữa tối đa `720pt`).

### 4.3 Trang chủ & Góc ba mẹ
- **Trang chủ (`HomeScreen`, `HomeTablet`):** mở khóa thẻ **Tiếng Việt** (`onTap` → `/subject/tieng-viet`), hiển thị tiến độ `(vietnameseLevel + 1) / 9` (tương tự thẻ Toán). Chừa lại duy nhất thẻ **Tiếng Anh** hiện "Sắp có".
- **Góc ba mẹ (`ProgressTab`):** thêm thẻ **Tiếng Việt** hiển thị *"Đang học: <tên cấp>"* và `X/9` ngay dưới thẻ Toán.

## 5. Kiểm thử

- `test/vietnamese/vietnamese_generator_test.dart`: kiểm thử cả 9 cấp sinh đúng 5 câu, luôn có 3 lựa chọn phân biệt không trùng, `correctIndex` hợp lệ, speech không rỗng, không lặp câu trong cùng 1 buổi.
- `test/features/vietnamese/vietnamese_screen_test.dart`: kiểm thử `VietnameseMapScreen` (điện thoại & iPad 3×3), `VietnameseSessionScreen` (nghe đọc, trả lời sai thử lại, trả lời đúng đủ 5 câu gọi `onCompleted` với đúng `firstTryCorrect`, không overflow trên điện thoại & iPad).
- Cập nhật test `home_screen_test.dart` và `progress_tab_test.dart` cho thẻ Tiếng Việt mới.
