# Giai đoạn 2B-1 — Đua tên lửa (chơi một mình, không cần mạng) — Thiết kế

> Phần 2B chia đôi (chủ dự án đã đồng ý): **2B-1** = trò chơi chạy trên máy, không cần mạng (tài liệu này); **2B-2** = máy chủ Java + phòng đua bằng mã mời, thiệp mời, đua với bóng của bạn (thiết kế riêng sau). Spec gốc: `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` §5.2. Trạng thái dự án: `docs/PROJECT_STATE.md`. Bản vẽ đã duyệt: trang thiết kế (Design canvas) "Phong cách lai Fun Edu", hàng **Bản 7** (Góc Chơi, Đua với Chíp, Phòng đua, Xưởng độ) — https://claude.ai/artifact/4ARDzEvtmu8NuYNJtuEq4o

## 1. Ý định và lý do

"Đua tên lửa" là **một cách học thêm mà bé tự chọn** (không phải phần thưởng bắt buộc sau bài, không thay "Bài hôm nay"). Mỗi câu trả lời đúng đẩy tên lửa lên; về đích trước thì thắng. Mục tiêu: bé **muốn quay lại** và (ở 2B-2) **muốn rủ bạn** — bằng niềm vui, không bằng áp lực.

2B-1 đem lại ngay: nút "Chơi" trên thanh điều hướng có nội dung thật; bé đua với Chíp Chíp; độ tên lửa của riêng mình.

## 2. Mục tiêu, không làm, không được làm

**Mục tiêu**
- **Góc Chơi** (tab "Chơi"): thẻ lớn "Đua tên lửa" → "Đua với Chíp"; ô "Xưởng độ tên lửa" (số món mới); ô "Mời bạn đua" / "Nhập mã" hiện nhưng báo "Sắp có" (làm ở 2B-2).
- **Đua với Chíp**: 10 câu Toán theo đúng cấp Toán hiện tại của bé (bộ sinh câu hỏi có sẵn), dạng **chọn đáp án** (3 phím đáp án to, mỗi phím một màu). Tên lửa bé và tên lửa Chíp leo lên đường đua 2,5D về hành tinh đích.
- **Sao chổi tăng tốc**: một số câu là "câu sao chổi" — trả lời đúng thì bay vọt 2 nấc.
- **Chíp đua vừa sức**: tốc độ Chíp tự điều chỉnh theo tốc độ trả lời của chính bé, để trận thường sát nút; bé trả lời đúng đều đặn thì thắng.
- **Về đích**: màn kết quả (thắng/thua), sao nhận được — **thua vẫn được sao** (spec), nút "Đua lại" / "Về nhà".
- **Xưởng độ tên lửa** (chủ dự án chốt): 2 loại món — **Tên lửa** (chọn một trong 4 tên lửa 3D nguyên chiếc: cam, xanh dương, xanh lá, tím) và **Vệt khói/lửa** (vẽ bằng code: lửa thường, khói cầu vồng, sao lấp lánh, …); mở món bằng cách đua đủ số trận; chọn món; tên lửa đã chọn hiện trong trận và ở Góc Chơi. Cánh/Mũi lắp rời để sau, khi có bộ ảnh bộ phận cùng góc nhìn.
- **Chuyển động thật và mượt** (yêu cầu của chủ dự án): lửa đẩy nhiều lớp lập lòe, khói phun và tan, tên lửa vọt lên có gia tốc và rung nhẹ, mây trôi nhiều lớp tạo chiều sâu, phím bấm lún. **60 khung hình/giây** trên điện thoại tầm trung và iPad, đo bằng `flutter run --profile`.
- **Hình 3D**: bộ ảnh đất sét/đồ chơi nhám chủ dự án đã tạo (`docs/superpowers/specs/assets/generated/game-rocket/`, danh sách ở `game-rocket-gallery.md`), tách nền đưa vào app.
- Điện thoại và iPad (dọc + ngang) theo quy tắc tablet hiện có.

