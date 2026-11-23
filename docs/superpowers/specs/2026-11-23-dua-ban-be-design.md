# Đua với bạn bè: trận 3 chặng, sticker trêu, sảnh đấu, kết bạn, Tủ khoe — thiết kế

> Ngày: 2026-11-23 · Trạng thái: **chờ chủ dự án duyệt** · Nhánh: `chipchip`
> Bản phác đã duyệt (chỉ để tham khảo bố cục, ảnh thật dùng tài sản 3D của app): `docs/superpowers/specs/assets/dua-ban-be/race-c.png`, `lobby-showcase.png`.
> Người code là AI khác, có người review. **Hiệu năng là yêu cầu bắt buộc** (§9): mọi task có tiêu chí đo.

## 1. Vì sao

Bé chủ yếu đua online **với bạn bè quen ngoài đời** (bạn lớp, anh chị em họ, con bạn ba mẹ). Trận hiện tại 10 câu, hai tên lửa giống hệt nhau (đều chở Chíp), không thấy ai dẫn, không có cao trào. Chủ dự án muốn trận đua "wow", kịch tính, có trêu nhau vui nhộn; phòng chờ đẹp như sảnh đấu game; mời bạn dễ; có chỗ khoe thành tích.

## 2. Mục tiêu / Không làm / Thất bại nếu

**Mục tiêu**
1. Đua online: **3 chặng × 6 câu = 18 câu**; giao diện "cả đoàn bay cùng nhau" (hướng C); khoang lái mang **ảnh nhân vật của bé**; vượt mặt, siêu tốc, Cổng Sao giữa chặng, chặng nước rút.
2. 8 sticker trêu + 3 sticker cổ vũ + câu nói nhanh, có chuyển động.
3. Phòng chờ kiểu sảnh đấu: ô lớn mỗi bạn, chấm xanh (kết nối) / xám (mất mạng, đếm ngược).
4. Kết bạn theo gia đình bằng mã do ba mẹ tạo; danh sách bạn có chấm online; mời đấu tức thì cho bạn đang mở app.
5. Tủ khoe: 3 ô khoe, thành tích đua + học (số cộng dồn), thả 👏 ❤️ ⭐.
6. Đạt mục tiêu hiệu năng §9 trên máy thật.

**Không làm**
- Mic/giọng nói thật (giai đoạn sau). Không chữ tự do, không bình luận, không ảnh thật, không bảng xếp hạng giữa bạn.
- Không thông báo đẩy: chỉ mời được bạn đang mở app.
- Đua với Chíp (offline) **giữ 10 câu**, không đổi luật.
- Không dùng dịch vụ realtime bên ngoài (Firebase…).

**Thất bại nếu**
- Màn đua giật (dưới mục tiêu §9) trên máy Android tầm trung.
- Sticker trêu che câu hỏi, làm chậm tên lửa, hoặc bị dùng để "dội bom".
- Trẻ lạ thấy hoặc mời được bé; thấy trạng thái online của gia đình không phải bạn.
- Chế độ khách phát sinh kết nối mạng.

## 3. Ràng buộc

`AGENTS.md` đầy đủ (Flutter 3.24.5, không nâng/thêm gói trừ khi spec cho phép — **spec này không thêm gói Flutter nào**; Riverpod; tokens; nút bé ≥ 64/tablet ≥ 80; ba mẹ ≥ 48; chuỗi tiếng Việt; dữ liệu trò chơi tách khỏi dữ liệu học; engine trò chơi không gọi mạng — phần mạng ở `lib/online/`). Ảnh mới: Gemini vẽ trên nền xanh lá → `tools/assets/chroma_key.py`, truy cập qua `lib/ui/assets.dart`. Máy chủ: Spring Boot 3.3.5, Java 21, PostgreSQL 16, không thêm thư viện. Bộ thông báo chung `lib/ui/feedback/`.

## 4. Các cách đã cân nhắc (kết bạn + online + mời)

