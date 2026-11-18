# Giai đoạn 2C — In phiếu tập tô PDF (Offline)

**Ngày:** 2026-11-18
**Nhánh:** `chipchip`
**Trạng thái:** Đã duyệt thiết kế

## 1. Mục tiêu

Cho phép ba mẹ trong **Góc ba mẹ** tạo, xem trước tức thì, in trực tiếp hoặc chia sẻ/lưu **phiếu tập tô PDF khổ A4 chuẩn vở ô li Việt Nam** cho từng bé, chạy **100% offline** trên máy, không gọi mạng, không thu thập dữ liệu.

## 2. Lối vào & Bố cục

- **Lối vào:** Trong thẻ **Tập viết** của tab **Tiến bộ** (`lib/parent/screens/progress_tab.dart`), bổ sung nút **"In phiếu tập tô (PDF)"** (nút ≥ 48pt theo chuẩn Góc ba mẹ).
- **Màn tạo phiếu (`WorksheetScreen`):** mở bằng `Navigator.push` từ `ProgressTab` (đã nằm sau cổng người lớn, hoạt động đồng nhất trên điện thoại và iPad):
  - **Điện thoại:** khung xem trước trang A4 thu gọn ở trên + thanh chuyển trang (khi > 1 trang) + vùng cuộn chọn chữ & mức gợi ý ở giữa + thanh 2 nút hành động ("In phiếu", "Chia sẻ / Lưu PDF") ghim đáy.
  - **iPad (`context.isTablet`):** bố cục 2 cột — cột trái (`width ~360–420`) chứa chế độ chọn chữ, lưới chọn mục, tùy chỉnh mức gợi ý và 2 nút xuất PDF; cột phải hiển thị khung xem trước trang A4 lớn sắc nét cùng điều khiển lật trang.

## 3. Chọn chữ & Tùy chỉnh

### 3.1 Ba chế độ chọn nhanh (`WorksheetSelectionMode`)
1. **Bé đang yếu (`weak` — mặc định):** tự động chọn tối đa 6 mục theo thứ tự ưu tiên:
   - Các mục có số lần sai `gap = completions - cleanCompletions > 0`, xếp giảm dần theo `gap` (bằng nhau theo thứ tự `writingLadder`).
   - Tiếp theo là các mục đang tập (`completions > 0 && !mastered`) chưa có trong danh sách.
   - Nếu vẫn chưa đủ 6 mục (ví dụ bé mới chưa học chữ nào): bổ sung các mục chưa học đầu tiên trong `writingLadder` để phiếu luôn sẵn sàng in ngay.
2. **Theo nhóm (`section`):** chọn nhanh 1 trong 4 nhóm của `WritingSection`: **Nét cơ bản**, **Chữ số**, **Chữ cái**, **Dấu thanh**.
3. **Tự chọn (`custom`):** lưới 49 mục chia theo 4 nhóm, chạm bật/tắt từng mục; các mục bé hay sai có chấm cam nhỏ đánh dấu giúp ba mẹ dễ nhận ra. Hỗ trợ chọn tối đa 30 mục (tối đa 5 trang A4, mỗi trang 6 dòng); khi chưa chọn mục nào thì 2 nút xuất PDF tự vô hiệu hóa và hiện gợi ý ngắn.

### 3.2 Ba mức gợi ý tập tô (`WorksheetStyle`)
Mỗi dòng trên trang A4 gồm **6 ô vuông ô li**:
1. **Có hướng dẫn (`guided` — mặc định):** 1 ô mẫu đậm (có số thứ tự nét `1, 2, 3` tại điểm bắt đầu + mũi tên hướng nét) + 3 ô nét đứt mờ để bé tô đè + 2 ô li trống có chấm bắt đầu để bé tự viết.
2. **Tô theo nhiều (`traceHeavy`):** 1 ô mẫu đậm + 5 ô nét đứt mờ (phù hợp bé mới cầm bút).
3. **Tự luyện (`practice`):** 1 ô mẫu đậm + 1 ô nét đứt mờ + 4 ô li trống có chấm bắt đầu (phù hợp bé đã quen nét).

## 4. Bố cục trang A4 & Chuẩn ô li Việt Nam

- **Khổ giấy:** A4 dọc (`595.28 × 841.89 pt`, tức `210 × 297 mm`), lề an toàn máy in gia đình `36 pt` (~`12.7 mm`).
- **Font tiếng Việt offline:** nạp trực tiếp `assets/fonts/Nunito-Regular.ttf` và `assets/fonts/Nunito-Bold.ttf` từ `rootBundle` vào `pw.Font.ttf(...)` → hiển thị 100% tiếng Việt có dấu sắc nét, không tải mạng.
- **Đầu trang:**
  - Tiêu đề: `Phiếu tập tô — <Tên gọi ở nhà của bé>` (dùng tên mặc định `"Bé"` nếu rỗng).
  - Phụ đề: ngày tạo `dd/mm/yyyy` + lời khích lệ *"Cùng Chíp Chíp luyện nét đẹp mỗi ngày!"*.
  - Góc phải: số trang `Trang k/N` khi có từ 2 trang trở lên.
