# Đăng nhập ngay lần đầu + liên kết máy — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lần đầu mở app ba mẹ được mời đăng nhập (khách là nút phụ); máy chủ chặn dữ liệu khách trộn vào tài khoản đã có dữ liệu bằng "liên kết máy"; hộp cảnh báo so sánh hai bên; "Vở của bé" (trang đẹp nhất mỗi chữ) được đồng bộ.

**Architecture:** Máy chủ thêm bảng `family_devices`; token mang claim `dev`; `POST/GET /api/v1/sync/link`; `/api/v1/sync` từ chối đẩy khi máy chưa liên kết. App thêm `deviceId`, trạng thái liên kết trong phiên, `LinkController` quyết định `fresh/upload/cảnh báo/replace_local`, bước "Chọn cách dùng" ở luồng đầu, màn "Đang tải dữ liệu của bé…", hộp cảnh báo, bảng drift `notebook_pages` (v9) đồng bộ bằng bản ghi `page:`.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6, drift 2.23 (v8 → v9), go_router 15; Spring Boot 3.3.5, Java 21, PostgreSQL 16, Flyway (V4 → V5), JUnit + Testcontainers/`TEST_DB_URL`.

**Spec:** `docs/superpowers/specs/2026-11-22-dang-nhap-lan-dau-lien-ket-may-design.md` — đọc cả spec trước task đầu; mục § trong plan trỏ về spec.

## Global Constraints

- Theo toàn bộ `AGENTS.md`: Flutter 3.24.5, không nâng gói, `withOpacity`; chỉ Riverpod; màu/bo góc/bóng từ `lib/ui/theme/tokens.dart`; ảnh qua `lib/ui/assets.dart`; chuỗi giao diện tiếng Việt, chú thích code tiếng Anh.
- Nút bé ≥ 64 (tablet ≥ 80), nút ba mẹ ≥ 48, tương phản chữ ≥ 4.5:1. Tablet rẽ nhánh trong cùng file bằng `context.formFactor`.
- Chế độ khách và build không có `FUNEDU_API_URL`: **0 request mạng** (test hiện có trong `test/online/` phải vẫn đạt).
- Mọi request mạng chỉ sau cổng ba mẹ + đồng ý.
- `stroke_attempts` không bao giờ nằm trong bản đẩy lên; chỉ `page:` (đã rút gọn: ≤ 40 điểm/nét, tọa độ 3 chữ số thập phân).
- Đổi bảng drift → `schemaVersion` 9, migration, `dart run build_runner build --delete-conflicting-outputs`, commit `.g.dart`; giữ mọi đường nâng cấp cũ.
- Mã lỗi máy chủ cố định: `link_required`, `account_not_empty` (HTTP 409); body lỗi theo `ApiErrors` hiện có.
- Log máy chủ không chứa tên bé, token, payload.
- Trước mỗi commit: `flutter analyze` sạch + test liên quan đạt; task máy chủ: `cd server && ./gradlew test` (môi trường AI: `pg_ctlcluster 16 main start`, `TEST_DB_URL=jdbc:postgresql://localhost:5432/funedu_test ./gradlew --max-workers=1 test`).
- Nhánh `chipchip`. Commit message kết thúc bằng dòng `Co-Authored-By:` theo hướng dẫn của phiên.

## Review Focus

1. **App bị tắt giữa lúc khôi phục** (đã `replace_local`/`fresh` thành công, đã xóa dữ liệu khách, chưa kéo xong): mở lại phải vào thẳng màn "Đang tải dữ liệu của bé…" và kéo tiếp, không rơi vào `/setup` tạo hồ sơ mới. → test ở Task 7 (`restore resumes after restart`).
2. **Mất mạng ngay sau khi đăng nhập, trước khi gọi link**: phiên đã lưu nhưng `linked == false`; mở lại app phải đi lại bảng quyết định, không đẩy gì, không xóa gì. → test ở Task 6 (`unlinked session at launch re-runs the decision`).
3. **Bấm đăng nhập hai lần / bấm khi đang khôi phục**: chỉ một luồng chạy. → test ở Task 8 (`second tap while signing in is ignored`).
4. **Tài khoản chỉ còn tombstone** (đã xóa hết bé): coi là trống → `upload` tự động, không cảnh báo. → test máy chủ Task 2 + app Task 6.
5. **Lần tập cũ không có tọa độ** (`points == null`, trước v6) khi điền `notebook_pages` ở migration v9: bỏ qua, không lỗi migration. → test ở Task 5 (`v8 to v9 backfill skips attempts without points`).

