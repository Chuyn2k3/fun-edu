# Đại tu Fun Edu → app tập viết và học cho bé 3–6 tuổi (linh vật Chíp Chíp)

> Trạng thái: **đã được chủ dự án duyệt (2026-11-12).** Thay cho bản nháp cũ cùng tên. Công việc triển khai làm trên nhánh `chipchip`.
> Phạm vi của tài liệu này: tầm nhìn sản phẩm, khung chức năng, kiến trúc, lộ trình 6 giai đoạn (0–5), và **chi tiết giai đoạn 0–1**. Các giai đoạn 2–5 chỉ ở mức khung; mỗi giai đoạn sẽ có spec và kế hoạch riêng khi đến lượt.
> Quy ước: mọi mục dưới đây đã được chủ dự án đồng ý trong buổi trao đổi ngày 2026-11-12, trừ các mục ghi **[Mở]**.

## 1. Vì sao làm lại

- App hiện tại (nhánh `develop` bản mobile, nhánh `new-web` bản web tại `hocvui.ibme.edu.vn`) giao diện không thân thiện, ít chức năng, không có điểm khác biệt.
- Về kỹ thuật: 5 cơ chế quản lý state trộn lẫn, nhiều code chết và file trùng, nội dung nằm cứng trong từng màn, hai nhánh mobile/web lệch nhau, `tflite` không chạy trên web.
- App mẫu để đối chiếu: StarJar Quiz. Điểm mạnh của nó là giao diện đồng nhất và đẹp. Điểm yếu: gần như mọi hoạt động là "nhìn câu hỏi, chạm đáp án", không dạy và kiểm tra được việc **viết** — thứ ba mẹ bé mầm non lo nhất trước khi vào lớp 1.

## 2. Định vị sản phẩm

**Điểm khác biệt chính: bé tập viết bằng ngón tay, app chấm từng nét** (thứ tự, hướng, độ lệch so với mẫu chữ tiểu học). StarJar dựng quanh câu hỏi trắc nghiệm nên khó làm theo. Tập viết đi xuyên mọi môn: viết số trong Toán, chữ cái và từ trong Tiếng Việt, chữ in trong Tiếng Anh, cùng một bộ chấm nét.

- **Người dùng:** bé 3–6 tuổi (mở rộng đến hết lớp 1 / đầu lớp 2 theo trình độ). **Người trả tiền:** ba mẹ.
- **Theo trình độ, không theo tuổi.** Trẻ cùng tuổi chênh nhau rất nhiều. Tuổi chỉ dùng để chọn điểm bắt đầu.
- **Không quảng cáo.** Có doanh thu từ gói trả phí.

### Mục tiêu
1. Bé muốn mở app mỗi ngày (vòng thưởng hằng ngày, linh vật, sưu tập, thi đua).
2. Ba mẹ thấy bé tiến bộ thật, đặc biệt là chữ viết.
3. Giao diện đồng nhất, đẹp, ít chữ, dùng được khi bé chưa biết đọc (mọi hướng dẫn đều đọc bằng giọng nói).
4. Nội dung tách khỏi trò chơi; thêm nội dung không cần viết code mới.

### Không làm
- Quảng cáo, SDK theo dõi của bên thứ ba, bán sao hay tiền ảo bằng tiền thật.
- Chat gõ chữ giữa các bé, tường công khai kiểu mạng xã hội.
- Cơ chế gây áp lực (mất chuỗi ngày bị phạt).
- Thu tiền theo thời gian chơi.
- Game sao chép trò có sẵn (Dino Run, Sweep bị bỏ vì lo bản quyền).

## 3. Cấu trúc học

- **4 môn lõi**, mỗi môn là một thang cấp độ: **Viết, Tiếng Việt, Toán, Tiếng Anh**.
  - Viết: nét cơ bản → số 0–10 → chữ thường → chữ hoa, dấu thanh → vần và từ ngắn → chữ in tiếng Anh.
  - Tiếng Việt: nhận mặt chữ → âm → vần → ghép tiếng → đọc từ có hình, theo thứ tự bài sách Tiếng Việt 1.
  - Toán: đếm, so sánh, hình khối → cộng trừ phạm vi 10 → 20 → 100, đồng hồ, tiền đơn giản.
  - Tiếng Anh: chữ cái, phonics, từ theo chủ đề, nghe rồi chọn, viết chữ in.