| Cách | Mô tả | Được | Mất |
|---|---|---|---|
| **1. WebSocket "sảnh" `/ws/lobby`** ✅ | Kết nối nhẹ khi app ở màn hình trước + đã đăng nhập; máy chủ giữ trạng thái online trong bộ nhớ, chỉ báo cho bạn bè; lời mời qua kênh này | Tức thì, dùng lại hạ tầng WebSocket phòng đua, chấm chính xác | Thêm kết nối lâu dài phải quản lý |
| 2. Hỏi định kỳ 15–20 s | HTTP lấy online + lời mời | Đơn giản | Mời trễ tới 20 s, tốn request, chấm không chính xác |
| 3. Firebase/realtime ngoài | — | — | Trái quy tắc dự án — loại |

**Chủ dự án chọn cách 1.** Đã chốt thêm trong trao đổi: độ dài **cách B** (3 chặng, 18 câu); giao diện **hướng C**; nói chuyện **cách C** (câu nói nhanh giờ, mic sau); Tủ khoe **hiện cả thành tích học**; sticker trêu **bộ 8** với các luật an toàn (§6.3).

## 5. Phần A — Trận đua online mới

### 5.1 Luật

- `onlineRaceStages = 3`, `onlineStageQuestions = 6` → `onlineRaceLength = 18` bước. Máy chủ: `Room.RACE_LENGTH` thành **18** cho phòng online (đua với Chíp không qua máy chủ, giữ `raceLength = 10`).
- **Chặng nước rút** (chặng 3, câu 13–18): câu đúng **lần đầu** +2 bước, đúng lần hai +1 (chặng 1–2 như hiện nay: +1 / chỉ đúng). Máy chủ kiểm: bước gửi lên chỉ được +1 hoặc +2, +2 chỉ hợp lệ khi `steps >= 12`; giữ tối thiểu 600 ms giữa hai bước. Đích = 18 bước (chặng 3 có thể về sớm).
- **Siêu tốc**: 3 câu đúng lần đầu liên tiếp → hiệu ứng (chỉ hình ảnh, không thêm bước — giữ công bằng và đơn giản).
- **Cổng Sao**: khi **bé** qua bước 6 và 12 → 2,5 s chuyển cảnh trên máy bé (câu hỏi tạm ẩn, đồng hồ trận không dừng ở máy chủ — chỉ máy bé vẽ cảnh; bạn khác vẫn đua). Bảng tạm thời lấy từ snapshot gần nhất.

### 5.2 Giao diện (theo `race-c.png`)

- Nền không gian cuộn (dùng lại `space_track.dart`, `speed_lines.dart`), cả đoàn ở giữa nửa trên; vị trí dọc của mỗi tên lửa = tiến độ tương đối so với người dẫn (người dẫn ở dòng cao nhất cố định, người sau tụt xuống theo khoảng cách bước, tối đa chiều cao vùng đua); vị trí ngang theo thứ tự vào phòng.
- Tên lửa: ảnh 3D màu theo thứ tự vào phòng (`rocket-orange/blue/green/purple` có sẵn); **khoang lái hiện ảnh đại diện của bé**, khoang to hơn hiện nay; viền vàng + nhãn tên vàng cho bé; huy hiệu thứ hạng tròn vàng.
- **Ảnh đại diện mới**: 12 nhân vật con vật 3D (cáo, gấu trúc, thỏ, hổ, mèo, chó, voi, khủng long, cú, chim cánh cụt, gấu, kỳ lân) vẽ bằng Gemini theo phong cách Chíp; thêm vào `kidAvatars` (giữ 6 ảnh cũ để hồ sơ cũ không hỏng); màn tạo/sửa hồ sơ hiện lưới mới.
- **Vượt mặt**: khi thứ hạng của bé tăng → banner vàng "VƯỢT! 🚀 Con lên hạng N" 1,2 s + rung nhẹ (`HapticFeedback.lightImpact`) + tiếng vút; bị vượt → banner nhỏ "Bin vừa vượt con!".
- Thanh 3 chặng dưới HUD; HUD "Chặng 2 · Câu 9/18".
- Panel dưới: hàng sticker/câu nói nhanh (cuộn ngang, nút ≥ 64), câu hỏi, 3 đáp án **cùng một màu**.
- Hết trận: màn kết quả hiện tại + bục 1-2-3 với ảnh đại diện, nút "Xem tủ khoe" trên từng bạn (Phần C).