---

## Bản đồ file

**Máy chủ** (`server/src/main/java/com/ibme/funedu/server/`)
- `resources/db/migration/V5__device_links.sql` (mới): `family_devices`, `refresh_tokens.device_id`.
- `auth/TokenService.java`: claim `dev`. `auth/AuthService.java`, `auth/AuthController.java`: `deviceId` khi đăng nhập/refresh, phản hồi thêm `device`, `account`.
- `sync/AccountSummary.java` (mới): tóm tắt tài khoản (§6.2 spec).
- `sync/DeviceLinkService.java` + `sync/DeviceLinkController.java` (mới): `/api/v1/sync/link`.
- `sync/SyncService.java` / `SyncController.java`: chặn đẩy khi chưa liên kết. `sync/SyncKinds.java`: thêm `page`. `web/ApiErrors.java`: 2 mã lỗi.

**App**
- `lib/online/device_id.dart` (mới): `deviceId` trong `app_settings`.
- `lib/online/auth/token_store.dart`, `session_controller.dart`: `linked`, `SignInResult`.
- `lib/online/link/account_summary.dart` (mới): `KidSummary`, `summarize(records)`.
- `lib/online/link/link_controller.dart` (mới): quyết định + thực hiện liên kết, cờ khôi phục.
- `lib/online/sync/sync_engine.dart`, `sync_store.dart`: chạy khi đã liên kết; bản ghi `page:`.
- `lib/data/app_database.dart` (+`.g.dart`): bảng `NotebookPages`, v9. `lib/collection/notebook_pages.dart` (mới): rút gọn nét, ghi trang đẹp nhất. `lib/collection/notebook.dart`: đọc từ bảng.
- `lib/profile/kid_repository.dart`: `wipeKidData()`, `deleteAllData()` giữ khóa cấp máy.
- `lib/features/setup/first_run_screen.dart`, `lib/features/setup/choose_mode_step.dart` (mới), `lib/features/setup/restore_screen.dart` (mới), `lib/app.dart`, `lib/router.dart`: luồng đầu + khôi phục.
- `lib/features/online/replace_data_dialog.dart` (mới): hộp cảnh báo. `lib/parent/screens/family_account_card.dart`, `lib/parent/screens/privacy_screen.dart`.
- Fixture chung: `test/fixtures/summary_records.json` (mới, test máy chủ và app cùng đọc).

---

### Task 1: Máy chủ — deviceId trong đăng nhập và token

**Files:**
- Create: `server/src/main/resources/db/migration/V5__device_links.sql`
- Modify: `auth/TokenService.java`, `auth/AuthService.java`, `auth/AuthController.java`, `auth/AppleCallbackController.java` (nếu nó gọi `signIn`)
- Test: `server/src/test/java/com/ibme/funedu/server/auth/AuthFlowTest.java`

**Interfaces:**
- Produces: claim JWT `TokenService.DEVICE_CLAIM = "dev"`; `AuthService.signIn(String provider, String idToken, String authorizationCode, UUID deviceId)`; `AuthService.Session` thêm `UUID deviceId`; `SignInRequest` thêm `@NotNull UUID deviceId`; phản hồi đăng nhập thêm `"device": {"linked": bool}` (Task 2 thêm `"account"`). Bảng `family_devices(family_id, device_id, mode, linked_at)` như spec §6.1.

- [ ] **Step 1: Viết test hỏng** trong `AuthFlowTest`:
  - `signInWithoutDeviceIdIs400` — body không có `deviceId` → 400; `deviceId: "abc"` → 400.
  - `accessTokenCarriesDeviceClaim` — đăng nhập với `deviceId` D → giải mã access token, claim `dev == D`.
  - `refreshKeepsDevice` — refresh → access token mới vẫn `dev == D`.
  - `newDeviceIsNotLinked` — phản hồi đăng nhập có `device.linked == false`.
  - `relinkedDeviceIsLinked` — chèn tay `family_devices(F, D, 'fresh')`, đăng xuất, đăng nhập lại cùng D → `device.linked == true`; với D2 khác → `false`.
  - Sửa các test cũ đang gọi `/auth/google` để gửi `deviceId` (helper trong `TestIdTokens`/test).