- **Bài thử xếp cấp** dạng trò chơi khi bắt đầu, **xếp riêng từng môn**.
- **Tự điều chỉnh:** đúng liên tục thì lên cấp, sai nhiều thì lùi hoặc ôn thêm. Ba mẹ chỉnh tay được.
- **"Bài hôm nay"** khoảng 10 phút, app tự trộn: 1 bài viết, 1 bài môn khác, 1 bài ôn phần bé hay sai.
- **Môn mở rộng về sau** (giai đoạn 5): Sinh học, Địa lý, Lịch sử dưới dạng "đảo khám phá" (câu hỏi và trò chơi, không có phần viết). Kho câu hỏi thiết kế theo **môn → chủ đề → cấp** ngay từ đầu nên thêm môn chỉ là thêm nội dung.

## 4. Vòng giữ chân

> Bé mở app → **Bài hôm nay** (~10 phút) → nhận **sao** → nuôi **Chíp Chíp** và dán **sticker** → ba mẹ thấy bé tiến bộ, đổi sao lấy **phần thưởng thật** → hôm sau nhắc bé học tiếp.

Bé quay lại vì linh vật và bộ sưu tập. Ba mẹ ở lại vì thấy kết quả. Mọi chức năng phải phục vụ vòng này.

## 5. Khung chức năng

### 5.1 Phía bé
| Chức năng | Nội dung |
|---|---|
| Trang chính | Chíp Chíp, nút lớn "Bài hôm nay", 4 đảo môn học, thanh điều hướng dưới |
| Bản đồ môn | Mỗi môn là con đường qua nhiều trạm (cấp) |
| Viết | Tô theo đường mẫu, sau đó viết không cần mẫu. Chấm từng nét; sai thì Chíp Chíp vẽ mẫu lại. Nét bé viết hiện như nét sáp màu |
| Dạng bài dùng chung | Tô/viết, nghe rồi chọn, kéo thả để ghép, sắp xếp, chạm để đếm, điền chỗ trống |
| Phản hồi | Mỗi câu trả lời có hiệu ứng, âm thanh và Chíp Chíp phản ứng. Sai thì được gợi ý, không bị phạt |
| Chíp Chíp | Cho ăn bằng sao, lớn dần theo cấp, trang trí nhà |
| Sưu tập | Album sticker, thẻ hình. Mỗi bài xong mở một món |
| Lịch chuyên cần | Mỗi ngày học dán một sticker. Bỏ ngày không mất gì, Chíp Chíp chỉ "nhớ bé" |
| Vở của bé | Lưu các trang bé tự viết, ba mẹ xem tiến bộ và chia sẻ được |
| Giấy khen | Xong một cấp có giấy khen mang tên gọi ở nhà của bé |
| Trò chơi | Bộ máy chung "mỗi lượt là một câu hỏi" (mục 5.2) |

### 5.2 Trò chơi và chế độ phòng
Câu hỏi lấy từ kho chung **theo trình độ của từng bé**, nên trò nào cũng chơi được với mọi môn.

| Trò | Cách chơi | Giai đoạn |
|---|---|---|
| Đua tên lửa | Trả lời đúng thì tên lửa được đẩy lên, ai về đích trước thắng | 2 |
| Kéo co | Trả lời đúng thì kéo dây về phía mình | 3 |
| Xây tháp | Cả đội trả lời đúng để xây đủ cao trước khi hết giờ | 3 |
| Tàu chở hàng | Trả lời đúng thì nối thêm một toa | 3 |
| Bắn bóng bay | Chạm bóng có đáp án đúng trước khi bay mất | 3 |

| Chế độ | Mô tả | Giai đoạn |
|---|---|---|
| Một mình | Đua với đồng hồ hoặc với Chíp Chíp | 2 |
| Chung máy, đối kháng | 2–4 bé chia màn hình, mỗi bé câu hỏi theo cấp của mình. Chỉ dùng dạng chạm, chọn, kéo thả (không có câu viết vì màn hình chia nhỏ quá chật) | 2 |
| Chung máy, thay phiên hợp tác | Cùng đẩy một tên lửa, đến lượt ai người đó trả lời; có câu viết | 2 |
| Qua mạng | Phòng có mã do ba mẹ tạo, chỉ có biểu tượng cảm xúc có sẵn, chơi xong rủ chơi tiếp | 4 |

