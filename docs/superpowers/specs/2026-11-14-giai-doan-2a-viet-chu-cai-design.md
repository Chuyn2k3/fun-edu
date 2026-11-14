# Giai đoạn 2A — Viết chữ cái (chữ thường, mẫu chữ trường tiểu học) — Thiết kế

> Phần đầu của giai đoạn 2 (thứ tự đã chốt với chủ dự án: **2A chữ cái → 2B Đua tên lửa → 2C in phiếu tập tô → 2E gói trả phí + máy chủ nhỏ → 2D tài khoản gia đình + đồng bộ**; 2F Tiếng Việt âm vần khi có giáo viên). Spec gốc: `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md`. Trạng thái dự án: `docs/PROJECT_STATE.md`.

## 1. Ý định và lý do

Bé 3–6 tuổi (nhất là bé sắp vào lớp 1) tập viết **29 chữ cái tiếng Việt viết thường theo mẫu chữ viết trong trường tiểu học của Bộ GD&ĐT**, trên ô li, app chấm từng nét như đang làm với nét cơ bản và số.

Vì sao:
- Tên app trên kho là "ChipChip: Bé Tập Viết, **Học Chữ**" — phải có chữ cái thì tên mới đúng.
- Điểm khác biệt của app là chấm nét; phụ huynh chọn app vì bé **viết đúng mẫu chữ cô dạy ở trường** — đây là điều các app chỉ có chữ in không làm được.
- Phần này không cần máy chủ, giúp bản miễn phí đủ giá trị để phát hành và đo tỷ lệ quay lại (spec mục 10) trước khi thu tiền.

## 2. Mục tiêu, không làm, không được làm

**Mục tiêu**
- 29 chữ thường: a ă â b c d đ e ê g h i k l m n o ô ơ p q r s t u ư v x y — hình dáng, chiều cao, thứ tự nét và chiều nét theo mẫu chữ trường tiểu học.
- 5 dấu thanh (sắc, huyền, hỏi, ngã, nặng) là các bài tập ngắn riêng, sau phần chữ cái.
- Học theo **nhóm nét** (dễ trước, khó sau), nối tiếp thang Viết hiện có (5 nét cơ bản + số 0–9).
- Viết trên **ô li** đúng tỷ lệ: bé thấy chữ "b" cao hơn chữ "a".
- "Bài hôm nay", bản đồ Viết, bài thử xếp cấp, góc ba mẹ, trang chủ hiểu thang mới.
- Một **tờ ảnh tổng hợp** cả 29 chữ + 5 dấu trên ô li để chủ dự án so với vở tập tô thật trước khi đưa vào app.

**Không làm (để sau)**
- Chữ hoa (chương trình lớp 1 chỉ dạy đọc chữ hoa; làm ở phần sau).
- Chữ in, ghép vần, đánh vần, đọc âm, viết từ/câu (phần 2F Tiếng Việt).
- Phân quyền miễn phí/trả phí (phần 2E).
- In phiếu tập tô (phần 2C — dùng lại dữ liệu nét của phần này).

**Không được làm (dù chạy được vẫn là thất bại)**
- Dạy sai thứ tự hoặc chiều nét so với mẫu chữ trường học.
- Chấm chữ nhỏ (cao 2 ô li) lỏng hơn hẳn chữ số hiện nay — bé viết bừa vẫn được khen.
- Làm mất tiến độ cũ của bé (nét, số đã thuộc) hoặc làm hỏng thang/bài hôm nay hiện có.
- Cần mạng.

## 3. Ràng buộc

- Mọi quy tắc trong `AGENTS.md` (Flutter 3.24.5, không thêm gói, token màu, `raisedDecoration`/`Pressable`, tablet riêng, ≥ 64/80, tương phản ≥ 4,5, chuỗi tiếng Việt, analyze + test sạch).
- **Không có ai ghi nét mẫu thật.** Nét mẫu là **dữ liệu tạm do máy sinh** (chủ dự án đã chọn). Phải đủ tốt để phát hành bản thử; ghi rõ trong PROJECT_STATE là nét tạm.
- Giữ nguyên định dạng file nét mẫu hiện có (`assets/glyphs/<id>.json`: `id`, `label`, `strokes[].points` toạ độ [0,1], y hướng xuống) — chỉ được **thêm** trường tuỳ chọn; 15 nét mẫu cũ vẫn đọc được không đổi.
- Không đổi schema cơ sở dữ liệu trừ khi bắt buộc; tiến độ lưu theo id chữ như hiện nay (`glyph_progress` theo `kid_id` + `glyph_id`).
- Chiều cao chữ theo mẫu chữ 2002 (đơn vị = 2 ô li):
  - 1 đơn vị (2 ô li): a ă â c e ê i m n o ô ơ u ư v x
  - 1,25 đơn vị (2,5 ô li): r s
  - 1,5 đơn vị (3 ô li): t
  - 2 đơn vị (4 ô li): d đ p q (p, q kéo xuống dưới đường kẻ chân)
  - 2,5 đơn vị (5 ô li): b g h k l y (g, y kéo xuống dưới đường kẻ chân)

