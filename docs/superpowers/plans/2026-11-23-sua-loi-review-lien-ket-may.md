# Sửa lỗi sau review "đăng nhập lần đầu + liên kết máy" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sửa 12 lỗi tìm được khi review commit `4f487c0..d6bbee7` (plan `2026-11-22-dang-nhap-lan-dau-lien-ket-may.md`), trọng tâm: không bao giờ trộn dữ liệu khách vào tài khoản, khôi phục không bao giờ kẹt hay rơi vào tạo hồ sơ.

**Architecture:** Cờ khôi phục đổi từ "có/không" thành **giai đoạn** (`replace` → `pull`); khôi phục chỉ **kéo về**, không đẩy; mọi đường thử lại đi qua một hàm `_ensureLinkedThenPull`. Hộp cảnh báo được hiện bởi một listener cấp app, không chỉ ở nút đăng nhập. Trang vở chỉ dựng khi xong chữ, ngoài transaction tiến độ.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, Riverpod 2.6, drift (v9 → **v10** vì thêm chỉ mục khai báo), Spring Boot 3.3.5.

**Spec:** `docs/superpowers/specs/2026-11-22-dang-nhap-lan-dau-lien-ket-may-design.md` (đọc §5, §7.1, §7.4) + plan cũ ở trên.

## Global Constraints

- Như plan cũ và `AGENTS.md` (nút ba mẹ ≥ 48, Riverpod, tokens, chuỗi tiếng Việt, `flutter analyze` sạch + `flutter test` đạt, `cd server && ./gradlew test`).
- Mỗi lỗi: **viết test tái hiện trước, chạy thấy hỏng**, rồi sửa.
- Không đổi API máy chủ (trừ Task 6 chỉ dọn code).

## Review Focus

1. App bị tắt ở **mọi** điểm giữa "báo máy chủ replace_local" và "kéo về xong": mở lại không bao giờ đẩy bản ghi khách nào lên (Task 1).
2. Mất mạng ở bước liên kết `fresh`/`replace_local` rồi bấm "Thử lại": máy được liên kết thật trên máy chủ (Task 1).
3. Đang ở màn khôi phục mà phiên hết hạn (refresh bị từ chối): về màn chọn cách dùng với thông báo, không kẹt vòng "Thử lại" (Task 1, test `restore with ended session returns to choose step`).
4. Hộp cảnh báo đang mở thì app vào nền rồi quay lại: không mở hộp thứ hai (Task 2, `warning shown once`).
5. Bé đang viết nhanh (60 nét/phút) không giật: không truy vấn trang vở trên mỗi nét (Task 4).

---

### Task 1: Khôi phục an toàn — giai đoạn, chỉ kéo, thử lại cả bước liên kết (lỗi 1, 2, 3)

**Files:**
- Modify: `lib/online/link/link_controller.dart`, `lib/profile/kid_repository.dart` (hằng số), `lib/online/sync/sync_engine.dart` (thêm chế độ chỉ kéo), `lib/features/setup/restore_screen.dart`
- Test: `test/online/link_controller_test.dart`, `test/features/setup/restore_screen_test.dart`, `test/online/sync_engine_test.dart`

**Interfaces:**
- `restorePendingKey` giữ tên `'link.restorePending'`, **giá trị** là giai đoạn: `'fresh'` (chưa liên kết, máy trống), `'replace'` (chưa chắc đã xóa dữ liệu khách), `'pull'` (đã liên kết + đã xóa, chỉ còn kéo).
- `SyncEngine.run({bool pushLocal = true}) -> Future<bool>`; `pushLocal: false` = chỉ kéo (gửi `changes: []` mọi vòng, vẫn gộp và ghi `synced_records` theo bản kéo về).
- `LinkController._ensureLinkedThenPull(String stage) -> Future<void>` — hàm **duy nhất** mà `afterSignIn` (fresh), `confirmReplace`, `resumeIfPending`, `retryRestore` gọi:
  1. `stage == 'fresh'` → `POST link {mode: fresh}`; `'replace'` → `POST link {mode: replace_local}` (idempotent ở máy chủ) rồi `wipeKidData()` rồi đặt cờ = `'pull'`.
  2. `markLinked()`, đặt `dataOwnerKey`.
  3. `SyncEngine.run(pushLocal: false)`; chọn bé đầu tiên; xóa cờ; `ref.invalidate(restorePendingSettingProvider)`; `state = LinkIdle()`.
  - Lỗi bất kỳ → `state = LinkRestoreFailed(...)` (**không** dùng `LinkFailed` trong đường khôi phục), cờ giữ nguyên giai đoạn hiện tại, `ref.invalidate(restorePendingSettingProvider)`.
  - `ApiException.unauthorized` (phiên đã hết) → xóa cờ chỉ khi giai đoạn là `'fresh'` (máy trống, không mất gì); giai đoạn `'replace'`/`'pull'` giữ cờ, `state = LinkRestoreFailed('signed_out')`, màn khôi phục hiện nút "Đăng nhập lại" (gọi lại luồng đăng nhập của màn đầu) thay cho "Thử lại".
