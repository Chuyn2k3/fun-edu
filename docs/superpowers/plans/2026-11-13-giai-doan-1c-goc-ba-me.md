# Giai đoạn 1C — Góc ba mẹ, hồ sơ bé, giới hạn giờ, giọng đọc: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện phần bắt buộc trước khi lên store của giai đoạn 1: giọng đọc hướng dẫn (giọng có sẵn của máy), nhiều hồ sơ bé với dữ liệu tách riêng, cổng xác nhận người lớn, lần đầu mở app do ba mẹ đồng ý và tạo hồ sơ, giới hạn giờ và giờ đi ngủ (Chíp Chíp đi ngủ), góc ba mẹ (tiến bộ, hồ sơ, giới hạn giờ, phần thưởng thật, cài đặt, xóa dữ liệu, chính sách quyền riêng tư).

**Architecture:** Giọng đọc qua một lớp trừu tượng `Speaker` (cài đặt bằng `flutter_tts`, test dùng bản giả) để sau này đổi sang file âm thanh tạo sẵn mà không sửa màn hình. Mọi bảng tiến độ gắn `kidId`; một provider `currentKidIdProvider` quyết định dữ liệu của bé nào được đọc/ghi. Góc ba mẹ là một nhánh route riêng `/parent/*`, chỉ vào được sau cổng. Giới hạn giờ đếm thời gian bé ở các màn dành cho bé (không tính góc ba mẹ và `/dev/*`). Thống kê gửi ra ngoài: **để sau** (chủ dự án đã chọn).

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, flutter_riverpod 2.6, go_router 15, drift 2.23 + drift_flutter 0.2.4 (ghim), **flutter_tts** (thêm mới, chọn bản tương thích Dart 3.5).

**Spec:** `docs/superpowers/specs/2026-11-12-fun-edu-overhaul-design.md` (mục 5.3, 6, 10 — Giai đoạn 1, 12). Kế hoạch trước: `docs/superpowers/plans/2026-11-12-giai-doan-1b-toan-xep-cap.md`.

## Global Constraints

- Flutter 3.24 (Dart 3.5); `package:flutter/material.dart`; `withOpacity`; Riverpod 2.x; không đổi phiên bản gói đã ghim. Gói mới duy nhất: `flutter_tts`.
- Không SDK quảng cáo/theo dõi/phân tích; **không gửi gì ra mạng** trong 1C. `flutter_tts` chỉ dùng giọng hệ điều hành.
- Không thu thông tin cá nhân của bé: hồ sơ chỉ có **tên gọi ở nhà** (≤ 20 ký tự), **ảnh đại diện chọn từ bộ có sẵn**, **tuổi** (3, 4, 5, 6, "7+"). Không tên thật, không ảnh chụp, không ngày sinh.
- Mọi thứ liên quan cài đặt, xóa dữ liệu, chính sách, thêm/sửa hồ sơ đều sau **cổng người lớn**.
- Màu/ảnh chỉ qua tokens và `AppImages`; thẻ trắng = một `BoxDecoration` có cả màu và bóng; nút cho bé ≥ 64; chữ ≥ 4.5:1. Góc ba mẹ được dùng cỡ nút thường (≥ 48) và nhiều chữ hơn, cùng màu và font.
- Không cơ chế gây áp lực: hết giờ thì Chíp Chíp đi ngủ nhẹ nhàng, không đếm ngược đỏ, không mất sao.
- Chữ hiển thị đúng nguyên văn kế hoạch.

## Review Focus

