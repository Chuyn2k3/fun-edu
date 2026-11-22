# Đăng nhập ngay lần đầu + liên kết máy (online/khách) — thiết kế

> Ngày: 2026-11-22 · Trạng thái: **chờ chủ dự án duyệt** · Nhánh: `chipchip`
> Tiếp nối spec 2D: `docs/superpowers/specs/2026-11-21-giai-doan-2d-2b2-online-design.md`.
> Người code là AI khác, có người rà soát: tài liệu này phải đủ để lập plan mà không phải hỏi lại.

## 1. Vì sao

Chủ dự án muốn **đăng nhập là cách dùng chính**: ba mẹ đăng nhập Google/Apple ngay lần đầu mở app, để mọi thứ của bé (hồ sơ, tiến độ, cấp, sao, trò chơi, sticker, huy hiệu, phần thưởng) được lưu trên máy chủ. Đổi máy, cài lại app: đăng nhập là có lại hết.

**Chế độ khách là dùng tạm**: chạy offline như hiện nay, dữ liệu chỉ ở trên máy, không gọi mạng.

Chỗ nguy hiểm cần chặn: máy đang có dữ liệu khách, ba mẹ đăng nhập vào tài khoản **đã có dữ liệu**. Nếu cứ gộp như code hiện tại, hai bộ dữ liệu trộn vào nhau (hai bé "Na", sao cộng lẫn). Chủ dự án chốt: **dữ liệu tài khoản thắng, dữ liệu khách trên máy bị thay**, phải **cảnh báo trước**, và **máy chủ phải chặn**, không chỉ giao diện.

## 2. Mục tiêu / Không làm / Thất bại nếu

**Mục tiêu**
1. Màn đầu tiên (sau cổng ba mẹ) mời đăng nhập, nút khách là nút phụ.
2. Đăng nhập trên máy mới vào tài khoản có dữ liệu → các bé hiện lại, **bỏ qua** tạo hồ sơ và bài thử xếp cấp.
3. Máy có dữ liệu khách + tài khoản trống → dữ liệu khách tự lên tài khoản, không hỏi.
4. Máy có dữ liệu khách + tài khoản có dữ liệu → hộp cảnh báo so sánh hai bên; chỉ khi ba mẹ xác nhận mới xóa dữ liệu khách và tải dữ liệu tài khoản về. Hủy thì quay lại chơi khách, không mất gì.
5. Máy chủ từ chối mọi lần đẩy dữ liệu từ một máy **chưa liên kết** với gia đình, và từ chối "mang lên" khi tài khoản đã có dữ liệu.
6. Đăng xuất rồi đăng nhập lại cùng tài khoản trên cùng máy: không hỏi gì, đồng bộ tiếp.
7. Người dùng khách có thể đăng nhập sau ở Góc ba mẹ, theo đúng luồng liên kết trên.

**Không làm**
- Không cho dữ liệu khách **ghi đè** tài khoản (dù ba mẹ muốn). Muốn vậy thì xóa tài khoản online rồi đăng nhập lại (tài khoản trống → mang lên).
- Không gộp chọn lọc từng bé.
- Không gửi dữ liệu khách lên máy chủ để "chọn sau".
- Không đổi thiết kế đồng bộ (bản ghi theo khóa, `baseVersion`), không đổi cách chấm nét.
- Không đồng bộ mọi lần tập (`stroke_attempts` vẫn ở trên máy). Chỉ **trang vở đẹp nhất của mỗi chữ** được lưu online (§7.6), để "Vở của bé" theo sang máy mới (chủ dự án chọn 2026-11-22, cách A).

**Thất bại nếu** (dù chạy được)
- Một bản app cũ/lỗi vẫn trộn được dữ liệu khách vào tài khoản có dữ liệu.
- Ba mẹ mất dữ liệu khách mà không thấy cảnh báo rõ, hoặc mất dữ liệu tài khoản trong bất kỳ trường hợp nào.
- Chế độ khách phát sinh dù một request mạng.
- Bé bị kẹt ở màn chờ khi mất mạng lúc đăng nhập lần đầu.