- [ ] **Step 2: Chạy** `./gradlew test --tests '*AuthFlowTest*'` → FAIL.
- [ ] **Step 3: V5 migration**: bảng `family_devices` đúng spec §6.1; `DELETE FROM refresh_tokens;` rồi `ALTER TABLE refresh_tokens ADD COLUMN device_id UUID NOT NULL;` (chưa phát hành: xóa phiên cũ là quyết định của plan, ghi chú trong SQL). Ghi `device_id` khi tạo refresh token; refresh sao chép `device_id` sang token mới; access token thêm claim `dev`. Phản hồi đăng nhập/refresh là `Session` (JSON) + `device.linked` = tồn tại dòng `(familyId, deviceId)`.
- [ ] **Step 4: Chạy** toàn bộ `./gradlew test` → PASS (41 test cũ + test mới).
- [ ] **Step 5: Commit** `feat(server): device id in sign-in and tokens`.

### Task 2: Máy chủ — tóm tắt tài khoản + loại bản ghi `page`

**Files:**
- Create: `sync/AccountSummary.java`, `test/fixtures/summary_records.json` (gốc repo)
- Modify: `auth/AuthController.java` (thêm `account` vào phản hồi đăng nhập), `sync/SyncKinds.java`
- Test: `server/src/test/java/com/ibme/funedu/server/sync/AccountSummaryTest.java` (mới)

**Interfaces:**
- Produces: `AccountSummary.of(UUID familyId) -> AccountSummary.Result`, `record Result(boolean hasData, List<Kid> kids)`, `record Kid(String nickname, String avatar, long stars, long glyphs, long pages, long items, long badges)`. JSON đúng spec §6.2. `hasData` = có bản ghi không tombstone **hoặc** có dòng `family_devices` với `mode = 'upload'`.
- Fixture `test/fixtures/summary_records.json`: `{"records": [{"key": "...", "payload": {...}}...], "expected": [{"nickname": "Na", "stars": 7, "glyphs": 2, "pages": 1, "items": 1, "badges": 1}]}` — gồm 2 bé, 1 bé bị tombstone (không có trong `expected`), 3 bản ghi `lesson:` có `stars` 2, 2, 3.

- [ ] **Step 1: Viết test hỏng**:
  - `matchesSharedFixture` — nạp `Path.of("../test/fixtures/summary_records.json")` vào `sync_records` của một gia đình, `AccountSummary.of` khớp `expected` (thứ tự theo `createdAt` của bé).
  - `onlyTombstonesIsEmpty` — gia đình chỉ có tombstone → `hasData == false`, `kids` rỗng.
  - `uploadLinkCountsAsData` — không bản ghi nhưng có `family_devices(mode='upload')` → `hasData == true`.
  - `pageKindAccepted` — đẩy `page:<uuid>:a` qua `/api/v1/sync` (máy đã liên kết bằng chèn tay) → không bị loại; payload 17 KB → 400 như loại khác.
- [ ] **Step 2: Chạy** → FAIL.
- [ ] **Step 3: Cài**: một câu SQL nhóm theo `split_part(key, ':', 2)` cho `lesson/glyph/page/item/badge`, `SUM((payload->>'stars')::bigint)` cho `lesson`; đọc `kid:` lấy `nickname`, `avatar`, sắp theo `payload->>'createdAt'`; tối đa 4 bé. Thêm `"page"` vào `SyncKinds.ALLOWED`, sửa chú thích lớp thành "Stroke attempts are not among them; only the best notebook page per glyph". Phản hồi đăng nhập thêm `"account": AccountSummary.Result`.
- [ ] **Step 4: Chạy** `./gradlew test` → PASS.
- [ ] **Step 5: Commit** `feat(server): account summary and notebook page records`.

### Task 3: Máy chủ — `/api/v1/sync/link` và chặn đẩy

**Files:**
- Create: `sync/DeviceLinkService.java`, `sync/DeviceLinkController.java`
- Modify: `sync/SyncController.java`, `web/ApiErrors.java`, `docs/online-setup.md` (mục API: `deviceId`, link, 409)
- Test: `server/src/test/java/com/ibme/funedu/server/sync/DeviceLinkTest.java` (mới), `SyncApiTest.java`