1. **Cài đè lên bản 1B đã có dữ liệu** → sau nâng cấp, dữ liệu cũ thuộc về hồ sơ "Bé" được tạo tự động, không mất sao/cấp/tiến độ. → test Task 2.
2. **Đổi bé giữa chừng** → trang chủ, bài hôm nay, bản đồ, góc ba mẹ hiển thị đúng dữ liệu của bé đang chọn; ghi tiến độ vào đúng bé. → test Task 2, 4.
3. **Hết giờ giữa bài** → bé được làm xong câu/nét đang dở (không cắt ngang giữa nét), rồi màn ngủ hiện ở lần chuyển màn kế tiếp; không ghi sai tiến độ. → test Task 5.
4. **Qua ngày mới / đổi giờ máy** → thời gian đã dùng tính lại theo ngày; giờ đi ngủ qua nửa đêm (ví dụ 20:30 → 6:00) xử lý đúng. → test Task 5.
5. **Thiết bị không có giọng tiếng Việt** → app không lỗi, không treo; chỉ im lặng. → test Task 1.

---

## Cấu trúc file

```
lib/voice/speaker.dart                 # Speaker (abstract), TtsSpeaker, SilentSpeaker, speakerProvider
lib/voice/voice_lines.dart             # chuỗi đọc dựng sẵn (số → chữ, câu hỏi Toán)
lib/profile/kid_tables.dart            # KidProfiles, AppSettings
lib/profile/kid_repository.dart        # KidRepository, currentKidIdProvider, kidsProvider
lib/profile/avatars.dart               # bộ ảnh đại diện có sẵn
lib/parent/parent_gate.dart            # ParentGate (câu đố phép nhân)
lib/parent/parent_gate_route.dart      # tiện ích mở cổng rồi đi tiếp
lib/features/setup/first_run_screen.dart
lib/features/home/kid_switcher.dart
lib/screen_time/screen_time_tables.dart
lib/screen_time/screen_time_service.dart   # đếm phút, giới hạn, giờ ngủ (thuần Dart + clock)
lib/screen_time/screen_time_guard.dart      # widget bọc khu vực bé
lib/features/sleep/sleep_screen.dart
lib/parent/screens/{parent_home,progress_tab,kids_tab,time_tab,rewards_tab,settings_tab,privacy_screen}.dart
lib/rewards/reward_tables.dart, lib/rewards/reward_repository.dart
```

---

### Task 1: Giọng đọc

**Files:**
- Create: `lib/voice/speaker.dart`, `lib/voice/voice_lines.dart`
- Modify: `pubspec.yaml` (`flutter_tts`), `ios/Runner/Info.plist` nếu gói yêu cầu, `lib/ui/widgets/chip_says.dart` (đọc lời Chíp khi lời thay đổi), `lib/features/writing/writing_screen.dart` (nút `Nghe` đọc lại lời hiện tại thay vì SnackBar `Giọng đọc sắp có`), `lib/features/math/math_session_screen.dart` (đọc câu hỏi khi sang câu mới; nút loa nhỏ cạnh câu hỏi đọc lại), `lib/features/placement/placement_screen.dart`
- Test: `test/voice/speaker_test.dart`, `test/voice/voice_lines_test.dart`, cập nhật test màn liên quan

**Interfaces:**
- Produces:
  - `abstract class Speaker { Future<void> speak(String text); Future<void> stop(); }`
  - `class TtsSpeaker implements Speaker` — `flutter_tts`, ngôn ngữ `vi-VN`, tốc độ 0.45, cao độ 1.1; nếu `setLanguage` thất bại hoặc không có giọng: mọi lời gọi thành không làm gì (không ném lỗi); mỗi `speak` dừng câu đang đọc trước.
  - `class SilentSpeaker implements Speaker` — không làm gì (dùng trong test và khi tắt âm thanh).
  - `final speakerProvider = Provider<Speaker>` — trả `SilentSpeaker` khi cài đặt `voiceEnabled` (Task 2, mặc định bật) là tắt; trước khi Task 2 xong, dùng `TtsSpeaker` luôn.
  - `String numberToVietnamese(int n)` cho 0–20 (`không`, `một`, …, `mười`, `mười một`, …, `mười lăm`, …, `hai mươi`); `String spokenQuestion(MathQuestion q)`: đếm/so sánh/ghép đọc nguyên `prompt`; phép tính đọc `"{a} cộng {b} bằng mấy?"` / `"{a} trừ {b} bằng mấy?"` với số bằng chữ.