## 3. Ràng buộc

- Flutter 3.24.5, Riverpod, drift (đang v8), go_router 15; máy chủ Spring Boot 3.3 + Flyway (đang V4). Theo mọi quy tắc trong `AGENTS.md` (nút ba mẹ ≥ 48, chuỗi tiếng Việt, màu qua `tokens.dart`…).
- Cổng ba mẹ và hộp đồng ý vẫn đứng **trước** mọi request mạng (Nghị định 13/2023).
- Build không có `FUNEDU_API_URL` (`OnlineConfig.enabled == false`): luồng đầu tiên y như hiện nay, không có bước đăng nhập.
- App chưa phát hành bản có online: không cần tương thích ngược với token cũ (token thiếu claim mới → coi là chưa liên kết, app tự liên kết lại).

## 4. Các cách đã cân nhắc

| Cách | Mô tả | Được | Mất |
|---|---|---|---|
| 1. Chỉ app quyết | App hỏi "tài khoản có dữ liệu chưa?" rồi tự gộp hoặc thay | Ít việc | Máy chủ không chặn; app lỗi vẫn trộn dữ liệu — trái yêu cầu |
| **2. Liên kết máy, máy chủ chặn** ✅ | Máy phải được liên kết với gia đình trước khi được đẩy dữ liệu; "mang lên" bị từ chối khi tài khoản đã có dữ liệu | Máy chủ là chốt chặn thật | Thêm bảng, 2 endpoint, 1 trạng thái trên app |
| 3. Kho tạm trên máy chủ | Đẩy dữ liệu khách lên vùng riêng để chọn sau | Không mất ngay | Phức tạp gấp đôi, gửi dữ liệu khách ra ngoài — loại |

**Chủ dự án chọn cách 2** (2026-11-22).

## 5. Khái niệm

- **deviceId**: UUID v4 app tự sinh lần đầu cần, lưu trong `app_settings` khóa `deviceId` (không bị xóa khi đăng xuất hay khi thay dữ liệu; mất khi gỡ app — khi đó máy cũng không còn dữ liệu nên không sao). Không phải định danh theo dõi: chỉ gửi lên máy chủ FunEdu sau khi ba mẹ đăng nhập.
- **Máy đã liên kết** với gia đình F: máy chủ có dòng `(F, deviceId)` trong `family_devices`. Chỉ máy đã liên kết mới được đẩy thay đổi.
- **Tài khoản có dữ liệu**: gia đình có ít nhất một bản ghi `sync_records` **không phải tombstone**, HOẶC đã có máy liên kết bằng chế độ `upload` (xem §6.3, chặn hai máy khách cùng mang lên).
- **Dữ liệu trên máy**: máy có ít nhất một hồ sơ bé.
- **Chủ dữ liệu trên máy** (`dataOwnerFamilyId` trong `app_settings`): gia đình mà dữ liệu trên máy thuộc về; trống = dữ liệu khách. Đặt khi liên kết xong; xóa khi thay dữ liệu xong hay xóa toàn bộ dữ liệu. Chỉ dùng để quyết định giao diện; máy chủ vẫn là bên chặn.

## 6. Máy chủ

### 6.1 Flyway V5

```sql
CREATE TABLE family_devices (
    family_id  UUID NOT NULL REFERENCES families (id) ON DELETE CASCADE,
    device_id  UUID NOT NULL,
    mode       TEXT NOT NULL CHECK (mode IN ('upload', 'replace_local', 'fresh')),
    linked_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (family_id, device_id)
);
```

Xóa tài khoản → cascade xóa liên kết. Một máy có thể liên kết với nhiều gia đình (đổi tài khoản trên cùng máy).

### 6.2 Token mang deviceId

