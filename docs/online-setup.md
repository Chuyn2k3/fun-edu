# Chạy và cấu hình phần online (2D)

Phần online gồm máy chủ `server/` (Spring Boot + PostgreSQL) và code app `lib/online/`. **App build không có `FUNEDU_API_URL` thì không có tính năng online và không gọi mạng** — mọi test Flutter chạy như vậy.

## 1. Chạy máy chủ + DB trên máy dev

Cần Java 21 và Docker (hoặc PostgreSQL 16 cài sẵn).

```bash
# DB bằng Docker
docker run -d --name funedu-db -p 5432:5432 \
  -e POSTGRES_DB=funedu -e POSTGRES_USER=funedu -e POSTGRES_PASSWORD=funedu \
  postgres:16-alpine
```

```bash
cd server
./gradlew test        # Testcontainers tự bật PostgreSQL riêng cho test (cần Docker)
```

```bash
cd server
DB_URL=jdbc:postgresql://localhost:5432/funedu DB_USER=funedu DB_PASSWORD=funedu \
AUTH_JWT_SECRET=$(openssl rand -base64 48) \
GOOGLE_CLIENT_IDS=<web client id>,<android client id>,<ios client id> \
APPLE_CLIENT_IDS=com.ibme.funedu,<apple services id> \
./gradlew bootRun
```

Kiểm tra: `curl localhost:8080/actuator/health` → `{"status":"UP",...}`. Flyway tự tạo bảng (`server/src/main/resources/db/migration`).

Không có Docker: tạo DB `funedu_test` (user/pass `funedu`) rồi `TEST_DB_URL=jdbc:postgresql://localhost:5432/funedu_test ./gradlew test`.

## 2. Chạy app trỏ vào máy chủ

```bash
flutter run \
  --dart-define=FUNEDU_API_URL=http://10.0.2.2:8080 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id> \
  --dart-define=APPLE_SERVICE_ID=<apple services id>
```

- Máy ảo Android gọi máy dev qua `10.0.2.2`; máy thật dùng IP LAN của máy dev hoặc tên miền HTTPS.
- Android 9+ chặn HTTP thường kể cả bản debug; repo đã mở `usesCleartextTraffic` **chỉ** ở `android/app/src/debug` và `profile`, nên thử `http://` bằng bản debug/profile. Bản release phải là `https://`.
- Máy chủ phải nghe được từ máy ảo/điện thoại (mặc định Spring nghe mọi địa chỉ; kiểm tường lửa cổng 8080). Thử: mở `http://10.0.2.2:8080/actuator/health` bằng Chrome trong máy ảo.
- Vào Góc ba mẹ → Cài đặt → "Lưu tiến độ online".

## 3. Google Sign-In

Google Cloud Console → APIs & Services → Credentials, tạo 3 OAuth client:

| Loại | Dùng cho | Ghi chú |
|---|---|---|
| Web application | `GOOGLE_SERVER_CLIENT_ID` của app + `GOOGLE_CLIENT_IDS` của máy chủ | Google ghi client này vào `aud` của id token |
| Android | gói `com.ibme.funedu` + SHA-1 khóa ký (debug và release/Play App Signing) | không cần đưa vào code |
| iOS | bundle `com.ibme.funedu` | cần sửa `ios/Runner/Info.plist` (dưới) |

`ios/Runner/Info.plist` (thay giá trị thật, **chưa thêm vào repo** vì cần client id của bạn):

```xml
<key>GIDClientID</key>
<string>IOS_CLIENT_ID.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>com.googleusercontent.apps.IOS_CLIENT_ID</string></array>
  </dict>
</array>
```

### Đăng nhập Google không được — kiểm lần lượt

Chạy bản **debug**: thông báo lỗi có thêm dòng `(...)` cho biết lý do.