- Hành vi: lời Chíp được đọc tự động mỗi khi đổi; câu Toán mới được đọc tự động; `Nghe` đọc lại lời Chíp hiện tại ở màn viết; rời màn thì `stop()`.

- [ ] **Step 1: Viết test** — `numberToVietnamese` cho 0, 1, 4, 5, 10, 11, 14, 15, 20 (`không`, `một`, `bốn`, `năm`, `mười`, `mười một`, `mười bốn`, `mười lăm`, `hai mươi`); `spokenQuestion` cho `3 + 2` → `ba cộng hai bằng mấy?`, `5 − 0`… (không xảy ra; dùng `5 − 1` → `năm trừ một bằng mấy?`); màn viết với `FakeSpeaker` ghi lại: lúc mở → `Bé tô nét số 1 nhé!`; bấm `Nghe` → đọc lại câu đó; màn Toán đọc câu 1 khi mở; `TtsSpeaker` với kênh giả ném lỗi ở `setLanguage` → `speak` không ném.
- [ ] **Step 2: Chạy, thấy FAIL.** **Step 3: Viết code.** **Step 4: PASS** (`flutter test`, `flutter analyze`). **Step 5: Commit** — `feat(voice): đọc lời Chíp Chíp và câu hỏi bằng giọng máy`

---

### Task 2: Hồ sơ bé và dữ liệu tách theo bé (DB v4)

**Files:**
- Create: `lib/profile/kid_tables.dart`, `lib/profile/kid_repository.dart`, `lib/profile/avatars.dart`
- Modify: `lib/data/app_database.dart` (schema 4 + migration), các bảng tiến độ (`GlyphProgress`, `LessonCompletions`, `SubjectLevels`, `StrokeAttempts`) thêm cột `kidId int` (khóa chính của `GlyphProgress` thành `{kidId, glyphId}`, `SubjectLevels` thành `{kidId, subject}`), `ProgressRepository`, `LevelRepository` và mọi provider đọc/ghi tiến độ nhận `kidId` hiện tại; sinh lại drift
- Test: `test/profile/kid_repository_test.dart`, `test/data/migration_test.dart` (v3 → v4 và v1 → v4), cập nhật test tiến độ/cấp

**Interfaces:**
- Produces:
  - Bảng `KidProfiles(id autoIncrement, nickname text(1..20), avatar text, age int, createdAt dateTime)`; bảng `AppSettings(key text PK, value text)`.
  - `const List<String> kidAvatars` — 6 đường dẫn `AppImages`: `chipMain`, `icStar`, `icCrown`, `icViet`, `icToan`, `icTiengAnh`.
  - `class KidRepository { Future<int> addKid({required String nickname, required String avatar, required int age}); Future<void> updateKid(...); Future<void> deleteKid(int id); Future<List<KidProfile>> kids(); Future<int?> currentKidId(); Future<void> setCurrentKid(int id); Future<String?> setting(String key); Future<void> setSetting(String key, String value); Future<void> deleteAllData(); }` — `deleteKid` xóa mọi dòng tiến độ của bé đó; xóa bé đang chọn thì chọn bé còn lại đầu tiên (hoặc null); tối đa 4 bé (`addKid` ném `StateError` khi đủ 4); `deleteAllData` xóa mọi bảng.
  - Provider: `kidRepositoryProvider`, `kidsProvider`, `currentKidIdProvider` (FutureProvider<int?>), `voiceEnabledProvider` (đọc `AppSettings['voiceEnabled']`, mặc định true). Mọi repository tiến độ nhận `kidId` từ `currentKidIdProvider`; `isPlaced` tính theo bé hiện tại.
