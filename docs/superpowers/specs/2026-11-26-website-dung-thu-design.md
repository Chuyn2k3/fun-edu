# Website dùng thử ChipChip (thiết kế)

Ngày: 2026-11-26 · Nhánh: `chipchip` · Trạng thái: chủ dự án đã duyệt (2026-11-26); dev trước, deploy đợt sau

## 1. Ý định và lý do

Chủ dự án muốn một **trang web để bé chơi ngay trên trình duyệt, không cần tải app**. Trang này là **bản dùng thử nhỏ để kéo người tải app**, không phải bản đầy đủ của app.
- Trang web làm mới, **không dùng Flutter**.
- Đặt trên **máy chủ Oracle của chủ dự án**, không dùng GitHub Pages như app cũ.

Người dùng là:
- ba mẹ đang tìm app học cho con: họ cần thấy nhanh ChipChip có gì hay;
- bé 3–6 tuổi chơi thử vài phút trên điện thoại, máy tính bảng hoặc máy tính của ba mẹ.

Thành công khi ba mẹ thấy bé chơi thích và bấm nút tải app.

## 2. Mục tiêu / không làm / phản mục tiêu

**Mục tiêu**
- Mở là chơi được ngay: không đăng nhập, không cài đặt, tải nhanh trên điện thoại và mạng yếu.
- Hai trò thử:
  - **Tô chữ:** tô bằng ngón tay hoặc chuột, chấm nét **giống hệt app**;
  - **Đố vui:** Chíp đọc câu hỏi, bé chạm chọn.
- Một trang giới thiệu cho ba mẹ: app có gì, ảnh màn hình, nút tải app, quyền riêng tư.
- Giữ tinh thần app: không quảng cáo, không công cụ theo dõi, không cookie, không thu thông tin của bé.

**Không làm**
- Không làm tài khoản, đồng bộ, thang cấp, trả phí, đua với bạn, các đảo Khám phá.
- Không làm web cho ba mẹ có đăng nhập và báo cáo: đó là dự án khác về sau.
- Không có trình quản trị nội dung; nội dung nằm trong code.

**Phản mục tiêu**
- Web chấm nét khác app: bé tô đúng trên app nhưng sai trên web, hoặc ngược lại.
- Trang chậm hoặc nặng trên điện thoại cũ.
- Có bất kỳ đoạn mã nào gửi dữ liệu ra ngoài: phân tích, font từ CDN, pixel quảng cáo.
- Dẫn bé ra khỏi trang: nút tải app phải nằm ở chỗ của ba mẹ, có cổng người lớn nhẹ.
- Chạm vào máy chủ API đang chạy (bản deploy web không được làm gián đoạn app).

## 3. Ràng buộc

- Màu, font, phong cách theo app:
  - màu lấy từ `lib/ui/theme/tokens.dart` (cam chính `#C8460F`, nền kem `#FBF5EC`, chữ navy `#22284A`…);
  - font Nunito tự phục vụ từ `assets/fonts/`, không dùng Google Fonts;
  - ảnh Chíp và biểu tượng lấy từ `assets/images/`.
- Nút cho bé ≥ 64 px; chữ đạt tương phản ≥ 4.5:1; chuỗi tiếng Việt.
- Chạy được trên Safari iOS, Chrome Android và trình duyệt máy tính bản mới, với cả cảm ứng lẫn chuột (Pointer Events).
- Giọng đọc dùng Web Speech API với giọng `vi-VN` của trình duyệt.
  - Máy không có giọng tiếng Việt thì **không đọc** (không dùng giọng tiếng Anh đọc tiếng Việt). Bé vẫn chơi được bằng chữ và hình; nút loa ẩn đi.
- Không lưu gì cần thiết. Chỉ dùng `localStorage` cho tiện ích nhỏ (bật/tắt tiếng), bọc try/catch; trang vẫn chạy đúng khi `localStorage` không dùng được.
- Không có máy chủ riêng cho web: chỉ là file tĩnh do Caddy trên Oracle phục vụ.

## 4. Các cách đã cân nhắc