- `POST /api/v1/auth/{provider}` thêm trường bắt buộc `deviceId` (UUID, kiểm định dạng; sai → 400).
- Access JWT thêm claim `dev` = deviceId. `refresh_tokens` thêm cột `device_id UUID NOT NULL` (V5; xóa token cũ trong migration vì chưa phát hành, hoặc cho phép NULL và coi NULL là chưa liên kết — **người code chọn**, ghi lý do). Refresh giữ nguyên `device_id` của token cũ.
- Phản hồi đăng nhập thêm:

```json
{
  "accessToken": "...", "refreshToken": "...", "familyId": "...",
  "device": { "linked": false },
  "account": {
    "hasData": true,
    "kids": [ { "nickname": "Na", "avatar": "fox", "stars": 540, "glyphs": 18, "pages": 16, "items": 7, "badges": 3 } ]
  }
}
```

`account.kids` đọc từ bản ghi `kid:<uuid>` (nickname, avatar); `stars` = tổng `payload->>'stars'` của bản ghi `lesson:<uuid>:*` (đúng công thức `ProgressRepository.totalStars()` của app: tổng sao các bài học xong); `glyphs`, `pages`, `items`, `badges` = số bản ghi `glyph:/page:/item:/badge:` không tombstone của bé. Tối đa 4 bé (giới hạn app). Đếm bằng một câu SQL nhóm theo `split_part(key, ':', 2)`, có chỉ mục sẵn theo `family_id`.

### 6.3 `POST /api/v1/sync/link` (cần access token)

Body: `{ "mode": "upload" | "replace_local" | "fresh" }`.

Trong **một transaction**, khóa dòng `families` của F (`SELECT … FOR UPDATE`) để hai máy không chen nhau:

| mode | Điều kiện | Kết quả |
|---|---|---|
| `upload` (máy có dữ liệu khách, muốn mang lên) | tài khoản **không** có dữ liệu (định nghĩa §5, gồm cả "đã có máy upload") | ghi `family_devices`, 200 |
| `upload` | tài khoản có dữ liệu | **409 `account_not_empty`** + `account` như §6.2 (để app hiện cảnh báo với số mới nhất) |
| `replace_local` (máy sẽ xóa dữ liệu khách rồi kéo về) | luôn được | ghi `family_devices`, 200 |
| `fresh` (máy không có dữ liệu) | luôn được | ghi `family_devices`, 200 |

Đã liên kết rồi mà gọi lại: trả 200, không đổi `mode` (idempotent). `GET /api/v1/sync/link` trả `{ linked, account }` để app hỏi lại sau khi mất mạng giữa chừng.

### 6.4 Chặn ở `/api/v1/sync`

- Máy **chưa liên kết** (không có dòng `(fam, dev)`, hoặc token thiếu `dev`): nếu `changes` không rỗng → **409 `link_required`**; nếu rỗng → cho kéo bình thường (máy `replace_local`/`fresh` cần kéo; kéo không làm hỏng gì).
- Thêm vào `ApiErrors`; mã lỗi ổn định để app nhận biết.
- Log: chỉ `familyId` rút gọn + mã lỗi, không tên bé/token (giữ quy tắc 2D-7).

### 6.5 Test máy chủ (bắt buộc)

- Đăng nhập thiếu/sai `deviceId` → 400. Token có `dev`; refresh giữ `dev`.
- Đẩy thay đổi khi chưa liên kết → 409 `link_required`; kéo khi chưa liên kết → 200.
- `upload` vào tài khoản trống → 200 rồi đẩy được; `upload` vào tài khoản có bản ghi → 409 kèm tóm tắt; chỉ có tombstone → coi là trống.
- **Hai máy cùng `upload` vào tài khoản trống** (song song, hai thread): đúng một 200, một 409.
- `replace_local`, `fresh` luôn 200; gọi lại idempotent.
- Đăng xuất rồi đăng nhập lại cùng `deviceId` → `device.linked = true`.
- Xóa tài khoản → liên kết mất.
- Phản hồi đăng nhập: `account.kids` đúng tên/ảnh/số đếm, bé đã xóa (tombstone) không hiện.
- **Sao khớp app**: cùng một bộ bản ghi `lesson:` (lấy từ fixture dùng chung với test app, ví dụ `test/fixtures/summary_records.json` được test máy chủ đọc), số sao máy chủ tính = số app tính.
- Bản ghi `page:` được nhận; payload > 16 KB bị từ chối như các loại khác.