- Mọi chỗ `setSetting(restorePendingKey, …)` đều đi kèm `ref.invalidate(restorePendingSettingProvider)`.

- [x] **Step 1: Viết test hỏng** (máy chủ giả đếm request đẩy):
  - `resume after crash between link and wipe never pushes guest data` — cờ `'replace'`, dữ liệu khách còn, phiên `linked=false`, máy chủ đã liên kết máy → `resumeIfPending()` → máy chủ giả nhận **0** thay đổi đẩy lên; DB chỉ còn dữ liệu tài khoản.
  - `resume after wipe only pulls` — cờ `'pull'` → 0 thay đổi đẩy; dữ liệu tài khoản có.
  - `retry after failed fresh link links the device` — `POST link` lỗi mạng lần 1 → `LinkRestoreFailed`; `retryRestore()` → máy chủ giả có liên kết `fresh`, phiên `linked == true`.
  - `failed replace keeps the restore screen` — `POST link replace_local` lỗi → `restoringProvider == true`, đường dẫn là `/restore` (không `/setup`), nút "Thử lại" có.
  - `failure after wipe keeps the restore screen` — kéo về lỗi sau khi xóa → như trên, cờ `'pull'`.
  - `restore with ended session returns to choose step` — refresh bị từ chối khi cờ `'fresh'` → về màn đầu bước chọn cách dùng, snackbar "Phiên đăng nhập đã hết, ba mẹ đăng nhập lại nhé".
  - `restore with ended session after wipe asks to sign in again` — cờ `'pull'` → màn khôi phục có nút "Đăng nhập lại".
- [x] **Step 2: Chạy** `flutter test test/online test/features/setup` → FAIL.
- [x] **Step 3: Cài** theo Interfaces.
- [x] **Step 4: Chạy** `flutter analyze && flutter test` → PASS.
- [x] **Step 5: Commit** `fix(online): restore in stages, pull-only, retry relinks`.

### Task 2: Hộp cảnh báo hiện ở mọi nơi trạng thái cần cảnh báo (lỗi 4)

**Files:**
- Create: `lib/features/online/link_warning_listener.dart`
- Modify: `lib/app.dart` (bọc trong builder của `MaterialApp.router`, cạnh `ScreenTimeGuard`), `lib/parent/screens/family_account_card.dart` (bỏ tự gọi `showReplaceDataDialog`, để listener làm), `lib/features/online/replace_data_dialog.dart`
- Test: `test/features/online/link_warning_listener_test.dart` (mới)

**Interfaces:**
- `class LinkWarningListener extends ConsumerStatefulWidget { const LinkWarningListener({required this.child}); }` — `ref.listen(linkControllerProvider)`: khi chuyển sang `LinkNeedsWarning` và chưa có hộp đang mở (`bool _open`), mở `showReplaceDataDialog` bằng `navigatorKey` của `appRouter` (`appRouter.routerDelegate.navigatorKey.currentContext`). **Không** mở khi đường dẫn là màn bé đang học/viết (`/lesson`, `/trace/*`, `/practice*`, `/game/*race*`): chờ tới khi về `/` hoặc `/parent` (dùng `routerLocation` hiện có). Đóng hộp → `_open = false`.
- `FamilyAccountCard` khi đã đăng nhập mà `session.linked == false` và state là `LinkNeedsWarning`: dòng chữ phụ "Chưa lưu online: cần ba mẹ chọn dữ liệu" + nút "Xem" mở lại hộp.

- [x] **Step 1: Viết test hỏng**:
  - `warning at launch is shown on home` — khởi động với phiên `linked=false`, tài khoản có dữ liệu, máy có bé → trên `/` thấy "Tài khoản này đã có dữ liệu".
  - `warning waits while the kid is writing` — đang ở `/trace/chu-a` → không có hộp; `go('/')` → hộp hiện.
  - `warning after link_required from sync` — máy chủ giả trả 409 `link_required` khi đồng bộ → hộp hiện.
  - `warning shown once` — phát lại `LinkNeedsWarning` hai lần (ví dụ resume app) → đúng một hộp.
  - `card offers to reopen the warning`.
- [x] **Step 2: Chạy** → FAIL. **Step 3: Cài.** **Step 4:** `flutter analyze && flutter test` → PASS.
- [x] **Step 5: Commit** `fix(online): show the replace warning wherever it is needed`.

### Task 3: Máy đã liên kết nhưng dữ liệu trên máy không thuộc tài khoản (lỗi 5, sửa thiếu sót của spec)

**Files:**
- Modify: `lib/online/link/link_controller.dart` (`afterSignIn` nhánh `r.linked`), spec §7.1 (thêm dòng bảng)
- Test: `test/online/link_controller_test.dart`

**Quy tắc mới** (thêm vào spec §7.1): `r.linked == true` **và** máy có bé **và** `dataOwnerKey` khác `familyId` (kể cả trống) **và** `account.hasData` → `LinkNeedsWarning` (xác nhận → `replace` như thường). Nếu `account.hasData == false` → đồng bộ như thường (mang lên). Nếu máy không có bé → kéo về (giai đoạn `'pull'`, không cần gọi link).