| Cách | Mô tả | Được / mất | Kết quả |
|---|---|---|---|
| **A** | Trang tĩnh viết bằng TypeScript thuần (Vite), canvas, không framework | Nhẹ nhất, mở nhanh; Caddy phục vụ thẳng; không có gì chạy thêm trên máy chủ. Đổi lại, web cho ba mẹ (React) về sau là dự án riêng | **Chủ dự án chọn** |
| B | Trang tĩnh dùng React | Đi trước cho web ba mẹ, nhưng nặng và nhiều thứ để bảo trì hơn cho 2 trò và một trang giới thiệu | Bỏ |
| C | Spring Boot phục vụ trang | Mỗi lần sửa web phải khởi động lại máy chủ API mà app đang dùng | Bỏ |
| — | Flutter web | Chủ dự án không muốn | Bỏ |

## 5. Thiết kế

### 5.1 Các trang

- **`/` (trang chính):**
  - Phía trên: Chíp, câu "Bé tập viết, học chữ cùng Chíp Chíp", và hai nút to **"✏️ Tô chữ"** và **"🎈 Đố vui"** cho bé.
  - Phía dưới, cho ba mẹ:
    - 3–4 điểm nổi bật (chấm từng nét, theo trình độ, 4 môn, không quảng cáo);
    - ảnh màn hình app;
    - nút App Store và Google Play;
    - liên kết quyền riêng tư.
- **`/to-chu`:** chọn một trong 8 chữ/số, tô xong thì có màn khen và gợi ý chữ tiếp theo.
- **`/do-vui`:** mỗi lượt 5 câu, xong thì có màn khen.
- **`/quyen-rieng-tu`:** chính sách đầy đủ, chia hai phần:
  - **trang web**: không thu thập gì, không cookie, không theo dõi, nét vẽ không rời máy;
  - **app ChipChip**: cùng nội dung với `lib/parent/screens/privacy_screen.dart`.

  Trang này sẽ là **đường dẫn chính sách quyền riêng tư công khai** khai báo với App Store và Google Play. Kho bắt buộc có đường dẫn này với app trẻ em, và `docs/store-listing.md` đang ghi là còn thiếu. Một test so khớp các đoạn chính giữa trang web và `privacy_screen.dart`, để hai bản không lệch nhau. Email liên hệ đặt trong file cấu hình website. *(Quyết định của người viết spec.)*

**Cuối mỗi trò** có thẻ "Muốn học tiếp? Tải ChipChip". Nút tải app nằm sau một **cổng người lớn nhẹ** (một câu hỏi phép nhân viết bằng chữ, giống cổng ba mẹ trong app), để bé không tự bấm ra khỏi trang.

```
Điện thoại
┌──────────────────────────────┐
│ 🐤 ChipChip                  │
│ Bé tập viết, học chữ cùng    │
│ Chíp Chíp                    │
│ ┌──────────┐ ┌──────────┐    │
│ │ ✏️ Tô chữ │ │ 🎈 Đố vui │    │
│ └──────────┘ └──────────┘    │
│ ── Dành cho ba mẹ ──         │
│ • Chấm từng nét …            │
│ [App Store] [Google Play]    │
│ Quyền riêng tư               │
└──────────────────────────────┘
```

### 5.2 Tô chữ

- **8 mục cố định:** số 1, 2, 3 và chữ a, o, b, c, e. Id lần lượt là `so-1`, `so-2`, `so-3`, `chu-a`, `chu-o`, `chu-b`, `chu-c`, `chu-e`. *(Quyết định của người viết spec: các mục dễ, đủ thấy cách chấm nét; danh sách nằm trong một file cấu hình.)*
- **Nét mẫu** là các file JSON chép nguyên từ `assets/glyphs/` lúc build, không sửa tay.
- **Hành vi giống màn tô của app:**
  - hiện nét mẫu và điểm bắt đầu;
  - bé tô từng nét theo thứ tự;
  - mỗi nét được chấm đúng/sai theo cùng luật với app (thứ tự, chiều, độ lệch);
  - sai thì Chíp động viên và nét mẫu nháy lại;
  - đủ nét thì có màn khen.