## 7. App

### 7.1 Trạng thái phiên

`StoredSession` thêm `linked` (bool). Thêm `LinkState` cho giao diện:

```
signedOut
  └─ signIn ─▶ needsDecision(account, local)   (chưa liên kết + cần quyết)
               ├─ tự quyết (không hỏi) ─▶ linking ─▶ linked
               └─ ba mẹ xác nhận / hủy
linked ─▶ (đồng bộ như hiện nay)
```

Quy tắc khi đăng nhập xong mà `device.linked == false` (app tự quyết, không hỏi nếu có thể):

| Máy | Tài khoản | Hành động |
|---|---|---|
| không có bé | bất kỳ | `fresh` → kéo về |
| có bé (khách hoặc gia đình khác) | `hasData == false` | `upload` → đẩy tất cả lên |
| có bé (khách hoặc gia đình khác) | `hasData == true` | **hộp cảnh báo** (§7.4) |

Máy có bé thuộc chính gia đình này (`dataOwnerFamilyId == familyId`) nhưng máy chủ báo chưa liên kết: vẫn theo hai dòng dưới (an toàn hơn tự xóa).

Nếu `device.linked == true` (máy này đã từng liên kết với gia đình này): đồng bộ ngay như hiện nay, không hỏi.

`SyncController` chỉ chạy khi `linked == true`. Gặp 409 `link_required` (ví dụ tài khoản bị xóa liên kết ở máy chủ) → đặt `linked = false`, đi lại bảng trên.

**Thay dữ liệu trên máy** (`replace_local`): gọi link trước (để nếu mạng hỏng thì chưa mất gì), rồi trong một transaction drift xóa mọi dữ liệu của bé (mọi bảng trừ các khóa `app_settings` cấp máy: `deviceId`, `consentAt`, cài đặt giọng đọc chung nếu có — người code liệt kê rõ), xóa `synced_records` và `sync.%`, rồi kéo về toàn bộ. Kéo lỗi giữa chừng → máy trống nhưng đã liên kết: màn "Đang tải dữ liệu của bé…" hiện nút "Thử lại"; không bao giờ quay lại tạo hồ sơ khi đang chờ kéo về.

Thêm `KidRepository.wipeKidData()` (khác `deleteAllData()` hiện có ở chỗ giữ khóa cấp máy). `deleteAllData()` ở Góc ba mẹ cũng phải giữ `deviceId` và xóa `dataOwnerFamilyId`.

### 7.2 Luồng lần đầu (thay `first_run_screen.dart`)

```
Cổng ba mẹ ─▶ Đồng ý ─▶ [Chọn cách dùng] ─┬─ Đăng nhập Google/Apple ─▶ (hộp đồng ý online) ─▶ đăng nhập
                                          │        ├─ tài khoản có bé ─▶ "Đang tải dữ liệu của bé…" ─▶ Trang chủ (bỏ qua hồ sơ + xếp cấp)
                                          │        └─ tài khoản trống ─▶ Tạo hồ sơ bé ─▶ Xếp cấp
                                          └─ Dùng thử không cần tài khoản ─▶ Tạo hồ sơ bé ─▶ Xếp cấp (như hiện nay)
```