**Interfaces:**
- Consumes: Task 1 claim `dev`, Task 2 `AccountSummary`.
- Produces: `POST /api/v1/sync/link` body `{"mode": "upload"|"replace_local"|"fresh"}` → 200 `{"linked": true}` hoặc 409 `{"error": "account_not_empty", "account": {...}}`; `GET /api/v1/sync/link` → `{"linked": bool, "account": {...}}`; `/api/v1/sync` với `changes` không rỗng từ máy chưa liên kết → 409 `{"error": "link_required"}`.

- [ ] **Step 1: Viết test hỏng** (`DeviceLinkTest`):
  - `pushBeforeLinkIs409` — `changes` 1 bản ghi → 409 `link_required`; `changes: []` → 200 (kéo được).
  - `uploadIntoEmptyAccount` — 200, rồi đẩy được.
  - `uploadIntoAccountWithData` — gia đình có `kid:` → 409 `account_not_empty`, body có `account.kids[0].nickname`.
  - `onlyTombstonesAllowsUpload` — 200.
  - `twoDevicesUploadAtOnce` — hai thread, hai `deviceId`, cùng gọi `upload` vào tài khoản trống (dùng `CountDownLatch` để xuất phát cùng lúc) → đúng một 200, một 409.
  - `replaceLocalAndFreshAlwaysLink` — tài khoản có dữ liệu: cả hai 200; gọi lại 200 và `mode` trong bảng không đổi.
  - `getLinkReportsState` — trước/sau liên kết.
  - `tokenWithoutDeviceIsUnlinked` — access token ký tay không có `dev` → đẩy bị 409 `link_required`.
  - `deleteAccountRemovesLinks` — xóa tài khoản → không còn dòng `family_devices`.
  - `badModeIs400`.
- [ ] **Step 2: Chạy** → FAIL.
- [ ] **Step 3: Cài** `DeviceLinkService.link(UUID familyId, UUID deviceId, String mode)` trong `@Transactional`: `SELECT id FROM families WHERE id = ? FOR UPDATE`; đã có dòng → trả linked; `upload` mà `AccountSummary.hasData` → ném `AccountNotEmptyException(Result)`; còn lại `INSERT`. `SyncController` kiểm `DeviceLinkService.isLinked(fam, dev)` trước khi gọi `SyncService.sync` khi `changes` không rỗng. `ApiErrors` ánh xạ 2 mã lỗi → 409.
- [ ] **Step 4: Chạy** `./gradlew test` → PASS; chạy riêng `DeviceLinkTest` 3 lần liền để chắc test song song ổn định.
- [ ] **Step 5: Sửa `docs/online-setup.md`** (thêm mục API liên kết), **commit** `feat(server): device link gate for sync`.

### Task 4: App — deviceId, phiên có `linked`, kết quả đăng nhập

**Files:**
- Create: `lib/online/device_id.dart`
- Modify: `lib/online/auth/token_store.dart`, `lib/online/auth/session_controller.dart`, `test/online/online_fakes.dart`
- Test: `test/online/session_controller_test.dart`, `test/online/device_id_test.dart` (mới)

**Interfaces:**
- Produces:
  - `const deviceIdKey = 'deviceId'`; `Future<String> ensureDeviceId(AppDatabase db)` (UUID v4 qua `lib/online/uuid.dart`, tạo một lần).
  - `StoredSession` thêm `final bool linked` (JSON `linked`, mặc định `false` khi đọc phiên cũ); `copyWith(..., bool? linked)`.
  - `class AccountSummary { final bool hasData; final List<KidSummary> kids; }` và `class KidSummary { final String nickname; final String avatar; final int stars, glyphs, pages, items, badges; }` (khớp JSON Task 2) ở `lib/online/link/account_summary.dart` (Task 6 thêm hàm tính tại chỗ) — Task này chỉ tạo hai lớp + `fromJson`.
  - `SessionController.signIn(String provider)` trả `Future<SignInResult>`; `class SignInResult { final bool linked; final AccountSummary account; }`. Body gửi thêm `'deviceId'`.
  - `SessionController.markLinked()` → lưu `linked = true`.

- [ ] **Step 1: Viết test hỏng**:
  - `device id is created once` — gọi `ensureDeviceId` 2 lần → cùng giá trị, đúng dạng UUID v4.
  - `sign-in sends deviceId and returns link state` — máy chủ giả trả `device.linked=false`, `account.hasData=true` + 1 bé → `SignInResult.linked == false`, `account.kids.single.nickname == 'Na'`; body request có `deviceId`.
  - `session read from old json is unlinked` — JSON không có `linked` → `false`.
  - `markLinked persists` — đọc lại store thấy `linked == true`.
  - Các test cũ của `session_controller_test.dart`, `family_account_card_test.dart` vẫn đạt (cập nhật phản hồi giả).
