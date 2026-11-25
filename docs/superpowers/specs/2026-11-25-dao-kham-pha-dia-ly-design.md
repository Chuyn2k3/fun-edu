# Đảo Khám phá — môn Địa lý "Khám phá Việt Nam" (thiết kế)

Ngày: 2026-11-25 · Nhánh: `chipchip` · Trạng thái: chờ chủ dự án duyệt

## 1. Ý định và lý do

Chủ dự án muốn thêm **nội dung mới** cho bé (ưu tiên hơn beta và thu tiền). Đợt này gồm hai dự án làm lần lượt: (1) môn mới có **ảnh địa danh** cho thú vị — tài liệu này; (2) trò chơi thứ hai — thiết kế riêng sau. Làm môn trước để trò mới có thêm câu hỏi để dùng (spec gốc §5.2: trò nào cũng lấy câu hỏi từ kho chung).

Spec gốc (`2026-11-12-fun-edu-overhaul-design.md` §3, giai đoạn 5) đã định Sinh học, Địa lý, Lịch sử là **"đảo khám phá"**: câu hỏi và trò chơi, không có phần viết, nội dung nhẹ và duyệt kỹ. Đợt này mở **khung Đảo Khám phá** và môn đầu tiên **Địa lý**. Sinh học và Lịch sử sẽ dùng lại cùng khung sau.

## 2. Mục tiêu / không làm / phản mục tiêu

**Mục tiêu**
- Bé 3–6 tuổi nhận ra cảnh vật, thời tiết, biểu tượng Việt Nam và các địa danh nổi tiếng trong nước và trên thế giới qua ảnh 3D đồ chơi kèm giọng Chíp.
- Thêm môn không làm lệch trang chủ nữa: trang chủ chỉ thêm **một** thẻ "Đảo Khám phá", lần sau thêm môn thì không cần sửa trang chủ.
- Chạy offline 100% như các môn khác; có thang cấp tự lên/lùi; ba mẹ thấy tiến bộ.

**Không làm đợt này**
- Sinh học, Lịch sử: chỉ hiện thẻ "Sắp có" trong sảnh đảo.
- Đưa Địa lý vào "Bài hôm nay" hoặc vào trận đua tên lửa (xem §5.8).
- Bài xếp cấp lần đầu cho Địa lý: bé bắt đầu ở cấp 1, giống Tiếng Anh.
- Bản đồ tương tác, chạm tỉnh thành, ảnh chụp thật.

**Phản mục tiêu** (thành thất bại dù code chạy đúng)
- Ảnh trông lệch phong cách app hoặc "giả AI" kiểu bóng nhựa rẻ tiền (bài học từ icon app, mục 2 `PROJECT_STATE.md`).
- Câu kể về địa danh sai sự thật hoặc nhạy cảm (chính trị, tôn giáo được nhấn mạnh, chiến tranh).
- Câu hỏi đòi bé phải biết đọc chữ.
- Trang chủ bị tràn hoặc phải cuộn ở điện thoại nhỏ, hoặc chật hơn so với hiện tại.

## 3. Ràng buộc

- Toàn bộ quy ước của `AGENTS.md` / `PROJECT_STATE.md` §3: Flutter 3.24.5, Riverpod, màu/bo góc chỉ lấy từ `tokens.dart`, ảnh chỉ qua `AppImages`, thẻ dùng `raisedDecoration` + `Pressable`, nút bé ≥ 64 (tablet ≥ 80), tương phản chữ ≥ 4.5:1, chuỗi giao diện tiếng Việt, tablet rẽ nhánh ngay trong cùng file (riêng trang chủ có `home_tablet.dart`).
- Không gọi mạng. Không thêm gói.
- Ảnh mới: **3D đồ chơi / mô hình thu nhỏ** (chủ dự án chọn), sinh bằng Gemini trên **nền xanh lá**, tách nền bằng `tools/assets/chroma_key.py`, xuất 1x/2x/3x, cập nhật `tools/assets/build_app_images.sh`, `test/ui/assets_test.dart`, `docs/phase0/asset-list.md`.
- `flutter analyze` sạch, `flutter test` đạt hết trước mỗi commit.

## 4. Các cách đã cân nhắc

| Cách | Mô tả | Được / mất | Kết quả |
|---|---|---|---|
| A | Thẻ "Địa lý" là môn thứ 5 trong lưới trang chủ | Thấy ngay; nhưng lưới 2×2 lẻ thẻ, phải canh lại điện thoại nhỏ + iPad, và làm lại lần nữa khi có 7 môn | Bỏ |
| **B** | **Một thẻ rộng "Đảo Khám phá" dưới lưới 4 môn → sảnh 3 đảo (Địa lý mở; Sinh học, Lịch sử "Sắp có")** | Trang chủ chỉ sửa một lần, đúng ý "đảo khám phá" của spec; đổi lại bé phải chạm thêm một lần | **Chủ dự án chọn** |
| C | Đặt trong Góc Chơi hoặc Sưu tập | Đây là phần học có cấp và có tiến bộ cho ba mẹ, đặt ở đó sẽ lạc chỗ | Bỏ |