| Dòng `(...)` | Nguyên nhân | Sửa |
|---|---|---|
| `GOOGLE_SERVER_CLIENT_ID chưa được truyền khi build` | thiếu `--dart-define` | thêm `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>` (client **Web**, không phải Android) |
| `sign_in_failed: ...ApiException: 10` | Google không nhận app: thiếu client **Android** đúng gói + SHA-1 | tạo client Android `com.ibme.funedu` + SHA-1 debug (lệnh dưới), đợi vài phút |
| `ApiException: 7` / `network_error` | máy ảo không ra mạng | kiểm mạng máy ảo |
| `ApiException: 12500` | máy thiếu Google Play services / màn đồng ý OAuth chưa xong | dùng image máy ảo **Google Play**, đăng nhập tài khoản Google trong máy; điền OAuth consent screen, thêm email vào **Test users** khi app ở chế độ Testing |
| `không tới được http://...` | app không gọi được máy chủ | sai `FUNEDU_API_URL` (máy ảo `10.0.2.2`, máy thật IP LAN), máy chủ chưa chạy, tường lửa |
| `máy chủ trả 401 ...` | máy chủ từ chối id token | `GOOGLE_CLIENT_IDS` của máy chủ phải chứa đúng **web client id** ở trên; log máy chủ ghi `Rejected google id token: <lý do>` (`bad aud`, `expired`...) |

SHA-1 của khóa debug:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

## 4. Sign in with Apple

1. Apple Developer → Identifiers → `com.ibme.funedu` → bật **Sign in with Apple**.
2. Xcode → Runner → Signing & Capabilities → **+ Sign in with Apple** (tạo `Runner.entitlements`). Chưa thêm sẵn vào repo vì phải bật capability ở trên trước, nếu không bản ký sẽ lỗi.
3. Android dùng trang web của Apple: tạo **Services ID** (ví dụ `com.ibme.funedu.signin`), bật Sign in with Apple, khai báo Return URL `https://<API_DOMAIN>/api/v1/auth/apple/callback`. Đưa Services ID vào `APPLE_SERVICE_ID` (app) và `APPLE_CLIENT_IDS` (máy chủ).
4. Tạo Key "Sign in with Apple" (file `.p8`) và điền `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` (dán nội dung file `.p8`) vào `server/deploy/.env`. Máy chủ dùng nó để đổi mã đăng nhập lấy token Apple (lưu mã hóa) và **thu hồi token khi ba mẹ xóa tài khoản** (Apple bắt buộc). Không có key thì máy chủ bỏ qua bước này. Không commit file này.

## 5. Triển khai lên máy Oracle

- Bật proxy **Cloudflare** (Full strict) trước tên miền API để ẩn IP gốc và lọc L7/DDoS.
- Security List / tường lửa Oracle chỉ mở cổng **443** (và SSH từ IP quản trị); PostgreSQL và cổng `8080` chỉ nghe nội bộ Docker network.
- Lưu trữ dữ liệu PostgreSQL và bản sao lưu trên **Oracle Block Volume đã mã hóa** (encrypted at rest).
- Sao lưu: `server/deploy/backup.sh` chạy hằng đêm bằng cron (mã hóa AES-256 bằng `BACKUP_PASSPHRASE`, giữ 14 ngày, có thể chép ra ngoài bằng rclone qua `BACKUP_REMOTE`); thử khôi phục mỗi tháng bằng `restore.sh` (vào DB nháp `funedu_restore`). Chi tiết: `server/README.md` mục Backups.


Xem `server/README.md` mục Deploy: `cd server/deploy && cp .env.example .env` (điền đủ), `docker compose up -d --build`. Caddy tự cấp HTTPS cho `API_DOMAIN`.

## 6. Thiết kế đồng bộ (tóm tắt)