### 5.3 Âm thanh

Dùng lại cơ chế âm thanh hiện có của màn đua (nếu chưa có, chỉ rung + hiệu ứng hình; **không thêm gói âm thanh**). Ghi rõ trong plan sau khi người code kiểm.

## 6. Phần B — Sticker, câu nói nhanh, sảnh đấu

### 6.1 Danh mục

`roomStickers` mở rộng (máy chủ giữ danh sách trắng giống app):
- Cổ vũ: `cheer` 👏, `love` ❤️, `party` 🎉.
- Trêu: `bubble` 🫧, `tongue` 😜, `byebye` 👋, `rain` 🌧️, `sleepy` 💤, `turtle` 🐢, `smoke` 💨, (giữ cũ `wow`, `fast`, `hi`, `gg` để tương thích).
- Câu nói nhanh: `q_almost` "Tớ sắp tới rồi!", `q_fast` "Cậu nhanh quá!", `q_oops` "Ối, tớ sai rồi!", `q_chase` "Bắt tớ đi!", `q_again` "Đua lại nào!" — gửi như sticker (`t: sticker`, id có tiền tố `q_`), máy nhận hiện bong bóng chữ + đọc bằng giọng đọc của app (`speaker`) **chỉ khi không đang đọc câu hỏi**.
- Sticker trêu có **đích**: `{t: sticker, id, to: playerId}`; không có `to` → hiện trên tên lửa người gửi. Máy chủ kiểm `to` tồn tại trong phòng.

### 6.2 Hình và chuyển động

- 11 ảnh sticker mới (3D, cùng bộ với `sticker-*.png` hiện có), lời mô tả cho Gemini ghi trong `docs/phase0/asset-list.md`.
- Chuyển động bằng code (không Lottie/Rive): `StickerFx` gồm các kiểu `popIn` (phóng to 0→1.15→1 trong 250 ms), `wobble`, `arcFly(from, to)` (đường cong bezier 450 ms), `burst` (hạt), `rainDrops`, `floatUp` (zZz). Mỗi sticker gán một chuỗi kiểu. Vẽ **trên cùng một Ticker/painter của cảnh đua** (§9.1), không tạo `AnimationController` riêng mỗi sticker.
- Hiệu ứng nằm trên vùng tên lửa; **không bao giờ đè panel câu hỏi**; không thay đổi tốc độ/bước.

### 6.3 Luật an toàn

- Gửi tối đa **1 sticker / 3 s / bé** (app khóa nút + máy chủ bỏ qua tin vượt, đếm theo người chơi).
- Nhận ≥ 3 sticker trêu trong 10 s → Chíp hiện bong bóng "Kệ bạn, mình bay tiếp nào!" (một lần mỗi chặng).
- Cài đặt ba mẹ `teaseStickers` (mặc định bật; đồng bộ như cài đặt khác của bé): tắt → bé không thấy hàng sticker trêu và **không hiển thị** sticker trêu nhận được (chỉ cổ vũ).

### 6.4 Sảnh đấu (theo `lobby-showcase.png`)

- Nền không gian giống màn đua; HUD: nút quay lại, "Mã phòng 4821 📋".
- Lưới 2×2 ô (tablet 4×1): ảnh đại diện lớn trong viền màu tên lửa, chấm **xanh `connected`** / **xám `away`** (+ "Mất mạng · chờ Ns" từ `awayMsLeft`), tên, nhãn "Sẵn sàng" (đã kết nối), tên lửa nhỏ màu riêng, vương miện chủ phòng, sticker vừa nhận nổi trên ô.
- Ô trống: "Mời bạn" → mở danh sách bạn online (Phần C); không có bạn online → hiện mã phòng để gửi.
- Chọn môn (chủ phòng), hàng sticker, nút "Bắt đầu! 3 chặng" (≥ 2 bạn xanh).
- Chạm ô một bạn → Tủ khoe (nếu là bạn đã kết; người không phải bạn → chỉ ảnh + tên).

## 7. Phần C — Kết bạn, online, mời đấu, Tủ khoe

### 7.1 Dữ liệu máy chủ (Flyway V6)