- **Lời nhắn** lấy từ các câu có sẵn trong app ("Giỏi quá! Giờ tô nét 2 nhé.", "Bé viết … đẹp lắm!").
- **Phần chấm** là bản TypeScript của `lib/stroke/`. Mọi ngưỡng giữ đúng như bản Dart. Rà soát đã chỉ ra những phần bắt buộc phải viết lại, thiếu thì chữ cái sẽ chấm khác app:
  - `geometry` và `gradeStroke`;
  - `Glyph.inWindow()`: cả hai màn tô của app chấm trong tọa độ cửa sổ chữ; `chu-b` có cửa sổ 0,583, các chữ khác 0,333;
  - `GradeConfig.forGlyph`: sai số co giãn theo `clamp(height/0.8, 0.5, 1)`, kèm luật đầu–cuối cho nét ngắn; nhánh dấu thanh không chạy với 8 mục này nhưng vẫn viết lại cho đủ;
  - cách `GlyphSession.submit` nhìn trước để phát hiện sai thứ tự;
  - phần chặn NaN;
  - kẹp điểm về [0,1] như `trace_pad.dart`.

  8 mục được chọn không có trường `context`, nên không cần phần phủ dấu thanh.
- **Kiểm chứng cùng kết quả:**
  - một test Dart sinh bộ ví dụ `website/test/fixtures/grading.json`: các nét đúng, sai thứ tự, ngược chiều, lệch, cho cả 8 mục, kèm kết quả app chấm;
  - test TypeScript chạy cùng bộ ví dụ và phải ra cùng kết quả.

### 5.3 Đố vui

Mỗi lượt 5 câu, 3 lựa chọn, sinh ngẫu nhiên, không cần ảnh mới:
- **Đếm sao:** "Có bao nhiêu ngôi sao?", 1–5 sao (ảnh `ic-star`), chọn số.
- **Cộng trong 5:** "2 + 1 = ?", chọn số.
- **Nghe chữ:** "Chíp đọc chữ nào?" Chíp đọc tên chữ ("chữ bờ"), bé chọn trong 3 chữ thường dễ nhầm, như b/d/h.
  - Câu này chỉ có khi trình duyệt có giọng `vi-VN`; không có giọng thì thay bằng câu đếm sao.

Luật chơi:
- Chọn sai: phím rung nhẹ, chọn lại.
- Chọn đúng: phím xanh, Chíp vui, sang câu kế. Nếu có giọng đọc thì chờ đọc xong.
- Không có điểm số, không tính giờ.

### 5.4 Giao diện

- Ưu tiên điện thoại; trên tablet và máy tính nội dung nằm giữa, rộng tối đa khoảng 720 px.
- Màn tô: vùng tô vuông chiếm phần lớn màn hình; nút "Nghe", "Xem mẫu", "Tô lại" ≥ 64 px.
- Không cuộn khi đang tô: vùng tô chặn cử chỉ cuộn và phóng to (`touch-action: none`).
- Có `prefers-reduced-motion`: giảm hiệu ứng.
- Tiêu đề trang, mô tả và ảnh chia sẻ (Open Graph) bằng tiếng Việt, để ba mẹ gửi link qua Zalo hoặc Facebook có ảnh xem trước.

### 5.5 Mã nguồn và build

- Thư mục mới `website/` ở gốc repo: Vite + TypeScript, test bằng Vitest, không framework giao diện.
- Lúc build:
  - script chép 8 file nét mẫu, ảnh Chíp cần dùng, `ic-star` và font Nunito từ `assets/` vào bản build;
  - không chép tay, không có bản thứ hai của dữ liệu.
- Bản build là thư mục `website/dist/`, không commit.
- Lệnh kiểm tra: `cd website && npm ci && npm test && npm run build`.
- **Kích thước:** JS sau nén ≤ 60 KB; cả trang đầu (không tính ảnh màn hình) ≤ 400 KB. Có bước kiểm tra trong lệnh build.
- **Font:** chỉ dùng hai độ đậm (ExtraBold cho tiêu đề, Bold cho chữ). Lúc build, font được cắt chỉ còn ký tự Latin + tiếng Việt và chuyển sang WOFF2 bằng `fonttools` (pip), mỗi file khoảng 30 KB, để không vượt mức kích thước. *(Quyết định của người viết spec.)*

