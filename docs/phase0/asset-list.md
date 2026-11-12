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
