# Online/offline mượt: bộ thông báo chung, pipeline đồng bộ, phòng đua khi mạng chập chờn, gia cố bảo mật — thiết kế

> Ngày: 2026-11-23 · Trạng thái: **chờ chủ dự án duyệt** · Nhánh: `chipchip`
> Làm **sau** plan `docs/superpowers/plans/2026-11-23-sua-loi-review-lien-ket-may.md` (12 lỗi review) — thiết kế này dựa trên code đã sửa xong các lỗi đó.
> Người code là AI khác, có người review: đủ để lập plan không phải hỏi lại.

## 1. Vì sao

Chủ dự án muốn app **offline-first thật sự**: bé học, viết, chơi không bao giờ bị chặn vì mạng; mọi thứ lưu trên máy (drift/SQLite), có mạng thì tự đồng bộ, **không trùng, không mất, không ghi đè** khi mất mạng giữa chừng, mạng yếu, hay một tài khoản dùng trên hai máy. Ba mẹ phải **thấy được** tình trạng lưu online mà không cần vào Góc ba mẹ. Phòng đua online phải mượt khi một bạn bị văng. Mọi hộp thoại/thông báo dùng **một kiểu chung** hợp giao diện app. Máy chủ và máy phải đủ an toàn (token, chống injection, chống spam/DDoS mức ứng dụng).

## 2. Mục tiêu / Không làm / Thất bại nếu

**Mục tiêu**
1. Bộ thông báo dùng chung (hộp hỏi, hộp nguy hiểm, thông báo nhỏ, dải trạng thái) thay mọi `AlertDialog`/`SnackBar` trong app.
2. Theo dõi mạng (chỉ khi đã đăng nhập); đồng bộ ngay khi có mạng lại, sau "Xong bài hôm nay", sau trận đua; thử lại thưa dần.
3. Đồng bộ đúng với mọi ca ở §6.6 (mỗi ca có test hai máy + mạng giả cắt giữa chừng).
4. Ba mẹ thấy trạng thái lưu ở trang chủ (chip mây), dải nhắc khi > 24 giờ chưa lưu, thông báo nhỏ khi lưu xong sau thời gian offline.
5. Phòng đua: bạn văng → tên lửa đứng yên + thông báo; quá 20 s tính bỏ cuộc; còn một bạn → bạn đó thắng; chính mình văng → "Đang kết nối lại…", thất bại → màn kết quả nhẹ nhàng, không trừ sao. Nút Mời bạn đua/Nhập mã báo cần mạng khi offline.
6. Gia cố bảo mật (§8).

**Không làm**
- Không thông báo đẩy (push/local notification) — chủ dự án chốt 2026-11-23.
- Không mã hóa toàn bộ DB trên máy (SQLCipher) — chủ dự án chọn dựa vào mã hóa của hệ điều hành (cách A).
- Không viết lại sang nhật ký thao tác (event log); không khóa ghi một máy.
- Không chặn DDoS mức mạng trong code (đó là việc của lớp ngoài như Cloudflare — chỉ ghi khuyến nghị ở §8.4).

**Thất bại nếu**
- Bé thấy lỗi mạng, phải chờ, hoặc mất tiến độ vì mạng.
- Gửi lại một lần đồng bộ làm số đếm/sao tăng gấp đôi; hai máy offline rồi gộp làm mất phần của một máy.
- Chế độ khách phát sinh request mạng, hoặc theo dõi mạng chạy khi chưa đăng nhập.
- Còn `AlertDialog`/`SnackBar` gọi trực tiếp ngoài bộ chung.

## 3. Ràng buộc

`AGENTS.md` đầy đủ (Flutter 3.24.5, không nâng gói, Riverpod, tokens, nút bé ≥ 64 / tablet ≥ 80, ba mẹ ≥ 48, tương phản ≥ 4.5:1, chuỗi tiếng Việt, drift đổi bảng → tăng schema + migration + `.g.dart`). **Gói mới duy nhất:** `connectivity_plus` — chọn bản tương thích Flutter 3.24.5/Dart 3.5 (kiểm trước khi ghim, ví dụ dòng 6.x), ghi phiên bản vào `PROJECT_STATE.md`. Máy chủ: Spring Boot 3.3.5, không thêm thư viện ngoài Bucket4j nếu cần (hoặc tự viết bộ đếm như `AuthRateLimitFilter` hiện có — **ưu tiên tự viết**, không thêm phụ thuộc).