Bé thua vẫn nhận ít sao.

### 5.3 Góc ba mẹ (sau cổng xác nhận người lớn)
| Chức năng | Nội dung |
|---|---|
| Hồ sơ bé | Nhiều bé một nhà; mỗi bé có tên gọi ở nhà, ảnh đại diện có sẵn, tuổi. Không tên thật |
| Tiến bộ | Theo môn: chữ nào viết đúng nét, đang tập, chưa học; phần hay sai; thời gian học; báo cáo tuần |
| Giới hạn giờ | **Tính năng miễn phí.** Ba mẹ đặt số phút mỗi ngày (mặc định 30–60, tối đa 180) và giờ đi ngủ. Hết giờ thì Chíp Chíp đi ngủ |
| Phần thưởng thật | Ba mẹ tự đặt, ví dụ "đủ 50 sao thì đi công viên" |
| Điều chỉnh học | Giao bài, chỉnh cấp, bật tắt môn |
| In phiếu tập tô | Xuất PDF theo chữ bé đang yếu |
| Tự tạo bộ câu hỏi | AI gợi ý và cảnh báo chỗ nghi sai; ba mẹ duyệt; **chỉ bé trong gia đình đó chơi** (giai đoạn 3) |
| Bé khám phá | Ba mẹ đăng ảnh kèm câu hỏi ("Đây là chim gì?"); các bé trả lời và thả sticker có sẵn; **chỉ trong vòng kín các gia đình đã kết nối bằng mã** (giai đoạn 4) |
| Nhắc học | Thông báo cho ba mẹ vào giờ cố định |
| Gói và tài khoản | Mua gói, khôi phục giao dịch, tài khoản gia đình (từ giai đoạn 2) |

### 5.4 Hậu trường
- Backend Java (từ giai đoạn 2), trang quản trị nội dung (giai đoạn 3), công cụ ghi nét mẫu (giai đoạn 0), quy trình làm hình (giai đoạn 0), thống kê ẩn danh tự làm (từ giai đoạn 1).

## 6. Thu tiền

- **Gói năm (và có thể thêm gói tháng) mở toàn bộ môn và cấp**, kể cả cấp làm thêm sau này. Gói năm là chính.
- Chỉ ba mẹ mua được, qua cổng xác nhận người lớn. Trên iOS/Android phải mua qua Apple/Google (họ giữ 15–30%).
- **Không thu tiền theo thời gian chơi.** Giới hạn giờ là tính năng miễn phí cho ba mẹ.

| Miễn phí | Trả phí |
|---|---|
| Vài cấp đầu của mỗi môn | Toàn bộ cấp, kể cả cấp mới |
| Bài hôm nay, Chíp Chíp, sticker cơ bản | Đầy đủ đồ trang trí, toàn bộ trò chơi |
| 1 hồ sơ bé, tiến bộ cơ bản | Tối đa 4 bé, báo cáo chi tiết, in phiếu tập tô, đồng bộ nhiều máy |
| Giới hạn giờ, phần thưởng thật | Tự tạo bộ câu hỏi có AI gợi ý |

- **[Mở]** Giá gói năm/tháng; số "cấp đầu" miễn phí cụ thể của mỗi môn.

## 7. Nội dung

| Loại | Cách làm | Ai duyệt |
|---|---|---|
| Toán | Sinh câu hỏi bằng code theo quy luật, không cần AI | Không cần (đáp án luôn đúng) |
| Nét viết mẫu | Ghi bằng công cụ ghi nét theo mẫu chữ tiểu học: 29 chữ thường, 29 chữ hoa, dấu thanh, số 0–9, 26 chữ in tiếng Anh | Chủ dự án |
| Tiếng Việt, Tiếng Anh (từ, hình, giọng đọc) | AI sinh bản nháp, duyệt trên trang quản trị rồi mới đăng | Chủ dự án duyệt hằng ngày; **giáo viên rà phần âm vần trước khi bán (giai đoạn 2)** và rà lại khi ra môn hoặc cấp mới |
| Bộ câu hỏi riêng của gia đình | Ba mẹ tạo, AI gợi ý và cảnh báo | Ba mẹ (chỉ dùng trong gia đình) |