- [ ] **Step 2: Chạy** `flutter test test/online` → FAIL.
- [ ] **Step 3: Cài** theo Interfaces. `_resetSyncState` **không** xóa `deviceId`.
- [ ] **Step 4: Chạy** `flutter analyze && flutter test test/online` → PASS.
- [ ] **Step 5: Commit** `feat(online): device id and link state in the session`.

### Task 5: App — bảng `notebook_pages` (v9) và đồng bộ trang vở

**Files:**
- Create: `lib/collection/notebook_pages.dart`
- Modify: `lib/data/app_database.dart` (+ `.g.dart`), `lib/collection/notebook.dart`, `lib/features/writing/writing_screen.dart`, `lib/features/trace/trace_screen.dart` (chỗ gọi `recordGlyphCompleted`), `lib/online/sync/sync_store.dart`, `lib/profile/kid_repository.dart` (`deleteKid` xóa trang)
- Test: `test/collection/notebook_pages_test.dart` (mới), `test/data/migration_test.dart`, `test/online/sync_engine_test.dart`

**Interfaces:**
- Produces:
  - Bảng `NotebookPages`: `kidId` int FK, `glyphId` text, `strokes` text (JSON `[[x0,y0,x1,y1,…],…]`), `mistakes` int, `writtenAt` DateTime; khóa chính `{kidId, glyphId}`. `schemaVersion => 9`.
  - `List<Stroke> simplifyStrokes(List<Stroke> strokes, {int maxPoints = 40})` — giữ điểm đầu/cuối, lấy mẫu đều theo độ dài cung, làm tròn 3 chữ số.
  - `bool isBetterPage({required int mistakes, required DateTime at, required int oldMistakes, required DateTime oldAt})` — ít lỗi hơn, bằng thì mới hơn (dùng chung cho ghi tại chỗ và gộp đồng bộ).
  - `Future<void> refreshNotebookPage(AppDatabase db, {required int kidId, required Glyph glyph})` — dựng trang đẹp nhất của chữ từ `attemptsFor` + `bestWritings`, rút gọn, upsert nếu `isBetterPage`.
  - `notebookProvider` đọc `notebook_pages` (giữ thứ tự `writingLadder`, giữ kiểu `NotebookPage`).
  - Bản ghi đồng bộ `page:<kidUuid>:<glyphId>` payload `{"s": [[...]], "m": int, "at": ms}`; gộp bằng `isBetterPage`.

- [ ] **Step 1: Viết test hỏng**:
  - `simplify keeps ends and caps points` — nét 500 điểm → 40 điểm, đầu/cuối giữ nguyên, mọi điểm gốc cách đường rút gọn ≤ 0.01.
  - `six strokes page is under 4 KB` — JSON payload `page:` 6 nét × 40 điểm < 4096 byte.
  - `refresh keeps the better page` — trang 0 lỗi rồi lần viết 2 lỗi → vẫn trang 0 lỗi; lần viết 0 lỗi mới hơn → thay.
  - `v8 to v9 backfill skips attempts without points` (trong `migration_test.dart`) — DB v8 có attempts của "a" (có points) và "b" (points null) → sau nâng cấp có trang "a", không có "b", không ném lỗi.
  - Trong `sync_engine_test.dart` (hai máy, máy chủ giả): `notebook page travels to the other device`, `better page replaces, worse does not`, `deleting a kid deletes its pages`, `stroke attempts never leave the device` (không bản ghi đẩy lên nào chứa khóa bắt đầu khác các loại cho phép, và không có `points`).
- [ ] **Step 2: Chạy** → FAIL.
- [ ] **Step 3: Cài** bảng + migration (`from < 9`: `createTable(notebookPages)` rồi điền bằng `refreshNotebookPage` cho mọi `(kidId, glyphId)` trong `stroke_attempts` có glyph tải được), chạy build_runner; gọi `refreshNotebookPage` ngay sau `recordGlyphCompleted` ở hai màn (lỗi chỉ `debugPrint`, không chặn bé); `SyncStore.exportAll`/`_write`/`_deleteKid` cho `page`.
- [ ] **Step 4: Chạy** `flutter analyze && flutter test test/collection test/data test/online test/features/collection` → PASS.
- [ ] **Step 5: Commit** `feat(notebook): notebook_pages table (v9) synced as page records`.

