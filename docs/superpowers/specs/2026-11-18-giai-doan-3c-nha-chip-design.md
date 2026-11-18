# Thiết kế Giai đoạn 3C — Tab "Nhà Chíp" (Offline 100%)

Ngày: 2026-11-18  
Nhánh: `chipchip`  
Phạm vi: Mở khóa tab cuối cùng **Nhà Chíp** (`/house`) trên thanh điều hướng chính của bé — nuôi Chíp Chíp lớn dần theo cấp và trang trí căn phòng ấm cúng bằng sao học tập, 100% offline, không đổi schema Drift và tách biệt hoàn toàn với `lib/game/`.

---

## 1. Mục tiêu

Theo spec tổng thể (`2026-11-12-fun-edu-overhaul-design.md`, mục 5.1):
- **Cho Chíp ăn bằng sao học tập** và **lớn dần theo cấp** (5 giai đoạn trưởng thành).
- **Trang trí nhà của Chíp** (tường/cửa sổ, thảm trải sàn, đồ góc phòng, vật phẩm đồng hành) hiển thị trực tiếp ngay trên sân khấu phòng Chíp.
- **Không trừ sao tổng học tập** dùng cho Quà thực tế của ba mẹ: Nhà Chíp chỉ theo dõi `spentStars` riêng (`availableStars = max(0, totalLearningStars - spentStars)`). Tổng sao trên Trang chủ, Sưu tập và Quà ba mẹ giữ nguyên không bao giờ giảm.
- **Có món hạt dẻ miễn phí 1 lần/ngày** để bé mới vào app (0 sao) vẫn có thể chăm Chíp ngay lập tức.

---

## 2. Lưu trữ & tách dữ liệu

- **Không đổi Drift schema (`schemaVersion = 7`):** Lưu JSON gọn theo từng bé trong bảng `AppSettings` dưới khóa `'chipHouse.<kidId>'` qua `ChipHouseRepository` (`lib/house/house_repository.dart`).
- Cập nhật `KidRepository._deleteProgressOf(id)` xóa kèm khóa `'chipHouse.<kidId>'` khi xóa hồ sơ bé.
- **Không import `lib/game/`:** Hoàn toàn thuộc hệ học tập.

---

## 3. Mô hình dữ liệu (`lib/house/house_model.dart`)

### 3.1 Trạng thái `ChipHouseState`
- `xp` (`int`): điểm lớn khôn của Chíp.
- `spentStars` (`int`): tổng sao học tập bé đã đổi đồ ăn/nội thất trong Nhà Chíp.
- `ownedIds` (`Set<String>`): danh sách mã đồ trang trí đã sở hữu (mặc định có sẵn 4 món cơ bản miễn phí).
- `equipped` (`Map<HouseSlot, String>`): món đang lắp ở 4 vị trí (`wall`, `rug`, `decor`, `buddy`).
- `lastFreeTreatDay` (`String?`, dạng `YYYY-MM-DD`): ngày gần nhất bé lấy hạt dẻ miễn phí.

### 3.2 5 Cấp trưởng thành của Chíp (`ChipStage`)
| Cấp | Tên giai đoạn | Mốc XP | Mô tả ngắn |
|---|---|---|---|
| 1 | Chíp Sơ Sinh | 0 | Bé Chíp mới tập nói líu lo |
| 2 | Chíp Tập Bay | 30 | Đôi cánh nhỏ đã cứng cáp hơn |
| 3 | Chíp Ham Học | 80 | Mê đọc chữ và đếm sao |
| 4 | Chíp Khám Phá | 150 | Dạn dĩ khám phá khắp khu vườn |
| 5 | Chíp Trạng Nguyên | 250 | Thông minh, hiểu biết cả 4 môn |

### 3.3 4 Món ăn vặt (`houseTreats`)
1. `acorn_free` — **Hạt dẻ giòn** · Miễn phí (1 lần/ngày) · +10 XP
2. `apple` — **Táo đỏ ngọt** · 2 sao · +15 XP
3. `honey_cake` — **Bánh mật ong** · 4 sao · +30 XP
4. `star_cake` — **Bánh kem ngôi sao** · 6 sao · +50 XP

### 3.4 16 Món trang trí (4 vị trí × 4 món)
- **Tường (`wall`):** Phòng nắng ấm (0⭐), Nhà trên cây (8⭐), Phòng biển xanh (12⭐), Bầu trời sao (16⭐).
- **Thảm (`rug`):** Thảm tròn kem (0⭐), Thảm cầu vồng (6⭐), Thảm đám mây (10⭐), Thảm ngôi sao (14⭐).
- **Góc phòng (`decor`):** Kệ sách nhỏ (0⭐), Chậu cây xanh (5⭐), Đèn mặt trăng (9⭐), Quả địa cầu (12⭐).
- **Bạn nhỏ (`buddy`):** Tự nhiên (0⭐), Gối ngôi sao (8⭐), Vương miện nhỏ (10⭐), Bút sáp vui vẻ (12⭐).

---

## 4. Giao diện & Bố cục (`lib/features/house/`)

- **Điều hướng:** Route `/house`, gán `kidNavHouse = 3` trong `lib/features/home/kid_nav.dart`. Cả 4 tab chính (`Học`, `Chơi`, `Sưu tập`, `Nhà Chíp`) đều mở khóa hoàn toàn.
- **Sân khấu Phòng Chíp (`room_stage.dart`):**
  - Vẽ bằng `CustomPainter` sắc nét (tường pastel, cửa sổ khung gỗ có bầu trời/cây/biển/sao theo theme, sàn gỗ ấm, thảm, kệ sách/chậu cây/đèn mặt trăng/địa cầu) + nhân vật Chíp 3D (`AppImages.chipMain` / `chipJoy` / `chipThumb` / `chipWrite`) và phụ kiện.
  - Chạm vào Chíp để vuốt ve: Chíp nảy vui vẻ, nổi bong bóng lời khen và đọc qua `Speaker`.
  - Khi cho ăn: nổi huy hiệu `+XP` bay nhẹ + phản ứng vui vẻ + chúc mừng nếu lên cấp.
- **Bảng điều khiển (`house_screen.dart`):**
  - Điện thoại: Sân khấu phòng ở trên → thanh cấp độ Chíp → 2 nút chuyển **Cho ăn** / **Trang trí** → lưới món ăn hoặc đồ trang trí → `FloatingNavBar` ở đáy.
  - iPad ngang: `NavRail` bên trái + bố cục 2 cột (trái: Sân khấu lớn + thanh cấp độ; phải: Cho ăn / Trang trí).
  - iPad dọc: `NavRail` bên trái + sân khấu trên, bảng điều khiển dưới.
  - Màu sắc lấy hoàn toàn từ `HouseColors` (`lib/ui/theme/tokens.dart`), chữ tương phản ≥ 4.5:1, nút bấm bé ≥ 64pt (điện thoại) / ≥ 80pt (iPad).