- AI kiểm tra "từ nguồn uy tín" chỉ là **gợi ý và cảnh báo**, không bảo đảm đúng. Bước duyệt luôn là con người.
- Mọi lời gọi AI đi qua backend; khóa không bao giờ nằm trong app.
- Giọng đọc: tạo sẵn bằng AI giọng tiếng Việt và tiếng Anh, đóng kèm vào app hoặc gói nội dung, chạy không cần mạng.

## 8. Phần nhìn

### 8.1 Phong cách: lai
- **Khung giao diện phẳng** (nút, thẻ, nhãn, điều hướng): vẽ bằng vector/Flutter.
- **Nhân vật, biểu tượng môn, phần thưởng, cảnh nền, ảnh bìa trò chơi: 3D mềm kiểu đồ chơi**, sinh bằng Gemini từ bộ mẫu gốc, xuất thành ảnh (không chạy 3D thật trong app). Linh vật cử động bằng cách chuyển giữa các tư thế có sẵn và hiệu ứng nảy/nhún bằng code.

### 8.2 Nguyên tắc giao diện (rút từ phân tích ảnh StarJar, không chép hình hay bố cục)
1. **Hình minh họa gánh vẻ đẹp**, khung giao diện tiết chế. Biểu tượng môn là vật thể 3D; thẻ trò chơi là tranh tràn viền có tiêu đề trắng đè lên.
2. **Nền sáng** có họa tiết rất mờ; đầu trang có cảnh minh họa mờ dần vào nền.
3. **Thẻ trắng, bo góc lớn, bóng đổ mềm và rộng, không viền.** Không dùng bóng cứng kiểu nút game.
4. **Một màu chính** cho trạng thái đang chọn. Màu từng môn chỉ dùng ở điểm nhấn (vòng tiến độ, biểu tượng): Viết cam, Tiếng Việt tím, Toán xanh dương, Tiếng Anh xanh lá.
5. **Chữ màu navy đậm** thay vì đen, tiêu đề rất to và đậm, chữ phụ xám xanh. Font bo tròn hỗ trợ tiếng Việt (Nunito hoặc Baloo 2).
6. Thanh điều hướng dưới nổi như viên thuốc; tab đang chọn là khối màu chính.
7. Nhãn nhỏ (cấp, sao, chuỗi ngày, phút hôm nay) là viên bo tròn có biểu tượng 3D nhỏ.
8. Nút cho bé ≥ 64 pt; mỗi màn hình một việc chính. Góc ba mẹ cùng màu và font nhưng trầm hơn, nhiều chữ hơn.
9. Chữ đạt độ tương phản 4.5:1; các trạng thái phân biệt bằng độ sáng, không chỉ bằng màu.

### 8.2a Bảng màu và chữ (đã chốt qua bản phác thảo thứ 2)
| Vai trò | Giá trị |
|---|---|
| Màu chính (nút chính, tab đang chọn) | Cam `#C8460F` (chữ trắng đạt 4.5:1); cam sáng `#E8590C` cho điểm nhấn, nút tròn lớn, thanh tiến độ |
| Nền | Kem `#FBF5EC` có chấm bi mờ `#EADFCF`; đầu trang là cảnh mây 3D mờ dần vào nền |
| Thẻ | Trắng `#FFFFFF`, bo 24–28 px, bóng `0 10–14px 24–32px rgba(80,60,40,0.09–0.12)` |
| Chữ | Navy `#22284A`; chữ phụ `#5B6385` |
| Màu môn (chỉ ở vòng tiến độ, nền ô biểu tượng) | Viết cam `#E8590C` / nền `#FFF0E4`; Tiếng Việt tím `#7C3AED` / `#F3EDFF`; Toán xanh dương `#2563EB` / `#E8F1FF`; Tiếng Anh xanh lá `#0F8A5F` / `#E5F7EF` |
| Font | Nunito, đậm 800–900 cho tiêu đề và nút |

Cam được chọn vì trùng màu khăn của Chíp Chíp và màu môn Viết, đồng thời khác StarJar (xanh).

