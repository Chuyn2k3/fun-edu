# Tài liệu Thiết Kế: Cải Tiến Toàn Diện Trò Chơi Đua Tên Lửa (Rocket Race Arcade Overhaul)

- **Ngày lập**: 2026-11-17
- **Nhánh**: `chipchip`
- **Mục tiêu**: Lột xác trải nghiệm trò chơi Đua Tên Lửa từ một "bài trắc nghiệm có ảnh động nền" thành một tựa game đua phi thuyền Arcade kịch tính, lôi cuốn, phản hồi xúc giác mạnh mẽ, đồ họa bắt mắt chuẩn lứa tuổi mầm non (3–6 tuổi).

---

## 1. Vấn đề Hiện Tại & Mục Tiêu Cải Tiến

### 1.1. Hiện trạng
- **Giao diện (UI Layout):** Màn hình bị chia đôi 50/50 theo chiều ngang. Đường đua bị bó hẹp ở nửa trên, nửa dưới là khung thẻ câu hỏi màu kem to chiếm diện tích lớn, tạo cảm giác như một bài kiểm tra trắc nghiệm hơn là một cuộc đua.
- **Hiệu ứng chuyển động (Game Feel & Juice):** Trả lời đúng thì tên lửa chỉ nhích nhẹ 1 nấc bằng lò xo tuyến tính đơn giản; không có gia tốc, không có rung lắc màn hình, không có vệt sáng tốc độ hay cảm giác xé gió.
- **Cơ chế chơi (Gameplay Mechanics):** Thiếu tính cạnh tranh tương tác. Chíp di chuyển đều đặn theo timer cố định; không có cơ chế combo, không có sự kiện/vật phẩm bất ngờ trên đường đua.

### 1.2. Mục tiêu đạt được
1. **Toàn màn hình không gian (Full-bleed Viewport):** Mở rộng sân đua chiếm 72–75% màn hình với góc nhìn vũ trụ sâu thẳm, thẻ câu hỏi và phím bấm nổi nhẹ (Floating Cockpit HUD) ở đáy màn hình.
2. **Cảm giác lái bùng nổ (Anticipation & Explosive Burst):** Hiệu ứng giật lùi lấy đà (80ms), phóng vọt bứt phá (`Curves.easeOutBack`), vệt sáng tốc độ ánh sáng (Warp Speed Lines), khói cuộn dày và rung nhẹ màn hình (Micro Screen Shake 2–3px).
3. **Cơ chế rượt đuổi kịch tính (Neck-and-neck Rubberbanding):** Chíp bám sát đuôi hoặc vượt nhẹ lên khi bé chần chừ, bé bấm đúng sẽ phóng vọt tạt đầu vượt mặt Chíp; cú bứt phá ở 2 câu cuối luôn bảo đảm chiến thắng vẻ vang cho bé.
4. **Hệ thống Combo Nitro & Vật phẩm:** Đúng 2 câu liên tiếp kích hoạt Nitro Siêu Tốc (lửa cầu vồng, phóng vọt 1.5 nấc); nhặt Sao May Mắn ở nấc 4 và 8 thưởng thêm sao vũ trụ.

---

## 2. Thiết Kế Chi Tiết

### 2.1. Bố Cục Giao Diện Mới (Floating Cockpit HUD)
- **Sân đua vũ trụ (Canvas):**
  - Chiếm 100% diện tích màn hình nền; không còn mảng nền kem ngăn cách.
  - Đường đua 2.5D được cân chỉnh lại tỷ lệ phối cảnh để đoạn nấc 7→10 không bị co ngắn đột ngột.
  - Hành tinh đích to đẹp ở phía xa, sao trời và mây thị sai lướt nhẹ.
- **Thẻ câu hỏi nổi (Floating Question Banner):**
  - Nằm ở tầng trên của canvas (lơ lửng tại 25–28% đáy màn hình).
  - Nền kính mờ mềm (`BackdropFilter` mờ nhẹ 8px + viền bo cong nổi khối 3D đồ chơi đất sét).
  - Phép tính, số lượng sao đếm, hoặc ký tự chữ cái hiển thị to, tương phản cao (≥ 4.5:1).
  - Tích hợp thanh đo nấc năng lượng Nitro ngay trên mép trên thẻ câu hỏi.