## 4. Các cách đã cân nhắc (pipeline đồng bộ)

| Cách | Mô tả | Được | Mất |
|---|---|---|---|
| **1. Giữ kho bản ghi theo khóa, gia cố** ✅ | Giữ khóa/`baseVersion`/khóa theo gia đình/so với `synced_records`; thêm đếm theo máy, LWW cho cài đặt, kéo theo trang, retry/timeout/lô thích ứng | Không viết lại repository; mỗi luật gộp có test | Luật gộp riêng từng loại; loại mới phải thêm luật (có test quét bắt buộc, §6.5) |
| 2. Nhật ký thao tác | Mỗi hành động là một dòng log có mã; dựng trạng thái từ log | Chặt nhất về lý thuyết | Sửa ~15 repository + chuyển dữ liệu; gấp 3–4 lần công |
| 3. Một máy được ghi | Máy kia chỉ xem | Đơn giản | Phá offline-first — loại |

**Chủ dự án chọn cách 1** (2026-11-23). Mã hóa DB trên máy: **cách A** (dựa vào hệ điều hành). Phòng đua: **A + C**.

## 5. Phần A — Bộ thông báo dùng chung (`lib/ui/feedback/`)

Các thành phần (tất cả lấy màu/bo góc/bóng từ `tokens.dart`, font Nunito, thẻ = một `BoxDecoration` có cả màu và bóng):

| API | Dùng khi | Hình |
|---|---|---|
| `Future<bool?> showAppDialog(BuildContext, {required String title, String? message, Widget? body, required String primaryLabel, String? secondaryLabel, AppDialogTone tone = AppDialogTone.normal, String? image, bool dismissible = true, AppAudience audience = AppAudience.parent})` | Mọi hộp hỏi/xác nhận | Thẻ trắng bo `AppRadii.tile`, ảnh Chíp nhỏ (mặc định `AppImages.chipMain`, có thể đổi), tiêu đề w900, nội dung w700 `textMuted`, nút chính `PrimaryButton`, nút phụ dạng chữ |
| `AppDialogTone.danger` | Xóa, thay dữ liệu | Nút hành động nguy hiểm là **nút phụ chữ đỏ** (token đỏ hiện có hoặc `AppColors.primary` nếu không có — không viết mã màu mới); nút chính là lựa chọn an toàn |
| `void showAppToast(BuildContext, String text, {AppToastKind kind = AppToastKind.info})` (`info/success/warning/offline/online`) | Thông báo ngắn | Viên thuốc trôi từ trên, biểu tượng theo loại, tự ẩn 3 s, chồng nhau thì thay cái cũ; dùng `Overlay` (không dùng `SnackBar`) |
| `AppStatusBanner({required String text, required AppToastKind kind, VoidCallback? onTap})` | Dải cố định (nhắc lưu online, mất mạng trong phòng đua) | Dải bo tròn, nền `tint` theo loại |

- `AppAudience.kid` → nút ≥ 64 (tablet ≥ 80), chữ lớn hơn; `parent` → nút ≥ 48. Tablet: thẻ hộp tối đa `TabletSizes.messageMaxWidth`.
- Hộp `dismissible: false` → `barrierDismissible: false` + `PopScope(canPop: false)`.
- **Thay toàn bộ**: 9 file đang dùng `showDialog`/`AlertDialog` (`settings_tab`, `kids_tab`, `worksheet_screen`, `family_account_card`, `collection_screen`, `notebook_section`, `replace_data_dialog`, `online_consent_dialog`, `sleep_screen`) và mọi `ScaffoldMessenger…showSnackBar`. `replace_data_dialog` giữ bố cục so sánh hai cột nhưng bọc bằng `showAppDialog(body: …)`.
- **Test quét mã nguồn** `test/ui/no_raw_dialogs_test.dart`: đọc mọi file `lib/**.dart` trừ `lib/ui/feedback/`, thất bại nếu có `AlertDialog(`, `showSnackBar(`, `SnackBar(`.

## 6. Phần B — Theo dõi mạng + pipeline đồng bộ

### 6.1 Theo dõi mạng (`lib/online/net/network_status.dart`)

