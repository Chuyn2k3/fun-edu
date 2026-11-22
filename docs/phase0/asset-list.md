# Danh sách hình cần làm cho giai đoạn 1

Tài liệu này dành cho chủ dự án. Mỗi hình tạo **riêng một lần** trên Gemini (không dùng bảng lưới nhiều hình trong một ảnh), rồi cắt nền bằng script `tools/assets/cut_sheet.py`.

## Cách làm

**Đoạn mô tả phong cách cố định** (dán vào mọi câu lệnh, giữ nguyên):

> soft 3D render, cute rounded toy-like shapes, smooth glossy plastic and soft clay materials, soft warm studio lighting, gentle shadows, vibrant soft pastel colors, plain pure white background, no text

Lưu ý:
- Làm trong cùng một cuộc chat Gemini và **luôn gửi kèm ảnh mẫu gốc** của Chíp Chíp để nhân vật giữ nguyên dáng vẻ.
- **Bật chế độ tạo ảnh**; đừng để Gemini trả về code SVG.
- Gemini hay vẽ thêm dấu ✦ ở góc ảnh: cắt bỏ (chọn khung cắt không chứa dấu này).
- Không ghi tên hãng hay nhân vật có thật trong câu lệnh.
- Đọc điều khoản dùng ảnh thương mại của Google tại thời điểm dùng.

## Cắt nền bằng script

```
pip install -r tools/assets/requirements.txt
python3 tools/assets/cut_sheet.py <ảnh> <cấu hình.json> <thư mục ra>
```

Cấu hình mẫu:

```json
{"items": [{"name": "chip-joy", "box": [0, 40, 341, 415]}], "export_widths": [120, 240, 360]}
```

`box` là khung cắt `[trái, trên, phải, dưới]` tính bằng pixel. Ra ba file đúng quy ước mật độ ảnh của Flutter: `chip-joy.png` (rộng 120), `2.0x/chip-joy.png` (240), `3.0x/chip-joy.png` (360).

## Danh sách hình

### Chíp Chíp (7 hình)
Mỗi hình tạo riêng, cạnh dài ít nhất 800 px.
1. Chíp Chíp chính (đứng thẳng, nhìn thẳng).
2. Vui (joy).
3. Giơ ngón cái (thumb).
4. Ngạc nhiên (surprise).
5. Động viên (encourage).
6. Ngủ (sleep).
7. Đang viết (write): **làm lại**. Cầm bút tự nhiên, có nét vẽ trên đất, ít nhất 800 px.

### Biểu tượng 4 môn (4 hình)
Viết, Tiếng Việt, Toán, Tiếng Anh. Mỗi biểu tượng một hình riêng.

### Biểu tượng thưởng (3 hình)
- Sao.
- Lửa (chuỗi ngày học).
- Vương miện: **bỏ dấu ✦ trên vành**.

### Cảnh đầu trang (1 hình)
Tỷ lệ dọc, rộng ít nhất 1170 px. Không cần tách nền.

### Sticker (khoảng 30 hình)
Mỗi sticker một hình riêng, nền trắng, nhìn cùng phong cách với Chíp Chíp. Chốt danh sách cụ thể cùng chủ dự án trước khi làm.


## Phần thưởng đua với bạn (2B-2, cần vẽ)

Đang dùng **ảnh 3D có sẵn làm tạm** (đúng nghĩa nhưng chưa phải huy chương). Khi vẽ xong: ảnh nền xanh lá, tách bằng `tools/assets/chroma_key.py`, xuất 1x/2x/3x vào `assets/images/game/`, đổi đường dẫn trong `lib/game/data/badges.dart` (`image:`) và `AppImages.stickers`.

| Huy hiệu | Ảnh thực tế / Ảnh tạm | Gợi ý vẽ (cùng kiểu huy chương đất sét 3D như 8 huy hiệu cũ) |
|---|---|---|
| Bạn Đua Vui Vẻ (`friend_racer`) | `badge-friend-racer.png` (Đã vẽ 3D) | Hai tên lửa nhỏ bay song song, dải ruy băng cam |
| Nhà Vô Địch (`friend_champion`) | `badge-friend-champion.png` (Đã vẽ 3D) | Cúp vàng có ngôi sao, ruy băng đỏ |
| Cuộc Đua Lớn (`big_race`) | `badge-big-race.png` (Đã vẽ 3D) | Bốn tên lửa bốn màu quanh hành tinh |
| Cổ Vũ Nhiệt Tình (`cheerleader`) | `badge-cheerleader.png` (Đã vẽ 3D) | Cờ cổ vũ + trái tim |

| Sticker hiếm | Ảnh thực tế / Ảnh tạm | Gợi ý vẽ (Chíp 3D, viền vàng lấp lánh) |
|---|---|---|
| `rare_chip_sleep` Chíp ngủ say | `sticker-rare-chip-sleep.png` (Đã vẽ 3D) | Chíp ngủ trên mặt trăng |
| `rare_chip_write` Chíp tập viết | `chip-write.png` | Chíp viết chữ phát sáng |
| `rare_rocket_chip` Chíp lái tên lửa | `game/rocket-chip.png` | Chíp đội mũ phi công vàng |
| `rare_crown` Vương miện vàng | `ic-crown.png` | Chíp đội vương miện |
| `rare_comet` Sao chổi rực rỡ | `game/comet.png` | Chíp cưỡi sao chổi |
| `rare_planet` Hành tinh vành đai | `game/planet.png` | Chíp ngồi trên vành Sao Thổ |

Sticker của 4 huy hiệu mới dùng tư thế Chíp có sẵn: giơ ngón cái, vui mừng, ngạc nhiên, cổ vũ.