Ảnh mẫu đã duyệt: `assets/icons-sheet.webp` (biểu tượng môn, sao, lửa, vương miện), `assets/bg-sky.webp` (cảnh đầu trang), `assets/cover-rocket.webp` (bìa Đua tên lửa). Bản phác thảo thứ 2 (trang chính, tập viết, xong bài, đua tên lửa) đã được chủ dự án duyệt; nó là mẫu tham chiếu cho bộ giao diện chung ở giai đoạn 0.

### 8.3 Linh vật: Chíp Chíp
- Chim sẻ con mũm mĩm, nâu kem, má hồng, **khăn quàng cam và bút sáp cam** (màu của môn Viết, gắn với điểm khác biệt "tập viết").
- Tên **Chíp Chíp** (gọi tắt "Chíp" trong lời thoại). **[Mở]** Tra trùng thương hiệu trước khi đặt tên app trên store.
- Ảnh mẫu đã duyệt: `assets/chipchip-main.webp`, bảng biểu cảm `assets/chipchip-expressions.webp`.
- 6 biểu cảm: vui nhảy, khen ngợi, ngạc nhiên, động viên khi sai, buồn ngủ (mũ ngủ cam, dùng khi hết giờ), đang viết. Tư thế "đang viết" cần tạo lại (bút cầm tự nhiên, có nét vẽ trên đất). Bản dùng thật: mỗi biểu cảm một ảnh riêng, độ phân giải cao nhất (≥ 800 px cho mỗi tư thế).

### 8.4 Quy trình làm hình
- Tạo trong cùng một cuộc chat Gemini, luôn gửi kèm ảnh mẫu gốc và một đoạn mô tả phong cách cố định ("soft 3D render, cute rounded toy-like shapes, smooth glossy plastic and soft clay materials, soft warm studio lighting, gentle shadows, vibrant soft pastel colors, plain pure white background, no text").
- Không ghi tên hãng/nhân vật có thật trong câu lệnh. Đọc điều khoản dùng ảnh thương mại của Google tại thời điểm dùng.
- Script (làm ở giai đoạn 0): cắt bảng lưới, tách nền trong suốt, nén, xuất đúng kích thước và quy ước tên file.

## 9. Kiến trúc

### 9.1 App di động: Flutter, dự án mới
- **Một** thư viện quản lý trạng thái: Riverpod. Điều hướng: go_router. Lưu trữ: SQLite qua drift.
- **Chạy đầy đủ không cần mạng.** Từ giai đoạn 2 đồng bộ lên máy chủ khi có mạng.
- Dựng trên nhánh `chipchip` (tách từ `new-web`); code cũ chỉ còn trong lịch sử git để tra cứu (ý tưởng trò Toán cũ, phần tạo PDF).

| Khối | Việc của nó | Phụ thuộc |
|---|---|---|
| Bộ chấm nét | Nhận nét bé vẽ + dữ liệu nét mẫu → kết quả từng nét: đúng thứ tự, đúng hướng, độ lệch. Chạy trên máy | Dữ liệu nét mẫu |
| Kho nội dung | Câu hỏi theo môn → chủ đề → cấp; gói nội dung tải về lưu trên máy; Toán sinh bằng code | Lưu trữ |
| Bộ xếp cấp | Bài thử đầu vào, lên/lùi cấp, soạn "Bài hôm nay" | Kho nội dung, Lưu trữ |
| Dạng bài | Mỗi dạng (tô/viết, nghe chọn, kéo thả, đếm...) chỉ nhận dữ liệu câu hỏi, không biết thuộc môn nào | Bộ chấm nét (với dạng viết) |
| Bộ máy trò chơi | Vòng "trả lời đúng thì tiến một bước", lấy câu hỏi theo trình độ từng người chơi | Bộ xếp cấp, Dạng bài |
| Phần thưởng | Sao, Chíp Chíp, sticker, lịch chuyên cần | Lưu trữ |
| Góc ba mẹ | Cổng người lớn, tiến độ, giới hạn giờ, phần thưởng thật | Các khối trên |
| Lưu trữ | SQLite trên máy; đồng bộ từ giai đoạn 2 | — |
| Bộ giao diện chung | Màu, chữ, khoảng cách, bo góc, bóng; linh kiện thẻ, viên nhãn, nút, thanh điều hướng | — |