## 4. Các cách đã cân nhắc (Approaches)

| Cách | Được | Mất |
|---|---|---|
| **1. Ghép chữ từ ~10 nét cơ bản của mẫu chữ** (móc xuôi, móc ngược, móc hai đầu, cong kín, cong hở trái/phải, khuyết trên, khuyết dưới, nét thắt, nét thẳng/xiên) vẽ bằng đường cong trong script Python; mỗi chữ = chuỗi nét có vị trí, chiều cao theo ô li, thứ tự, chiều | Đồng bộ giữa các chữ; thứ tự và chiều nét đúng như cô dạy; sửa một nét cơ bản thì mọi chữ dùng nó đẹp lên | Độ uốn chưa như tay người viết; chỗ nối có thể hơi cứng |
| 2. Lấy từ font mô phỏng mẫu chữ rồi tìm đường giữa nét | Hình đẹp sát vở mẫu | Bản quyền font không rõ; máy không biết thứ tự/chiều nét; giao nét dễ sai |
| 3. Vẽ tay từng chữ bằng toạ độ | Linh hoạt | Không đồng bộ, tốn công gấp nhiều lần |

**Chủ dự án chọn cách 1.**

## 5. Những điều chủ dự án đã quyết

- Mẫu chữ: **chữ viết thường của trường tiểu học** (không phải chữ in).
- Chữ hoa: **để sau**.
- Dấu phụ (ă â ê ô ơ ư đ): nét riêng, viết **sau** thân chữ (ví dụ "ô" = "o" rồi dấu mũ).
- Dấu thanh: 5 bài tập riêng, ngắn, sau phần chữ cái.
- Nét mẫu: **máy sinh tạm** theo cách 1, có tờ ảnh tổng hợp để chủ dự án duyệt.
- Thứ tự phần: 2A trước, không cần máy chủ.

## 6. Đề xuất của mình (chủ dự án có thể sửa khi đọc)

1. **Thứ tự học theo nhóm nét** (như cô dạy viết), nối sau `so-9`:
   - Nhóm 1 (nét móc, nét thẳng): i, t, u, ư, n, m, v, r, s
   - Nhóm 2 (nét cong): o, ô, ơ, c, x, e, ê, a, ă, â, d, đ, q
   - Nhóm 3 (nét khuyết): l, b, h, k, g, y, p
   - Dấu thanh: huyền, sắc, nặng, hỏi, ngã
   (Thứ tự trong nhóm có thể tinh chỉnh khi soạn nét; nguyên tắc: chữ dùng nét đã quen đi trước.)
2. **Mã chữ** dạng ASCII, theo kiểu gõ Telex cho chữ có dấu phụ: `chu-a`, `chu-aw` (ă), `chu-aa` (â), `chu-dd` (đ), `chu-ee` (ê), `chu-oo` (ô), `chu-ow` (ơ), `chu-uw` (ư); dấu thanh `dau-sac`, `dau-huyen`, `dau-hoi`, `dau-nga`, `dau-nang`. Nhãn hiển thị "Chữ ă", "Dấu sắc".
3. **Khung ô li chung cho mọi chữ:** mỗi file chữ mang thêm siêu dữ liệu tuỳ chọn mô tả khung ô li (vị trí đường kẻ chân chữ, chiều cao một ô li trong toạ độ [0,1]). Ô viết vẽ lưới ô li từ siêu dữ liệu này (đường kẻ chân và đường đầu chữ thường đậm hơn). Nét mẫu cũ không có siêu dữ liệu → vẫn dùng giấy kẻ 5 dòng như hiện nay.
4. **Không chấm lỏng chữ nhỏ:** ô viết **phóng to theo vùng chữ cần** (ví dụ chữ "a" chỉ hiện khoảng 4–5 hàng ô li quanh nó, chữ "b"/"g" hiện đủ 8–9 hàng) để mọi chữ chiếm phần lớn ô viết; bộ chấm vẫn dùng ngưỡng hiện có trên toạ độ đã phóng. Tiêu chí: chữ "a" phải bị chấm sai khi bé vẽ một vòng tròn lệch ra ngoài vùng 2 ô li tương đương mức chữ số hôm nay.
5. **Giọng đọc:** trường tuỳ chọn `speech` trong file chữ để Chíp đọc đúng cách cô dạy (ví dụ chữ "b" đọc "bờ", "ă" đọc "á"); không có thì đọc nhãn.
6. **Bài thử xếp cấp: giữ nguyên** (nét ngang, số 0, số 4). Bé qua hết thì bắt đầu ở số 5, rồi lần lượt sang chữ cái. Không thêm bước chữ cái: với thang hiện tại, qua một chữ ở giữa thang sẽ tự tính các chữ đứng trước là đã thuộc, điều đó sai.
7. **Bản đồ Viết chia mục:** Nét cơ bản · Chữ số · Chữ cái · Dấu thanh (49 ô); trang chủ đổi phụ đề thẻ Viết thành "Nét, số, chữ cái"; góc ba mẹ (tab Tiến bộ) nhóm chip theo các mục này.
8. **Tờ ảnh tổng hợp:** script xuất PNG 29 chữ + 5 dấu trên ô li, đánh số thứ tự nét và mũi tên chiều nét, lưu vào `docs/` để chủ dự án duyệt; mỗi lần sửa nét thì xuất lại.