- Bước "Chọn cách dùng" chỉ có khi `OnlineConfig.enabled`.
- Lần đầu máy chưa có dữ liệu nên luôn là `fresh`, không bao giờ có cảnh báo ở luồng này.
- Đăng nhập lỗi (mạng, cài đặt, hủy): ở lại màn chọn, thông báo như `family_account_card.dart` hiện có, nút khách vẫn dùng được. Không bao giờ kẹt.
- Tài khoản có bé: sau khi kéo về, chọn bé đầu tiên (code đồng bộ đã đặt `currentKidId`); nếu bé đó đã có cấp (`level:` bản ghi) thì `isPlacedProvider` đúng và chuyển hướng ở `app.dart` tự bỏ qua xếp cấp. Bé chưa xếp cấp thì vào xếp cấp như thường.
- Khi đang kéo về, chuyển hướng ở `app.dart` **không** được đẩy sang `/setup` vì "chưa có bé": cần cờ "đang khôi phục" (ví dụ provider `restoringProvider`) mà `_redirect` tôn trọng.
- Hộp đồng ý của bước Đồng ý sửa chữ: không còn câu "không gửi dữ liệu của bé ra ngoài" tuyệt đối; nói rõ: dùng khách thì chỉ trên máy; đăng nhập thì lưu lên máy chủ FunEdu những gì liệt kê trong `_ConsentDialog` hiện có. Hộp đồng ý online (`_ConsentDialog`) vẫn hiện trước khi gọi Google/Apple — có thể gộp vào bước Đồng ý nếu chữ đã đủ, **người code quyết**, miễn là đồng ý xảy ra trước request đầu tiên.

Phác màn "Chọn cách dùng" (thẻ `MessageCard`, như các bước hiện có):

```
        [ảnh Chíp]
   Lưu tiến độ của bé
 Đăng nhập để giữ tiến độ khi đổi máy
 và dùng trên nhiều máy.

 [  G  Đăng nhập với Google        ]   ← PrimaryButton, ≥ 64
 [    Đăng nhập với Apple          ]   ← chỉ iOS/khi có (appleAvailable)

   Dùng thử không cần tài khoản        ← TextButton ≥ 48
   Dữ liệu chỉ lưu trên máy này,
   xóa app là mất.                     ← chữ phụ textMuted
```

### 7.3 Góc ba mẹ

- `FamilyAccountCard` khi chưa đăng nhập: thêm dòng cảnh báo nhẹ "Đang dùng thử: dữ liệu chỉ ở trên máy này" (màu chữ phụ, có biểu tượng). Đăng nhập từ đây đi qua cùng bảng quyết định §7.1, nên có thể gặp hộp cảnh báo.
- Khi đã đăng nhập: giữ như hiện tại. Đăng xuất: giữ dữ liệu trên máy (như hiện nay) và giữ `dataOwnerFamilyId`, chữ đổi thành "Đã đăng xuất. Dữ liệu vẫn ở trên máy này". Đăng nhập lại cùng tài khoản → máy chủ báo đã liên kết → không hỏi.
- Không thêm dải nhắc ở màn của bé (màn bé không có chữ cho ba mẹ).

### 7.4 Hộp cảnh báo thay dữ liệu

Hiện khi máy có bé và tài khoản có dữ liệu. Là màn/hộp toàn màn (dialog không đóng bằng chạm ngoài, không vuốt bỏ).

```
  Tài khoản này đã có dữ liệu

  Trên máy này (dùng thử)        Tài khoản Google ...@gmail
  ┌──────────────────────┐       ┌──────────────────────┐
  │ 🦊 Na · 120⭐ · 8 chữ  │       │ 🦊 Na · 540⭐ · 18 chữ │
  │   5 trang vở · 2 sticker│      │   16 trang vở · 7 sticker│
  │                        │       │ 🐼 Bin · 30⭐ · 2 chữ  │
  └──────────────────────┘       └──────────────────────┘

  Nếu tiếp tục, dữ liệu trên máy này (tiến độ, sao, sticker,
  vở của bé) sẽ bị XÓA và thay bằng dữ liệu của tài khoản.
  Không hoàn tác được.

  [ Hủy, tiếp tục dùng thử ]           ← nút thường, mặc định
  [ Xóa dữ liệu trên máy và dùng tài khoản ]   ← nút màu nguy hiểm
```