**Không làm (để sau)**
- Phòng đua qua mạng, mã mời, thiệp mời, đua với bóng, sticker cảm xúc gửi cho bạn (2B-2).
- Câu hỏi Viết/chữ cái trong trận (cần ô viết lớn; cân nhắc ở chế độ khác sau).
- Âm thanh/hiệu ứng tiếng (app chưa có gói âm thanh; đề xuất riêng sau). Giọng đọc câu hỏi dùng `Speaker` có sẵn.
- "Hành tinh của tuần", "Đua cả nhóm".

**Không được làm (dù chạy được vẫn là thất bại)**
- Cơ chế gây áp lực: mất chuỗi, trừ sao, đếm ngược ép quay lại, thông báo giục bé. Thua không bị phạt.
- Bán món độ bằng tiền thật hoặc bằng sao mua được.
- Chuyển động giật, tụt khung hình, nóng máy; hoặc hiệu ứng làm bé không đọc được câu hỏi.
- Thời gian chơi **lọt ra ngoài** giới hạn giờ ba mẹ đặt (thời gian chơi phải được tính như mọi màn của bé; hết giờ/giờ ngủ thì không vào được trận).
- Cần mạng.

## 3. Ràng buộc

- Mọi quy tắc trong `AGENTS.md` (Flutter 3.24.5, **không thêm gói**, token màu, `raisedDecoration`/`Pressable`, tablet riêng, ≥ 64/80, tương phản ≥ 4,5, chuỗi tiếng Việt, analyze + test sạch, đổi bảng drift thì tăng `schemaVersion` + migration).
- Ảnh chỉ qua `lib/ui/assets.dart`; ảnh mới tạo bằng script trong `tools/assets/` (có cấu hình, tạo lại được), không sửa tay.
- Giới hạn giờ/giờ ngủ (`ScreenTimeGuard`) áp dụng như mọi màn của bé.
- Chuyển động tôn trọng cài đặt "giảm chuyển động" của máy (`MediaQuery.disableAnimations`): khi bật thì giữ lửa tĩnh, bỏ rung.

## 4. Các cách đã cân nhắc

| Cách | Được | Mất |
|---|---|---|
| **Hình 3D vẽ sẵn (ảnh) trên khung 2,5D, chuyển động bằng code** | Nhẹ, mượt, đồng bộ Chíp Chíp 3D, không thêm gói | Mô hình không xoay tự do |
| 3D thật dựng khi chạy (bộ máy 3D) | Xoay camera tự do | App nặng, tốn pin, phải làm mô hình 3D, thêm gói lớn |

**Chủ dự án chọn: hình 3D vẽ sẵn + khung 2,5D.** Phong cách cũng đã qua các vòng: phẳng → nét sáp 2D → 2,5D → **3D đất sét trên khung 2,5D (Bản 7)**.

Máy chủ cho phòng đua: chủ dự án chọn **Java Spring Boot tự chạy trên máy Oracle** (dùng ở 2B-2, không thuộc tài liệu này).

## 5. Những điều chủ dự án đã quyết

- Trò chơi là cách học thêm bé tự chọn.
- Chơi chung = phòng qua mạng bằng mã mời (2B-2), **không** chơi chung một máy.
- Bộ cơ chế: độ tên lửa, sao chổi tăng tốc, thiệp mời (2B-2), đua với bóng (2B-2). Không gây nghiện kiểu ép buộc.
- Phong cách Bản 7; chuyển động phải thật, mượt; lửa đẩy nhiều lớp có quầng sáng và khói.
- Sticker cảm xúc Chíp Chíp là bộ riêng, dễ thương (dùng ở 2B-2).

## 6. Đề xuất của mình (chủ dự án có thể sửa khi đọc)

