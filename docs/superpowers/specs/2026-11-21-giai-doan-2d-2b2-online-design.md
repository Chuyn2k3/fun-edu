# Giai đoạn 2D + 2B-2 — Tài khoản gia đình, lưu dữ liệu online, phòng đua tên lửa qua mạng

> Trạng thái: **chủ dự án đã duyệt** (2026-11-21), gồm đổi quy tắc "không gọi mạng" ở §2.
> Đã chốt với chủ dự án: (1) làm **2D trước**, rồi **2B-2**; (2) ba mẹ đăng nhập bằng **Google hoặc Apple**, **mỗi gia đình đúng một tài khoản** (không mời bố/mẹ thứ hai) — chủ dự án chốt 2026-11-21; (3) phòng đua **trực tiếp (WebSocket) + đua với bóng**; (4) máy chủ Java Spring Boot đặt trong **thư mục `server/` của repo này** (nhánh `chipchip`).
> Spec gốc: `2026-11-12-fun-edu-overhaul-design.md` §5.2, §9.2. Spec 2B-1: `2026-11-16-giai-doan-2b1-dua-ten-lua-mot-minh-design.md`.

## 1. Mục tiêu

- Ba mẹ đăng nhập một lần → tiến độ của các bé **lưu trên máy chủ**, dùng được trên **nhiều máy** (điện thoại + iPad), không mất khi đổi máy.
- Bé **mời bạn đua tên lửa** bằng mã phòng do ba mẹ tạo; nếu bạn không online thì **đua với bóng** của bạn.
- Giữ nguyên lời hứa sản phẩm: không quảng cáo, không SDK theo dõi, dữ liệu bé tối thiểu, **app vẫn chạy đầy đủ khi không có mạng hoặc không đăng nhập**.

## 2. Thay đổi quy tắc dự án (cần chủ dự án đồng ý)

`AGENTS.md` hiện ghi "không gọi mạng". Đề xuất đổi thành:
- App **chỉ gọi máy chủ riêng của FunEdu** (và máy chủ đăng nhập Google/Apple lúc ba mẹ đăng nhập), **chỉ sau khi ba mẹ đăng nhập** trong Góc ba mẹ. Chưa đăng nhập thì không có lời gọi mạng nào.
- Không SDK phân tích/quảng cáo; gói mới chỉ: `google_sign_in`, `sign_in_with_apple`, `http`, `web_socket_channel`, `flutter_secure_storage` (phiên bản tương thích Flutter 3.24.5, ghim cứng).
- Dữ liệu trò chơi vẫn tách khỏi dữ liệu học (bảng riêng, luồng đồng bộ riêng).

## 3. Kiến trúc

```
App Flutter (offline-first, drift)          Máy chủ Oracle (Docker Compose)
  ├─ lib/online/auth/   đăng nhập ─HTTPS──▶  Caddy (HTTPS tự động)
  ├─ lib/online/sync/   đồng bộ  ─HTTPS──▶    └▶ Spring Boot (server/, Java 21)
  └─ lib/online/room/   phòng đua ─WSS───▶         ├─ REST: /auth, /sync, /rooms, /ghosts
                                                    ├─ WebSocket: /ws/room
                                                    └▶ PostgreSQL 16 (Flyway)
                                              Sao lưu pg_dump hằng đêm ra nơi khác
```

- `server/`: Spring Boot 3, Java 21, Gradle, Spring Web + Spring WebSocket + Spring Security (resource server JWT), Spring Data JDBC, Flyway, Testcontainers cho test. Không ORM nặng; SQL rõ ràng.
- Triển khai: `server/deploy/docker-compose.yml` (app + postgres + caddy), biến môi trường cho bí mật (**không commit bí mật**), tên miền API do chủ dự án chọn.
- App: thư mục mới `lib/online/` (Riverpod), không chạm bộ chấm nét / engine trò chơi.

## 4. Tài khoản gia đình (2D)