```sql
CREATE TABLE friend_codes (
    code        TEXT PRIMARY KEY CHECK (code ~ '^[A-Z0-9]{6}$'),
    family_id   UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX friend_codes_family_idx ON friend_codes (family_id);
CREATE INDEX friend_codes_expires_idx ON friend_codes (expires_at);

-- One row per pair, smaller id first, so a pair is stored once.
CREATE TABLE friendships (
    family_a    UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    family_b    UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (family_a, family_b),
    CHECK (family_a < family_b)
);
CREATE INDEX friendships_b_idx ON friendships (family_b);

-- What a family shows to friends: chosen kid cards (no learning levels).
CREATE TABLE showcases (
    family_id   UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    kid_uuid    TEXT NOT NULL CHECK (length(kid_uuid) <= 64),
    payload     JSONB NOT NULL,          -- ≤ 4 KB, built by the app (§7.5)
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (family_id, kid_uuid)
);

CREATE TABLE showcase_reactions (
    to_family   UUID NOT NULL,
    to_kid      TEXT NOT NULL,
    from_family UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    kind        TEXT NOT NULL CHECK (kind IN ('clap','heart','star')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (to_family, to_kid, from_family, kind),
    FOREIGN KEY (to_family, to_kid) REFERENCES showcases (family_id, kid_uuid) ON DELETE CASCADE
);
```

Xóa tài khoản → cascade xóa mã, bạn, tủ, phản ứng. Mỗi gia đình tối đa **50 bạn**.

### 7.2 API REST (cần access token; giới hạn tần suất theo gia đình như `RateLimitFilter`)

| Method | Vào | Ra / lỗi |
|---|---|---|
| `POST /api/v1/friends/code` | — | `{code, expiresAt}` (6 ký tự, không dễ nhầm: bỏ `0 O 1 I`), hạn **24 giờ**, mỗi gia đình tối đa 3 mã còn hạn; 10 lần/giờ |
| `POST /api/v1/friends/redeem` | `{code}` | 200 `{friend: FriendDto}`; 404 `code_invalid` (sai/hết hạn — cùng một lỗi để không dò được); 409 `self` / `already_friends` / `too_many_friends`; 20 lần/giờ/gia đình (chống đoán mã) |
| `GET /api/v1/friends` | — | `[{familyId, kids:[{kidUuid, nickname, avatar, rocket}], online}]` |
| `DELETE /api/v1/friends/{familyId}` | — | 204 (xóa cả hai chiều, đẩy `friend_removed` qua sảnh) |
| `PUT /api/v1/showcase/{kidUuid}` | payload §7.5 | 204 |
| `GET /api/v1/showcase/{familyId}/{kidUuid}` | — | payload + `reactions:{clap,heart,star}` + `mine:[kinds]`; 404 nếu không phải bạn |
| `POST /api/v1/showcase/{familyId}/{kidUuid}/react` | `{kind}` | 204 (idempotent theo khóa chính); đẩy `reaction` qua sảnh cho chủ tủ |

`FriendDto.kids` lấy từ bản ghi `kid:` trong `sync_records` (nickname, avatar) + `setting:<kid>:raceNickname` nếu có, đọc **một lần mỗi gia đình** (§9.2).

### 7.3 Sảnh `/ws/lobby`

- Bắt tay: access token như `/ws/room`; một gia đình có thể nhiều kết nối (nhiều máy) — online = có ≥ 1 kết nối.
- App mở kết nối khi: đã đăng nhập **và** app ở màn hình trước **và** (đang ở Góc Chơi, phòng chờ, màn kết quả, hoặc danh sách bạn). Rời các màn đó 30 s hoặc app vào nền → đóng. Mất kết nối → nối lại 1/3/6/10 s.
- Tin máy chủ → app: `{t:"hello", friendsOnline:[familyId]}`, `{t:"presence", familyId, online}`, `{t:"invite", inviteId, from:{familyId, kidUuid, nickname, avatar}, roomCode, expiresInMs}`, `{t:"invite_cancelled", inviteId}`, `{t:"reaction", kidUuid, kind, fromNickname}`, `{t:"friend_added"|"friend_removed", familyId}`.
- Tin app → máy chủ: `{t:"invite", toFamilyId, roomCode, kidUuid}` (chỉ tới bạn đang online; phòng phải tồn tại và người mời đang ở trong; tối đa 1 lời mời đang chờ cho mỗi cặp; hết hạn 30 s), `{t:"invite_reply", inviteId, accept}`, `{t:"ping"}`.
- Nhận lời mời: `showAppDialog(audience: kid, image: ảnh bạn)` "Na mời con đua tên lửa!" — "Vào đua" / "Để sau"; không hiện khi bé đang học/viết/đua (xếp hàng, hiện khi về Góc Chơi hoặc trang chủ; quá hạn thì bỏ). "Vào đua" → vào phòng bằng `roomCode` như "Nhập mã" (không qua cổng ba mẹ — lời mời chỉ đến từ bạn đã được ba mẹ kết).
- Giới hạn: ≤ 3 kết nối sảnh/gia đình, ≤ 5 tin/giây/kết nối, ping mỗi 25 s, đóng nếu im 60 s.

