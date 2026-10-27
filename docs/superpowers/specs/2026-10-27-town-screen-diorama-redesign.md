# Design Spec: Làng Cổ Tích (TownScreen) - Thung Lũng Diorama 3D

- **Ngày tạo:** 2026-10-27
- **Trạng thái:** Chờ phê duyệt (Pending User Review)
- **Dự án:** FunEdu (`Chuyn2k3/fun-edu`)
- **Mục tiêu:** Tái thiết kế toàn diện màn hình chính thế giới học tập (TownScreen) sang phong cách game 3D thế giới mở (Isometric Diorama Valley), khắc phục triệt để bố cục phẳng chật chội hiện tại, đảm bảo chiều sâu thị giác chuẩn AAA và tương thích hoàn hảo trên cả iPhone lẫn iPad.

---

## 1. Bối cảnh & Mục tiêu (Context & Objectives)

### 1.1. Vấn đề của thiết kế hiện tại:
1. **Phần đỉnh màn hình bị nghẽn diện tích (~45% chiều cao):** Banner tiêu đề *"Làng Cổ Tích FunEdu"* và khung thoại của Pippo quá cồng kềnh, chiếm mất nửa trên màn hình trước khi trẻ kịp nhìn thấy các trạm học.
2. **Công trình bị đóng khung thành "Card Web":** Các trạm học (Tiệm Tạp Hóa, Nhà Nấm) là các hình chữ nhật phẳng giả lập card web, thiếu vắng chất liệu 3D hữu cơ (gỗ mộc, ngói nung, tán lá, bóng đổ mềm mại).
3. **Thiếu chiều sâu và cảm giác thế giới mở:** Con đường cuộn dọc đơn điệu chỉ cho phép nhìn 1.5 trạm mỗi khung nhìn, tạo cảm giác như đọc một danh sách học từ vựng hơn là khám phá một ngôi làng cổ tích.

### 1.2. Chuẩn Benchmark mục tiêu:
- Học tập trực tiếp từ ảnh phong cách tham khảo (Media Benchmark): Game 3D với ánh sáng ấm áp, đổ bóng mềm (soft ambient shadows), chất liệu xúc giác (tactile textures: gỗ mộc, đất nện, quả mọng).
- Trải nghiệm tương tác giống các tựa game giáo dục trẻ em hàng đầu thế giới: Toca Life World, Dr. Panda Town, Duolingo ABC.
- **Cam kết phương pháp:** *"Làm từng cái một nhưng đến đâu chuẩn đến đó"* — hoàn thiện từng công trình, nghiệm thu thẩm mỹ trực tiếp trước khi mở rộng.

---

## 2. Kiến trúc Bố cục Không gian (Spatial Architecture)

### 2.1. Canvas Thung lũng Tự nhiên (Diorama Valley Canvas)
Thay thế toàn bộ `CustomScrollView` dạng danh sách bằng một canvas không gian mở dạng **Isometric Diorama** (tỉ lệ chuẩn 800 x 1100 px):

```
+-------------------------------------------------------------------+
| [Bé Yêu Lv.3]                              (⭐ 150) (💧 12) (🔊)   | <- Edge-Pinned Jelly HUD
+-------------------------------------------------------------------+
|  🌤️ Bầu trời nắng ấm + Luồng nắng xiên (God rays)                 |
|  ⛰️ Rặng núi mờ sương + 🏡 Cối xay gió mini (Tầng 1 - Hậu cảnh)    |
|                                                                   |
|                      🏰 LÂU ĐÀI CHỮ CÁI                           | <- Tầng 2 (Scale 0.75x)
|                     (Đỉnh đồi trung tâm)                          |
|                                                                   |
|   🍎 TIỆM TẠP HÓA NHÍ            [Cầu gỗ]    🌳 CÂY TRI THỨC      | <- Tầng 3 (Scale 1.0x)
|   (Bên trái quảng trường)          ~~~      (Bên kia bờ suối)     |
|                      [   QUẢNG TRƯỜNG   ]                         |
|                      [  🐻 GẤU PIPPO   ]                         |
|                                                                   |
|   🍄 NHÀ NẤM TOÁN HỌC                       🐣 TRẠI ẤP THÚ        | <- Tầng 4 (Scale 1.15x)
|   (Góc dưới trái)                           (Bờ hồ góc phải)      |
|                                                                   |
|                   [ 🧭 Bản Đồ | 🎮 Game | 🎒 Balo ]                | <- Floating Glass Dock
+-------------------------------------------------------------------+
```

