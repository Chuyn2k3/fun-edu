# Giai đoạn 3A — Môn Tiếng Anh (9 cấp độ, Offline)

**Ngày:** 2026-11-18
**Nhánh:** `chipchip`
**Trạng thái:** Đã duyệt thiết kế

## 1. Mục tiêu

Mở khóa đảo môn cuối cùng trên Trang chủ — **Tiếng Anh** (`Subject.tiengAnh`, màu xanh ngọc `#0F8A5F`), chạy **100% offline**, gồm 9 cấp độ cho trẻ 3–7 tuổi với giọng đọc tiếng Anh chuẩn (`en-US`) qua `Speaker`, hình ảnh trực quan (chấm màu sắc, chấm đếm số, ghép chữ cái đầu phonics, điền câu chào), và tích hợp vào Trang chủ + Góc ba mẹ mà **không cần đổi schema Drift**.

## 2. Thang 9 cấp độ (`lib/english/english_level.dart`)

| # | Id | Tên cấp | Nội dung | Dạng hiển thị |
|---:|---|---|---|---|
| 0 | `letters-a-m` | Chữ cái A – M | `Aa` → `Mm` | Nghe phát âm tiếng Anh → chọn chữ (`listenPick`) |
| 1 | `letters-n-z` | Chữ cái N – Z | `Nn` → `Zz` | Nghe phát âm tiếng Anh → chọn chữ (`listenPick`) |
| 2 | `numbers-1-10` | Số đếm 1 – 10 | `one (1)` → `ten (10)` | Nhìn số + chấm đếm & nghe → chọn từ tiếng Anh (`countPick`) |
| 3 | `colors` | Màu sắc | `red, blue, yellow, green, orange, purple, pink, black, white, brown` | Chấm màu tròn trực quan & nghe → chọn từ / chấm màu (`colorPick`) |
| 4 | `animals` | Con vật | `cat, dog, bird, fish, duck, pig, cow, lion, frog, bear` | Nghe tiếng Anh + gợi ý tiếng Việt → chọn từ (`listenPick`) |
| 5 | `food-fruit` | Trái cây & Đồ ăn | `apple, banana, orange, grape, cake, milk, bread, egg, rice, mango` | Nghe tiếng Anh + gợi ý tiếng Việt → chọn từ (`listenPick`) |
| 6 | `phonics` | Âm đầu Phonics | `a-pple, b-all, c-at, d-og, f-ish, h-at, m-oon, p-ig, s-un, t-ree` | Ghép chữ mở đầu `[ ? ] + [ pple ]` (`phonicsBuild`) |
| 7 | `family-body` | Gia đình & Cơ thể | `mom, dad, baby, sister, brother, eye, nose, ear, hand, foot` | Nghe tiếng Anh + gợi ý tiếng Việt → chọn từ (`listenPick`) |
| 8 | `greetings` | Câu chào ngắn | `Good morning`, `Thank you`, `I love mom`, `It is a cat`, `See you`… | Điền từ tiếng Anh vào chỗ trống (`phraseFill`) |

## 3. Giọng đọc đa ngôn ngữ (`lib/voice/speaker.dart`)

- Thêm `abstract interface class MultilingualSpeaker implements Speaker` với `Future<void> speakWithLanguage(String text, String language)` và extension `speakInLanguage(text, language)` trên `Speaker`.
- `TtsSpeaker` ghi nhớ ngôn ngữ đang đặt (`_currentLanguage`, mặc định `'vi-VN'`), tự chuyển sang `'en-US'` khi gọi `speakWithLanguage(..., 'en-US')` và tự đổi lại `'vi-VN'` khi gọi `speak(...)`. Nếu thiết bị không có giọng `en-US`, xử lý lỗi nhẹ nhàng không crash.
- Tương thích ngược 100%: mọi `Speaker` giả trong test chỉ `implements Speaker` vẫn chạy nguyên vẹn.

## 4. Lưu trữ & Tích hợp App

- **Lưu trữ (`LevelRepository`):** khóa `'tieng-anh'` trên bảng `subject_levels` sẵn có (0 đổi schema Drift), luật lên/lùi cấp dùng `nextLevelIndex` (5 câu/buổi).
- **Trang chủ (`HomeScreen` / `HomeTablet`):** mở khóa thẻ **Tiếng Anh** với vòng tiến độ `(englishLevelIndex + 1)/9` → bấm mở `/subject/tieng-anh`. Cả 4 đảo môn lõi đều hoạt động 100%.
- **Góc ba mẹ (`ProgressTab`):** thêm thẻ tiến độ **Tiếng Anh** (`Đang học: <Tên cấp>`, `X/9`) dưới Tiếng Việt.
- **Bài hôm nay:** giữ nguyên 4 bước (`Viết → Tiếng Việt → Toán → Viết ôn`) cho nhịp học ~10 phút phù hợp bé 3–6 tuổi.

## 5. Kiểm thử

- `test/english/english_generator_test.dart`: kiểm thử cả 9 cấp sinh 5 câu độc lập, 3 đáp án không trùng, `correctIndex` hợp lệ, giọng đọc không rỗng.
- `test/features/english/english_screen_test.dart`: kiểm thử `EnglishMapScreen` (phone & iPad 3×3), `EnglishSessionScreen` (đọc `en-US`, sai thử lại, đúng đủ 5 câu gọi `onCompleted`, hiển thị màu/số/phonics/câu chào không overflow trên điện thoại & iPad), và `LevelRepository.recordEnglishSession`.
- Cập nhật `test/features/home_screen_test.dart` (không còn thẻ môn "Sắp có" trên Trang chủ).