1. **Trận đua**: 10 câu; câu thứ 3, 6, 9 là câu sao chổi (đúng = +2 nấc, các câu khác +1); đích = 10 nấc nên bé có thể về đích sớm hơn câu thứ 10. Sai thì tên lửa rung nhẹ, bé chọn lại (không lùi). Câu hỏi đọc to khi xuất hiện, có nút "Nghe".
2. **Chíp vừa sức**: Chíp tiến 1 nấc sau mỗi khoảng thời gian bằng ~1,25 lần thời gian trả lời trung bình của bé trong trận (khởi đầu theo thời gian trung bình của bé ở các trận trước, mặc định 6 giây); không bao giờ vượt bé quá 2 nấc; không có câu sao chổi.
3. **Sao**: về nhất 5 sao, về nhì 3 sao; ghi vào sổ sao chung như bài học (để Góc ba mẹ thấy). Không tính là "ngày học" (ngày học vẫn chỉ tính "Bài hôm nay").
4. **Xưởng độ**: Tên lửa — cam có sẵn, xanh dương mở ở 1 trận, xanh lá 3 trận, tím 6 trận; Vệt — lửa thường có sẵn, cầu vồng 2 trận, sao lấp lánh 5 trận, lửa xanh 8 trận. Lưu món đã chọn và tổng số trận theo từng bé (bảng mới, `schemaVersion` 7). Tên lửa trắng của Chíp Chíp chỉ dành cho Chíp.
5. **Chuyển động** (code, không thêm gói): lửa = vẽ bằng `CustomPainter` nhiều lớp (lõi trắng, giữa vàng, ngoài cam→đỏ mờ dần, quầng sáng) với nhiễu theo thời gian để lập lòe + hạt khói phun ra rồi tan; tên lửa dịch chuyển bằng đường cong lò xo, lửa bùng dài lúc vọt; mây 2–3 lớp trôi khác tốc độ; sao chổi bay ngang có vệt sáng. Mỗi lớp động trong `RepaintBoundary` riêng; một `Ticker` cho cả cảnh.
6. **Ảnh mây và lửa-khói** hiện bị lỗ khi tách nền (nền trắng): dùng mây vẽ bằng code theo kiểu 2,5D cho tới khi chủ dự án tạo lại ảnh trên nền xanh lá; lửa luôn vẽ bằng code (không dùng ảnh).
7. **iPad**: ngang = đường đua bên trái, câu hỏi bên phải; dọc = như điện thoại nhưng to hơn.

## 6b. Chi tiết đã chốt sau lượt rà soát của người làm (mình quyết)

- **Giới hạn giờ:** thời gian trong trò chơi **được tính** vào giới hạn giờ và giờ ngủ như mọi màn của bé (không thêm đường dẫn miễn trừ).
- **Dạng câu hỏi trong trận:** chỉ dùng câu có đáp án là một số và đưa về **3 phím số**: câu đếm (hiện hình để đếm rồi chọn số), câu cộng/trừ, câu ghép số. Câu so sánh (đáp án trái/phải) **không dùng** trong trận — bộ sinh bỏ qua và lấy câu khác cùng cấp. Trận đua **không** làm đổi cấp Toán của bé.
- **Sao và ngày học:** kết quả trận lưu vào **bảng mới** `race_results` (bé, lúc xong, hạng, số câu đúng ngay lần đầu, sao) trong cùng migration `schemaVersion` 7 với bảng món độ. Tổng sao của bé = sao bài học + sao trận đua; "ngày học trong tuần" vẫn chỉ tính bài học. Góc ba mẹ (Tiến bộ) thêm một dòng "Đua tên lửa: N trận".
- **Đếm trận để mở món:** tính theo từng bé; trận thua vẫn tính; bỏ ngang giữa trận thì không tính và không có sao.
- **Vào trò chơi:** cùng luật điều hướng như các màn khác (bé chưa xếp cấp thì vào bài xếp cấp trước).

## 7. Để lại cho người làm

- Cách tổ chức mã trò chơi (thư mục `lib/game/` hoặc `lib/features/game/`), tách logic trận đua (thuần Dart, test được) khỏi phần vẽ.
- Thông số cụ thể của chuyển động (thời lượng, đường cong, mật độ hạt) — tiêu chí là mượt, thật, không rối mắt.
- Cách đo hiệu năng và chứng cứ (ghi số khung hình ở chế độ profile vào báo cáo; nếu không chạy được trên máy thật thì nói rõ).

## 8. Xong khi

- Bé vào tab "Chơi" → đua với Chíp → về đích → nhận sao → mở món → lắp món → thấy tên lửa mới trong trận sau; mọi thứ chạy không cần mạng.
- Logic trận đua có test (tiến nấc, sao chổi, Chíp vừa sức, sao, mở món); màn hình có test widget cho điện thoại và iPad.
- `flutter analyze` sạch, toàn bộ test đạt; `docs/PROJECT_STATE.md` cập nhật mục 6–8.