- **Đăng nhập** (chỉ trong Góc ba mẹ, sau cổng người lớn): "Đăng nhập với Google" / "Đăng nhập với Apple" → app nhận `id_token` → `POST /api/v1/auth/google|apple` → máy chủ kiểm chữ ký bằng JWKS của Google/Apple, kiểm `iss`, hạn dùng, kiểm `aud` = client id của app → tạo/tìm `parent_account` → trả **access token** (JWT 15 phút) + **refresh token** (chuỗi ngẫu nhiên, máy chủ chỉ lưu bản băm, xoay vòng mỗi lần dùng). Lưu trong `flutter_secure_storage`.
- **Một gia đình** = **đúng một tài khoản ba mẹ** (Google hoặc Apple; ràng buộc `UNIQUE (family_id)` trong DB) + tối đa 4 bé. Bố và mẹ muốn dùng chung thì đăng nhập cùng một tài khoản đó.
- **Xóa tài khoản đã đăng nhập Apple:** Apple yêu cầu máy chủ gọi API thu hồi token của Apple; cần Key "Sign in with Apple" của chủ dự án nên làm ở 2D-7 (lúc có khóa thật).
- **Xóa tài khoản** ngay trong app (App Store và Google Play đều bắt buộc): xóa toàn bộ dữ liệu gia đình trên máy chủ; dữ liệu trên máy giữ hoặc xóa theo lựa chọn của ba mẹ.
- **Đăng xuất**: app quay về chế độ chỉ trên máy, dữ liệu trên máy giữ nguyên.

**Dữ liệu máy chủ giữ về ba mẹ:** nhà cung cấp + mã định danh (`sub`) và email (Apple có thể là email ẩn danh `privaterelay`). **Về bé:** tên gọi ở nhà, biệt danh đua, mã ảnh đại diện có sẵn, tuổi, tiến độ. **Không đồng bộ** toạ độ nét vẽ (`stroke_attempts`) — chỉ ở trên máy (dữ liệu tối thiểu).

## 5. Đồng bộ dữ liệu (2D)

**Offline-first:** mọi ghi vẫn vào drift trước; đồng bộ chạy nền khi có mạng (mở app, xong bài, xong trận, mỗi 5 phút khi đang mở, kéo để làm mới ở Góc ba mẹ).

**Thay đổi schema drift v8** (migration + test giữ mọi đường nâng cấp cũ):
- Mỗi bảng được đồng bộ thêm `uuid` (khóa toàn cục, sinh trên máy), `updated_at`, `deleted` (xóa mềm để truyền được việc xóa), `dirty` (chưa đẩy).
- Bảng `sync_state` (con trỏ `server_version` lần kéo cuối).

**Giao thức:** `POST /sync` gửi `{since: version, changes: [...]}` → máy chủ ghi, gán `version` tăng dần toàn cục (bigserial) → trả `{changes kể từ since, version mới}`. Một lời gọi = vừa đẩy vừa kéo, idempotent theo `uuid`.

**Luật gộp theo loại dữ liệu:**

| Loại | Bảng | Luật |
|---|---|---|
| Nhật ký chỉ thêm | `lesson_completions` (sao), `daily_usage`, `race_results` | Hợp theo `uuid` — không bao giờ mất sao |
| Trạng thái | `kid_profiles`, `glyph_progress`, `subject_levels`, cài đặt theo bé (giới hạn giờ, giờ ngủ, Nhà Chíp), `game_profile`, `game_items`, `game_badges`, `game_counters`, `real_rewards` | Bản ghi mới hơn thắng (máy chủ so `updated_at`, hòa thì `version`) |
| Ngoại lệ | `glyph_progress.completions`, sao vũ trụ | Lấy lớn hơn (không để hai máy chơi song song làm mất lượt) |
| Không đồng bộ | `stroke_attempts`, cài đặt riêng máy (`voiceEnabled`) | Chỉ trên máy |

**Máy thứ hai đăng nhập:** nếu máy đã có bé chưa đồng bộ → hỏi ba mẹ "Gộp bé trên máy này vào tài khoản?" (gộp hoặc ghép với bé cùng tên đã có).

## 6. Phòng đua qua mạng (2B-2)

**Tạo và vào phòng**
- Ba mẹ (sau cổng) bấm "Mời bạn đua" → `POST /rooms` → mã **6 ký tự** (bỏ ký tự dễ nhầm 0/O, 1/I), hết hạn 30 phút, 2–4 bé. Ba mẹ gửi mã cho ba mẹ bạn qua Zalo/tin nhắn (app không có chat).
- Bé (hoặc ba mẹ) bấm "Nhập mã" → vào **phòng chờ**: thấy tên lửa + ảnh đại diện + **biệt danh đua** của các bạn; chủ phòng bấm "Bắt đầu".
- **Biệt danh đua** (chủ dự án chốt 2026-11-21): mỗi bé có một biệt danh hiện trong phòng đua, mặc định là tên gọi ở nhà, ba mẹ đổi được ở Góc ba mẹ (tối đa 16 ký tự, chọn từ gợi ý có sẵn hoặc gõ). Ảnh đại diện luôn hiện kèm.