Kiểu ảnh: **3D đồ chơi** (chủ dự án chọn), không dùng ảnh chụp thật (vướng bản quyền, lệch phong cách).

## 5. Thiết kế

### 5.1 Đường đi của bé

```
Trang chủ
[ Viết ]      [ Tiếng Việt ]
[ Toán ]      [ Tiếng Anh  ]
[ 🌏 Đảo Khám phá   1/9    ]   ← thẻ rộng, vòng tiến độ của Địa lý
        │
        ▼
/kham-pha  (sảnh)
[ Địa lý ]  [ Sinh học · Sắp có ]  [ Lịch sử · Sắp có ]
        │
        ▼
/subject/dia-ly  (bản đồ 9 cấp, giống bản đồ Tiếng Anh)
        │
        ▼
/practice-dia-ly/:levelIndex  (5 câu) → về bản đồ
```

- Thẻ rộng trên trang chủ: ảnh đảo, tiêu đề "Đảo Khám phá", dòng phụ "Địa lý, Sinh học, Lịch sử", vòng tiến độ lấy theo cấp Địa lý (khi có thêm môn thì builder quyết cách gộp tiến độ).
- Chạm "Sắp có" thì hiện `showAppToast(context, 'Sắp có', kind: AppToastKind.info)`, giống Góc Chơi.

### 5.2 Thang 9 cấp và nội dung

Mỗi cấp có 5–6 mục; mỗi mục có: `id`, tên (đọc to), một câu kể ngắn (Chíp đọc sau khi bé trả lời đúng), một gợi ý (cho dạng "nghe kể rồi chọn"), và ảnh.

| # | id | Tiêu đề | Mục |
|---|---|---|---|
| 1 | `canh-vat` | Cảnh vật quanh em | núi, sông, biển, rừng, đồng lúa, hang động |
| 2 | `thoi-tiet` | Thời tiết | nắng, mưa, gió, mây, cầu vồng, sấm sét |
| 3 | `viet-nam` | Đất nước em | lá cờ Việt Nam, bản đồ hình chữ S, nón lá, áo dài, hoa sen |
| 4 | `mien-bac` | Miền Bắc | Hồ Gươm (Tháp Rùa), Vịnh Hạ Long, Văn Miếu, Chùa Một Cột, ruộng bậc thang Sa Pa |
| 5 | `mien-trung` | Miền Trung | Cố đô Huế (Ngọ Môn), Chùa Cầu Hội An, Cầu Rồng Đà Nẵng, Động Phong Nha, Cầu Vàng Bà Nà |
| 6 | `mien-nam` | Miền Nam | Chợ Bến Thành, Chợ nổi Cái Răng, Nhà thờ Đức Bà, Bưu điện Sài Gòn, Mũi Cà Mau |
| 7 | `chau-a` | Châu Á | Vạn Lý Trường Thành, Núi Phú Sĩ, Đền Taj Mahal, Angkor Wat, Tháp đôi Petronas |
| 8 | `chau-au-phi` | Châu Âu & châu Phi | Tháp Eiffel, Kim tự tháp, Tháp nghiêng Pisa, Tháp đồng hồ Big Ben, Đấu trường La Mã |
| 9 | `chau-my-uc` | Châu Mỹ & châu Úc | Tượng Nữ thần Tự do, Nhà hát Opera Sydney, Machu Picchu, Tượng Chúa Cứu Thế, Thác Niagara |

Tổng: 47 mục, 47 ảnh địa danh/cảnh vật.

**Bản đồ hình chữ S (cấp 3) bắt buộc có quần đảo Hoàng Sa và Trường Sa** (quy định về bản đồ ở Việt Nam). Ảnh phải thấy rõ hai quần đảo, dù ảnh không có chữ; chủ dự án kiểm riêng ảnh này. *(Quyết định của người viết spec.)*

Câu kể: tối đa khoảng 15 từ, chỉ nói điều nhìn thấy được và ở đâu (ví dụ "Hồ Gươm ở Hà Nội. Giữa hồ có Tháp Rùa."). Không có số năm, không nhắc chiến tranh, chính trị hay tôn giáo. **Toàn bộ chữ phải được chủ dự án duyệt trước khi phát hành** (spec: "nhẹ, duyệt kỹ"); builder gom vào một bảng để duyệt.

### 5.3 Dạng câu hỏi