- **3 Phím bấm Arcade (Touch Keys):**
  - Đặt ở đáy màn hình, kích thước lớn an toàn cho bé (chiều cao ≥ 64pt trên điện thoại, ≥ 80pt trên iPad).
  - Hiệu ứng `raisedKeyDecoration` nổi khối rõ nét.
  - **Bấm đúng:** Nút phát sáng hào quang (glow), dấu tích $\checkmark$ bật nảy 380ms.
  - **Bấm sai:** Nút rung lắc nhẹ kèm hiệu ứng "hụt ga", âm thanh Chíp nhắc "Thử lại nhé!", nhưng không khóa màn hình hay ngắt quãng nhịp đua.

### 2.2. Động Lực Học Tên Lửa & Hiệu Ứng Hình Ảnh (Kinematics & FX)
1. **Kinematics (Chuyển động):**
   - **Giai đoạn lấy đà (Anticipation - 80ms):** Tên lửa thụt lùi xuống 6px, ngọn lửa nén ngắn lại như lò xo bị ép.
   - **Giai đoạn bứt phá (Burst - 400ms):** Tên lửa bắn vọt về phía trước theo đường cong `Curves.easeOutBack`, vượt qua đích đến một chút rồi nhún lại nấc mới.
2. **Hiệu ứng tia sáng xé gió (Warp Speed Lines):**
   - Trong 450ms bứt tốc, xuất hiện 8–12 vệt sáng thẳng đứng mờ ảo lướt nhanh dọc 2 bên viền màn hình (vẽ bằng `CustomPainter` tối ưu, không tốn tài nguyên GPU).
3. **Nền thị sai tăng tốc (Dynamic Parallax):**
   - Tốc độ trôi của mây và sao hậu cảnh tăng gấp 3 lần trong lúc bứt tốc, tạo ảo giác phi thuyền đang thực sự tăng tốc độ bay.
4. **Rung nhẹ màn hình (Micro Screen Shake):**
   - Dao động ngẫu nhiên 2–3px theo hàm $\sin$ suy giảm trong 200ms khi bứt tốc hoặc khi kích hoạt Nitro.
5. **Chế độ trợ năng (Reduce Motion):**
   - Khi hệ điều hành hoặc cài đặt bật "Giảm chuyển động": tự động tắt rung màn hình và vệt xé gió, chỉ giữ lại hiệu ứng phóng tên lửa mượt mà không giật lắc.

### 2.3. Thuật Toán Rượt Đuổi (Neck-and-neck Rubberbanding)
- **Vị trí của Chíp ($P_{chip}$):** Được tính toán linh hoạt dựa theo vị trí của bé ($P_{kid}$) và trạng thái làm bài:
  - **Bé trả lời đúng nhanh:** Chíp bám sát đuôi ở khoảng cách $P_{kid} - 0.5$ nấc, lửa Chíp cũng bùng lên cố gắng bám đuổi.
  - **Bé dừng lại suy nghĩ / bấm sai:** Sau mỗi 3 giây bé chưa trả lời đúng, Chíp nhích lên 0.4 nấc (tối đa không bao giờ vượt quá $P_{kid} + 1.2$ nấc). Chíp ngoái đầu lại nháy mắt trêu đùa.
  - **Bé trả lời đúng:** Tên lửa bé bứt phá vượt qua Chíp với hiệu ứng gió cuộn tạt đầu đối thủ.
  - **Đoạn kết (Nấc 8–10):** Tốc độ Chíp tự động giảm 30% để đảm bảo cú bứt phá câu 9, 10 luôn đưa bé về đích đầu tiên.

### 2.4. Cơ Chế Combo Nitro & Sao May Mắn
- **Combo Streak:**
  - Đúng 1 câu: Tích lũy 1 điểm năng lượng (ngọn lửa bùng cam bình thường).
  - Đúng 2 câu liên tiếp: Kích hoạt **Nitro Siêu Tốc**! Ngọn lửa chuyển sang màu cầu vồng rực rỡ, tên lửa phóng vọt 1.5 nấc, tia sáng xé gió dày đặc.
  - Bấm sai: Streak về 0, tên lửa đứng yên tại chỗ (không bị lùi).
