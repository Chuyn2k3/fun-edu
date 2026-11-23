# Online/offline mượt — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bộ thông báo dùng chung toàn app; pipeline đồng bộ offline-first chịu được mất mạng/mạng yếu/hai máy; ba mẹ thấy trạng thái lưu ở trang chủ; phòng đua mượt khi có bạn văng (A + C); gia cố bảo mật máy và máy chủ.

**Architecture:** `lib/ui/feedback/` (hộp, toast, dải) thay mọi `AlertDialog`/`SnackBar`. `lib/online/net/` theo dõi mạng (chỉ khi đăng nhập) kích hoạt `SyncController` (retry thưa dần). `SyncEngine` gộp theo từng trang, timeout + lô thích ứng; số đếm lưu theo máy trong bảng `device_counters`, cài đặt LWW bằng cột `updated_at` (drift v11). Máy chủ phòng thêm `away` + luật "còn một người thắng"; `RateLimitFilter` + `RequestSizeLimitFilter` + test quét.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6, drift (v10 → v11), go_router 15, `connectivity_plus` (gói mới duy nhất); Spring Boot 3.3.5, Java 21, PostgreSQL 16; Caddy.

**Spec:** `docs/superpowers/specs/2026-11-23-online-offline-muot-design.md` (đã duyệt 2026-11-23). **Điều kiện bắt đầu:** plan `docs/superpowers/plans/2026-11-23-sua-loi-review-lien-ket-may.md` đã xong (drift đang v10, `LinkController._ensureLinkedThenPull`, `SyncEngine.run({bool pushLocal})`, `LinkWarningListener` đã có).

## Global Constraints

- Toàn bộ `AGENTS.md`: không nâng gói; Riverpod; màu/bo góc/bóng từ `lib/ui/theme/tokens.dart`; ảnh qua `lib/ui/assets.dart`; thẻ = một `BoxDecoration` có màu + bóng; nút bé ≥ 64 (tablet ≥ 80), nút ba mẹ ≥ 48; tương phản ≥ 4.5:1; chuỗi giao diện tiếng Việt; chú thích tiếng Anh.
- Gói mới duy nhất `connectivity_plus`, bản tương thích Flutter 3.24.5/Dart 3.5 (kiểm `flutter pub get` không đổi phiên bản gói khác trong `pubspec.lock`); ghi phiên bản vào `PROJECT_STATE.md`. Máy chủ không thêm thư viện.
- Chế độ khách / build không có `FUNEDU_API_URL`: 0 request, không gọi `connectivity_plus`.
- Không thông báo đẩy; không SQLCipher; không event log.
- Gửi số đếm **luôn là giá trị tuyệt đối theo máy**, không gửi "+n".
- Drift: một lần tăng schema **v11** cho `device_counters`, `sync_pending_remote`, cột `updated_at`; migration + test v10→v11 và v1→v11; build_runner; commit `.g.dart`.
- Trước mỗi commit: `flutter analyze` sạch + test liên quan đạt; máy chủ `cd server && ./gradlew test` (môi trường AI: `pg_ctlcluster 16 main start`; `TEST_DB_URL=jdbc:postgresql://localhost:5432/funedu_test ./gradlew --max-workers=1 test`).
- Nhánh `chipchip`; commit kết thúc bằng dòng `Co-Authored-By:` theo phiên.

## Review Focus

1. **Máy cũ đã có số đếm trước v11** (glyph completions, giây dùng, bộ đếm huy hiệu, sao vũ trụ) rồi đồng bộ lần đầu dạng mới: tổng không giảm, không gấp đôi trên cả máy này lẫn máy kia còn đang chạy bản cũ chưa cập nhật. → test ở Task 6 (`legacy counters keep their value`, `old server record from not-yet-updated device`).
2. **Đổi bé giữa lúc đồng bộ đang chạy** (ba mẹ chuyển bé trong Góc ba mẹ): đồng bộ không ghi nhầm tiến độ sang bé khác, màn hình làm mới đúng bé. → test ở Task 5 (`switching kid during sync keeps data per kid`).
3. **Đồng hồ máy chỉnh lùi** (ba mẹ đổi giờ): LWW cài đặt vẫn hội tụ giống nhau trên hai máy (so `u`, bằng nhau so `deviceId`), số đếm không bị ảnh hưởng. → test ở Task 6 (`clock skew still converges`).
4. **Toast/dải chồng nhau** khi mạng nhấp nháy (mất/có 10 lần trong 30 s): tối đa một toast trên màn, không nhắc "đã lưu" liên tục. → test ở Task 7 (`flapping network shows at most one toast`).
5. **Bạn văng đúng lúc 3-2-1 đếm ngược** (chưa vào `racing`): xử lý như phòng chờ (giữ chỗ 20 s, không tính bỏ cuộc trận), và nếu còn 1 người khi vào `racing` thì luật C áp ngay. → test ở Task 8 (`drop during countdown`).