Mỗi lượt 5 câu, mỗi câu **3 ảnh để chọn** (giống số lựa chọn của Tiếng Anh; ảnh minh họa 2×2 lúc trao đổi chỉ là phác thảo):

1. **Chạm ảnh đúng** (`pickImage`): Chíp đọc "Đâu là Vịnh Hạ Long?" → 3 ảnh.
2. **Nghe kể rồi chọn** (`listenClue`): Chíp đọc gợi ý "Nơi này có rất nhiều đảo đá giữa biển xanh." → 3 ảnh.

Cấp 1–3 chỉ dùng dạng 1; từ cấp 4 trộn cả hai dạng, khoảng một nửa mỗi dạng.

Dạng "ghép ảnh với tên" đã nêu lúc trao đổi **bị bỏ** vì bé 3–6 tuổi chưa đọc được tên; cả hai dạng còn lại đều chọn bằng ảnh, không cần biết chữ.

Luật chung, như Tiếng Anh:
- Chọn sai: ảnh rung, Chíp động viên và đọc lại câu hỏi; bé chọn tiếp.
- Chọn đúng: Chíp vui, đọc tên địa danh rồi đọc câu kể, sau đó sang câu kế.
- Ba ảnh trong một câu là ba mục khác nhau, cùng cấp; trong 5 câu một lượt không lặp đáp án đúng khi cấp còn đủ mục. Builder quyết cách tránh lặp khi cấp chỉ có 5 mục.
- Lên/lùi cấp theo `nextLevelIndex` (`lib/math/level_rule.dart`), tính theo số câu đúng ngay lần đầu, giống ba môn kia; chỉ ghi khi bé học đúng cấp hiện tại (giống `PracticeEnglishScreen`).
- Nút loa đọc lại câu hỏi.

Giọng đọc `vi-VN`. Tên nước ngoài đọc theo cách người Việt quen gọi ("Tháp Ép-phen", "Kim tự tháp"). Builder thử trên giọng máy và ghi lại tên nào đọc sai để viết theo phiên âm trong chuỗi đọc (chuỗi hiển thị vẫn giữ tên chuẩn).

### 5.4 Màn hình

- **Sảnh `/kham-pha`** (màn mới): tiêu đề "Đảo Khám phá", nút quay về, 3 thẻ đảo dùng `raisedDecoration` + `Pressable`. Điện thoại: 3 thẻ xếp dọc hoặc 1 + 2; tablet: 3 thẻ một hàng. Rẽ nhánh tablet ngay trong file.
- **Bản đồ `/subject/dia-ly`**: làm theo `english_map_screen.dart` (9 ô, ô đã qua/đang học bấm được, ô sau khóa).
- **Màn học**: làm theo `english_session_screen.dart` (đầu màn `SessionHeader`, Chíp + bong bóng lời, khu chọn). Khu chọn là 3 thẻ ảnh ≥ 96 trên điện thoại, ≥ 140 trên tablet; tablet ngang đặt Chíp bên trái, ảnh bên phải như Tiếng Anh.
- **Trang chủ**: thêm thẻ rộng dưới `_SubjectGrid` ở `home_screen.dart` và `home_tablet.dart`. Phải lọt vào ngân sách chiều cao hiện có (`_fits`, chế độ gọn khi chiều cao an toàn < 700). Trang chủ điện thoại vốn đã là danh sách cuộn được: trên iPhone 375×667, 4 thẻ môn vẫn phải nằm trọn phía trên thanh điều hướng (test hiện có), còn thẻ khám phá có thể nằm dưới và cuộn tới. Trên iPad ngang, thẻ khám phá là thẻ thứ 5 trong cùng hàng môn, để không đổi ngân sách chiều cao. Kiểm bằng `tools/shot/home_shot_test.dart`.

### 5.5 Dữ liệu và lưu trữ

- Nội dung viết bằng Dart như Tiếng Anh: thư mục mới `lib/explore/` gồm `geography_level.dart` (danh sách cấp + mục), `geography_question.dart`, `geography_generator.dart` (có tham số `Random` để test).
- Cấp lưu trong bảng `subject_levels` có sẵn với khóa môn `'dia-ly'`. **Không đổi schema drift.**
- `LevelRepository`: thêm `recordGeographySession`; thêm `geographyLevelIndexProvider`, nối vào `homeSummaryProvider`, `refresh_after_sync.dart` và `ref.listen` trong `app.dart` như `englishLevelIndexProvider`.
- Đồng bộ: bản ghi `level` trong `sync_store.dart` đã chung cho mọi môn. Builder kiểm lại không có danh sách môn cứng nào chặn `'dia-ly'`, ở app lẫn máy chủ (danh sách trắng loại bản ghi).
- Màu môn: thêm `Subject.diaLy(color, tint)` trong `tokens.dart`, chọn màu khác 4 màu hiện có (gợi ý xanh biển sâu/ngọc lam). Chữ trắng trên màu chính phải đạt ≥ 4.5:1, có test `contrastRatio`.