### Task 6: App — `LinkController`: quyết định, liên kết, thay dữ liệu

**Files:**
- Create: `lib/online/link/link_controller.dart`; bổ sung `lib/online/link/account_summary.dart`
- Modify: `lib/online/sync/sync_engine.dart` (`SyncController` chỉ chạy khi `linked`; 409 `link_required` → `SessionController` đặt `linked=false` + `LinkController.decide()`), `lib/profile/kid_repository.dart`, `test/online/fake_sync_server.dart` (thêm link + 409)
- Test: `test/online/link_controller_test.dart` (mới), `test/online/account_summary_test.dart` (mới), `test/profile/kid_repository_test.dart`

**Interfaces:**
- Consumes: Task 4 `SignInResult`, `markLinked`; Task 3 API; Task 5 bản ghi `page`.
- Produces:
  - `List<KidSummary> summarizeRecords(Map<String, Map<String, Object?>> records)` — đầu vào là `SyncStore.exportAll()`; cùng quy tắc máy chủ.
  - `Future<List<KidSummary>> localSummary(SyncStore store)`.
  - `sealed class LinkState`: `LinkIdle`, `LinkNeedsWarning(AccountSummary account, List<KidSummary> local)`, `LinkRestoring`, `LinkFailed(String message)`.
  - `class LinkController extends Notifier<LinkState>`: `Future<void> afterSignIn(SignInResult r)`; `Future<void> confirmReplace()`; `Future<void> cancelReplace()` (gọi `SessionController.signOut()`); `Future<void> resumeIfPending()` (gọi khi app mở).
  - `const restorePendingKey = 'link.restorePending'` trong `app_settings` (không bắt đầu bằng `sync.`); `final restoringProvider = Provider<bool>` (true khi `LinkRestoring` hoặc cờ còn).
  - `KidRepository.wipeKidData()` — xóa mọi bảng trừ các khóa `app_settings`: `deviceId`, `consentAt`, `restorePendingKey`; `deleteAllData()` giữ `deviceId`.
  - `const dataOwnerKey = 'dataOwnerFamilyId'`: đặt khi liên kết xong; xóa trong `wipeKidData`/`deleteAllData`.
- Quyết định (spec §7.1): `linked` → `markLinked` + đồng bộ. Không có bé → `fresh` + khôi phục. Có bé, `!account.hasData` → `upload` + đồng bộ; 409 → `LinkNeedsWarning` với `account` trong 409. Có bé, `account.hasData` → `LinkNeedsWarning`. `confirmReplace`: đặt `restorePendingKey` → `link(replace_local)` → `wipeKidData` → `markLinked` → kéo hết → xóa cờ. `fresh` cũng đặt cờ trước và xóa sau khi kéo xong.

- [ ] **Step 1: Viết test hỏng**:
  - `account_summary_test.dart`: `matches the shared fixture` — dựng drift từ `test/fixtures/summary_records.json` bằng `applyRemote`, `localSummary` khớp `expected` (cùng fixture với Task 2).
  - `link_controller_test.dart` (máy chủ giả):
    - `empty device links fresh and restores` — tài khoản có 2 bé → sau đó DB có 2 bé, cờ khôi phục đã xóa, `currentKidId` là bé thứ nhất.
    - `guest data into empty account uploads without asking` — trạng thái không qua `LinkNeedsWarning`, máy chủ giả nhận bản ghi `kid:`.
    - `guest data into account with data needs warning` — `LinkNeedsWarning`, số liệu hai bên đúng.
    - `upload refused shows warning with server numbers` — máy chủ giả trả 409 `account_not_empty`.
    - `cancel signs out and keeps guest data`.
    - `confirm replaces local data` — dữ liệu khách mất, dữ liệu tài khoản có, `deviceId` và `consentAt` còn, `dataOwnerFamilyId` = gia đình.
    - `already linked device just syncs`.
    - `unlinked session at launch re-runs the decision` — phiên lưu `linked=false`, không bé tài khoản trống… → `resumeIfPending` đi lại bảng quyết định, không request đẩy nào trước link.
    - `restore resumes after restart` — cờ `link.restorePending` còn, DB trống, phiên `linked=true` → `resumeIfPending` kéo về, không qua `/setup` (kết hợp Task 7).
    - `sync is not pushed while unlinked` và `link_required from server re-runs the decision`.
  - `kid_repository_test.dart`: `wipeKidData keeps device keys`.