- `enum NetState { unknown, offline, online }`. `networkStatusProvider` (Riverpod) **chỉ khởi động khi có phiên đăng nhập** (`sessionProvider` khác null) và `OnlineConfig.enabled`; đăng xuất → dừng. Chế độ khách: provider trả `unknown`, không gọi `connectivity_plus`.
- `connectivity_plus` chỉ là **gợi ý**: báo "không có kết nối" → `offline` ngay; báo "có kết nối" → chưa tin, kích hoạt đồng bộ; trạng thái `online` chỉ được đặt khi một request tới máy chủ thành công (đồng bộ hoặc phòng đua). Request thất bại vì mạng (`ApiException.status == 0`/timeout) → `offline`.
- Không ping riêng; không request nào ngoài máy chủ FunEdu.

### 6.2 Khi nào đồng bộ (`SyncController`)

Giữ: đăng nhập/liên kết xong, mở lại app (resume), mỗi 5 phút khi mở, bấm tay. Thêm:
- `NetState` chuyển `offline/unknown → (connectivity báo có mạng)` → `syncNow()` sau 2 s (gộp các báo liên tiếp).
- Sau `recordLessonCompleted` (màn "Xong bài hôm nay") và sau khi lưu kết quả trận đua (`GameRepository` offline + online): gọi `ref.read(syncControllerProvider.notifier).requestSync()` — hàm không chặn, gộp yêu cầu trong 3 s.
- **Thử lại thưa dần** khi lỗi: 30 s, 1 phút, 2 phút, 4 phút, 8 phút, rồi 10 phút cố định; thành công → về lại lịch 5 phút. Bộ hẹn giờ thử lại hủy khi có trigger mới thành công. App ở nền → không hẹn giờ (dừng timer, tiếp tục khi resume).
- Một lần đồng bộ tại một thời điểm (giữ `_running`); trigger đến khi đang chạy → đánh dấu `_again = true`, chạy thêm đúng một lần sau khi xong.

### 6.3 Mỗi lần đồng bộ (`SyncEngine.run`)

1. **Timeout** mỗi request 15 s (`ApiClient` thêm `timeout`). Timeout/mất mạng → dừng lần đồng bộ, lỗi `network`.
2. **Đẩy**: lấy `pendingChanges()` (so với `synced_records` như hiện nay), gửi theo lô. Kích cỡ lô thích ứng: bắt đầu 500; timeout → lô sau ×½ (tối thiểu 50), lưu ở `sync.batch`; thành công 3 lần liên tiếp → ×2 (tối đa 500).
3. **Kéo theo trang**: mỗi phản hồi (≤ 1000 bản ghi) được **gộp ngay trong một transaction drift** cùng với việc ghi `sync.cursor` = `version` của trang đó. Bỏ cách "kéo hết rồi mới gộp". Thứ tự bé-trước-tiến-độ: bản ghi tiến độ của bé chưa có (uuid lạ) được để vào bảng chờ `sync_pending_remote` (key, version, payload) và áp lại sau khi bản ghi `kid:` tới (ở trang sau hoặc lần sau); áp được thì xóa khỏi bảng chờ.
4. Xung đột (`conflicts`): máy chủ trả bản thắng; app gộp theo luật §6.4, ghi local, vòng sau gửi bản đã gộp với `baseVersion` mới. Tối đa 5 vòng như hiện nay.
5. `markSynced(key, version, payload)` chỉ sau khi máy chủ trả 200 cho lô đó.

### 6.4 Luật gộp (sửa các luật "lấy số lớn hơn" làm mất dữ liệu)

**Nguyên tắc: luôn gửi giá trị tuyệt đối của từng máy, không bao giờ gửi "+n".** Gửi lại bao nhiêu lần cũng ra cùng kết quả.