- **Thân trang (tối đa 6 dòng/trang):**
  - Cột nhãn trái (~`44 pt`): tên mục (`a`, `Số 3`, `Dấu hỏi`...) và số nét (`2 nét`).
  - **6 ô vuông ô li** xếp hàng ngang đều nhau (~`76 × 76 pt` / `~27 × 27 mm` mỗi ô):
    - Vẽ chính xác đường lưới ô li bằng chính công thức `RuledPaper.horizontalLines`, `RuledPaper.verticalLines`, `RuledPaper.heavyLines` từ `Glyph.ruling` (khi glyph không có `ruling` như nét cơ bản / chữ số: vẽ 5 dòng kẻ ngang chuẩn vở với dòng giữa và dòng chân chữ đậm hơn).
    - Đường lưới phụ màu xanh lam nhạt dễ nhìn khi in màu hoặc in đen trắng; đường chân chữ (`baseline`) và đường đầu chữ thường (`x-height`) đậm hơn rõ rệt.
    - Với dấu thanh (`glyph.context != null`, ví dụ `chu-a`): tự động vẽ chữ ngữ cảnh mờ làm nền bên dưới dấu (cắt gọn trong ô viết giống hệt màn tập viết `FaintLetter`), giúp bé đặt đúng vị trí dấu thanh.
    - Nét vẽ từ `Glyph.inWindow().strokes` dưới dạng đường vector mịn (bo đầu tròn `round`), nét 1 điểm (chấm chữ `i`, dấu nặng) vẽ chấm tròn rõ.
    - Ô mẫu đậm: vẽ màu mực đậm + vòng tròn nhỏ đánh số thứ tự nét tại điểm bắt đầu + mũi tên ngắn chỉ hướng viết.
    - Ô nét đứt mờ: vẽ nét đứt màu xám nhạt để bé tô theo.
    - Ô tự viết: giữ lưới ô li + chấm tròn nhỏ mờ tại điểm bắt đầu nét đầu tiên.
- **Chân trang:** *"Chíp Chíp — Học vui mỗi ngày"* bên trái + 3 ngôi sao rỗng bên phải để ba mẹ tô thưởng sau khi bé viết xong.

## 5. Kiến trúc mô-đun & Gói phụ thuộc

### 5.1 Gói phụ thuộc mới (`pubspec.yaml`)
- `pdf: ^3.11.1` (pure Dart, tương thích Dart 3.5 / Flutter 3.24.5)
- `printing: ^5.13.4` (hộp thoại in AirPrint / Android Print + share/save file PDF offline)
- Không nâng bất kỳ phiên bản gói nào đã cài; giữ nguyên `drift_flutter: 0.2.4`.

### 5.2 Tách lớp sạch sẽ (`lib/worksheet/`)
1. `lib/worksheet/worksheet_model.dart`:
   - `WorksheetSelectionMode`, `WorksheetStyle`, `WorksheetCellKind`, `WorksheetConfig`.
   - `weakGlyphIds(Map<String, GlyphStat> stats, {int maxCount = 6})`: thuật toán ưu tiên chữ bé hay sai/đang tập.
   - `paginateGlyphs(List<String> ids, {int perPage = 6})`: chia trang A4.
   - `cellKindsFor(WorksheetStyle style)`: danh sách 6 loại ô (`model`, `trace`, `blank`) trên mỗi dòng.
   - `worksheetFileName(String kidName, DateTime date)`: tạo tên file an toàn không dấu (ví dụ `phieu-tap-to-be-na-20261118.pdf`).
2. `lib/worksheet/worksheet_pdf.dart`:
   - `WorksheetPdfFonts`: giữ 2 `pw.Font` (`regular`, `bold`), có hàm tĩnh `loadFromAssets()` nạp từ `assets/fonts/Nunito-*.ttf`.
   - `Future<Uint8List> buildWorksheetPdf({required WorksheetConfig config, required Map<String, Glyph> glyphs, required WorksheetPdfFonts fonts})`: hàm thuần Dart sinh file PDF hợp lệ, test unit trực tiếp không cần native plugin.
3. `lib/worksheet/worksheet_printer.dart`:
   - `abstract class WorksheetPrinter` với 2 phương thức `printPdf(Uint8List bytes, String jobName)` và `sharePdf(Uint8List bytes, String fileName)`.
   - `PrintingWorksheetPrinter` gọi `Printing.layoutPdf` và `Printing.sharePdf`.
   - `worksheetPrinterProvider` (Riverpod `Provider<WorksheetPrinter>`) cho phép override trong widget test.
4. `lib/worksheet/worksheet_preview.dart`:
   - Widget `WorksheetPreview` vẽ trực tiếp trang A4 tỷ lệ `210 : 297` bằng `CustomPainter` cùng quy ước ô li, chữ "a" mờ, số nét, mũi tên và 3 ngôi sao chân trang — phản hồi tức thì khi ba mẹ thay đổi lựa chọn.
5. `lib/parent/screens/worksheet_screen.dart`:
   - Màn tạo & xuất phiếu trong Góc ba mẹ, responsive cả điện thoại và iPad.
   - Nút mở gắn trong `_WritingCard` của `lib/parent/screens/progress_tab.dart`.

## 6. Kiểm thử

- `test/worksheet/worksheet_model_test.dart`: kiểm thử thuật toán `weakGlyphIds` (nhiều lỗi, đang tập, bé mới), phân trang, `cellKindsFor`, chuẩn hóa tên file tiếng Việt.
- `test/worksheet/worksheet_pdf_test.dart`: kiểm thử `buildWorksheetPdf` sinh bytes PDF hợp lệ (`%PDF-1.`), hỗ trợ đủ 4 nhóm (nét cơ bản, số, chữ cái có `ruling`, dấu thanh có `context`), nhiều trang, 3 mức gợi ý, tên bé tiếng Việt có dấu.
- `test/parent/worksheet_screen_test.dart`: kiểm thử mở từ `ProgressTab`, chọn chế độ Bé đang yếu / Theo nhóm / Tự chọn, đổi mức gợi ý, lật trang xem trước, bấm In & Chia sẻ gọi đúng `WorksheetPrinter`, không overflow trên điện thoại 320×568 / 390×844 và iPad 1024×768 / 768×1024.
- Xác minh trực quan bằng render ảnh xem trước trang phiếu A4 & kiểm tra bằng mắt.