## 6b. Chi tiết kỹ thuật đã chốt (mình quyết, sau lượt rà soát của người làm)

- **Toạ độ và chấm điểm:** file chữ lưu nét trong **khung ô li chung** (toạ độ [0,1], y hướng xuống) kèm siêu dữ liệu `ruling` gồm: `cell` (chiều cao 1 ô li trong toạ độ khung), `baseline` (y của đường kẻ chân chữ), và `window` (hình vuông [x, y, cạnh] bao chữ + lề ~0,5 ô li). Ô viết **luôn vuông**, hiện đúng vùng `window` phóng đầy ô viết, vẽ ô li tương ứng. Bộ chấm nhận nét mẫu và nét bé vẽ **đã quy về toạ độ [0,1] của `window`**, nên ngưỡng 0,12 / 0,25 áp dụng như chữ số hôm nay, bất kể chữ cao 2 hay 5 ô li. Nét mẫu cũ (không có `ruling`) giữ nguyên cách cũ.
- **Phân bố trên/dưới đường kẻ chân** (đơn vị ô li; người làm bám mẫu chữ 2002, tờ ảnh tổng hợp là nơi chủ dự án kiểm lại): a/c/e/i/m/n/o/u/v/x… cao 2 trên; r, s 2,5 trên; t 3 trên; d, đ 4 trên; b, h, k, l 5 trên; g, y 2 trên + 3 dưới; p, q 2 trên + 2 dưới. Dấu phụ (ă â ê ô ơ ư) và dấu thanh nằm trong 1–1,5 ô li phía trên đầu chữ; nét ngang của đ và t theo mẫu.
- **Số nét của mỗi chữ:** theo mẫu chữ 2002 — phần viết liền một mạch là một nét; nét nhấc bút (chấm của i, ngang của t và đ, dấu phụ, dấu thanh) là nét riêng, viết sau thân chữ. Tờ ảnh tổng hợp đánh số thứ tự nét để kiểm.
- **Dấu thanh:** bé tô dấu **trên một chữ "a" mờ** (chỉ để biết vị trí, không chấm) — thêm trường tuỳ chọn `context` (mã chữ nền) vào file nét mẫu. Dấu nặng là một chấm (dùng luật chấm hiện có); dấu sắc/huyền ngắn được kiểm bằng test tự chấm, chỉnh ngưỡng độ dài tối thiểu chỉ khi test cho thấy nét đúng bị chấm sai.
- **Duyệt tờ ảnh tổng hợp không phải là cửa chặn:** chữ cái được đưa vào app ngay dưới dạng dữ liệu tạm; chủ dự án duyệt và mình sửa ở lượt sau.
- **Bản đồ Viết:** giữ cách mở ô như hiện nay (không thêm khoá mới).

## 7. Để lại cho người làm

- Hình dạng cụ thể của từng nét cơ bản và tham số từng chữ (bám mẫu chữ 2002, ưu tiên nét trơn, thứ tự và chiều đúng).
- Cách tổ chức script sinh (mở rộng `tools/glyphs/make_glyphs.py` hay file mới), có test Python.
- Cách ô viết tính vùng phóng to và vẽ ô li; giao diện mục trên bản đồ Viết (điện thoại và iPad).
- Ngưỡng chấm có cần tinh chỉnh riêng cho nét khuyết/nét thắt hay không — chỉ chỉnh nếu test cho thấy bé viết đúng mà bị chấm sai; ghi lại lý do.

## 8. Xong khi

- 34 file nét mẫu mới (29 chữ + 5 dấu) trong `assets/glyphs/`, có test tự chấm: nét mẫu chấm chính nó → đúng; nét bị đảo chiều/đảo thứ tự → sai.
- Bé học được chữ cái trong "Bài hôm nay" và từ bản đồ Viết; tiến độ cũ không đổi.
- Tờ ảnh tổng hợp đã gửi chủ dự án duyệt.
- `flutter analyze` sạch, toàn bộ test đạt; `docs/PROJECT_STATE.md` cập nhật mục 6–8 (ghi rõ nét chữ cái là dữ liệu tạm).