- Migration v3 → v4: tạo hai bảng mới; nếu có bất kỳ dữ liệu tiến độ nào, tạo hồ sơ `Bé` (avatar `chipMain`, tuổi 5) và gán mọi dòng cũ cho bé đó, đặt làm bé hiện tại. Cài mới: không tạo bé nào (lần đầu mở sẽ vào Task 4).

- [ ] **Step 1: Viết test** — thêm 2 bé, ghi tiến độ cho bé 1, đổi sang bé 2 → tổng sao 0, `isPlaced` false; xóa bé 1 → dữ liệu bé 1 hết, bé 2 còn; thêm bé thứ 5 → `StateError`; migration v3 có sao và cấp → sau mở có bé `Bé`, tổng sao và cấp giữ nguyên; `deleteAllData` → không còn bé, không còn tiến độ.
- [ ] **Step 2–5:** FAIL → viết code, sinh lại drift, sửa mọi chỗ gọi → PASS toàn bộ → Commit `feat(profile): hồ sơ bé, dữ liệu tách theo từng bé`

---

### Task 3: Cổng xác nhận người lớn

**Files:**
- Create: `lib/parent/parent_gate.dart`, `lib/parent/parent_gate_route.dart`
- Test: `test/parent/parent_gate_test.dart`

**Interfaces:**
- Produces:
  - `ParentGate({required VoidCallback onPassed, VoidCallback? onCancel, Random? random})` — tiêu đề `Dành cho ba mẹ`; dòng `Nhập kết quả: {a bằng chữ} nhân {b bằng chữ}` với `a, b` ngẫu nhiên trong 3..9 (dùng `numberToVietnamese`); bàn phím số 0–9, nút `Xóa`, nút `Xác nhận`; sai → `Chưa đúng, thử lại nhé` và tạo câu mới; nút `Đóng` gọi `onCancel`. Không đọc câu đố thành tiếng.
  - `Future<bool> showParentGate(BuildContext context)` — mở cổng dạng màn toàn phần, trả true nếu qua.
  - Route `/parent` và mọi route con chỉ mở qua `showParentGate` (nút ổ khóa trang chủ gọi `showParentGate` rồi `context.push('/parent')`).

- [ ] **Step 1: Viết test** — với `Random(1)`: đọc câu đố, nhập đúng → `onPassed` một lần; nhập sai → thấy `Chưa đúng, thử lại nhé` và câu đố đổi; `Đóng` → `onCancel`; câu đố không chứa chữ số (chỉ chữ).
- [ ] **Step 2–5:** FAIL → code → PASS → Commit `feat(parent): cổng xác nhận người lớn`

---

### Task 4: Lần đầu mở app, đổi bé, lời chào theo tên

**Files:**
- Create: `lib/features/setup/first_run_screen.dart`, `lib/features/home/kid_switcher.dart`
- Modify: `lib/app.dart` (thứ tự chuyển hướng: chưa có bé → `/setup`; có bé nhưng bé hiện tại chưa xếp cấp → `/placement`; `/dev/*`, `/setup`, `/parent*` không bị chuyển), `lib/router.dart`, `lib/features/home/home_screen.dart` (viên chào `Chào {tên}!` với ảnh đại diện; chạm vào → `KidSwitcher`), `test/app_smoke_test.dart`
- Test: `test/features/first_run_test.dart`, `test/features/kid_switcher_test.dart`