| Loại | Payload mới | Gộp | Giá trị dùng trong app |
|---|---|---|---|
| `glyph` (số lần viết, số lần sạch) | `{"by": {"<deviceId>": {"c": 5, "k": 3}}, "last": ms}` | mỗi máy lấy max của chính máy đó; `last` = max | tổng các máy |
| `usage` (giây/ngày) | `{"by": {"<deviceId>": 900}}` | mỗi máy max | tổng |
| `counter` (tiến độ huy hiệu) | `{"by": {"<deviceId>": 7}}` | mỗi máy max | tổng |
| `game.cosmicStars` (sao vũ trụ) | `{"earned": {"<deviceId>": 120}, "spent": {"<deviceId>": 0}, ...phần còn lại}` | `earned`/`spent` mỗi máy max; các trường khác (tên lửa đang chọn…) LWW theo `updatedAt` | `Σearned − Σspent` (hiện app chưa có tiêu sao: `spent` để sẵn, luôn 0) |
| `setting`, `kid`, `reward`, `game` (trường không đếm) | thêm `"u": ms` (thời điểm sửa trên máy) | **LWW**: `u` lớn hơn thắng; bằng nhau → so `deviceId` (chuỗi) để hai máy chọn giống nhau | — |
| `lesson`, `race`, `item`, `badge`, `page`, `level` | giữ nguyên | như hiện tại | — |

- Bảng local giữ số tổng như hiện nay; **phần của máy này** = tổng local − tổng các máy khác đã biết. Cách cài: bảng drift mới `device_counters (key TEXT, device_id TEXT, value INT, PK(key, device_id))` lưu phần của từng máy đã biết (kể cả máy này); `exportAll()` dựng payload `by` từ bảng này; mọi chỗ ghi số đếm (`ProgressRepository.recordGlyphCompleted`, ghi giây sử dụng, `GameRepository`, bộ đếm huy hiệu) cộng vào **dòng của máy này** trong `device_counters` và cập nhật cột tổng trong cùng transaction. `applyRemote` ghi dòng các máy khác rồi tính lại tổng.
- **Chuyển dữ liệu cũ** (migration drift + lần đồng bộ đầu): giá trị hiện có của mỗi bộ đếm gán cho dòng `deviceId` của máy này. Bản ghi cũ trên máy chủ (dạng không có `by`) khi kéo về: coi là phần của máy `"legacy"`; khi máy này đẩy bản mới, phần `"legacy"` được giữ nguyên trong `by` (không mất số cũ). Có test.
- `deviceId` là mã đã có từ đợt liên kết máy (`app_settings.deviceId`).
- **Thời điểm sửa cho LWW**: thêm cột `updated_at` (DateTime, nullable) vào `app_settings`, `kid_profiles`, `real_rewards`, `game_profile` (cùng lần tăng schema v11); mọi chỗ ghi các bảng này đặt `updated_at = now`. Cột null (dữ liệu cũ) coi là `u = 0`. `exportAll()` đưa vào payload trường `u`.

### 6.5 Chống quên luật gộp

Test `test/online/merge_rules_coverage_test.dart`: mọi `kind` trong `SyncStore.exportAll()` của một DB đầy đủ dữ liệu phải có luật trong `_merge` (danh sách tường minh, không rơi vào `default`) và phải nằm trong `SyncKinds.ALLOWED` của máy chủ (đọc file Java bằng regex). Thêm loại mới mà quên → test đỏ.

### 6.6 Các ca lỗi phải có test (máy chủ giả + hai máy + mạng giả)

Mở rộng `test/online/fake_sync_server.dart`: có thể (a) làm rơi phản hồi sau khi đã lưu (máy chủ đã ghi, máy nhận timeout), (b) trễ quá 15 s, (c) lỗi 500, (d) cắt giữa các trang kéo về.

| Test | Kỳ vọng |
|---|---|
| `lost response after server saved does not double` | Máy A đẩy 10 bài + glyph c=3, phản hồi rơi; lần sau đồng bộ → máy chủ có đúng 10 `lesson`, glyph tổng 3 |
| `two devices offline both count` | A viết "a" 3 lần, B 2 lần, cả hai offline rồi đồng bộ theo thứ tự bất kỳ → cả hai máy thấy 5 |
| `cosmic stars earned on two devices add up` | A +10, B +5 → 15 trên cả hai |
| `settings last edit wins on both devices` | A đặt giới hạn 20 phút lúc t1, B đặt 30 phút lúc t2 > t1 → cả hai 30 |
| `pull resumes from the last applied page` | 2500 bản ghi, cắt sau trang 1 → lần sau chỉ kéo từ trang 2 (đếm request), dữ liệu đủ |
| `progress before its kid waits and applies later` | trang 1 có `glyph:<uuid>` của bé mới, trang 2 có `kid:<uuid>` → sau cùng có tiến độ đầy đủ |
| `timeout halves the batch` | 1000 thay đổi, máy chủ giả timeout lô 500 → lô 250 thành công; không trùng |
| `retry backs off and resets` | lỗi liên tiếp → hẹn 30 s, 60 s, 120 s…; thành công → về 5 phút (dùng `fake_async`) |
| `app killed mid-pull keeps data consistent` | ném lỗi giữa `applyRemote` trang 2 → trang 1 đã lưu + cursor trang 1; mở lại → đủ |
| `legacy counters keep their value` | máy chủ có `glyph` dạng cũ c=4; máy đẩy dạng mới → tổng không dưới 4, không gấp đôi |
| `guest mode makes no requests and starts no watcher` | không đăng nhập → 0 request, `connectivity_plus` giả không được gọi |