- [ ] **Step 2: Chạy** → FAIL.
- [ ] **Step 3: Cài** theo Interfaces.
- [ ] **Step 4: Chạy** `flutter analyze && flutter test test/online test/profile` → PASS.
- [ ] **Step 5: Commit** `feat(online): device link decision, replace and restore`.

### Task 7: App — luồng lần đầu: "Chọn cách dùng" + màn khôi phục

**Files:**
- Create: `lib/features/setup/choose_mode_step.dart`, `lib/features/setup/restore_screen.dart`
- Modify: `lib/features/setup/first_run_screen.dart` (thêm `_Step.chooseMode` giữa consent và profile khi `onlineConfigProvider.enabled`; chữ bước đồng ý theo spec §7.2), `lib/app.dart` (`_redirect`: khi `restoringProvider` → `/restore`; không đẩy `/setup`), `lib/router.dart` (route `/restore`), `lib/main.dart` hoặc `app.dart` (gọi `LinkController.resumeIfPending()` khi mở)
- Test: `test/features/first_run_test.dart`, `test/features/setup/restore_screen_test.dart` (mới), `test/app_navigation_test.dart`

**Interfaces:**
- Consumes: Task 6 `LinkController`, `restoringProvider`, `LinkState`.
- Produces: route `/restore`; `ChooseModeStep({required VoidCallback onGuest, required Future<void> Function(String provider) onSignIn})`.
- Chữ cố định (spec §7.2): tiêu đề "Lưu tiến độ của bé"; phụ đề "Đăng nhập để giữ tiến độ khi đổi máy và dùng trên nhiều máy."; nút "Đăng nhập với Google", "Đăng nhập với Apple" (chỉ khi `appleAvailable`); nút phụ "Dùng thử không cần tài khoản"; chữ phụ "Dữ liệu chỉ lưu trên máy này, xóa app là mất."; màn khôi phục "Đang tải dữ liệu của bé…", lỗi "Chưa tải được, ba mẹ kiểm tra mạng nhé" + nút "Thử lại".
- Đồng ý online (`_ConsentDialog` hiện ở `family_account_card.dart`): chuyển ra file dùng chung `lib/features/online/online_consent_dialog.dart` và hiện trước khi gọi Google/Apple ở cả hai nơi.

- [ ] **Step 1: Viết test hỏng**:
  - `guest path is unchanged` — chọn "Dùng thử…" → tạo hồ sơ → `/placement`; 0 request.
  - `no server url hides the choose step` — đồng ý → thẳng hồ sơ bé.
  - `sign in to account with placed kids goes home` — không qua `/setup`, `/placement`; trang chủ hiện tên bé thứ nhất.
  - `sign in to empty account creates profile then placement`.
  - `sign-in failure stays on choose step` — lỗi mạng → vẫn thấy nút khách, snackbar như `family_account_card`.
  - `restore failure shows retry` — kéo lỗi → "Thử lại"; bấm → kéo lại; không nhảy `/setup`.
  - `restore resumes after restart` — (phần giao diện của test Task 6) app khởi động với cờ khôi phục → hiện `/restore`.
  - `choose step buttons are big enough` — nút đăng nhập (`PrimaryButton`) cao ≥ 64, nút khách ≥ 48, trên cả kích thước điện thoại và tablet.
- [ ] **Step 2: Chạy** → FAIL.
- [ ] **Step 3: Cài**.
- [ ] **Step 4: Chạy** `flutter analyze && flutter test` (toàn bộ) → PASS.
- [ ] **Step 5: Commit** `feat(setup): sign in on first launch, restore an existing family`.

### Task 8: App — hộp cảnh báo thay dữ liệu, Góc ba mẹ, chữ quyền riêng tư

**Files:**
- Create: `lib/features/online/replace_data_dialog.dart`
- Modify: `lib/parent/screens/family_account_card.dart` (dùng `LinkController`; dòng "Đang dùng thử: dữ liệu chỉ ở trên máy này"; chữ đăng xuất "Đã đăng xuất. Dữ liệu vẫn ở trên máy này"), `lib/features/setup/first_run_screen.dart` (hiện hộp khi `LinkNeedsWarning` — thực tế lần đầu không xảy ra nhưng dùng chung luồng), `lib/parent/screens/privacy_screen.dart`, `AGENTS.md`, `docs/superpowers/specs/2026-11-21-giai-doan-2d-2b2-online-design.md` (mục dữ liệu: thêm `page`, `deviceId`)
- Test: `test/features/online/replace_data_dialog_test.dart` (mới), `test/online/family_account_card_test.dart`

