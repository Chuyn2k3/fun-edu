# Kế hoạch tiếp theo (sau rà soát 2026-11-21)

> Thứ tự đề xuất, chờ chủ dự án duyệt. Mỗi đợt khi bắt đầu sẽ có plan chi tiết riêng (TDD, rà soát từng task) như các giai đoạn trước.
> Nguyên tắc giữ nguyên: offline 100%, không SDK theo dõi, Riverpod, màu qua `tokens.dart`, ảnh qua `AppImages`, `flutter analyze` sạch + `flutter test` đạt trước mỗi commit.

## Đã xong trong đợt rà soát này

- Câu sao chổi trong trận đua giờ đọc "Câu sao chổi! Trả lời đúng là bay vọt 2 nấc!" **rồi đọc tiếp câu hỏi**; nút loa luôn đọc câu hỏi (trước đây trận Tiếng Việt có 3/10 câu bé không nghe được chữ cần chọn).
- Bản đồ Toán / Tiếng Việt / Tiếng Anh: khi chưa tải xong cấp, các ô hiện trung tính (không "Đang học" ở cấp 1, không ổ khóa, không bấm được).
- Nhà Chíp: khi chưa tải xong (hoặc lỗi đọc), cho ăn / trang trí không làm gì (trước đây Chíp nói sai "chưa đủ sao").
- iOS: màn con dùng `CupertinoPage` (giữ vuốt mép trái để quay lại); Android vẫn mờ + phóng nhẹ 160 ms.
- `app.dart` nạp sẵn cấp môn bằng `ref.listen` (không dựng lại cả app khi đổi cấp); xóa 25 màu `GameColors` không dùng.

## Đợt A — Dọn trước beta (nhỏ, ~1–2 ngày, làm ngay được)

1. **Trang chủ và Sưu tập không nháy số 0.** Khi đang tải: ẩn con số (sao, "N ngày học tuần này", vòng tiến độ) bằng khung trống cùng kích thước thay vì in 0; "Bài hôm nay" chưa bấm được tới khi có danh sách bài. Test: provider treo `Completer` → không có chữ "0 ngày", nút bài hôm nay không mở `/lesson`.
2. **Góc Chơi báo quà đang chờ** (mục 7: thoát tấm chọn quà thì chỉ Xưởng độ biết). Thêm chấm "Quà chờ bé!" trên thẻ Xưởng độ ở Góc Chơi.
3. **`GameRepository`:** `select()` kiểm loại món (tên lửa/vệt); `select`/`markSeen` trong transaction.
4. **`_letterNames` trong màn đua** đọc từ `speech` của glyph thay vì bảng chép tay.
5. Bản đồ Toán còn `Opacity` cho ô khóa (Tiếng Việt/Anh đã bỏ) → làm giống hai màn kia.

## Đợt B — Phản hồi thử máy thật (chờ chủ dự án)

- Tổng hợp lỗi/góp ý từ đợt `flutter run --profile` (120 Hz, giọng `vi-VN`/`en-US`, in PDF, bố cục điện thoại/iPad).
- Nếu tụt khung trong trận đua: bỏ trước 3 lần `MaskFilter.blur` (lửa ngoài ×2, vệt sao chổi) và blur 12 của vòng sáng hành tinh.
- Kiểm tra vuốt quay lại iOS trên máy thật sau khi đổi sang `CupertinoPage`.

## Đợt C — Chữ hoa tập viết (giai đoạn 2G, lớn nhất, ~1–1,5 tuần)

Mục tiêu: 29 chữ hoa tiếng Việt (A Ă Â B C D Đ E Ê G H I K L M N O Ô Ơ P Q R S T U Ư V X Y), chấm nét như chữ thường.

1. **Nét mẫu** (`tools/glyphs/letters.py`): thêm chữ hoa `hoa-*` theo mẫu chữ viết trường tiểu học (cao 5 ô li trên khung 12 ô li), dùng lại các nét con (`cong_kin_pen`, `khuyet_*`, `mu`, `breve`, `rau`). `render_sheet.py` vẽ bảng xem; pytest: số nét, chiều, không tự cắt sai, mũ/dấu phụ khớp chữ gốc. **Cổng duyệt:** chủ dự án duyệt bảng chữ hoa trước khi làm tiếp.
2. **Chấm nét:** `GradeConfig.forGlyph` giữ luật `ruling` (chữ cao 5 ô li → hệ số 1); mở rộng `letter_confusion_test.dart` cho cặp chữ hoa dễ nhầm (U/Ư, O/Ô/Ơ, A/Ă/Â, D/Đ, E/Ê, V/U).
3. **Thang Viết:** thêm nhóm "Chữ hoa" sau dấu thanh trong `writing_ladder.dart` / `writing_sections.dart`; bản đồ Viết, tab Tiến độ ba mẹ, phiếu tập tô PDF (nhóm mới) tự nhận nhóm. Bài xếp cấp không đổi.
4. **Giọng đọc:** `speech` "Mình viết chữ A hoa nhé!".
5. Không đổi schema drift (tiến độ theo glyph id).

## Đợt D — Vở của bé (~3–4 ngày)

- Lưu lại lần viết đẹp nhất mỗi chữ (đã có toạ độ trong `stroke_attempts`; chọn lần ít sai nhất, gần nhất) — **không chụp ảnh, không thêm dữ liệu cá nhân**.
- Tab mới trong Sưu tập: lưới trang vở, vẽ lại nét của bé bằng `CustomPainter` trên ô li; ba mẹ xem trong Góc ba mẹ; in một trang "Vở của bé" PDF.
- Có thể cần chỉ mục cho `stroke_attempts` (đổi schema → tăng `schemaVersion`, migration + test).

## Đợt E — Toán nâng cao (~1 tuần)

- Cấp 10–12: số đến 100 (chục và đơn vị, que tính), xem đồng hồ (giờ đúng/giờ rưỡi), nhận biết tiền Việt Nam (tờ 1.000–10.000, ảnh vẽ phẳng, không dùng ảnh tiền thật).
- Bản đồ Toán điện thoại thêm 3 trạm; iPad đổi lưới 3×3 → 3×4 (kiểm lại `_fits`).
- Trận đua thêm dạng so sánh (mục 7: bé ở cấp so sánh đang đua bằng câu đếm).

## Xen kẽ — Tách file lớn (không đổi hành vi)

Tách theo widget con, có test bảo vệ trước khi tách: `collection_screen.dart` (1865 dòng), `race_screen.dart` (1282), `room_stage.dart` (1200), `race_scene.dart` (1146), `race_result_screen.dart` (1128).

## Cần chủ dự án quyết

1. Thứ tự đợt C/D/E (đề xuất C → D → E vì tập viết là điểm khác biệt chính).
2. Chữ hoa: theo mẫu chữ nào (mẫu chữ viết tiểu học hiện hành, kiểu 1 nét thanh đậm hay đơn giản hóa cho bé 3–6 tuổi)?
3. 2E gói trả phí: giá và số cấp miễn phí mỗi môn — vẫn đang mở, cần chốt trước khi làm máy chủ.