### 2.2. Phối cảnh Đa tầng & Tỷ lệ Xa - Gần (4-Tier Layered Depth)
1. **Tầng 1 (Hậu cảnh xa nhất - Chân trời):** Bầu trời xanh lơ ấm, mặt trời với luồng hào quang vàng mềm, núi đồi mờ viễn cận (atmospheric haze), cối xay gió mini quay nhịp nhàng.
2. **Tầng 2 (Trung cảnh xa - Tỷ lệ 0.75x):** Đỉnh đồi cao tọa lạc **Lâu Đài Chữ Cái (Alphabet Castle)**. Quy mô nhỏ hơn tự nhiên theo luật xa gần, suối nước chảy từ chân đồi uốn quanh thung lũng.
3. **Tầng 3 (Trung tâm hoạt động - Tỷ lệ 1.0x chuẩn):**
   - **Quảng trường gạch đá tròn (Village Plaza):** Chú gấu Pippo đứng trung tâm, nhịp thở nhún nảy (breathing idle bounce).
   - **Tiệm Tạp Hóa Nhí (Market Station):** Nằm bên trái quảng trường, cửa hàng mái ngói gỗ, thùng táo đỏ bóng bẩy, sạp bí ngô.
   - **Cây Tri Thức (Wonder Tree):** Nằm bên phải quảng trường bên kia bờ suối, kết nối qua một chiếc cầu gỗ mộc mạc.
4. **Tầng 4 (Tiền cảnh gần mắt - Tỷ lệ 1.15x):**
   - **Nhà Nấm Toán Học (Math Mushroom):** Góc dưới trái, mái nấm đỏ đốm trắng rực rỡ, chi tiết sắc nét.
   - **Trại Ấp Thú (Pet Sanctuary):** Góc dưới phải cạnh hồ nước êm đềm với hàng rào gỗ và tổ ấp trứng.
   - Cụm hoa dại cỏ tươi ở viền đáy màn hình tạo chiều sâu thị giác người chơi cúi nhìn xuống thung lũng (top-down 35° isometric).

---

## 3. Quy tắc Tiếp đất & Đổ bóng (Ground Blend & Lighting)

1. **Chân móng tiếp đất hữu cơ (Ground Foundation Blend):**
   - Không đặt bất kỳ công trình hay nhân vật nào như hình cắt dán bay lơ lửng trên nền cỏ phẳng.
   - Dưới chân mỗi công trình có một vạt đất nện / móng đá sỏi tự nhiên (`FoundationPatchPainter`).
   - Viền chân tường được đan xen các bụi hoa nhỏ, thảm cỏ rìa che phủ chân móng để "cắm rễ" công trình hòa vào nền đất.
2. **Nguồn sáng & Đổ bóng đồng nhất (Consistent Global Lighting):**
   - Nguồn sáng chính: Góc **trên-phải chiếu chéo xuống dưới-trái (135°)**.
   - Mọi vật thể (Pippo, Tiệm tạp hóa, Nhà nấm, Cây tri thức, Cầu gỗ) đều có bóng đổ mềm (Directional Shadow + Ambient Occlusion) nghiêng về góc dưới bên trái với cùng một góc chiếu và độ mờ (blur radius).
3. **Đường mòn lát đá cuội kết nối hữu cơ (Organic Cobblestone Paths):**
   - Con đường chính uốn lượn từ cổng làng qua quảng trường trung tâm.
   - Từ quảng trường có các nhánh đường đá cuội màu vàng mật ong rẽ tự nhiên đến tận bậc tam cấp của 5 ngôi nhà, không để đường bị đứt gãy hay cụt lơ lửng.

---

## 4. Đặc tả Giao diện HUD Tinh Gọn (Edge-Pinned Jelly HUD)

- **Nguyên tắc:** HUD chỉ bám sát mép viền ngoài cùng, để lại 95% không gian trong suốt cho thung lũng.
- **Thanh trạng thái trên đỉnh (Top HUD):**
  - Trái: Avatar bé + Level badge thu nhỏ (`Bé Yêu Lv.3`).
  - Phải: Viên kẹo Sao Vàng (⭐ 150), Giọt Nước Thần (💧 12), Nút Âm thanh/Cài đặt bo tròn bóng bẩy.
- **Khung thoại của Pippo:**
  - Loại bỏ hoàn toàn khung thoại cố định choán chỗ ở giữa trời.
  - Khi bé chạm vào chú gấu Pippo, một bong bóng thoại hoạt hình nhỏ gọn xuất hiện ngay trên đầu Pippo, hiển thị câu chào hoặc gợi ý trò chơi, sau đó tự thu nhỏ biến mất sau 3 giây hoặc khi bé chạm ra ngoài.
