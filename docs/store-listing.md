# Nội dung trang kho ứng dụng (bản nháp)

> Cập nhật: 2026-11-13. Chỉ ghi những gì app **đang có**. Khi thêm tính năng (chữ cái, Tiếng Việt, Tiếng Anh, gói trả phí) thì sửa lại file này trước khi gửi bản mới lên kho.
> **Lưu ý:** tên có "Học Chữ" và từ khóa "chữ cái" — chỉ nên phát hành với tên này khi đã có phần Viết chữ cái (giai đoạn 2). Nếu phát hành sớm hơn, tạm dùng `ChipChip: Bé Tập Viết, Tập Tô`.

## Thương hiệu
- Tên app: **ChipChip** (tên dưới icon). Linh vật trong app: chim sẻ "Chíp Chíp" (có dấu, để giọng đọc tiếng Việt đọc đúng).
- Tên nhà phát triển trên kho: **FunEdu**. Mã gói: `com.ibme.funedu`.
- Khẩu hiệu: **"Hết chữ gà bới!"** — phụ: "Mỗi ngày 10 phút, con viết đẹp hơn."
- Icon: `docs/superpowers/specs/assets/generated/app-icon-source.webp` (phong cách phẳng, nét sáp màu). Tạo lại icon: `python3 tools/assets/make_app_icons.py`.

## App Store (iOS)
| Ô | Giới hạn | Nội dung |
|---|---|---|
| Tên | 30 | `ChipChip: Bé Tập Viết, Học Chữ` (30) |
| Phụ đề | 30 | `Tập tô & Toán cho bé vào lớp 1` (30) |
| Từ khóa (ẩn) | 100 | `luyện chữ,viết đẹp,chữ cái,ô ly,mầm non,mẫu giáo,đếm số,trẻ em,chữ số,nét cơ bản` — không lặp từ đã có ở tên/phụ đề, không dấu cách sau dấu phẩy |
| Danh mục | — | Giáo dục; khu vực Trẻ em (Kids), nhóm tuổi 5 trở xuống hoặc 6–8 |

## Google Play
| Ô | Giới hạn | Nội dung |
|---|---|---|
| Tên | 30 | `ChipChip: Bé Tập Viết, Học Chữ` |
| Mô tả ngắn | 80 | `Bé tập tô chữ, chấm từng nét như cô giáo. Toán vui. Không quảng cáo.` (68) |
| Danh mục | — | Giáo dục; tham gia chương trình "Được giáo viên chấp thuận" / Gia đình |

## Mô tả dài (dùng chung, chỉnh nhẹ cho từng kho)

Hết chữ gà bới! ChipChip giúp bé 3–6 tuổi tập viết đúng từ những nét đầu tiên.

✏️ CHẤM TỪNG NÉT NHƯ CÔ GIÁO
Bé dùng ngón tay tô trên ô li. ChipChip kiểm tra từng nét: đúng thứ tự, đúng chiều, không lệch khỏi đường mẫu — rồi nhẹ nhàng chỉ cho bé viết lại nét chưa đúng. Không chỉ "chạm là xong" như nhiều app khác.

📚 HỌC THEO TRÌNH ĐỘ, KHÔNG THEO TUỔI
Bài thử ngắn lúc đầu giúp xếp bé vào đúng mức. Bé làm tốt thì lên bài khó hơn, còn chật vật thì ôn lại — tự động.

⏱️ BÀI HÔM NAY – 10 PHÚT MỖI NGÀY
Mỗi ngày một bài ngắn gồm tập viết và Toán. Xong bài, bé nhận sao và được chú chim sẻ Chíp Chíp khen ngợi.

🔢 TOÁN VUI
Đếm, so sánh, ghép số, cộng trừ trong phạm vi 20 qua các trò chạm và kéo thả.

👨‍👩‍👧 GÓC BA MẸ
• Xem tiến bộ của bé.
• Đặt giới hạn thời gian và giờ đi ngủ — hết giờ, Chíp Chíp đi ngủ cùng bé.
• Tạo tối đa 4 hồ sơ cho anh chị em.
• Đặt phần thưởng thật để bé đổi bằng sao.

🔒 AN TOÀN CHO BÉ
• Không quảng cáo.
• Không thu thập thông tin cá nhân của bé; dữ liệu lưu trên máy.
• Góc ba mẹ có khóa dành cho người lớn.

Sắp có: tập viết chữ cái, Tiếng Việt, Tiếng Anh.

## Chữ trên 5 ảnh giới thiệu (theo thứ tự)
1. **Hết chữ gà bới!** — Chấm từng nét như cô giáo *(màn tập viết, Chíp Chíp khen)*
2. **Mỗi ngày 10 phút** — Bài hôm nay vừa sức bé *(trang chủ)*
3. **Viết sai nét? Chíp chỉ cho bé** *(màn viết khi sai nét)*
4. **Toán vui, chạm là học** *(màn Toán)*
5. **Ba mẹ yên tâm** — Giới hạn giờ, không quảng cáo *(góc ba mẹ)*

## Cần chủ dự án kiểm tra trước khi gửi
- Tìm "ChipChip" trên App Store, Google Play và ipvietnam.gov.vn (trùng tên / nhãn hiệu).
- Chính sách quyền riêng tư công khai (URL) — kho bắt buộc với app trẻ em; nội dung lấy từ `lib/parent/screens/privacy_screen.dart`.
- Điền email liên hệ.