### 5.6 Góc ba mẹ

Tab Tiến bộ (`lib/parent/screens/progress_tab.dart`): thêm thẻ "Địa lý" giống `_EnglishCard` ("Đang học: <tiêu đề cấp>", "n/9"). Cập nhật bố cục tablet `parent_home_tablet.dart` nếu thẻ được xếp theo lưới.

### 5.7 Ảnh cần làm

- 47 ảnh mục (§5.2), khung vuông, mô hình thu nhỏ đặt trên một mảng đất/đế tròn, cùng góc nhìn từ trên chéo xuống, cùng ánh sáng; không chữ, không người thật nhận diện được.
- 1 ảnh thẻ "Đảo Khám phá" (hòn đảo nhỏ có la bàn/quả địa cầu), 3 ảnh đảo trong sảnh (Địa lý; Sinh học và Lịch sử có thể để mờ/khóa).
- Câu lệnh Gemini và danh sách tên file ghi vào `docs/phase0/asset-list.md`; tách nền bằng `chroma_key.py`.
- Code làm trên **ảnh tạm** sinh bằng `tools/assets/make_placeholders.py` (vẫn đạt `assets_test`); ảnh thật thay vào ở một bước riêng.
- **Cổng phát hành:** thẻ "Đảo Khám phá" trên trang chủ chỉ hiện khi bật một hằng số trong code (mặc định tắt). Chỉ bật sau khi chủ dự án duyệt toàn bộ chữ (§5.2) và ảnh thật đã thay xong. Nhờ vậy gộp vào `chipchip` sớm mà ảnh tạm hay chữ chưa duyệt không tới tay bé. Test chạy với cả hai trạng thái. *(Quyết định của người viết spec.)*
- Trước khi sinh cả bộ: làm **3 ảnh mẫu** (Hồ Gươm, Vịnh Hạ Long, Tháp Eiffel) để chủ dự án duyệt phong cách, giống "Giai đoạn 0 — cổng duyệt ảnh mẫu" của đợt đua tên lửa.

### 5.8 Những gì cố ý chưa nối

- **Bài hôm nay**: không thêm Địa lý, giữ bài khoảng 10 phút như hiện tại (Tiếng Anh cũng chưa có trong Bài hôm nay).
- **Đua tên lửa**: `subject_picker.dart` vẫn chỉ có Toán và Tiếng Việt; Địa lý vào trò chơi ở dự án trò chơi thứ hai.
- **Sưu tập (sticker học tập, giấy khen)**: đợt này **không** thêm sticker hay giấy khen cho Địa lý. Giữ nguyên 12 sticker và 6 giấy khen cùng các test đếm số lượng. "Trạng nguyên nhí" vẫn tính trên 4 môn lõi: Địa lý là môn trên Đảo Khám phá, không phải môn lõi, nên lời khen "giỏi đều cả 4 môn" vẫn đúng và bé đã có sticker không bị khóa lại. Tiếng Anh có sticker `en_lv3` và giấy khen `cert_english`; nếu muốn Địa lý cũng có thì làm ở đợt sau, khi đã có ảnh thật. *(Quyết định của người viết spec, chờ chủ dự án xác nhận.)*

## 6. Kiểm thử

- Generator: mỗi cấp sinh đúng 5 câu, mỗi câu 3 lựa chọn khác nhau, đáp án đúng nằm trong lựa chọn, cấp 1–3 chỉ có `pickImage`, cùng seed ra cùng kết quả.
- Dữ liệu: mỗi mục có tên, câu kể, gợi ý không rỗng; mỗi đường dẫn ảnh có trong `AppImages` và có file thật (`assets_test.dart`).
- Widget: màn học (chọn sai rồi chọn đúng, gọi `onCompleted` với số đúng ngay lần đầu), sảnh ("Sắp có" hiện toast), bản đồ (ô khóa/mở), trang chủ có thẻ rộng trên điện thoại nhỏ / điện thoại thường / iPad dọc và ngang mà không tràn.
- Repository: ghi cấp `'dia-ly'` lên/lùi đúng luật; đồng bộ một bản ghi `level` của `'dia-ly'` qua lại.
- Tương phản màu `Subject.diaLy`.

## 7. Để lại cho người làm

- Tên class, cách chia file, part file.
- Bố cục chính xác của sảnh trên điện thoại.
- Cách tránh lặp đáp án khi cấp chỉ có 5 mục.
- Màu cụ thể của `Subject.diaLy` (trong ràng buộc tương phản).
- Cách gộp tiến độ trên thẻ rộng khi có thêm môn.