**Interfaces:**
- Produces:
  - `FirstRunScreen` — bước 1 (dành cho ba mẹ, sau `ParentGate`): tiêu đề `Chào ba mẹ!`, đoạn đồng ý: `Chíp Chíp chỉ lưu tên gọi ở nhà, ảnh đại diện có sẵn và tuổi của bé, ngay trên máy này. Không quảng cáo, không gửi dữ liệu của bé ra ngoài. Ba mẹ có thể xóa toàn bộ dữ liệu bất cứ lúc nào trong Góc ba mẹ.`, liên kết `Xem chính sách quyền riêng tư` (→ `PrivacyScreen` của Task 7; trước khi Task 7 xong, mở màn tạm có cùng tiêu đề), ô đánh dấu `Tôi đồng ý`, nút `Tiếp tục` (chỉ bật khi đã đánh dấu); bước 2: `Tạo hồ sơ cho bé` — ô `Tên gọi ở nhà` (1–20 ký tự), lưới 6 ảnh đại diện, chọn tuổi `3 4 5 6 7+`, nút `Xong` → lưu `consentAt` vào `AppSettings`, `addKid`, `setCurrentKid` → `/placement`.
  - `KidSwitcher` — bảng chọn hiện từ dưới lên: các bé (ảnh to ≥ 72 + tên), bé đang chọn có viền cam; chạm → `setCurrentKid`, làm mới provider, đóng; nút `Thêm bé` (qua cổng) → màn tạo hồ sơ (dùng lại bước 2).
- Đổi bé làm mới: `homeSummaryProvider`, `todayLessonProvider`, `mathLevelIndexProvider`, `isPlacedProvider`, `kidsProvider`, `currentKidIdProvider`.

- [ ] **Step 1: Viết test** — cài mới (DB bộ nhớ rỗng): mở app → cổng → nhập đúng → `Chào ba mẹ!`; `Tiếp tục` tắt khi chưa đánh dấu; tạo bé `Na` → vào `Chào bé! Mình là Chíp Chíp`. Hai bé `Na` (đã xếp cấp) và `Bin` (chưa): đang ở `Na` thấy `Chào Na!`; đổi sang `Bin` → bị đưa vào bài xếp cấp. Không tràn ở 375×667 và 1024×1366.
- [ ] **Step 2–5:** FAIL → code → PASS → Commit `feat(setup): lần đầu mở app, đổi bé`

---

### Task 5: Giới hạn giờ và giờ đi ngủ

**Files:**
- Create: `lib/screen_time/screen_time_tables.dart`, `lib/screen_time/screen_time_service.dart`, `lib/screen_time/screen_time_guard.dart`, `lib/features/sleep/sleep_screen.dart`
- Modify: `lib/data/app_database.dart` (bảng `DailyUsage(kidId, day text 'yyyy-MM-dd', seconds int)`, PK `{kidId, day}`; schema 5 + migration), `lib/router.dart` (bọc các route của bé bằng `ScreenTimeGuard`)
- Test: `test/screen_time/screen_time_service_test.dart`, `test/features/sleep_test.dart`

**Interfaces:**
- Produces:
  - Cài đặt theo bé trong `AppSettings`: `dailyLimitMinutes.{kidId}` (mặc định 45; cho phép 15..180 bước 15), `bedtimeStart.{kidId}` / `bedtimeEnd.{kidId}` (`HH:mm`, mặc định không đặt), `extraMinutes.{kidId}.{yyyy-MM-dd}` (ba mẹ cho thêm).
  - `class ScreenTimeService { ScreenTimeService(AppDatabase db, KidRepository kids, {Clock now}); Future<void> addUsage(int kidId, Duration d); Future<Duration> usedToday(int kidId); Future<ScreenTimeStatus> status(int kidId); Future<void> grantExtra(int kidId, int minutes); }` với `enum ScreenTimeStatus { ok, limitReached, bedtime }`. Giờ ngủ qua nửa đêm: nếu `start > end` thì "đang giờ ngủ" khi `now >= start || now < end`.
  - `ScreenTimeGuard({required Widget child})` — khi app ở tiền cảnh và đang ở route của bé, cộng thời gian mỗi 15 giây (lưu xuống DB) và kiểm tra trạng thái **khi đổi màn** (không cắt ngang màn đang làm); khác `ok` → thay bằng `SleepScreen`. Thời gian ở `/parent*`, `/setup`, `/dev/*` không tính.
  - `SleepScreen(status)` — ảnh `chipSleep`, dòng `Chíp Chíp buồn ngủ rồi. Mai mình học tiếp nhé!` (hết giờ) hoặc `Đến giờ đi ngủ rồi. Chúc bé ngủ ngon!` (giờ ngủ); Chíp đọc câu đó; nút nhỏ `Ba mẹ` (qua cổng) → cho thêm `15 phút` / `30 phút` hoặc mở Góc ba mẹ.