**Trong trận (WebSocket, máy chủ giữ trận)**
- Mỗi bé nhận **câu hỏi theo trình độ của mình** (sinh trên máy như 2B-1, cùng 10 nấc), nên bé 3 tuổi và 6 tuổi đua công bằng.
- App gửi `{step, correct, t}` mỗi câu; máy chủ kiểm nhịp tối thiểu (chống bấm máy), phát vị trí mọi tên lửa ~5 lần/giây; thứ tự về đích do máy chủ quyết.
- Cảnh đua mở rộng từ 2 làn (bé + Chíp) lên **2–4 làn** (`StarPath`); camera vẫn theo bé.
- Giao tiếp chỉ bằng **bộ sticker cảm xúc Chíp có sẵn** (không gõ chữ, không giọng nói).
- Mất mạng: tên lửa đứng yên, kết nối lại trong 20 giây thì đua tiếp; quá hạn thì bé đó dừng, trận tiếp tục với các bạn còn lại; bé mất mạng vẫn nhận sao như thua.
- Xong trận: màn kết quả có thứ hạng + "Đua lại!" (cùng phòng).

**Đua với bóng**
- Mỗi trận (một mình hoặc trong phòng) lưu "bóng" = mốc thời gian từng nấc, gửi lên khi đồng bộ (đã đăng nhập).
- Bé chỉ thấy bóng của **bạn đua** = bé đã từng chung phòng, và ba mẹ đồng ý kết bạn ở Góc ba mẹ.
- Góc Chơi: "Đua với bóng của <bạn>" — đua offline với bóng đã tải về.

**An toàn trẻ em:** không tìm kiếm người lạ, không phòng công khai, chỉ vào bằng mã do người lớn tạo; trong phòng hiện ảnh đại diện + biệt danh đua do ba mẹ đặt; không chữ tự do giữa các bé.

## 7. Bảo mật và vận hành

- HTTPS/WSS bắt buộc; token ngắn hạn; refresh token băm; giới hạn tần suất `/auth`, `/rooms`.
- Mọi truy vấn lọc theo `family_id` lấy từ token (không tin id từ app) — có test chống truy cập chéo gia đình.
- Bí mật (client id Google/Apple, khóa ký JWT, mật khẩu DB) chỉ trong biến môi trường máy chủ / file `.env` không commit.
- Sao lưu: `pg_dump` hằng đêm, mã hóa, gửi ra nơi lưu trữ khác máy Oracle; thử khôi phục mỗi tháng.
- Theo dõi: `/actuator/health`, log có cấu trúc (không ghi tên bé, không ghi token).
- Cập nhật chính sách quyền riêng tư + màn đồng ý + mục "An toàn dữ liệu" trên Google Play / "Nhãn quyền riêng tư" App Store (theo Nghị định 13/2023 về dữ liệu cá nhân: ba mẹ đồng ý trước khi gửi dữ liệu của bé).

## 8. Kiểm thử

- Máy chủ: test đơn vị + test tích hợp với PostgreSQL thật (Testcontainers): xác thực token giả lập JWKS, luật gộp đồng bộ, truy cập chéo gia đình, phòng (vào/ra/mất mạng/hết hạn) qua WebSocket client test.
- App: máy chủ giả trong test (không gọi mạng thật trong `flutter test`); test migration v7→v8; test gộp hai máy offline rồi đồng bộ (không mất sao, không nhân đôi); test cảnh đua 4 làn không chồng nhau 320–1366.

## 9. Ngoài phạm vi

Gói trả phí và xác thực giao dịch (2E), web cho ba mẹ, chat chữ, phòng công khai, xếp hạng toàn quốc, thống kê ẩn danh.

## 10. Chủ dự án cần chuẩn bị (không đưa vào code)

1. Tên miền cho API (ví dụ `api.<tên miền của bạn>`) trỏ về máy Oracle; quyền SSH vào máy Oracle.
2. Google Cloud: OAuth client id cho Android (SHA-1 khóa ký), iOS và web (để máy chủ kiểm `aud`).
3. Apple Developer: bật "Sign in with Apple" cho `com.ibme.funedu`; tạo Services ID (cho đăng nhập Apple trên Android) và một Key "Sign in with Apple" (máy chủ dùng để thu hồi token khi xóa tài khoản).
4. Nơi lưu bản sao lưu ngoài máy Oracle.