### 6.7 Ba mẹ thấy trạng thái (không cần vào Góc ba mẹ)

- `syncHealthProvider` → `SyncHealth { int pending; DateTime? lastOkAt; NetState net; bool running; }`. `pending` = số bản ghi chưa đồng bộ, **đếm theo loại hiển thị được** (bài học, chữ, trận đua); tính rẻ: lưu sau mỗi `pendingChanges()` vào bộ nhớ, không quét DB liên tục.
- **Chip mây trang chủ** (`home_screen.dart`, `home_tablet.dart`, góc trên cạnh thanh sao; chỉ khi đã đăng nhập): ☁✓ "Đã lưu" (ẩn chữ sau 3 s, còn biểu tượng) · ☁↑ "Đang lưu…" · ☁⚠ "N bài chưa lưu". Chạm → cổng ba mẹ → Góc ba mẹ mở cuộn tới thẻ tài khoản. Chip ≥ 48 (đối tượng ba mẹ).
- **Dải nhắc** (`AppStatusBanner`, trang chủ, trên nội dung): khi `lastOkAt` cũ hơn 24 giờ **và** `pending > 0`: "Ba mẹ ơi, tiến độ N ngày nay chưa lưu online. Kiểm tra mạng giúp bé nhé". Chạm → như chip. Ẩn ngay khi đồng bộ thành công. Không hiện trong màn học/viết/đua.
- **Thông báo nhỏ** `showAppToast(kind: online)` "Đã lưu online tiến độ của bé ✓" khi một lần đồng bộ thành công sau khi đã `offline` ≥ 1 phút — chỉ khi đang ở `/` hoặc `/parent*`.
- **Thẻ tài khoản ở Góc ba mẹ**: thêm "Đang offline · N bài chưa lưu, sẽ tự lưu khi có mạng" khi `net == offline`.
- Màn bé (học, viết, đua offline): **không** hiện gì về mạng.

## 7. Phần C — Phòng đua khi mạng chập chờn (A + C)

### 7.1 Máy chủ (`server/.../room/Room.java`)

- Giữ: `reconnectGrace` 20 s; trong trận, quá hạn → `p.left = true`.
- **Mới (C)**: trong `racing`, sau mỗi thay đổi (`tick`, rời phòng, quá hạn): nếu số người **chưa `left` và chưa về đích** ≤ 1 **và** số người chưa `left` (kể cả đã về đích) == 1 → người còn lại được xếp hạng ngay (hạng = số người đã về đích + 1), `state = done`, gửi `{"type":"result", "reason":"others_left"}` trong snapshot. Có ≥ 2 người chưa `left` → đua tiếp như thường.
- Snapshot mỗi người thêm `"away": true` khi mất kết nối nhưng còn trong 20 s (khác `left`), và `"awaySince"` (ms còn lại tới khi bị tính bỏ cuộc) để app đếm ngược.
- Test (`RoomFlowTest`): `racer away then back keeps progress`, `racer away past grace is left and race goes on` (3 người), `only one left wins at once` (2 người, một văng quá 20 s), `everyone else left after someone finished` (A về đích, B văng → C thắng hạng 2).

### 7.2 App