- [ ] **Step 1: Viết test** — dịch vụ với đồng hồ giả: 44 phút → `ok`, 45 phút → `limitReached`; sang ngày mới → `ok`; cho thêm 15 phút → `ok` đến 60; giờ ngủ 20:30–06:00: 21:00 và 05:59 → `bedtime`, 06:00 và 12:00 → `ok`. Màn: hết giờ khi đang ở màn viết → màn viết vẫn hiện đến khi xong chữ rồi chuyển, khi đó thấy `Chíp Chíp buồn ngủ rồi. Mai mình học tiếp nhé!`; qua cổng và chọn `15 phút` → về trang chủ.
- [ ] **Step 2–5:** FAIL → code, migration v5 → PASS → Commit `feat(screen-time): giới hạn giờ, giờ đi ngủ, Chíp Chíp đi ngủ`

---

### Task 6: Góc ba mẹ — khung và tab Tiến bộ

**Files:**
- Create: `lib/parent/screens/parent_home.dart`, `lib/parent/screens/progress_tab.dart`
- Modify: `lib/router.dart` (`/parent`), `lib/features/home/home_screen.dart` (ổ khóa → cổng → `/parent`, bỏ SnackBar `Góc ba mẹ sắp có`)
- Test: `test/parent/progress_tab_test.dart`

**Interfaces:**
- Produces:
  - `ParentHome` — tiêu đề `Góc ba mẹ`, hàng chọn bé (chip tên), nút `Về màn bé`; thanh điều hướng dưới 5 mục: `Tiến bộ`, `Hồ sơ`, `Thời gian`, `Phần thưởng`, `Cài đặt` (Task 7 làm 4 mục sau; trước đó hiện `Sắp có`).
  - `ProgressTab` (theo bé đang chọn trong góc ba mẹ): thẻ `Hôm nay` (`{phút đã dùng} / {giới hạn} phút`, thanh tiến độ); thẻ `Tuần này` (`{N} ngày học`, tổng sao); thẻ `Tập viết` — lưới các chữ trong thang với 3 trạng thái `Viết đúng nét` (nền `AppColors.text`, chữ trắng), `Đang tập` (nền `Subject.viet.tint`, chữ `AppColors.text`), `Chưa học` (viền); chú thích 3 trạng thái; dòng gợi ý chữ hay sai nhất: `Chữ {label} bé còn hay sai, cho bé tập thêm nhé.` (chọn chữ có `completions - cleanCompletions` lớn nhất, ẩn nếu không có); thẻ `Toán` — `Đang học: {title cấp}` và `{cấp}/9`.

- [ ] **Step 1: Viết test** — dữ liệu giả: bé thuộc `net-ngang`, đang tập `so-1` (sai 3), Toán cấp 2 → thấy `Viết đúng nét` cho `Nét ngang`, `Chữ Số 1 bé còn hay sai, cho bé tập thêm nhé.`, `Đang học: So sánh`, `3/9`; ổ khóa trang chủ → cổng → `Góc ba mẹ`; không tràn ở hai cỡ màn.
- [ ] **Step 2–5:** FAIL → code → PASS → Commit `feat(parent): góc ba mẹ và tab tiến bộ`

---

### Task 7: Góc ba mẹ — Hồ sơ, Thời gian, Phần thưởng, Cài đặt, Chính sách