---

## Bản đồ file

**App**
- `lib/ui/feedback/app_dialog.dart`, `app_toast.dart`, `app_status_banner.dart`, `feedback.dart` (export) — mới.
- `lib/online/net/network_status.dart` — mới. `lib/online/api_client.dart` (timeout 15 s, phân biệt timeout).
- `lib/online/sync/sync_engine.dart` (`SyncController` trigger/retry; `SyncEngine` theo trang, lô thích ứng), `lib/online/sync/sync_store.dart` (luật gộp, `by`, `u`, bảng chờ), `lib/online/sync/sync_health.dart` — mới.
- `lib/online/sync/device_counters.dart` — mới (đọc/ghi phần theo máy).
- `lib/data/app_database.dart` (+`.g.dart`): bảng `DeviceCounters`, `SyncPendingRemote`, cột `updatedAt`.
- Nơi ghi số đếm: `lib/progress/progress_repository.dart`, `lib/screen_time/screen_time_service.dart`, `lib/game/data/game_repository.dart`, `lib/profile/kid_repository.dart` (cập nhật `updated_at`).
- `lib/features/home/home_screen.dart`, `home_tablet.dart`, `lib/features/home/sync_chip.dart` — mới; `lib/parent/screens/family_account_card.dart`.
- `lib/online/room/room_controller.dart`, `lib/features/online_race/*.dart`, `lib/features/game/race_standings_strip.dart`, `lib/features/game/game_hub_screen.dart` (nút Mời bạn đua/Nhập mã).
- 9 file hộp thoại (spec §5) + mọi chỗ `showSnackBar`.
- `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/data_extraction_rules.xml` (mới), `ios/Runner/Runner.entitlements`.

**Máy chủ**
- `room/Room.java`, `room/RoomSocketHandler.java`; `web/RateLimitFilter.java` (thay `AuthRateLimitFilter.java`), `web/RequestSizeLimitFilter.java` (mới), `web/SecurityConfig.java`; `sync/SyncService.java` (độ sâu payload); `deploy/Caddyfile`; `docs/online-setup.md`.

---

### Task 1: Bộ thông báo dùng chung `lib/ui/feedback/`

**Files:**
- Create: `lib/ui/feedback/app_dialog.dart`, `app_toast.dart`, `app_status_banner.dart`, `feedback.dart`
- Test: `test/ui/feedback/app_dialog_test.dart`, `app_toast_test.dart`, `app_status_banner_test.dart`

**Interfaces:**
- Produces (đúng spec §5):
  - `enum AppDialogTone { normal, danger }`, `enum AppAudience { kid, parent }`
  - `Future<bool?> showAppDialog(BuildContext context, {required String title, String? message, Widget? body, required String primaryLabel, String? secondaryLabel, AppDialogTone tone = AppDialogTone.normal, String? image, bool dismissible = true, AppAudience audience = AppAudience.parent})` — trả `true` khi bấm nút chính, `false` nút phụ, `null` khi đóng ngoài.
  - `enum AppToastKind { info, success, warning, offline, online }`; `void showAppToast(BuildContext context, String text, {AppToastKind kind = AppToastKind.info, Duration duration = const Duration(seconds: 3)})` — dùng `Overlay.of(context, rootOverlay: true)`, toast mới thay toast cũ.
  - `class AppStatusBanner extends StatelessWidget { const AppStatusBanner({super.key, required this.text, required this.kind, this.onTap}); }`
- Tone `danger`: nút phụ là hành động nguy hiểm, chữ màu đỏ lấy từ token hiện có (nếu `tokens.dart` không có màu đỏ đạt 4.5:1 trên trắng, thêm **một** token `AppColors.danger` vào `tokens.dart`, có test tương phản).