**Interfaces:**
- Consumes: Task 6 `LinkNeedsWarning`, `confirmReplace`, `cancelReplace`.
- Produces: `Future<void> showReplaceDataDialog(BuildContext context, {required List<KidSummary> local, required AccountSummary account, required String accountLabel})`.
- Chữ cố định (spec §7.4): tiêu đề "Tài khoản này đã có dữ liệu"; cột "Trên máy này (dùng thử)" và "Tài khoản <email hoặc Google/Apple>"; mỗi bé "<nickname> · <stars>⭐ · <glyphs> chữ · <pages> trang vở · <items> món đồ" (`items` gồm sticker và đồ trò chơi); đoạn "Nếu tiếp tục, dữ liệu trên máy này (tiến độ, sao, sticker, Vở của bé) sẽ bị XÓA và thay bằng dữ liệu của tài khoản. Không hoàn tác được."; nút "Hủy, tiếp tục dùng thử" (mặc định), nút nguy hiểm "Xóa dữ liệu trên máy và dùng tài khoản" → **hộp xác nhận thứ hai** "Xóa dữ liệu của <tên các bé> trên máy này?" với "Giữ lại" / "Xóa" (plan chọn xác nhận hai lần thay cho bấm giữ: dễ test, quen với ba mẹ). Hộp không đóng khi chạm ngoài (`barrierDismissible: false`), `PopScope(canPop: false)`.
- Chữ quyền riêng tư và hộp đồng ý online: đúng các câu trong spec §8.
- `AGENTS.md`: thay dòng mạng và dòng `stroke_attempts` đúng câu trong spec §8.

- [ ] **Step 1: Viết test hỏng**:
  - `dialog shows both sides` — 1 bé máy, 2 bé tài khoản → thấy đủ tên và số "540⭐".
  - `cancel keeps guest data and signs out`.
  - `delete needs a second confirmation` — bấm nút xóa → hộp thứ hai; "Giữ lại" → không gì bị xóa; "Xóa" → `confirmReplace` được gọi.
  - `tapping outside does not close` và `back does not close`.
  - `phone stacks, tablet sides` — điện thoại 2 khối dọc, tablet ngang (so `getTopLeft`).
  - `text contrast` — dùng `contrastRatio` hiện có cho màu nút nguy hiểm trên nền.
  - `family_account_card_test.dart`: `guest hint shows when signed out`, `second tap while signing in is ignored` (hai lần bấm → 1 request `/auth/google`).
- [ ] **Step 2: Chạy** → FAIL.
- [ ] **Step 3: Cài**; màu nút nguy hiểm lấy token có sẵn (`AppColors.primary` hoặc token đỏ nếu có trong `tokens.dart`; không thêm mã màu trong màn hình).
- [ ] **Step 4: Chạy** `flutter analyze && flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(online): replace-data warning, guest hint, privacy wording`.

### Task 9: Kiểm toàn nhánh + tài liệu tình trạng

**Files:**
- Modify: `docs/PROJECT_STATE.md` (mục 6–8), `docs/superpowers/plans/2026-11-21-ke-hoach-tiep-theo.md` (dòng "đã xong")

- [ ] **Step 1: Chạy** `flutter analyze` → "No issues found!"; `flutter test` → "All tests passed!"; `cd server && ./gradlew test` → 0 failures; `cd tools/glyphs && python3 -m pytest -q` → đạt.
- [ ] **Step 2: Thử tay theo `docs/online-setup.md`** (nếu có máy chủ local): máy ảo mới → đăng nhập → tạo bé → gỡ app, cài lại → đăng nhập → bé hiện lại, Vở của bé có trang. Ghi kết quả (hoặc "chưa thử được, lý do") vào `PROJECT_STATE.md`.
- [ ] **Step 3: Cập nhật** `PROJECT_STATE.md` mục 6–8 và kế hoạch tiếp theo.
- [ ] **Step 4: Commit** `docs: first-launch sign-in and device link done`, `git push -u origin chipchip`.
