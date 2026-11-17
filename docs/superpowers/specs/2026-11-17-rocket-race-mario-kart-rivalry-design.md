# Đua Tên Lửa: Đột Phá Bám Đuổi & Vượt Mặt Kiểu Mario Kart (Design Spec)

- **Ngày tạo:** 2026-11-17
- **Nhánh:** `chipchip`
- **Trạng thái:** Chờ người dùng duyệt trước khi lập kế hoạch triển khai

---

## 1. Mục tiêu & Bối cảnh

### 1.1. Vấn đề hiện tại
- Hai tên lửa xuất phát ngang hàng và tịnh tiến song song từng bước một, tạo cảm giác "hai xe di di cạnh nhau đơn điệu, cùi bắp, không có tính đột phá hay kịch tính".
- Trẻ không nhận diện rõ đâu là đối thủ Chíp: Tên lửa của Chíp thiếu bản sắc và biểu cảm nhân vật; trẻ không có cảm giác mục tiêu "phía trước là bạn Chíp đang bay, mình phải trả lời đúng để vượt qua!".
- Cú bứt tốc thiếu tính bùng nổ: Thiếu khoảnh khắc so kè, vượt sườn (overtake) và phản ứng tương tác vui nhộn giữa hai đấu thủ.

### 1.2. Mục tiêu thiết kế
1. **Nhận diện đối thủ rõ ràng:** Trẻ vừa nhìn vào màn hình là thấy ngay bạn gà Chíp Chíp (vàng tươi, đeo kính phi công) đang lái tên lửa phía trước và vẫy tay khiêu khích.
2. **Cơ chế so kè Mario Kart (Dynamic Chase & Overtake):**
   - Chíp luôn giữ vai trò dẫn trước một đoạn ngắn để làm mục tiêu rượt đuổi.
   - Trẻ trả lời **ĐÚNG** $\to$ Tên lửa của bé kích hoạt phản lực Nitro cực đại, gầm rú lao vút lên **vượt mặt Chíp**.
   - Khoảnh khắc vượt mặt: Luồng khí động học làm tên lửa Chíp **xoay tít 360° tại chỗ (spin-out hài hước)** với biểu cảm mắt xoay tròn `@_@`, tụt lại phía sau.
   - Trẻ trả lời **SAI** hoặc chần chừ $\to$ Tên lửa của bé khựng nhẹ xì khói, Chíp phụt lửa vượt lên trước kèm tiếng còi trêu đùa "bim bim".
3. **Giữ nguyên 100% logic học & an toàn:**
   - 10 câu hỏi Toán / Tiếng Việt, chấm điểm, tích lũy sao vũ trụ, mở quà garage và huy hiệu không đổi.
   - Hoàn toàn offline, không SDK theo dõi, không quảng cáo.

---

## 2. Thiết kế Nhân vật & Phối cảnh

### 2.1. Phối cảnh 2.5D bám đuôi (Elevated Behind-the-Racer Cam)
- **Tên lửa của Bé (Player):** Nằm ở vị trí cận cảnh chính diện phía dưới (to, rõ buồng lái, đuôi lửa phản lực rực rỡ sát tầm mắt, ngay trên cụm buồng lái HUD).
- **Tên lửa của Chíp (Rival):** Bay ở làn bên cạnh nhưng chếch lên phía trước ($y_{chip} < y_{kid}$, khoảng 35–45pt phía trước theo chiều sâu không gian).
- **Đường đua:** Hút về phía hành tinh đích ở chân trời, với vạch phân làn và các mốc sao may mắn (mốc 4 và 8).

### 2.2. Tạo hình bạn Chíp Chíp lái tên lửa
- Buồng lái tên lửa của Chíp có vòm kính trong suốt, thấy rõ chú gà vàng Chíp Chíp đội mũ/kính phi công cầm vô lăng:
  - **Trạng thái 1 (Dẫn trước):** Chíp toe toét ngoái sang vẫy tay trêu chọc ("Đố bắt kịp Chíp đấy!").
  - **Trạng thái 2 (Bị vượt / Spin-out):** Tên lửa xoay 360°, hai mắt Chíp xoay tròn `@_@`, hai cánh đập loạn xạ ngộ nghĩnh.
  - **Trạng thái 3 (Rượt đuổi):** Chíp hai tay ghì vô lăng, mắt tập trung cao độ, tên lửa phụt khói cố gắng bám theo.