- [ ] **Step 1: Viết test hỏng**:
  - `dialog returns true/false/null` theo nút chính/phụ/chạm ngoài.
  - `non-dismissible dialog ignores outside tap and back`.
  - `kid audience buttons are at least 64 (80 on tablet)`; `parent audience at least 48`.
  - `danger tone shows the danger action as a red text button` + `contrastRatio(danger, AppColors.card) >= 4.5`.
  - `dialog is one card decoration with color and shadow` (tìm `DecoratedBox`/`Container` có `BoxDecoration.color != null && boxShadow != null`).
  - `toast replaces the previous toast` (hai lần gọi → một toast); `toast hides after duration` (`pump(3s)`).
  - `banner calls onTap`; không tràn ở 320×568 và tablet 1024×768.
- [ ] **Step 2: Chạy** `flutter test test/ui/feedback` → FAIL.
- [ ] **Step 3: Cài** theo Interfaces; ảnh mặc định `AppImages.chipMain`; tablet: chiều rộng tối đa `TabletSizes.messageMaxWidth`.
- [ ] **Step 4: Chạy** `flutter analyze && flutter test test/ui` → PASS.
- [ ] **Step 5: Commit** `feat(ui): shared dialog, toast and status banner`.

### Task 2: Thay mọi hộp thoại / SnackBar + test quét

**Files:**
- Modify: `lib/parent/screens/settings_tab.dart`, `kids_tab.dart`, `worksheet_screen.dart`, `family_account_card.dart`, `lib/features/collection/collection_screen.dart`, `notebook_section.dart`, `lib/features/online/replace_data_dialog.dart`, `online_consent_dialog.dart`, `lib/features/sleep/sleep_screen.dart`, mọi file có `showSnackBar` (tìm bằng `grep -rn "showSnackBar\|SnackBar(" lib`)
- Create: `test/ui/no_raw_dialogs_test.dart`
- Test: các test widget hiện có của các màn trên (cập nhật finder nếu tìm `AlertDialog`/`SnackBar`)

**Interfaces:**
- Consumes: Task 1.
- Quy ước: hộp ở màn bé (`collection_screen`, `notebook_section` phần dialog trang vở, `sleep_screen`) dùng `audience: AppAudience.kid`; còn lại `parent`. Hộp xóa (tài khoản, bé, toàn bộ dữ liệu, thay dữ liệu) dùng `tone: danger`, nút chính là "Giữ lại"/"Hủy".
- Chữ hiện có giữ nguyên (chỉ đổi khung).

- [ ] **Step 1: Viết test hỏng** `no_raw_dialogs_test.dart`: duyệt `Directory('lib').listSync(recursive: true)` các `.dart` trừ `lib/ui/feedback/`, mỗi file không chứa `AlertDialog(`, `SnackBar(`, `showSnackBar(`; báo danh sách file vi phạm.
- [ ] **Step 2: Chạy** → FAIL liệt kê các file.
- [ ] **Step 3: Thay** từng file; giữ `ValueKey` đang có trên nút (ví dụ `confirm-delete-account`, `consent-online`) bằng cách truyền key cho nút trong `showAppDialog` (thêm tham số `Key? primaryKey, Key? secondaryKey` vào Task 1 nếu cần — ghi vào Interfaces của Task 1 khi làm).
- [ ] **Step 4: Chạy** `flutter analyze && flutter test` (toàn bộ) → PASS.
- [ ] **Step 5: Commit** `refactor(ui): every dialog and message uses the shared feedback kit`.