### 9.2 Backend: Java, Spring Boot, PostgreSQL, máy chủ Oracle (24 GB RAM, 100 GB SSD)
- Giai đoạn 1: chỉ một **điểm nhận thống kê ẩn danh tối giản** (sự kiện "mở app", "xong bài"; không tài khoản).
- Giai đoạn 2: tài khoản gia đình, đồng bộ tiến độ, xác thực giao dịch Apple/Google, phát hành gói nội dung.
- Giai đoạn 3: AI sinh nội dung, AI gợi ý cho ba mẹ tạo câu hỏi, trang quản trị.
- Giai đoạn 4: WebSocket cho phòng chơi qua mạng, vòng kín Bé khám phá.
- Sao lưu cơ sở dữ liệu ra nơi khác (máy Oracle miễn phí có thể bị thu hồi và là điểm chết duy nhất).

### 9.3 Công cụ nội bộ
- Công cụ ghi nét mẫu: chế độ dành cho người phát triển trong chính app Flutter.
- Quy trình làm hình: mục 8.4.
- Trang quản trị nội dung: giai đoạn 3.

### 9.4 Web: React, giai đoạn 4, ban đầu chỉ góc ba mẹ.

## 10. Lộ trình

### Giai đoạn 0: thử nghiệm và nền móng
Làm theo thứ tự, rủi ro cao trước:
1. **Thử bộ chấm nét.** Định nghĩa dạng dữ liệu nét mẫu, làm công cụ ghi nét, ghi mẫu 5 nét cơ bản + số 0–3 + chữ a, b. Thử với bé thật trên điện thoại và máy tính bảng.
   **Đạt khi:** nét bé vẽ hơi xấu nhưng đúng được chấp nhận; sai thứ tự hoặc sai hướng bị bắt lỗi; số lần chấm sai một nét đúng dưới khoảng 1/10. Không đạt thì chỉnh thuật toán trước khi làm tiếp.
2. Dựng khung dự án Flutter mới (Riverpod, go_router, drift).
3. Bộ giao diện chung theo mục 8.2; chốt màu chính qua bản phác thảo thứ 2.
4. Script quy trình làm hình; tạo bộ ảnh độ phân giải cao cho giai đoạn 1.
5. Dọn dẹp:
   - **Mã gói:** repo đang dùng `com.example.fun_edu` (Android) và `com.example.funEdu` (iOS); Google Play không nhận mã `com.example`. **Đã chốt: app mới dùng mã `com.ibme.funedu`** cho cả Android và iOS.
   - **Khóa OpenAI:** `lib/feature/game_feature/game/sweep/game/data/envied/env.g.dart` đang được git theo dõi và `lib/helper/global.dart` có comment chứa khóa. Thu hồi khóa trên trang OpenAI (khóa đã nằm trong lịch sử git).

### Giai đoạn 1: bản cập nhật đầu (miễn phí hết, không cần mạng)
- Ba mẹ tạo hồ sơ bé → bài thử xếp cấp dạng trò chơi cho Viết và Toán.
- Trang chính: Chíp Chíp, "Bài hôm nay", 4 đảo (Tiếng Việt, Tiếng Anh hiện "Sắp có").
- Viết: nét cơ bản → số 0–10.
- Toán: đếm, so sánh, cộng trừ phạm vi 10 rồi 20; dạng bài chạm để đếm, nghe rồi chọn, kéo thả.
- Giọng đọc mọi hướng dẫn (tạo sẵn, đóng kèm).
- Phần thưởng: sao, album ~30 sticker, lịch chuyên cần, Chíp Chíp 6 biểu cảm.
- Góc ba mẹ: cổng người lớn, tiến độ Viết và Toán, giới hạn giờ, phần thưởng thật.
- Điểm nhận thống kê ẩn danh tối giản.
- **Xong khi:** phát hành và đo 4 tuần. Tỷ lệ quay lại sau 7 ngày ≥ 25% và số ngày học trung bình ≥ 3 ngày/tuần thì sang giai đoạn 2; thấp hơn thì sửa vòng giữ chân trước khi thu tiền.