### 7.4 Giao diện Phần C

- **Góc ba mẹ → "Bạn đua của bé"**: nút "Tạo mã kết bạn" (hiện mã to + "Chép mã", "Gửi qua…" dùng chia sẻ hệ thống có sẵn của dự án nếu có, không thì chỉ chép), ô "Nhập mã của bạn", danh sách gia đình bạn (ảnh các bé, nút "Xóa bạn" `tone: danger`), công tắc "Tủ khoe", "Hiện thành tích học trong Tủ khoe", "Sticker trêu".
- **Góc Chơi → hàng "Bạn đua"**: cuộn ngang ảnh các bé bạn, chấm xanh/xám, chạm bạn xanh → tạo phòng + mời ngay (một chạm); chạm bạn xám → Tủ khoe.
- **Tủ khoe** (theo bản phác): thẻ ảnh lớn, tên, tên lửa + vệt, 3 ô khoe, thành tích (12 trận · 7 thắng · 24 sticker; ✏️ chữ · 📘 bài · ⭐ sao nếu bật), 3 nút phản ứng (chọn rồi thì sáng lên), số phản ứng. Màn "Tủ khoe của con" (bé tự chọn 3 ô từ sticker/huy hiệu đang có) trong Sưu tập.

### 7.5 Nội dung Tủ khoe

App dựng và `PUT` khi: đăng nhập xong, bé đổi ô khoe, sau mỗi trận đua online, sau "Xong bài hôm nay" (gộp, tối đa 1 lần/5 phút). Payload: `{nickname, avatar, rocket, trail, pinned:[itemId|badgeId ×≤3], races, wins, stickers, learning?:{glyphs, lessons, stars}}` — `learning` chỉ khi ba mẹ bật. Không cấp học, không tên thật, không email.

## 8. Bảo vệ trẻ em / quyền riêng tư

- Chỉ ba mẹ (sau cổng ba mẹ) tạo/nhập mã, xóa bạn, bật/tắt tủ, sticker trêu. Bé không tự kết bạn.
- Online và tủ chỉ hiện với bạn đã kết; máy chủ **không lưu lịch sử online** (chỉ trong bộ nhớ); log không chứa tên bé.
- Cập nhật `privacy_screen.dart`, hộp đồng ý online, `AGENTS.md` (mục mạng: thêm sảnh/kết bạn), spec 2D.

## 9. Hiệu năng (bắt buộc, có đo)

### 9.1 App — mục tiêu và cách làm

**Mục tiêu (đo bằng `flutter run --profile` + DevTools, theo `docs/perf.md`):** màn đua online 4 bạn, có sticker bay, trên Android tầm trung (ví dụ Galaxy A3x/A5x 2–3 năm tuổi) và iPhone 11: **≥ 58 fps trung bình, không khung nào > 32 ms, raster ≤ 8 ms/khung, UI ≤ 8 ms/khung**; máy 120 Hz không tụt dưới 90 fps khi chỉ có cảnh bay. Mở phòng chờ → màn đua **≤ 300 ms**. Bộ nhớ ảnh tăng ≤ 30 MB so với màn đua hiện tại.