### Task 3: Theo dõi mạng + timeout API

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`, `lib/online/api_client.dart`
- Create: `lib/online/net/network_status.dart`
- Test: `test/online/network_status_test.dart`, `test/online/api_client_test.dart` (mới nếu chưa có)

**Interfaces:**
- Produces:
  - `enum NetState { unknown, offline, online }`
  - `abstract class ConnectivitySource { Stream<bool> get hasConnection; Future<bool> check(); }` + `PluginConnectivitySource` (bọc `connectivity_plus`: `none` → false, còn lại → true) + `final connectivitySourceProvider = Provider<ConnectivitySource>(...)` (test thay bằng bản giả).
  - `class NetworkStatus extends Notifier<NetState>`: `void reportOk()`, `void reportNetworkError()`; `final networkStatusProvider`. Chỉ `listen` nguồn khi `sessionProvider` có phiên và `onlineConfigProvider.enabled`; hủy khi đăng xuất. Nguồn báo false → `offline`; báo true → không đổi trạng thái, phát sự kiện `onMaybeBack` (stream nội bộ `Stream<void> get maybeBack`).
  - `ApiClient`: timeout mỗi request **15 s**; timeout và lỗi socket → `ApiException(0, 'timeout')` / `ApiException(0, 'network')`. Sau mỗi phản hồi HTTP bất kỳ (kể cả 4xx) → `NetworkStatus.reportOk()`; `status == 0` → `reportNetworkError()` (bằng callback `onNetResult` truyền vào `ApiClient` để không vòng import).
- [ ] **Step 1: Viết test hỏng**:
  - `guest mode does not touch connectivity` (nguồn giả đếm lượt `listen`/`check` = 0).
  - `signed in: source false -> offline`; `source true keeps state and emits maybeBack`; `successful request -> online`; `timeout -> offline`.
  - `sign out stops listening`.
  - `request over 15 s throws ApiException(0, 'timeout')` (dùng `http` client giả trễ, `fake_async`).
- [ ] **Step 2: Chạy** → FAIL. **Step 3: Cài**; thêm `connectivity_plus` (bản tương thích; ghi lý do chọn bản trong commit).
- [ ] **Step 4: Chạy** `flutter pub get && flutter analyze && flutter test test/online` → PASS; `git diff pubspec.lock` chỉ thêm gói mới và phụ thuộc của nó.
- [ ] **Step 5: Commit** `feat(online): network status (signed-in only) and 15 s request timeout`.

### Task 4: Trigger đồng bộ + thử lại thưa dần

**Files:**
- Modify: `lib/online/sync/sync_engine.dart` (`SyncController`), `lib/features/lesson/lesson_done_screen.dart` hoặc nơi gọi `recordLessonCompleted`, `lib/game/data/game_repository.dart` nơi lưu trận (gọi qua provider ở màn kết quả, không gọi mạng trong engine trò chơi), `lib/features/game/race_result_screen.dart`, `lib/features/online_race/room_result_screen.dart`
- Test: `test/online/sync_controller_test.dart` (mới)

**Interfaces:**
- Consumes: Task 3 `networkStatusProvider`, `maybeBack`.
- Produces: `SyncController.requestSync()` (không chặn, gộp yêu cầu trong **3 s**); hằng `syncRetryDelays = [30s, 60s, 120s, 240s, 480s]` rồi **600 s** cố định; lịch thường 5 phút.
- Quy tắc (spec §6.2): `maybeBack` → `syncNow()` sau **2 s** (gộp); đang chạy mà có trigger → `_again = true`, chạy thêm đúng một lần; app vào nền → hủy mọi timer, resume → `syncNow()`; thành công → reset retry; 429 coi như lỗi tạm (retry), không báo lỗi.
- **Không** gọi mạng từ `lib/game/engine/`; trigger đặt ở màn kết quả.

- [ ] **Step 1: Viết test hỏng** (`fake_async`, máy chủ giả):
  - `back online syncs after 2 s once` (3 sự kiện `maybeBack` liên tiếp → 1 lần đồng bộ).
  - `lesson done requests a sync`; `race result requests a sync` (offline và online).
  - `requests within 3 s coalesce`.
  - `retry backs off and resets` (lỗi: 30, 60, 120… s; thành công → 5 phút).
  - `trigger while running runs exactly one more`.
  - `background cancels timers` (`AppLifecycleListener` giả `onHide`/`onResume`).
  - `429 is retried quietly` (trạng thái `failed`, không exception ra ngoài).
- [ ] **Step 2–4:** hỏng → cài → `flutter analyze && flutter test test/online test/features` đạt.
- [ ] **Step 5: Commit** `feat(sync): sync on reconnect, after lessons and races, with backoff`.

### Task 5: `SyncEngine` — kéo theo trang, bảng chờ, lô thích ứng (drift v11 phần 1)

**Files:**
- Modify: `lib/data/app_database.dart` (+`.g.dart`) — bảng `SyncPendingRemote` (`key` TEXT PK, `version` INT, `payloadJson` TEXT nullable) **và** bảng `DeviceCounters` + cột `updatedAt` của Task 6 trong **cùng** migration v11 (làm schema một lần; Task 6 dùng bảng). `lib/online/sync/sync_engine.dart`, `lib/online/sync/sync_store.dart`
- Test: `test/online/sync_engine_test.dart`, `test/data/migration_test.dart`, `test/online/fake_sync_server.dart` (thêm chế độ: `dropResponseAfterSave`, `delay`, `failWith500`, `failOnPage(n)`)

**Interfaces:**
- Produces:
  - `SyncEngine.run({bool pushLocal = true}) -> Future<bool>` giữ chữ ký. Bên trong: mỗi trang kéo về → `SyncStore.applyPage(List<SyncRecord> records, int cursor)` (một transaction: gộp, lưu bảng chờ, ghi `sync.cursor`), rồi `SyncStore.applyWaiting()` (áp bản ghi trong `sync_pending_remote` có bé đã biết, xóa dòng đã áp).
  - Lô thích ứng: khóa `sync.batch` trong `app_settings` (mặc định 500; timeout → `max(50, batch ~/ 2)`; 3 lần thành công liên tiếp (`sync.batchOk`) → `min(500, batch * 2)`).
- Bản ghi có uuid bé chưa biết → vào `sync_pending_remote`, **không** báo lỗi.

- [ ] **Step 1: Viết test hỏng** (spec §6.6): `lost response after server saved does not double`, `pull resumes from the last applied page` (đếm request), `progress before its kid waits and applies later`, `timeout halves the batch`, `app killed mid-pull keeps data consistent`, `switching kid during sync keeps data per kid` (Review Focus 2: đổi `currentKidId` giữa trang 1 và 2 → tiến độ mỗi bé đúng uuid); migration `v10 to v11 creates the new tables and columns`, `v1 to v11`.
- [ ] **Step 2–3:** hỏng → cài (build_runner).
- [ ] **Step 4:** `flutter analyze && flutter test test/online test/data` → PASS.
- [ ] **Step 5: Commit** `feat(sync): page-by-page pull with waiting records and adaptive batches (drift v11)`.

### Task 6: Số đếm theo máy + LWW cài đặt

**Files:**
- Create: `lib/online/sync/device_counters.dart`
- Modify: `lib/online/sync/sync_store.dart` (`exportAll`, `_merge`, `_write`), `lib/progress/progress_repository.dart` (glyph completions/clean), `lib/screen_time/screen_time_service.dart` (giây/ngày), `lib/game/data/game_repository.dart` (sao vũ trụ, bộ đếm huy hiệu `gameCounters`), mọi chỗ ghi `app_settings`/`kid_profiles`/`real_rewards`/`game_profile` (đặt `updatedAt`)
- Create test: `test/online/merge_rules_coverage_test.dart`
- Test: `test/online/sync_engine_test.dart`, `test/online/device_counters_test.dart` (mới)

**Interfaces:**
- Consumes: Task 5 bảng `DeviceCounters(key TEXT, deviceId TEXT, value INT, PK(key, deviceId))`, cột `updatedAt`.
- Produces:
  - `class DeviceCounterStore { Future<void> add(String counterKey, int delta); Future<int> total(String counterKey); Future<Map<String,int>> byDevice(String counterKey); Future<void> mergeRemote(String counterKey, Map<String,int> byDevice); }` — `add` cộng vào dòng `deviceId` của máy này **trong transaction của bên gọi** (nhận `AppDatabase`, dùng `db.transaction` lồng được).
  - Khóa bộ đếm: `glyph.c:<kidUuid>:<glyphId>`, `glyph.k:<kidUuid>:<glyphId>`, `usage:<kidUuid>:<day>`, `counter:<kidUuid>:<name>`, `stars.earned:<kidUuid>`, `stars.spent:<kidUuid>`.
  - Payload đồng bộ đúng spec §6.4 (`by`, `earned`, `spent`, `u`). Gộp LWW: `u` lớn hơn thắng; bằng nhau → `deviceId` lớn hơn (so chuỗi) thắng — cần đưa `"d": deviceId` của máy sửa vào payload LWW.
  - Dữ liệu cũ: migration v11 (Task 5) gán giá trị cột tổng hiện có cho `deviceId` máy này (gọi `ensureDeviceId` trong migration); bản ghi máy chủ dạng cũ (không `by`) → phần của `"legacy"`.
- [ ] **Step 1: Viết test hỏng**: `two devices offline both count`, `cosmic stars earned on two devices add up`, `settings last edit wins on both devices`, `clock skew still converges` (Review Focus 3), `legacy counters keep their value`, `old server record from not-yet-updated device` (Review Focus 1: máy B bản cũ đẩy `glyph` dạng cũ c=6 sau khi A đẩy dạng mới → tổng không giảm dưới 6 và không cộng trùng phần của A), `resend is idempotent` (gửi cùng payload 3 lần → tổng không đổi); `merge_rules_coverage_test`: mọi kind trong `exportAll()` (DB đủ loại dữ liệu) có nhánh tường minh trong `_merge` (`SyncStore.mergeKinds` công khai dạng `Set<String>`) và có trong `SyncKinds.ALLOWED` (đọc `server/src/main/java/com/ibme/funedu/server/sync/SyncKinds.java` bằng regex).
- [ ] **Step 2–3:** hỏng → cài. Màn hình đọc tổng như cũ (cột tổng vẫn được cập nhật) — không sửa màn hình.
- [ ] **Step 4:** `flutter analyze && flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(sync): per-device counters and last-write-wins settings`.

### Task 7: Ba mẹ thấy trạng thái — chip mây, dải nhắc, toast

**Files:**
- Create: `lib/online/sync/sync_health.dart`, `lib/features/home/sync_chip.dart`
- Modify: `lib/features/home/home_screen.dart`, `home_tablet.dart`, `lib/parent/screens/family_account_card.dart`, `lib/parent/parent_gate_route.dart` (mở Góc ba mẹ cuộn tới thẻ tài khoản: tham số `focus: 'account'`), `lib/online/sync/sync_engine.dart` (cập nhật health)
- Test: `test/features/home/sync_chip_test.dart`, `test/online/sync_health_test.dart`

**Interfaces:**
- Consumes: Task 1 (toast, banner), Task 3 (`NetState`), Task 4/5.
- Produces: `class SyncHealth { final int pending; final DateTime? lastOkAt; final NetState net; final bool running; final DateTime? offlineSince; }`; `final syncHealthProvider`.
- Chữ cố định (spec §6.7): chip "Đã lưu" / "Đang lưu…" / "$n bài chưa lưu"; dải "Ba mẹ ơi, tiến độ $d ngày nay chưa lưu online. Kiểm tra mạng giúp bé nhé" (`d` = số ngày làm tròn lên, tối thiểu 1); toast "Đã lưu online tiến độ của bé ✓"; thẻ tài khoản "Đang offline · $n bài chưa lưu, sẽ tự lưu khi có mạng".
- Ngưỡng: dải khi `lastOkAt` cũ hơn **24 giờ** và `pending > 0`; toast khi thành công sau `offline` ≥ **1 phút** và đường dẫn là `/` hoặc `/parent*`.
- [ ] **Step 1: Viết test hỏng**: `chip hidden in guest mode`; `chip shows three states`; `chip tap opens parent gate then account card`; `banner after 24 h with pending`; `banner hidden while learning` (ở `/lesson`, `/trace/*`); `toast after being offline a minute`; `flapping network shows at most one toast` (Review Focus 4); `chip at least 48 tall`; không tràn 320×568, tablet dọc/ngang.
- [ ] **Step 2–4:** hỏng → cài → `flutter analyze && flutter test` đạt.
- [ ] **Step 5: Commit** `feat(home): sync status chip, parent reminder banner, saved toast`.

### Task 8: Phòng đua — máy chủ: `away` + luật "còn một người thắng"

**Files:**
- Modify: `server/src/main/java/com/ibme/funedu/server/room/Room.java`
- Test: `server/src/test/java/com/ibme/funedu/server/room/RoomFlowTest.java`

**Interfaces:**
- Produces (snapshot mỗi người): `"away": bool` (mất kết nối, chưa quá `reconnectGrace`), `"awayMsLeft": long|null`; snapshot phòng: `"endReason": "others_left"|null`.
- Luật C (spec §7.1): trong `racing`, sau mỗi thay đổi: `active = chưa left && rank == null`; `present = chưa left`. Nếu `present == 1` và người đó `rank == null` → `rank = (số người có rank) + 1`, `state = done`, `endReason = "others_left"`. Trong `countdown`: bạn văng xử lý như `lobby` (giữ 20 s, không `left`); khi chuyển sang `racing` mà `present == 1` → áp luật C ngay.
- [ ] **Step 1: Viết test hỏng**: `racer away then back keeps progress`, `racer away past grace is left and race goes on` (3 người), `only one left wins at once` (2 người), `everyone else left after someone finished` (A về đích, B văng quá hạn → C hạng 2, `endReason others_left`), `drop during countdown` (Review Focus 5), `away fields in snapshot` (`awayMsLeft` giảm dần).
- [ ] **Step 2–4:** hỏng → cài → `./gradlew test` đạt (chạy `RoomFlowTest` 3 lần liền ổn định).
- [ ] **Step 5: Commit** `feat(room): away players and last-one-standing win`.

### Task 9: Phòng đua — app

**Files:**
- Modify: `lib/online/room/room_controller.dart` (`RoomPlayer.away`, `awayMsLeft`; `RoomState.reconnecting`, `endReason`; `roomRetryDelaysProvider` = `[1s, 3s, 6s, 5s, 5s]` tổng ≥ 20 s), `lib/features/online_race/room_race_screen.dart`, `room_result_screen.dart`, `room_lobby_screen.dart`, `room_widgets.dart`, `lib/features/game/race_standings_strip.dart`, `lib/features/game/game_hub_screen.dart` (nút Mời bạn đua / Nhập mã), `lib/features/online_race/room_entry_screen.dart`
- Test: `test/online/room_controller_test.dart`, `test/features/online_race/room_network_test.dart` (mới)

**Interfaces:**
- Consumes: Task 1, Task 3, Task 8.
- Chữ cố định (spec §7.2): toast "$name bị mất mạng, đang chờ $name quay lại…", "$name đã quay lại!", "$name đã rời trận"; nhãn avatar "Đang chờ"; dải "Đang kết nối lại…"; kết quả C "Các bạn đã rời trận, con thắng rồi!"; kết quả mất mạng "Mạng chập chờn mất rồi, mình đua lại sau nhé!" + nút "Về Góc Chơi"; hộp offline (`audience: kid`) "Cần có mạng để đua với bạn nhé" + "Được rồi".
- Mất kết nối của chính mình quá 20 s → màn kết quả mất mạng, **không** gọi `GameRepository` (không lưu trận, không trừ sao).
- [ ] **Step 1: Viết test hỏng**: `rival away shows waiting and toast`, `rival back shows toast once`, `rival left disappears from standings`, `last one standing wins with others_left title`, `self drop keeps race screen with banner`, `self reconnect within 20s resumes`, `self drop past 20s shows gentle result without saving` (DB `race_results` không đổi, sao vũ trụ không đổi), `offline invite shows need-network dialog` (`NetState.offline`, 0 request), `lobby shows away countdown`.
- [ ] **Step 2–4:** hỏng → cài → `flutter analyze && flutter test` đạt.
- [ ] **Step 5: Commit** `feat(room): smooth racing through dropped connections`.

### Task 10: Bảo mật máy chủ — giới hạn tần suất, kích thước, độ sâu, test quét

**Files:**
- Create: `web/RateLimitFilter.java` (thay `AuthRateLimitFilter.java`, xóa file cũ), `web/RequestSizeLimitFilter.java`, test `web/RateLimitTest.java`, `web/RequestSizeLimitTest.java`, `SecurityScanTest.java` (gói test gốc)
- Modify: `web/SecurityConfig.java`, `sync/SyncService.java` (độ sâu ≤ 6, chuỗi ≤ 4 KB trừ `page`), `room/RoomSocketHandler.java` (≤ 5 kết nối/gia đình, ≤ 20 tin/giây/kết nối), `deploy/Caddyfile`, `docs/online-setup.md` (mục triển khai: Cloudflare, chỉ mở 443, đĩa Oracle mã hóa)
- Test: `auth/AuthRateLimitTest.java` (chuyển sang dùng filter mới), `sync/SyncApiTest.java`, `room/RoomFlowTest.java`

**Interfaces:**
- Giới hạn (spec §8.4, cửa sổ trượt 1 phút, bộ nhớ, dọn khóa cũ mỗi phút): đăng nhập/refresh 20/IP; `/api/v1/sync` 60/gia đình + 120/IP; `POST /api/v1/rooms` 10/gia đình. Vượt → 429 `{"error":"too_many"}` + header `Retry-After` (giây).
- Kích thước: `Content-Length` > 4 MB → 413 `{"error":"too_large"}`; không có `Content-Length` → đếm luồng, vượt → 413.
- Caddyfile: `request_body { max_size 4MB }`, `servers { timeouts { read_body 30s write 30s idle 2m } }`.
- [ ] **Step 1: Viết test hỏng**: `syncRateLimitedPerFamily` (61 lần → 429 + `Retry-After`), `syncRateLimitedPerIp`, `roomsRateLimitedPerFamily`, `oversizeBodyIs413`, `chunkedOversizeBodyIs413`, `deepPayloadIsRejected` (độ sâu 7 → 400), `longStringIsRejected`, `wsFloodIsClosed`, `sixthSocketIsRefused`, `wsWithoutTokenIsRefused`; `SecurityScanTest`: (a) mọi phương thức `@GetMapping/@PostMapping/@DeleteMapping` trong `src/main` ngoài danh sách trắng (`/auth/*`, `/actuator/health`, `/api/v1/auth/apple/callback`) có tham số `@AuthenticationPrincipal Jwt`; (b) không có literal SQL (`SELECT|INSERT|UPDATE|DELETE`) nối `+` với thứ không phải literal chuỗi.
- [ ] **Step 2–4:** hỏng → cài → `./gradlew test` đạt.
- [ ] **Step 5: Commit** `feat(server): per-family rate limits, body size and depth limits, security scans`.

### Task 11: Bảo mật trên máy + app xử lý 429/413

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` (`android:allowBackup="false"`, `android:fullBackupContent="false"`, `android:dataExtractionRules="@xml/data_extraction_rules"`), create `android/app/src/main/res/xml/data_extraction_rules.xml` (loại trừ mọi domain cho `cloud-backup` và `device-transfer`), `ios/Runner/Runner.entitlements` (+ `com.apple.developer.default-data-protection` = `NSFileProtectionComplete`; nếu file chưa tồn tại thì tạo và nối vào project — ghi rõ trong commit), `lib/online/auth/token_store.dart` (`AndroidOptions(encryptedSharedPreferences: true)`), rà `debugPrint` trong `lib/online/**`
- Test: `test/security/platform_config_test.dart` (mới), `test/online/sync_controller_test.dart`

- [ ] **Step 1: Viết test hỏng**:
  - `android manifest disables backup` (đọc file XML, kiểm 3 thuộc tính); `data extraction rules exclude everything`.
  - `ios entitlement sets complete data protection` (đọc plist).
  - `secure storage uses encrypted shared preferences on android` (kiểm `SecureTokenStore` tạo `FlutterSecureStorage` với option đúng — tách hàm `secureStorageOptions()` để test).
  - `online logs never print tokens or kid names` (quét `lib/online/**` không có `debugPrint` chứa `accessToken`, `refreshToken`, `nickname`, `payload`).
  - `413 stops the batch and halves it` (máy chủ giả trả 413 → lô sau nhỏ hơn, không vòng vô hạn).
- [ ] **Step 2–4:** hỏng → cài → `flutter analyze && flutter test` đạt. iOS loại thư mục DB khỏi sao lưu (`NSURLIsExcludedFromBackupKey`): làm nếu được bằng `MethodChannel` nhỏ trong `AppDelegate.swift` không thêm gói; nếu không thì ghi việc sau vào `PROJECT_STATE.md` mục 7.
- [ ] **Step 5: Commit** `feat(security): no cloud backup, complete data protection, encrypted token storage`.

### Task 12: Tổng kiểm + tài liệu

- [ ] `flutter analyze` → "No issues found!"; `flutter test` → "All tests passed!"; `cd server && ./gradlew test` → 0 failures.
- [ ] Thử tay (nếu có máy chủ local, theo `docs/online-setup.md`): hai máy ảo cùng tài khoản, tắt mạng một máy, viết chữ ở cả hai, bật mạng → số lần viết cộng đúng; phòng đua 2 bạn, tắt mạng một máy giữa trận → máy kia thắng sau 20 s. Ghi kết quả hoặc lý do chưa thử vào `PROJECT_STATE.md`.
- [ ] Cập nhật `docs/PROJECT_STATE.md` mục 3 (gói `connectivity_plus` + phiên bản, drift v11), 6–8; `docs/online-setup.md` (luật gộp mới, mã lỗi 413/429).
- [ ] Commit `docs: online/offline hardening done`, `git push -u origin chipchip`.