- `RoomPlayer` thêm `away` (bool), `awayMsLeft` (int?). `RoomState` thêm `endReason` (`'others_left'` | null).
- **Bạn văng** (`away`): trong `RaceScreen` online, tên lửa bạn đó đứng yên, mờ 40%, nhãn nhỏ "Đang chờ" trên avatar; `showAppToast(kind: warning)` "Bin bị mất mạng, đang chờ Bin quay lại…" một lần mỗi lần văng. Bạn đó quay lại → toast `success` "Bin đã quay lại!". Quá hạn (`left`) → toast "Bin đã rời trận" và tên lửa biến mất khỏi dải xếp hạng (`race_standings_strip.dart`, hiện "Rời trận").
- **Còn mình (C)**: màn kết quả với tiêu đề "Các bạn đã rời trận, con thắng rồi!" (hạng 1) hoặc theo hạng nếu có bạn đã về đích; nhận sao/sticker như thắng thường (`onlineCosmicStarsFor` theo hạng).
- **Chính mình văng**: `RoomController` khi socket đứt trong `racing` → `RoomState.reconnecting = true`; màn đua **giữ nguyên** (bé vẫn thấy cảnh, không trả lời được), phủ `AppStatusBanner(kind: offline)` "Đang kết nối lại…" + Chíp. Thử lại 1 s, 3 s, 6 s, rồi tiếp mỗi 5 s **cho tới khi hết 20 s** (khớp hạn của máy chủ; đổi `roomRetryDelaysProvider`). Nối lại → snapshot đồng bộ tiến độ, ẩn dải. Hết 20 s → về màn kết quả kiểu "Mạng chập chờn mất rồi, mình đua lại sau nhé!" + Chíp động viên, **không trừ sao, không lưu trận** (không gọi `GameRepository`), nút "Về Góc Chơi".
- **Phòng chờ**: bạn `away` hiện như hiện nay (mờ + "Đang kết nối lại…") kèm đếm ngược giây còn lại.
- **Nút Mời bạn đua / Nhập mã** khi `NetState.offline`: nút vẫn hiện; chạm → `showAppDialog(audience: kid, image: chip động viên)` "Cần có mạng để đua với bạn nhé" (một nút "Được rồi"). Không qua cổng ba mẹ trước.
- Test (`test/online/room_controller_test.dart`, `test/features/online_race/`): `rival away shows waiting and toast`, `rival back shows toast once`, `last one standing wins with others_left title`, `self drop keeps race screen with banner`, `self reconnect within 20s resumes`, `self drop past 20s shows gentle result without saving`, `offline invite shows need-network dialog`.

## 8. Phần D — Gia cố bảo mật (cách A)

### 8.1 Trên máy
- Android: `android:allowBackup="false"` + `android:fullBackupContent="false"` + `android:dataExtractionRules` (Android 12+) loại trừ mọi thứ — DB và token không lên sao lưu đám mây/chuyển máy. iOS: đánh dấu thư mục DB `NSURLIsExcludedFromBackupKey` (qua `path_provider` + platform channel nhỏ hoặc gói có sẵn trong dự án; nếu cần code native thì ghi rõ trong plan) — **người code kiểm cách làm được mà không thêm gói; nếu không được, ghi lại là việc sau**.
- iOS Data Protection: `NSFileProtectionComplete` cho app (entitlement `com.apple.developer.default-data-protection`), file DB mở được khi máy đã mở khóa (app chỉ chạy khi mở khóa).
- Token: giữ `flutter_secure_storage` (Keychain/Keystore); Android dùng `encryptedSharedPreferences: true`.
- Log debug: không in token, payload đồng bộ, tên bé (rà `debugPrint` trong `lib/online/`).

### 8.2 Xác thực mọi request
- Giữ: mọi `/api/v1/**` trừ đăng nhập/refresh/health cần access JWT (HS256, 15 phút, kiểm `iss`/`aud`/hạn); gia đình lấy từ token; refresh xoay vòng, dùng lại → thu hồi hết.
- WebSocket phòng: kiểm token khi bắt tay (đã có) — thêm test `ws without token is refused`.
- Thêm test quét: mọi `@RequestMapping` trong `server/src/main` (trừ danh sách trắng) có tham số `@AuthenticationPrincipal Jwt` — chống quên.