**Quy tắc code (reviewer kiểm từng task):**
1. **Một Ticker duy nhất** cho cả cảnh (như `RaceScene` hiện có): tên lửa, nền, sticker, hạt, banner đều cập nhật trong `_onTick`; không `setState` cả màn mỗi khung — `CustomPainter` nhận `Listenable` (repaint) thay cho rebuild.
2. `RepaintBoundary` tách: (a) nền không gian, (b) lớp tên lửa + hiệu ứng, (c) HUD, (d) panel câu hỏi. Panel câu hỏi **không** repaint theo khung.
3. Ảnh: giải mã trước (`precacheImage`) toàn bộ tên lửa, ảnh đại diện trong phòng, sticker trước khi vào trận (trong 3-2-1); vẽ bằng `canvas.drawImageRect` với `ui.Image` đã giải mã, kích thước giải mã khớp kích thước vẽ (`cacheWidth`); ảnh sticker ≤ 256 px.
4. **Cấm** trong vòng khung: `Opacity`/`saveLayer`/`BackdropFilter`/`ImageFilter.blur`/`ShaderMask` động; dùng `Paint..color` có alpha, `ColorFilter` tạo sẵn. Phát sáng = ảnh glow vẽ sẵn, không blur thời gian thực.
5. Hạt (khói, pháo giấy, bong bóng nổ): **pool cố định** (≤ 120 hạt toàn cảnh), không cấp phát mỗi khung; mỗi sticker ≤ 24 hạt.
6. Tin mạng → state: `RoomController` chỉ đổi state khi snapshot khác (so `steps`/`rank`/`connected`/`away` từng người); vị trí hiển thị **nội suy** giữa hai snapshot (lerp 200 ms) để mượt dù tin đến 5–10 lần/giây; không rebuild widget tree theo tin.
7. Bố cục ổn định: kích thước các vùng cố định theo màn hình; banner/sticker là lớp vẽ, không chèn widget làm layout lại.
8. Test hiệu năng tự động (chạy trên máy dev, không thay đo máy thật): `test/perf/online_race_frame_test.dart` — `WidgetTester` + `binding.reportTimings`/`FrameTiming` không áp dụng trong test, nên kiểm **số lần build/paint**: 120 khung với 4 tên lửa + 6 sticker bay → panel câu hỏi build 0 lần, mỗi painter `shouldRepaint` đúng, không tạo `AnimationController` mới. Kèm hướng dẫn đo máy thật vào `docs/perf.md`.

### 9.2 Máy chủ — mục tiêu và cách làm

**Mục tiêu trên một máy Oracle Ampere A1 (4 OCPU, 24 GB, Java 21):** **5.000 kết nối sảnh đồng thời + 1.000 phòng đua đồng thời (4 người, 5 bước/giây/người)**; độ trễ tin trong phòng (nhận bước → gửi snapshot) **p99 ≤ 150 ms** (sửa 2026-11-23: bản đầu ghi 100 ms, không đạt được vì gộp gửi mỗi 100 ms đã chiếm tới 100 ms; chủ dự án chọn giữ 10 lần/giây và nới mục tiêu — với bé 3–6 tuổi 150 ms không nhận ra, tên lửa vốn được nội suy); lời mời tới bạn **p99 ≤ 300 ms**; REST bạn bè/tủ **p99 ≤ 150 ms**; CPU ≤ 60 %; heap ≤ 2 GB.