### 5.6 Triển khai lên Oracle

- `server/deploy/Caddyfile` thêm một khối `{$WEB_DOMAIN}` phục vụ file tĩnh từ `/srv/web`, gồm:
  - nén gzip/zstd;
  - cache lâu cho file có mã băm, không cache `index.html`;
  - header bảo mật: CSP chỉ cho `'self'`, `X-Content-Type-Options`, `Referrer-Policy: no-referrer`, `Permissions-Policy` tắt camera, mic và vị trí.
- `docker-compose.yml` của dịch vụ `caddy`:
  - mount thêm `./web:/srv/web:ro`;
  - thêm `WEB_DOMAIN` vào `environment:` (và vào `.env.example`);
  - mount **cả thư mục** cấu hình Caddy thay vì một file `Caddyfile`, để các lần sửa sau chỉ cần `caddy reload`, không phải tạo lại container.
- **Lần đầu đưa lên** phải tạo lại container `caddy` (`docker compose up -d caddy`), nên API gián đoạn vài giây. Làm vào lúc vắng người, ví dụ ban đêm. Các lần cập nhật web sau đó chỉ là chép file, không gián đoạn gì. *(Quyết định của người viết spec.)*
- **Máy Oracle có thể đã khác repo.** `docs/online-setup.md` ghi giới hạn RAM cho từng container, nhưng `docker-compose.yml` trong repo chưa có. Vì vậy:
  - kế hoạch không deploy tự động;
  - repo được sửa cho khớp với máy (thêm giới hạn RAM như tài liệu ghi);
  - `docs/online-setup.md` có hướng dẫn từng bước để chủ dự án tự áp lên máy, gồm cả cách kiểm tra máy có sửa gì riêng không (`git status` / `diff`). *(Quyết định của người viết spec.)*
- **Quy trình cập nhật web** (ghi vào `docs/online-setup.md`):
  1. build trên máy dev;
  2. chép `website/dist/` vào thư mục `web/` cạnh `docker-compose.yml` trên Oracle bằng `rsync`.

  Không cần khởi động lại gì.
- **Tên miền:** chủ dự án điền `WEB_DOMAIN`. Tạm thời có thể dùng `web-funedu.152.67.101.215.sslip.io` như cách đang làm với API.
- **Link App Store / Google Play:** đặt trong một file cấu hình của website. Khi chưa có link thì hiện "Sắp có trên App Store / Google Play" (không bấm được).

## 6. Kiểm thử

- **Vitest:**
  - phần chấm nét khớp bộ ví dụ sinh từ Dart cho cả 8 mục;
  - sinh câu đố: 3 lựa chọn khác nhau, có đáp án, số trong phạm vi;
  - nghe chữ được thay bằng câu khác khi không có giọng;
  - lưu tiện ích vẫn chạy khi `localStorage` ném lỗi.
- **Playwright** (đã có sẵn trên máy dev), trên điện thoại 375×667, tablet và máy tính:
  - trang chính không cuộn ngang, nút ≥ 64 px;
  - tô đúng nét `so-1` bằng thao tác giả lập thì có màn khen;
  - chơi hết 5 câu đố thì có màn khen;
  - nút tải app cần qua cổng người lớn;
  - **không có yêu cầu mạng nào ra ngoài tên miền của trang** (kiểm bằng cách bắt mọi request).
- **Dart:** test sinh bộ ví dụ chấm nét chạy trong `flutter test`. Bộ ví dụ lệch với file đã commit thì test báo lỗi.

## 7. Để lại cho người làm

- Cấu trúc file trong `website/`, tên hàm, cách vẽ canvas.
- Nội dung chữ trang giới thiệu, dựa trên `docs/store-listing.md`.
- Chọn ảnh màn hình app cho trang giới thiệu (chụp bằng `tools/shot/`).
- Hiệu ứng khen (nhẹ, không thư viện ngoài).