---

## 3. Cơ chế Kinematics & Hoạt họa (Gameplay Mechanics)

### 3.1. Trạng thái vị trí so kè (Relative Lead Offset)
Thay vì hai tên lửa có tọa độ phụ thuộc tuyệt đối vào số bước rời rạc song song, vị trí của Chíp và Bé được tính bằng:
$$y_{kid} = g.yAt(p_{kid})$$
$$y_{chip} = g.yAt(p_{chip}) - leadOffset$$

- Khi bắt đầu ván đấu hoặc Chíp đang dẫn: $leadOffset \approx 0.08$ (tương đương gần 1 nấc phía trước).
- Khi Bé trả lời đúng:
  1. $p_{kid}$ tăng vọt lên nấc mới.
  2. Vận tốc bứt tốc của Bé cao hơn bình thường (surge animation ~500ms).
  3. Khi $y_{kid}$ tiến sát và vượt qua $y_{chip}$: Kích hoạt sự kiện **`onOvertake`**.

### 3.2. Hiệu ứng Vượt mặt (Overtake Sequence)
Khi Bé vượt qua Chíp:
1. **Camera Shake & Speed Lines:** Màn hình rung nhẹ 3px, vệt gió siêu tốc kéo dài 400ms.
2. **Chíp Spin-Out:**
   - Tên lửa Chíp quay 1 vòng 360° quanh tâm (`spinAngle` chạy từ $0 \to 2\pi$ trong 450ms).
   - Tỷ lệ co dãn nhẹ (squash & stretch) tạo cảm giác hoạt hình mềm mại.
3. **Banner chữ nổi cổ vũ:** Hiện pop-up hiệu ứng ngắn 700ms giữa màn hình: **"VƯỢT LÊN!"** hoặc **"SIÊU TỐC!"**.
4. **Âm thanh:** Tiếng gió vút "VÈOOO!" kèm giọng Chíp thốt lên ngạc nhiên "Oái!".

### 3.3. Phản ứng khi Bé chọn Sai
1. Tên lửa Bé khựng nhẹ lùi lại 6px trong 120ms, ống xả xì ra đám khói đen xám nhỏ (`smoke_particles.dart`).
2. Chíp tăng tốc vọt lên trước một đoạn, còi "bim bim" trêu đùa.

---

## 4. Tác động Kiến trúc & Mã nguồn

### 4.1. File `lib/game/scene/race_scene.dart`
- Thêm trường `spinAngle` và `overtakeTimer` vào class `_Racer`.
- Khi vẽ racer (`_paintRacer`): Áp dụng `canvas.rotate(racer.spinAngle)` quanh tâm `rocketRect`.
- Thêm logic kiểm tra khoảnh khắc vượt mặt khi cập nhật vị trí giữa Bé và Chíp.
- Vẽ hoạt họa nhân vật Chíp lái tên lửa trong buồng lái kính.

### 4.2. File `lib/game/scene/space_track.dart`
- Tinh chỉnh `TrackGeometry` để khoảng cách giữa hai làn và độ sâu phối cảnh làm nổi bật sự vượt mặt giữa làn 0 và làn 1.

### 4.3. File `lib/features/game/race_screen.dart`
- Thêm widget banner nổi ngắn `_OvertakeBanner` khi sự kiện vượt mặt diễn ra.

---

## 5. Chiến lược Kiểm thử & Đảm bảo Chất lượng

1. **Unit tests (`test/game/scene/`):**
   - Kiểm tra `spinAngle` kích hoạt đúng khi Bé vượt Chíp và trở về 0 sau khi hết thời gian spin-out.
   - Kiểm tra Chíp dẫn trước ở đầu ván và phản ứng đúng khi Bé trả lời đúng/sai.
   - Kiểm tra chế độ giảm chuyển động (`reduceMotion`): Tắt spin-out và rung lắc, giữ chuyển động nhảy nấc an toàn.
2. **Visual screenshot tests (`tools/shot/game_shot_test.dart`):**
   - Chụp lại ảnh khoảnh khắc Chíp dẫn trước, khoảnh khắc Bé bứt tốc vượt mặt Chíp, và khoảnh khắc spin-out.
3. **Hệ thống:**
   - Đảm bảo `flutter analyze` 100% sạch không lỗi.
   - Toàn bộ 2.513 test hiện tại tiếp tục pass 100%.