### 8.3 Chống injection / dữ liệu xấu
- Giữ: mọi SQL qua `JdbcTemplate` có tham số; danh sách trắng `kind`; regex khóa; payload ≤ 16 KB, ≤ 2000 thay đổi.
- Thêm **test quét** `NoSqlConcatTest`: không có chuỗi SQL (`SELECT|INSERT|UPDATE|DELETE`) được ghép bằng `+` với biến (cho phép ghép hằng số chuỗi như `AccountSummary` hiện tại — kiểm bằng regex: phần sau `+` phải là literal).
- Payload: kiểm là JSON object, độ sâu ≤ 6, không chứa chuỗi > 4 KB (trừ `page` mảng số) — chống payload lồng sâu.
- Giới hạn kích thước request: `server.tomcat.max-swallow-size`, `spring.servlet…` không áp cho JSON → thêm filter `RequestSizeLimitFilter`: `Content-Length` > 4 MB → 413; không có `Content-Length` thì đếm luồng, vượt → 413. (4 MB = 2000 × ~2 KB trung bình; lô 500 của app ≪ 4 MB.)
- Caddy: `request_body max_size 4MB` trong `server/deploy/Caddyfile`.

### 8.4 Chống spam / DDoS mức ứng dụng
- Mở rộng `AuthRateLimitFilter` thành `RateLimitFilter` với nhiều nhóm (cửa sổ trượt 1 phút, bộ nhớ, dọn khóa cũ):
  - đăng nhập/refresh: 20/phút/IP (giữ);
  - `/api/v1/sync`: 60/phút/**gia đình** (lấy từ token) và 120/phút/IP;
  - `POST /api/v1/rooms`: 10/phút/gia đình (giữ giới hạn đoán mã hiện có);
  - WebSocket: ≤ 5 kết nối đồng thời/gia đình, ≤ 20 tin/giây/kết nối (đóng kết nối nếu vượt).
  - Vượt → 429 `{"error":"too_many"}` + `Retry-After`; app coi 429 như lỗi mạng tạm thời (thử lại thưa dần, không báo lỗi cho bé).
- Caddy: giới hạn kết nối/timeout đọc (`read_timeout 30s`, `write_timeout 30s`) để chống slowloris.
- Ghi khuyến nghị (không code): đặt Cloudflare (gói miễn phí) trước tên miền API khi lên thật; chỉ mở cổng 443 trên Oracle, chặn 8080/5432 từ ngoài (`server/deploy/README` hoặc `docs/online-setup.md` mục triển khai).
- Test: `syncRateLimitedPerFamily`, `oversizeBodyIs413`, `deepPayloadIsRejected`, `wsFloodIsClosed`.

### 8.5 Máy chủ khi lưu
- PostgreSQL trên Oracle: đĩa mã hóa mặc định của Oracle Cloud (Block Volume encryption) — ghi vào hướng dẫn triển khai; kết nối app↔DB trong mạng Docker nội bộ (không mở 5432). Không mã hóa cột thêm (dữ liệu tối thiểu); `apple_refresh_token` đã niêm phong AES-GCM.

## 9. Thứ tự làm (gợi ý cho plan)

1. Phần A (bộ thông báo) — các phần sau dùng nó.
2. Phần B: theo dõi mạng + trigger + retry → pipeline (timeout, lô thích ứng, kéo theo trang + bảng chờ) → luật gộp theo máy + migration → chip/dải/toast cho ba mẹ.
3. Phần C: máy chủ (away/C) → app.
4. Phần D: máy chủ (giới hạn, kích thước, test quét) → app (backup, secure storage, log).

Drift: `device_counters` + `sync_pending_remote` cùng một lần tăng schema (sau v10 của plan sửa lỗi → **v11**).

## 10. Để người code tự quyết (ghi trong PR)

- Phiên bản `connectivity_plus` cụ thể (tương thích Flutter 3.24.5).
- Vị trí chính xác của chip mây trên tablet ngang/dọc (miễn không che nút của bé).
- Cách đánh dấu không sao lưu trên iOS (§8.1).
- Tên lớp/file con trong `lib/ui/feedback/` và `lib/online/net/`.

## 11. Quyết định của tôi (AI viết spec), chủ dự án kiểm khi đọc

- Dải nhắc ba mẹ hiện khi **> 24 giờ** chưa lưu và có dữ liệu chờ.
- Toast "đã lưu" chỉ khi trước đó offline ≥ 1 phút (tránh nhắc liên tục).
- Hạn chờ bạn văng giữ **20 giây** (khớp máy chủ hiện có).
- Nút nguy hiểm trong hộp là nút phụ chữ đỏ, nút chính là lựa chọn an toàn.
- Giới hạn: 60 lần đồng bộ/phút/gia đình, request ≤ 4 MB.
- Sao vũ trụ để sẵn `spent` dù app chưa có chỗ tiêu sao (để sau này mua đồ không phải đổi định dạng).