- [ ] **Step 1: Test hỏng**: `linked device with guest data after delete-all warns` (đăng nhập F → đăng xuất → `deleteAllData` → tạo bé khách → đăng nhập F, máy chủ giả trả `linked: true`, có dữ liệu → `LinkNeedsWarning`, 0 thay đổi đẩy lên); `linked device with own data just syncs` (owner = F → đồng bộ, không hộp).
- [ ] **Step 2–4:** chạy hỏng → cài → `flutter analyze && flutter test` đạt.
- [ ] **Step 5: Commit** `fix(online): warn when a linked device holds someone else's data`.

### Task 4: Trang vở — chỉ dựng khi xong chữ, không làm hỏng tiến độ, chỉ mục cho máy mới (lỗi 6, 7, 8, 10)

**Files:**
- Modify: `lib/data/app_database.dart` (bỏ `refreshNotebookPage` trong `logAttempt`; khai báo chỉ mục `stroke_attempts(kid_id, glyph_id)` bằng `@TableIndex` trên `StrokeAttempts`; `schemaVersion` 10, migration `from < 10`: `CREATE INDEX IF NOT EXISTS …` — giữ cùng tên `stroke_attempts_kid_glyph_idx`), `lib/data/app_database.g.dart` (build_runner), `lib/progress/progress_repository.dart` (gọi `refreshNotebookPage` **sau** transaction, bọc `try/catch` + `debugPrint`)
- Test: `test/data/migration_test.dart`, `test/progress/progress_repository_test.dart`, `test/collection/notebook_pages_test.dart`

- [ ] **Step 1: Test hỏng**:
  - `accepted stroke does not rebuild the page` — `logAttempt(ok: true)` khi chưa xong chữ → không có dòng `notebook_pages` mới (trang chỉ xuất hiện sau `recordGlyphCompleted`).
  - `page failure keeps glyph progress` — `refreshNotebookPage` ném lỗi (dữ liệu `points` hỏng/ép bằng glyph id lạ) → `glyph_progress.completions` vẫn tăng.
  - `fresh install has the attempts index` — DB tạo mới: `PRAGMA index_list(stroke_attempts)` có `stroke_attempts_kid_glyph_idx`; nâng cấp v9 → v10 cũng có (không lỗi trùng).
  - `stroke counts match the glyph assets` — với mọi file `assets/glyphs/*.json`, `glyphStrokeCounts[id] == glyph.strokes.length`, và số khóa bằng số file.
- [ ] **Step 2–4:** hỏng → cài → `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze && flutter test` đạt.
- [ ] **Step 5: Commit** `fix(notebook): build pages on completion only, keep progress safe, index on fresh installs`.

### Task 5: Giao diện nhỏ (lỗi 9, 11)

**Files:**
- Modify: `lib/features/setup/first_run_screen.dart`
- Test: `test/features/first_run_test.dart`

- [ ] **Step 1: Test hỏng**: `privacy link is at least 48 tall`; `second tap on sign-in is ignored` (bấm "Đăng nhập với Google" hai lần nhanh → 1 request `/auth/google`; nút tắt hoặc hiện vòng chờ trong lúc đăng nhập).
- [ ] **Step 2–4:** hỏng → trả `minimumSize: Size(48, 48)`; thêm cờ `_signingIn` như `FamilyAccountCard` → đạt (kiểm không tràn ở 320×568).
- [ ] **Step 5: Commit** `fix(setup): parent-size privacy link, single sign-in at a time`.

### Task 6: Dọn máy chủ (lỗi 12)

**Files:**
- Modify: `auth/AuthService.java` (xóa 2 overload `signIn` sinh `UUID.randomUUID()`; test dùng overload có `deviceId`), `auth/AuthService.refresh` (bỏ nhánh `deviceId != null ? … : randomUUID` — cột `NOT NULL`), `server/settings.gradle` (giữ plugin foojay **chỉ nếu** README ghi lý do; nếu không cần thì bỏ), `server/README.md`
- Test: các test hiện có

- [ ] **Step 1:** Sửa test đang gọi overload cũ sang `signIn(provider, idToken, code, deviceId)`.
- [ ] **Step 2:** Xóa code thừa; quyết định foojay, ghi một dòng trong `server/README.md`. Kiểm `docker compose build` vẫn không cần tải JDK (Dockerfile dùng image JDK sẵn).
- [ ] **Step 3: Chạy** `cd server && ./gradlew test` → PASS.
- [ ] **Step 4: Commit** `chore(server): drop device-less sign-in overloads`.

### Task 7: Tổng kiểm + tài liệu

- [ ] `flutter analyze` → "No issues found!"; `flutter test` → "All tests passed!"; `cd server && ./gradlew test` → 0 failures.
- [ ] Cập nhật `docs/PROJECT_STATE.md` mục 6–8 (ghi "đã sửa 12 lỗi review"), spec §7.1 (Task 3).
- [ ] Commit `docs: review fixes for device link`, `git push -u origin chipchip`.