- Máy chủ lưu bản ghi `(family_id, key, payload JSON, version, deleted)` trong `sync_records`; khóa dạng `kid:<uuid>`, `glyph:<kid>:<chữ>`, `lesson:<kid>:<ms>`, `level:<kid>:<môn>`, `usage:<kid>:<ngày>`, `reward:<kid>:<ms>`, `setting:<kid>:<tên>`, `race:<kid>:<ms>`, `game:<kid>`, `item:<kid>:<món>`, `badge:<kid>:<huy hiệu>`, `counter:<kid>:<khóa>`.
- App (`lib/online/sync/sync_store.dart`) xuất DB thành bản ghi, so với `synced_records` (bản lần trước) để biết thay đổi; gộp bản kéo về: bài học/trận đua/món đồ hợp lại; bộ đếm, giây dùng, sao vũ trụ lấy lớn hơn; huy hiệu giữ ngày sớm nhất; còn lại giữ bản sửa trên máy; xóa từ máy chủ luôn thắng.
- Gửi kèm `baseVersion`; lệch thì máy chủ báo xung đột và trả bản đang có → app gộp rồi gửi lại.
- Không đồng bộ: `stroke_attempts` (nét vẽ), giọng đọc, bé đang chọn, thời điểm đồng ý.
- Đồng bộ khi: đăng nhập, mở lại app, mỗi 5 phút khi đang mở, bấm "Lưu online ngay".

## 7. Phòng đua qua mạng (2B-2)

- Ba mẹ đã đăng nhập → Góc Chơi → **"Mời bạn đua"** (qua cổng ba mẹ) → "Tạo phòng" → đưa mã 6 ký tự cho ba mẹ bạn. Bên kia: **"Nhập mã"** → gõ mã → phòng chờ.
- Phòng chờ: mã to + "Chép mã", danh sách 2–4 bạn, bé chọn môn của mình (Toán / Tiếng Việt), 6 sticker Chíp; chủ phòng bấm **"Bắt đầu!"** → đếm 3-2-1 → trận đua (màn đua cũ, tên lửa + ảnh của bạn thay Chíp; có 3–4 bạn thì làn thứ hai là bạn đang dẫn đầu).
- Về đích: màn xếp hạng cập nhật trực tiếp; chủ phòng **"Đua lại!"** đưa cả phòng về phòng chờ.
- Trận qua mạng **không cộng sao vũ trụ, không tính huy hiệu và không đổi nhịp Chíp** (chỉ trận với Chíp mới tính).
- Thử local: chạy máy chủ (mục 1), 2 máy ảo/điện thoại cùng trỏ `FUNEDU_API_URL`, đăng nhập 2 tài khoản khác nhau. Giao thức chi tiết: `server/README.md` mục "Race rooms".
- Máy chủ giữ phòng trong bộ nhớ: khởi động lại máy chủ thì các phòng đang mở mất (bé vào phòng mới).

## 8. Liên kết máy và cổng đồng bộ (V5)

- Đăng nhập (`POST /api/v1/auth/google`, `POST /api/v1/auth/apple`) yêu cầu trường `deviceId` (UUID). JWT access token chứa claim `dev` = deviceId.
- Phản hồi đăng nhập trả thêm `device: { linked: boolean }` và `account: { hasData: boolean, kids: [...] }`.
- API liên kết máy:
  - `POST /api/v1/sync/link` body `{ "mode": "upload" | "replace_local" | "fresh" }`: liên kết máy với gia đình.
    - `upload`: chỉ cho phép nếu tài khoản chưa có dữ liệu (hoặc chỉ toàn tombstone) và chưa có máy nào liên kết `upload`. Nếu tài khoản có dữ liệu, trả **409 `account_not_empty`** kèm thông tin `account`.
    - `replace_local`, `fresh`: luôn thành công, idempotent.
  - `GET /api/v1/sync/link`: trả `{ "linked": boolean, "account": { "hasData": ..., "kids": [...] } }`.
- Cổng đồng bộ `POST /api/v1/sync`:
  - Nếu `changes` không rỗng: yêu cầu máy đã liên kết (`(family_id, device_id)` tồn tại trong `family_devices`). Nếu chưa liên kết hoặc thiếu claim `dev`, trả **409 `link_required`**.
  - Nếu `changes` rỗng (kéo dữ liệu): cho phép máy chưa liên kết để phục vụ kéo dữ liệu khôi phục.