- **Sao May Mắn (Lucky Star Pickup):**
  - Tại nấc 4 và nấc 8, một viên sao vàng 3D lơ lửng giữa đường đua.
  - Khi tên lửa bé bay chạm vào: Sao nổ tung thành các tia sáng vàng lấp lánh, phát hiệu ứng âm thanh chúc mừng và cộng trực tiếp +1 sao vũ trụ vào kho thưởng trận đấu.

### 2.5. Cán Đích & Ăn Mừng (Victory Celebration)
- Khi chạm hành tinh đích (nấc 10):
  - Pháo hoa nở rộ toàn màn hình.
  - Tên lửa Chíp hạ cánh song song, Chíp xuất hiện với cử chỉ vỗ cánh cười vui mừng (dùng tạo hình chuẩn từ sticker `sticker_clap` vừa hoàn thành).
  - Hiển thị bảng tổng kết phần thưởng và huy hiệu.

---

## 3. Kiến Trúc Kỹ Thuật & Tác Động Mã Nguồn

### 3.1. Các tệp tin liên quan
1. `lib/game/scene/race_scene.dart`:
   - Bổ sung hiệu ứng `SpeedLinesPainter` (vệt sáng xé gió).
   - Thêm bộ điều khiển `ScreenShake` (rung vi sai).
   - Tinh chỉnh `TrackGeometry` để đoạn cuối đường đua thoáng và đều nhịp hơn.
   - Thêm lớp hiển thị vật phẩm `LuckyStarPickup` trên đường đua.
2. `lib/features/game/race_screen.dart`:
   - Tái cấu trúc layout: `RaceScene` làm nền full-screen (`Positioned.fill`).
   - Cụm `FloatingCockpitHUD` chứa câu hỏi và `AnswerKeys` đặt ở `Align(alignment: Alignment.bottomCenter)`.
3. `lib/game/engine/race.dart` & `race_controller.dart`:
   - Nâng cấp thuật toán `rubberbandChipStep()` theo vị trí của bé.
   - Bổ sung biến trạng thái `comboStreak` và cờ `isNitroActive`.
   - Bổ sung sự kiện `onCollectLuckyStar` tăng sao vũ trụ.

### 3.2. Ràng buộc & Tương thích
- **Flutter 3.24.5 / Dart 3.5**, không dùng package bên ngoài mới.
- Màu sắc và độ nổi tuân thủ nghiêm ngặt `AppColors`, `GameColors`, `raisedKeyDecoration`.
- Đảm bảo 60fps ổn định: Các hạt khói, tia sáng xé gió và mây tiếp tục vẽ qua `CustomPainter` / `drawRawAtlas`, không sinh widget mới mỗi frame.
- Giữ nguyên toàn bộ logic bảo vệ giờ chơi của phụ huynh (`ScreenTimeGuard`) và tính toàn vẹn của dữ liệu offline.

---

## 4. Kế Hoạch Kiểm Thử & Nghiệm Thu
1. **Kiểm tra UI & Bố cục:** Kiểm tra trên màn hình điện thoại (375x667, 390x844, 430x932) và iPad (ngang & dọc) không bị tràn pixel (zero overflow).
2. **Kiểm tra chức năng:**
   - Combo Streak kích hoạt đúng khi trả lời 2 câu đúng liên tiếp.
   - Bấm sai không làm lùi tên lửa, reset combo về 0.
   - Chíp bám đuổi nhịp nhàng, không vượt quá khoảng cách cho phép.
   - Nhặt Sao May Mắn cộng đúng số sao vào kết quả trận đấu.
3. **Kiểm tra hiệu năng & Trợ năng:**
   - Chế độ "Giảm chuyển động" (Reduce Motion) tắt sạch rung lắc và vệt xé gió.
   - Chạy `flutter analyze` sạch không lỗi, `flutter test` toàn bộ test suite đạt 100%.