### Giai đoạn 2–5 (mức khung)
| Giai đoạn | Nội dung chính | Con số đo |
|---|---|---|
| 2. Bắt đầu thu tiền | Backend Java, tài khoản gia đình, đồng bộ. Gói năm/tháng, khôi phục giao dịch. Viết chữ cái (thường, hoa, dấu thanh). Tiếng Việt âm vần theo sách Tiếng Việt 1 (giáo viên rà). Tối đa 4 hồ sơ bé, in phiếu tập tô. Bộ máy trò chơi + Đua tên lửa (một mình, chung máy đối kháng, chung máy thay phiên) | Tỷ lệ mua gói ≥ 3–5% trên gia đình dùng quá 7 ngày |
| 3. Làm sâu | Tiếng Anh. Toán đến 100, đồng hồ, tiền. Kéo co, Xây tháp, Tàu chở hàng, Bắn bóng bay. Nuôi và trang trí Chíp Chíp đầy đủ. Vở của bé, giấy khen, báo cáo tuần. Trang quản trị + AI sinh nội dung. Ba mẹ tự tạo bộ câu hỏi (chỉ trong gia đình) | Tỷ lệ gia hạn |
| 4. Mở rộng | Phòng chơi qua mạng. Bé khám phá (vòng kín). Truyện đọc to, bé đọc to và app chấm. Web cho ba mẹ (React) | Tăng người dùng |
| 5. Đảo khám phá | Sinh học, Địa lý, Lịch sử (nhẹ, duyệt kỹ) | Giữ chân lâu dài |

## 11. Đo lường
- Thống kê ẩn danh tự làm, không SDK bên thứ ba.
- Giai đoạn 1: tỷ lệ quay lại sau 7 ngày (≥ 25%); số ngày học trung bình mỗi tuần trên bé còn dùng (≥ 3).
- Giai đoạn 2: tỷ lệ mua gói trên gia đình dùng quá 7 ngày (≥ 3–5%).
- Chất lượng: tỷ lệ chữ "đang tập" chuyển sang "viết đúng nét".
- Các mục tiêu là mức khởi điểm, chỉnh lại khi có dữ liệu thật.

## 12. An toàn trẻ em và quyền riêng tư (áp dụng từ giai đoạn 1)
- Không quảng cáo, không SDK theo dõi/phân tích bên thứ ba; đáp ứng yêu cầu mục Kids của Apple và chương trình Families của Google.
- Không thu thông tin cá nhân của bé: không tên thật, không ảnh mặt, không vị trí. Hồ sơ bé chỉ có tên gọi ở nhà, ảnh đại diện có sẵn, tuổi.
- Mọi thứ liên quan tiền, cài đặt và liên kết ra ngoài nằm sau cổng xác nhận người lớn.
- Không chat gõ chữ; tương tác giữa các bé chỉ qua biểu tượng cảm xúc/sticker có sẵn.
- Ảnh ba mẹ đăng (giai đoạn 4): AI kiểm tra mặt người, chữ, biển số trước khi đăng; có báo cáo và chặn; chỉ trong vòng kín.
- Nội dung AI sinh luôn là bản nháp, con người duyệt rồi mới đến tay bé.
- Tuân thủ Nghị định 13/2023: ba mẹ đồng ý khi tạo hồ sơ bé; xóa được toàn bộ dữ liệu gia đình; chính sách quyền riêng tư bằng tiếng Việt.
- Không cơ chế gây áp lực, không bán sao, không tiền ảo mua bằng tiền thật.

## 13. App đang có trên store
- Cập nhật đè lên app cũ (giữ mã gói) nếu tìm được mã gói thật (mục 10, giai đoạn 0, bước 5). Đổi tên và ảnh trên store sang thương hiệu mới.
- **Không chuyển dữ liệu cũ**; bé làm bài thử xếp cấp lại. Người dùng cũ được tặng quà chào mừng (ví dụ trang phục đặc biệt cho Chíp Chíp). Ghi rõ trong phần "Có gì mới".

## 14. Việc còn mở
1. ~~Mã gói~~ — đã chốt `com.ibme.funedu`.
2. ~~Màu chính và màu nền~~ — đã chốt ở mục 8.2a.
3. **[Mở]** Giá gói năm/tháng; số cấp miễn phí mỗi môn (trước giai đoạn 2).
4. **[Mở]** Tra trùng thương hiệu "Chíp Chíp" và tên app trên store.
5. **[Mở]** Giáo viên nào rà nội dung Tiếng Việt (trước giai đoạn 2).
6. **[Mở]** Có cần vai trò thầy cô (tạo lớp, giao bài) không — hiện để sau giai đoạn 5.