- **Dock điều hướng đáy (Bottom Floating Glass Dock):**
  - Thanh dock dạng viên thuốc thủy tinh mờ (Frosted glass capsule), viền sáng mạ vàng, lơ lửng nhẹ trên mép đáy màn hình:
    - `🧭 Bản Đồ` (Đang chọn - Hiệu ứng Jelly nhún nảy cam tươi).
    - `🎮 Trò Chơi` (Nút chuyển nhanh danh sách mini-game).
    - `🎒 Balo Thần Kỳ` (Túi đồ và phần thưởng tích lũy).

---

## 5. Tương thích Đa thiết bị (Responsive Engine: iPhone vs iPad)

| Thiết bị | Chế độ hiển thị | Hành vi tương tác |
| :--- | :--- | :--- |
| **iPad / Máy tính bảng (4:3, 16:10)** | **Panoramic 100% Fit** | Toàn bộ thung lũng thu gọn trọn vẹn trong một khung nhìn hoành tráng như một sa bàn đồ chơi 3D thu nhỏ, không cần cuộn hay kéo. |
| **iPhone / Điện thoại (19.5:9, 20:9)** | **Adaptive Viewport Pan** | Màn hình tự động lấy nét vào trung tâm (Pippo & Tiệm Tạp Hóa). Cho phép bé dùng 1 ngón tay vuốt nhẹ nhàng (Interactive Pan) để lướt xem các góc làng cực kỳ mượt mà với hiệu ứng quán tính (damping physics). |

---

## 6. Lộ trình Thực hiện theo Cam kết ("Làm từng cái một, đến đâu chuẩn đến đó")

### Giai đoạn 1: Dựng khung Canvas Thung Lũng & HUD Mới
- Xây dựng `DioramaValleyCanvas` thay thế `WindingAdventureTrail` dạng list cuộn.
- Tích hợp hệ thống phân tầng 4 lớp, đường mòn đá cuội nối liền mạch và hệ thống tiếp đất `GroundFoundationPainter`.
- Dọn dẹp cụm banner/thoại rườm rà ở đỉnh, chuyển thành HUD Jelly tinh gọn viền ngoài.

### Giai đoạn 2: Nâng cấp Công trình #1 - Tiệm Tạp Hóa Nhí (Market Building)
- Tạo asset và widget 3D chất lượng cao cho Tiệm Tạp Hóa theo đúng ngôn ngữ của ảnh mẫu:
  - Mái ngói gỗ nung với vân gỗ tactile.
  - Sạp hoa quả bên hông với giỏ táo đỏ tươi, bí ngô vàng ươm.
  - Bảng hiệu gỗ treo dây thừng khắc chữ "Tiệm Tạp Hóa Nhí".
  - Hiệu ứng nhún đàn hồi khi chạm vào (Squash & Stretch) kèm âm thanh gõ gỗ vui tai.
- Chạy nghiệm thu trực tiếp trên iPhone Simulator & Visual Companion, gửi ảnh chụp cho người dùng đánh giá.

### Giai đoạn 3: Lần lượt hoàn thiện 4 Công trình còn lại
- **Nhà Nấm Toán Học:** Mái nấm đỏ tròn 3D phát sáng lung linh, bảng phép tính gỗ.
- **Cây Tri Thức:** Cây đại thụ tán lá đa tầng, lá thần phát sáng lơ lửng.
- **Trại Ấp Thú:** Chuồng gỗ mộc, rơm vàng ấm áp và trứng thần kỳ phát sáng.
- **Lâu Đài Chữ Cái:** Tháp đá cổ kính mini trên đỉnh đồi trung tâm với cờ phấp phới.

### Giai đoạn 4: Tinh chỉnh Responsive iPad & Hiệu ứng Chuyển động
- Kiểm tra hiển thị toàn cảnh trên iPad Simulator và iPhone 16 Pro Max Simulator.
- Đảm bảo 60fps mượt mà, không giật lag.

---

## 7. Kế hoạch Kiểm thử & Xác minh (Verification Plan)
1. **Lint & Code Integrity:** Chạy `flutter analyze lib/features/town/` không có cảnh báo hay lỗi.
2. **Visual Fidelity:** Chụp ảnh màn hình Simulator kiểm tra trực tiếp:
   - Tỷ lệ viễn cận 4 tầng rõ ràng.
   - Nguồn sáng và bóng đổ đồng nhất góc 135°.
   - Không còn tình trạng công trình bị đóng hộp thành card web phẳng.
3. **Responsive Verification:** Kiểm tra hiển thị co giãn trên cả iPhone (màn hình hẹp dọc) và iPad (màn hình rộng).