- Điện thoại: hai khối xếp dọc; tablet: cạnh nhau.
- Nút xóa cần **bấm giữ 2 giây** hoặc hộp xác nhận thứ hai ("Xóa dữ liệu của bé Na trên máy này?") — **người code chọn một**, có test.
- Hủy → gọi đăng xuất (thu hồi refresh token, xóa phiên trên máy), dữ liệu khách nguyên vẹn, `dataOwnerFamilyId` không đổi.
- Số liệu bên máy tính tại chỗ từ drift, cùng thước đo như máy chủ: sao (tổng sao bài học), số chữ đã học, số trang vở, số món đồ (sticker/đồ trò chơi), số huy hiệu. Tính bằng **một hàm Dart** từ các bản ghi `SyncStore.export()` theo đúng quy tắc §6.2, để hai bên chắc chắn cùng thước đo.
- Câu cảnh báo ghi rõ vở: "Vở của bé trên máy này sẽ bị thay bằng vở trong tài khoản".
- Nếu `upload` bị 409 khi app tưởng tài khoản trống (máy khác vừa mang lên) → hiện hộp này với số liệu trong phản hồi 409.
- Có `Semantics` cho trình đọc màn hình; chữ ≥ 4.5:1.

### 7.5 Test app (bắt buộc)

Dùng máy chủ giả trong `test/online/` (mở rộng `online_fakes.dart`):
- Lần đầu, chọn khách → 0 request, tạo hồ sơ, xếp cấp (như test hiện có).
- Lần đầu, đăng nhập, tài khoản có 2 bé đã xếp cấp → không qua `/setup` hay `/placement`, trang chủ hiện bé thứ nhất, `fresh` được gọi.
- Lần đầu, đăng nhập, tài khoản trống → tạo hồ sơ → xếp cấp; dữ liệu được đẩy sau khi liên kết.
- Lần đầu, đăng nhập lỗi mạng → ở lại màn chọn, nút khách chạy.
- Khách có dữ liệu + tài khoản trống → `upload` tự động, không hộp cảnh báo.
- Khách có dữ liệu + tài khoản có dữ liệu → hộp cảnh báo; Hủy → đăng xuất, dữ liệu khách còn nguyên; Xác nhận → `replace_local`, dữ liệu khách mất, dữ liệu tài khoản có, `deviceId` và `consentAt` còn.
- `upload` nhận 409 → hộp cảnh báo với số liệu từ 409.
- Đăng xuất, đăng nhập lại cùng tài khoản (máy chủ trả `linked: true`) → không hộp, đồng bộ chạy.
- `SyncController` không đẩy khi chưa liên kết; 409 `link_required` → trở về bước quyết định.
- Build không có `FUNEDU_API_URL` → không có bước "Chọn cách dùng".
- Kéo về lỗi khi khôi phục → màn chờ có "Thử lại", không nhảy sang `/setup`.

### 7.6 Đồng bộ trang vở (cách A)

- **Bảng drift mới `notebook_pages`** (schema **v9**, migration + test v8→v9 và v1→v9): `kid_id` (FK, xóa theo bé), `glyph_id`, `strokes` (JSON), `mistakes` int, `written_at`; khóa chính `(kid_id, glyph_id)`. Đây là nguồn của "Vở của bé" từ nay.
- **Ghi**: mỗi khi bé viết xong một chữ, tính trang đẹp nhất của chữ đó bằng `bestWritings` hiện có và **upsert** nếu tốt hơn trang đang lưu (ít nét sai hơn; bằng nhau thì mới hơn). Migration v9 điền sẵn từ `stroke_attempts` hiện có.
- **Đọc**: `notebookProvider` đọc `notebook_pages` thay vì dựng lại từ `stroke_attempts` mỗi lần (nhanh hơn).
- **Rút gọn nét** trước khi lưu: tối đa 40 điểm mỗi nét (giữ điểm đầu, cuối, chia đều theo độ dài), tọa độ làm tròn 3 chữ số thập phân. Có test: trang 6 nét × 40 điểm < 4 KB JSON; vẽ lại trông giống bản gốc (sai lệch ≤ 0.01).
- **Đồng bộ**: khóa `page:<kidUuid>:<glyphId>`, payload `{ "s": [[x0,y0,x1,y1,…], …], "m": mistakes, "at": ms }`. Gộp hai bên: ít nét sai hơn thắng, bằng nhau thì `at` mới hơn thắng. Máy chủ thêm `page` vào `SyncKinds.ALLOWED` (sửa chú thích "Stroke coordinates are not among them" thành "only the best notebook page per glyph").
- In vở (PDF) dùng cùng `notebook_pages`, không đổi giao diện.
- Test app: hai máy (máy chủ giả) — máy A viết chữ "a" đẹp → máy B kéo về có trang "a"; máy B viết "a" đẹp hơn → máy A nhận trang mới; trang kém hơn không ghi đè; xóa bé xóa trang; `stroke_attempts` **không** bao giờ nằm trong bản đẩy lên.

