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
| `rare_chip_write` Chíp tập viết | `sticker-rare-chip-write.png` (Đã vẽ 3D) | Chíp viết chữ phát sáng |
| `rare_rocket_chip` Chíp lái tên lửa | `sticker-rare-rocket-chip.png` (Đã vẽ 3D) | Chíp đội mũ phi công vàng |
| `rare_crown` Vương miện vàng | `sticker-rare-crown.png` (Đã vẽ 3D) | Chíp đội vương miện |
| `rare_comet` Sao chổi rực rỡ | `sticker-rare-comet.png` (Đã vẽ 3D) | Chíp cưỡi sao chổi |
| `rare_planet` Hành tinh vành đai | `sticker-rare-planet.png` (Đã vẽ 3D) | Chíp ngồi trên vành Sao Thổ |

Sticker của 4 huy hiệu mới dùng tư thế Chíp có sẵn: giơ ngón cái, vui mừng, ngạc nhiên, cổ vũ.

## Bộ ảnh đại diện con vật & Sticker Đua Bạn Bè (2B-2 / Online)

Hiện đang dùng ảnh giữ chỗ vector/canvas do `tools/assets/make_placeholders.py` sinh ra (không ghi đè khi thay ảnh thật).
Khi vẽ bằng Gemini:
- **Câu lệnh chung:** `soft 3D render, cute rounded toy-like shapes, smooth glossy plastic and soft clay materials, soft warm studio lighting, gentle shadows, vibrant colors, solid green background #00FF00, no text`
- Tách nền bằng script: `python3 tools/assets/chroma_key.py <ảnh> <config.json> <thư mục ra>`

### 12 Ảnh đại diện con vật (`assets/images/avatars/`)

| Tên file | Nhân vật | Gợi ý mô tả Gemini (3D mềm kiểu đồ chơi như Chíp, nền xanh lá #00FF00) |
|---|---|---|
| `fox.png` | Cáo con | Chú cáo con màu cam đất sét mềm, tai vểnh, má phúng phính, mắt to tròn lanh lợi |
| `panda.png` | Gấu trúc | Chú gấu trúc con tròn xoe trắng đen, ôm cành măng tre đồ chơi, má hồng |
| `bunny.png` | Thỏ con | Bé thỏ con màu trắng hồng pastel, hai tai dài cụp nhẹ, nơ nhỏ xinh xắn |
| `tiger.png` | Hổ con | Chú hổ con màu vàng cam có sọc vằn mềm mại, cười toe toét dũng cảm |
| `cat.png` | Mèo con | Mèo con tròn trịa lông vàng kem, râu mép ngộ nghĩnh, mắt biếc long lanh |
| `dog.png` | Cún con | Chú cún con tai cụp màu nâu ấm, mũi đen tròn ươn ướt, đeo vòng cổ đỏ |
| `elephant.png` | Voi con | Chú voi con màu xanh đá pastel (slate blue), vòi cong giơ lên chào, tai to |
| `dino.png` | Khủng long | Bé khủng long bạo chúa tí hon màu xanh lá mạ, gai lưng tròn mềm, bụng vàng |
| `owl.png` | Cú mèo | Chú cú mèo con mắt tròn xoe sáng ngời, lông tím pastel mềm mại, đầu nghiêng tò mò |
| `penguin.png` | Cánh cụt | Chim cánh cụt con mập mạp bụng trắng lưng đen, mỏ cam, lắc lư ngộ nghĩnh |
| `bear.png` | Gấu con | Gấu nâu con ấm áp, ôm hũ mật ong đất sét nhỏ, biểu cảm hiền lành |
| `unicorn.png` | Kỳ lân | Bé kỳ lân màu trắng ngọc, bờm ngũ sắc pastel, sừng vàng xoắn ốc đồ chơi |

### 8 Sticker Đua bạn bè (`assets/images/game/`)

| Tên file | Sticker | Gợi ý mô tả Gemini (3D mềm kiểu đồ chơi như Chíp, nền xanh lá #00FF00) |
|---|---|---|
| `sticker-tease-bubble.png` | Bọt bóng trêu | Bong bóng xà phòng 3D trong veo ngũ sắc bốc lên lung linh, phản chiếu ánh sáng |
| `sticker-tease-tongue.png` | Lè lưỡi trêu | Biểu tượng mặt cười 3D đất sét lè lưỡi nháy mắt tinh nghịch lém lỉnh |
| `sticker-tease-byebye.png` | Vẫy tay tạm biệt | Bàn tay găng trắng 3D vẫy tay chào tạm biệt bye-bye bồng bềnh |
| `sticker-tease-rain.png` | Mưa rào | Đám mây nhỏ màu xanh xám có giọt mưa rơi tí tách kèm hạt mưa lấp lánh |
| `sticker-tease-sleepy.png` | Buồn ngủ | Mũ ngủ sọc xanh trắng kèm chữ zZz 3D bồng bềnh lơ lửng |
| `sticker-tease-turtle.png` | Rùa bò chậm | Chú rùa con mai tròn màu xanh ngọc bò chậm rãi, đầu rụt rè ngộ nghĩnh |
| `sticker-tease-smoke.png` | Xì khói | Đám mây khói xì poof xám trắng bùng ra tròn xoe như khói ống xả xe đồ chơi |
| `sticker-party.png` | Pháo hoa tiệc | Ống pháo giấy bung tỏa hoa giấy ngũ sắc và dải ruy băng lấp lánh ăn mừng |