**Files:**
- Create: `lib/parent/screens/kids_tab.dart`, `time_tab.dart`, `rewards_tab.dart`, `settings_tab.dart`, `privacy_screen.dart`, `lib/rewards/reward_tables.dart`, `lib/rewards/reward_repository.dart`
- Modify: `lib/data/app_database.dart` (bảng `RealRewards(id, kidId, title text 1..60, starsNeeded int, createdAt, redeemedAt nullable)`; schema 6 + migration), trang chủ (viên phần thưởng nhỏ nếu bé có phần thưởng đang chờ: `{sao hiện có}/{cần} sao: {title}`)
- Test: `test/parent/parent_tabs_test.dart`, `test/rewards/reward_repository_test.dart`

**Interfaces / hành vi:**
- `KidsTab`: danh sách bé (ảnh, tên, tuổi), `Sửa`, `Xóa` (hộp xác nhận `Xóa hồ sơ {tên}? Toàn bộ tiến độ của bé sẽ mất.`), `Thêm bé` (tối đa 4; đủ thì nút tắt và ghi `Tối đa 4 bé`).
- `TimeTab`: giới hạn mỗi ngày (thanh trượt 15–180, bước 15, hiện `{n} phút`); giờ đi ngủ bật/tắt với chọn `Bắt đầu` / `Kết thúc`; hiện `Hôm nay đã dùng {n} phút`.
- `RewardsTab` + `RewardRepository { add(kidId, title, starsNeeded), list(kidId), redeem(id) }`: thêm phần thưởng (`Ví dụ: Đi công viên`, số sao cần 10..200), danh sách với thanh tiến độ theo tổng sao của bé, nút `Đã thưởng` khi đủ sao (đánh dấu `redeemedAt`; không trừ sao).
- `SettingsTab`: công tắc `Giọng đọc` (ghi `voiceEnabled`), `Làm lại bài xếp cấp cho {tên}` (xóa cấp của bé → lần sau vào bài xếp cấp), `Chính sách quyền riêng tư` (→ `PrivacyScreen`), `Xóa toàn bộ dữ liệu` (hộp xác nhận phải gõ chữ `XÓA`; xong → `deleteAllData` → về `/setup`).
- `PrivacyScreen`: tiêu đề `Chính sách quyền riêng tư`; nội dung tiếng Việt, các mục: dữ liệu thu (tên gọi ở nhà, ảnh đại diện có sẵn, tuổi, tiến độ học, thời gian dùng), lưu ở đâu (chỉ trên máy), không chia sẻ/không quảng cáo/không SDK theo dõi, quyền của ba mẹ (xem, sửa, xóa trong Góc ba mẹ), căn cứ Nghị định 13/2023/NĐ-CP, liên hệ `[EMAIL LIÊN HỆ]` (để trống cho chủ dự án điền).

- [ ] **Step 1: Viết test** — thêm/sửa/xóa bé; giới hạn đổi 60 → `ScreenTimeService` dùng 60; phần thưởng 10 sao, bé có 12 sao → nút `Đã thưởng` bật, bấm → chuyển vào `Đã thưởng`, tổng sao vẫn 12; tắt `Giọng đọc` → `speakerProvider` là `SilentSpeaker`; `Xóa toàn bộ dữ liệu` cần gõ `XÓA`, xong về `Chào ba mẹ!`; không tràn ở hai cỡ màn.
- [ ] **Step 2–5:** FAIL → code, migration v6 → PASS toàn bộ, `flutter analyze` sạch → Commit `feat(parent): hồ sơ, thời gian, phần thưởng, cài đặt, chính sách`

---

## Xong giai đoạn 1C khi

- `flutter analyze` sạch, mọi test PASS trên Flutter 3.24.5.
- Cài mới: ba mẹ qua cổng, đồng ý, tạo hồ sơ → bé làm bài xếp cấp → học; Chíp Chíp nói được; nhiều bé dữ liệu riêng; hết giờ thì Chíp Chíp đi ngủ; góc ba mẹ đủ 5 mục; xóa toàn bộ dữ liệu được.
- Cài đè từ 1B: dữ liệu cũ thành hồ sơ `Bé`, không mất gì.
- Chủ dự án chạy thử trên máy thật, điền email liên hệ trong chính sách.