## 8. Tài liệu cần sửa khi làm

- `AGENTS.md` dòng mạng: "chỉ gọi máy chủ FunEdu (và Google/Apple lúc đăng nhập), chỉ sau khi ba mẹ qua cổng ba mẹ, đồng ý và đăng nhập (ở màn đầu hoặc Góc ba mẹ). Chế độ khách không gọi mạng."
- `docs/PROJECT_STATE.md` mục 6–8; `docs/online-setup.md` (API link, `deviceId`, mã lỗi 409).
- Chính sách quyền riêng tư (`privacy_screen.dart`): thêm "mã ngẫu nhiên của máy, chỉ để biết máy nào đã liên kết với tài khoản" và "trang vở đẹp nhất của mỗi chữ (nét chữ bé viết), để giữ Vở của bé khi đổi máy; các lần tập khác chỉ ở trên máy".
- Hộp đồng ý online (`_ConsentDialog`): bỏ "Không lưu nét vẽ của bé", thay bằng "Lưu trang vở đẹp nhất của mỗi chữ; các lần tập khác chỉ ở trên máy".
- `AGENTS.md`: "nét vẽ (`stroke_attempts`) không rời máy" → "`stroke_attempts` không rời máy; chỉ trang vở đẹp nhất mỗi chữ (`notebook_pages`, đã rút gọn) được đồng bộ". Spec 2D §dữ liệu cập nhật tương ứng.

## 9. Để người code tự quyết (ghi lại trong plan/PR)

- Cách xử lý token cũ không có `device_id` ở V5 (xóa hay cho NULL).
- Bấm giữ hay xác nhận hai lần cho nút xóa (§7.4).
- Gộp hay tách hai hộp đồng ý ở luồng đầu (§7.2), miễn đồng ý trước request đầu.
- Tên provider/lớp cụ thể, chia file (giữ màn < ~400 dòng như phần còn lại của app).

## 10. Quyết định của tôi (AI viết spec), chủ dự án kiểm khi đọc

- Đăng xuất **giữ** dữ liệu trên máy (như hiện nay); nhờ `deviceId` đăng nhập lại cùng tài khoản không bị hỏi.
- Máy từng thuộc gia đình này nhưng chưa liên kết trên máy chủ (hiếm: ví dụ tài khoản bị xóa rồi tạo lại) vẫn hiện cảnh báo, không tự xóa.
- Thước đo trong hộp cảnh báo: sao, số chữ, số trang vở, số món đồ, số huy hiệu (chủ dự án muốn có sao; máy chủ tính sao đúng công thức app, có test đối chiếu).
- Tài khoản chỉ có tombstone (đã xóa hết bé) coi như trống.
- Máy liên kết `fresh` chưa đẩy gì không tính là "tài khoản có dữ liệu": nếu cùng lúc một máy khách `upload` thì hai bộ dữ liệu mới cùng vào tài khoản trống. Chấp nhận (không có dữ liệu cũ nào bị đè).
- `deviceId` lưu trong drift `app_settings`, không trong secure storage (không phải bí mật).
