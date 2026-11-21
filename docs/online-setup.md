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
- Android chặn HTTP thường ở bản release; khi thử bằng `http://` dùng bản debug/profile, bản phát hành phải là `https://`.
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

## 4. Sign in with Apple

1. Apple Developer → Identifiers → `com.ibme.funedu` → bật **Sign in with Apple**.
2. Xcode → Runner → Signing & Capabilities → **+ Sign in with Apple** (tạo `Runner.entitlements`). Chưa thêm sẵn vào repo vì phải bật capability ở trên trước, nếu không bản ký sẽ lỗi.
3. Android dùng trang web của Apple: tạo **Services ID** (ví dụ `com.ibme.funedu.signin`), bật Sign in with Apple, khai báo Return URL `https://<API_DOMAIN>/api/v1/auth/apple/callback`. Đưa Services ID vào `APPLE_SERVICE_ID` (app) và `APPLE_CLIENT_IDS` (máy chủ).
4. Tạo Key "Sign in with Apple" (file `.p8`) — để thu hồi token khi xóa tài khoản (bước 2D-7, chưa làm). Không commit file này.

## 5. Triển khai lên máy Oracle

Xem `server/README.md` mục Deploy: `cd server/deploy && cp .env.example .env` (điền đủ), `docker compose up -d --build`. Caddy tự cấp HTTPS cho `API_DOMAIN`.

## 6. Thiết kế đồng bộ (tóm tắt)

- Máy chủ lưu bản ghi `(family_id, key, payload JSON, version, deleted)` trong `sync_records`; khóa dạng `kid:<uuid>`, `glyph:<kid>:<chữ>`, `lesson:<kid>:<ms>`, `level:<kid>:<môn>`, `usage:<kid>:<ngày>`, `reward:<kid>:<ms>`, `setting:<kid>:<tên>`, `race:<kid>:<ms>`, `game:<kid>`, `item:<kid>:<món>`, `badge:<kid>:<huy hiệu>`, `counter:<kid>:<khóa>`.
- App (`lib/online/sync/sync_store.dart`) xuất DB thành bản ghi, so với `synced_records` (bản lần trước) để biết thay đổi; gộp bản kéo về: bài học/trận đua/món đồ hợp lại; bộ đếm, giây dùng, sao vũ trụ lấy lớn hơn; huy hiệu giữ ngày sớm nhất; còn lại giữ bản sửa trên máy; xóa từ máy chủ luôn thắng.
- Gửi kèm `baseVersion`; lệch thì máy chủ báo xung đột và trả bản đang có → app gộp rồi gửi lại.
- Không đồng bộ: `stroke_attempts` (nét vẽ), giọng đọc, bé đang chọn, thời điểm đồng ý.
- Đồng bộ khi: đăng nhập, mở lại app, mỗi 5 phút khi đang mở, bấm "Lưu online ngay".