**Quy tắc code:**
1. **Virtual threads** cho Tomcat/WebSocket (`spring.threads.virtual.enabled: true`, Spring Boot 3.2+ có sẵn) — kiểm không có `synchronized` giữ khóa khi làm I/O (gửi WebSocket trong `synchronized` gây pin thread): tách "tính snapshot" (trong khóa) và "gửi" (ngoài khóa) ở `Room`.
2. Gửi: giữ `ConcurrentWebSocketSessionDecorator` (giới hạn buffer + thời gian gửi); khách chậm vượt buffer → đóng kết nối đó, không chặn phòng.
3. **Gộp broadcast**: mỗi phòng gửi snapshot tối đa **10 lần/giây** (đánh dấu "bẩn" khi có bước, `tick` 100 ms hiện có gửi nếu bẩn) thay vì gửi mỗi bước; tin sticker gửi ngay nhưng chỉ cho người trong phòng.
4. Snapshot nhỏ: tên khóa JSON ngắn như hiện tại; tuần tự hóa **một lần** cho mọi người trong phòng (phần "you" gửi riêng một lần khi vào phòng, không nhúng mỗi snapshot) — snapshot ≤ 600 byte cho 4 người.
5. **Sảnh**: `ConcurrentHashMap<UUID familyId, Set<Session>>` online; `ConcurrentHashMap<UUID, Set<UUID>> friendsCache` nạp khi gia đình kết nối sảnh (một truy vấn, chỉ mục `friendships` hai chiều), cập nhật khi thêm/xóa bạn, bỏ khi gia đình không còn kết nối; báo presence chỉ cho bạn **đang online** (giao của hai tập) — không quét toàn bộ.
6. `GET /friends`: **một** truy vấn lấy danh sách bạn + **một** truy vấn lấy mọi bản ghi `kid:` của các gia đình đó (`family_id = ANY(?) AND kind = 'kid' AND NOT deleted`, dùng chỉ mục `sync_records_family_kind_live_idx` đã có) — không N+1. Có test đếm số câu SQL (≤ 3).
7. Tủ khoe: đọc theo khóa chính; số phản ứng bằng `GROUP BY kind` một truy vấn.
8. Dọn mã kết bạn hết hạn trong tác vụ đêm hiện có (`RefreshTokenCleanup` mở rộng hoặc lớp riêng cùng lịch).
9. **Kiểm tải** `server/src/test/java/.../load/LobbyRoomLoadTest.java` (đánh dấu `@Tag("load")`, không chạy trong `./gradlew test` thường; chạy `./gradlew loadTest`): Java `HttpClient` WebSocket, 2.000 kết nối sảnh + 300 phòng × 4 người bước 5/giây trong 60 s trên máy dev → in p50/p95/p99 độ trễ, số lỗi; tiêu chí trên máy dev: p99 phòng ≤ 150 ms, 0 kết nối rớt ngoài ý muốn. Ghi kết quả và cách chạy lại trên Oracle vào `docs/perf.md`.

## 10. Thứ tự làm (gợi ý cho plan)

1. Phần A: tài sản (ảnh đại diện 12 con vật, 11 sticker — có thể dùng ảnh tạm emoji trong code tới khi có ảnh thật, `AppImages` trỏ về file giữ chỗ), luật 18 bước + nước rút (máy chủ + app), cảnh đua mới, vượt mặt/siêu tốc/Cổng Sao, test + đo hiệu năng.
2. Phần B: sticker có đích + chuyển động + luật an toàn, câu nói nhanh, sảnh đấu mới, gộp broadcast + tách gửi khỏi khóa ở máy chủ.
3. Phần C: V6 + REST bạn/tủ, `/ws/lobby`, Góc ba mẹ, hàng bạn đua, lời mời, Tủ khoe, kiểm tải.

## 11. Để người code tự quyết (ghi trong PR)

- Có âm thanh hiệu ứng hay chỉ rung (§5.3) tùy cơ chế âm thanh hiện có.
- Vị trí ngang các tên lửa khi 2 và 3 người (căn giữa cân đối).
- Bố cục tablet ngang của sảnh và Tủ khoe (miễn không phóng to bố cục điện thoại).

## 12. Quyết định của tôi (AI viết spec), chủ dự án kiểm khi đọc

- Nước rút: +2 bước cho câu đúng lần đầu ở chặng 3; siêu tốc chỉ là hiệu ứng, không thêm bước.
- Cổng Sao chỉ là cảnh trên máy bé (2,5 s), trận không dừng chờ.
- 12 ảnh đại diện con vật mới (giữ 6 ảnh cũ).
- Mã kết bạn 6 ký tự, hạn 24 giờ; tối đa 50 bạn/gia đình; lời mời hết hạn 30 s.
- Sticker: 1 cái / 3 giây / bé; ba mẹ tắt được sticker trêu (mặc định bật).
- Mục tiêu hiệu năng §9 (≥ 58 fps máy tầm trung; 5.000 kết nối sảnh + 1.000 phòng trên một máy Oracle A1; độ trễ phòng p99 ≤ 150 ms).
