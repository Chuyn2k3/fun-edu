# Kế hoạch tiếp theo (cập nhật 2026-11-21)

> **Hướng chủ dự án chốt:** làm **2D: tài khoản gia đình + lưu dữ liệu online** trước, rồi **2B-2: phòng đua tên lửa qua mạng + đua với bóng**. Đăng nhập **chỉ bằng Google** (bỏ Apple; lưu ý rủi ro duyệt App Store ở spec §4). Máy chủ Java Spring Boot ở thư mục `server/` của repo này.
> Thiết kế: `docs/superpowers/specs/2026-11-21-giai-doan-2d-2b2-online-design.md` (**chờ duyệt**). Khi spec được duyệt, mỗi bước dưới đây có plan chi tiết riêng (TDD, rà soát từng task).

## Đã xong trong đợt rà soát 2026-11-21

- Câu sao chổi đọc lời sao chổi **rồi đọc câu hỏi**; nút loa luôn đọc câu hỏi.
- Bản đồ Toán / Tiếng Việt / Tiếng Anh: ô trung tính khi chưa tải xong cấp.
- Nhà Chíp: không cho ăn/trang trí khi dữ liệu chưa tải.
- iOS dùng `CupertinoPage` cho màn con (giữ vuốt quay lại).
- `app.dart` nạp sẵn cấp bằng `ref.listen`; xóa 25 màu `GameColors` không dùng.

## Bước 0 — Chuẩn bị (song song, phần lớn là việc của chủ dự án)

- Duyệt spec, đồng ý đổi quy tắc "không gọi mạng" trong `AGENTS.md` (spec §2).
- Tên miền API, SSH máy Oracle, Google OAuth client id, nơi lưu bản sao lưu (spec §10).
- AI: kiểm phiên bản các gói Flutter mới tương thích Flutter 3.24.5 / Dart 3.5 rồi ghim.

## 2D — Tài khoản gia đình + đồng bộ (~3–4 tuần)

| Bước | Nội dung | Xong khi |
|---|---|---|
| 2D-1 ✅ | Khung `server/`: Spring Boot 3 + Java 21 + Gradle, PostgreSQL + Flyway, `/actuator/health`, Testcontainers, `docker-compose` (app + db + Caddy), README chạy local | **Xong 2026-11-21:** 5 test đạt (health không lộ chi tiết, chỉ mở `/actuator/health`, bảng `families`/`parent_accounts` với ràng buộc), jar chạy thật + Flyway V1. **Chưa build thử image Docker** (Docker Hub chặn 429 trong môi trường AI) — chạy `docker compose up -d --build` lần đầu trên máy thật |
| 2D-2 | Đăng nhập: kiểm `id_token` Google bằng JWKS, access JWT 15 phút + refresh token băm xoay vòng, đăng xuất, **xóa tài khoản**, giới hạn tần suất | Test với JWKS giả: token sai `aud`/hết hạn bị từ chối |
| 2D-3 | App: `lib/online/` (client HTTP, lưu token an toàn), màn "Tài khoản gia đình" trong Góc ba mẹ (đăng nhập / đăng xuất / xóa), cập nhật màn đồng ý + chính sách quyền riêng tư | Chưa đăng nhập: không lời gọi mạng nào (có test) |
| 2D-4 | drift **v8**: `uuid`, `updated_at`, `deleted`, `dirty` cho bảng đồng bộ; `sync_state`; migration + test mọi đường v1→v8 | Test migration xanh, dữ liệu cũ có uuid |
| 2D-5 | Máy chủ `/sync` (đẩy + kéo một lời gọi, `version` toàn cục, luật gộp spec §5, lọc theo `family_id` từ token) | Test: hai máy offline cùng học rồi đồng bộ không mất/nhân đôi sao; không đọc được dữ liệu gia đình khác |
| 2D-6 | App: bộ đồng bộ nền (mở app, xong bài/trận, 5 phút, kéo làm mới), trạng thái "Đã lưu online lúc …" ở Góc ba mẹ, gộp bé khi máy thứ hai đăng nhập | Thử 2 máy giả lập: điện thoại + iPad thấy cùng tiến độ |
| 2D-7 | Triển khai lên máy Oracle: HTTPS, biến môi trường bí mật, sao lưu `pg_dump` hằng đêm ra ngoài + thử khôi phục, log không chứa tên bé/token | API thật chạy; bản sao lưu khôi phục được |

## 2B-2 — Phòng đua qua mạng + đua với bóng (~3 tuần)

| Bước | Nội dung | Xong khi |
|---|---|---|
| 2B2-1 | Máy chủ phòng: `POST /rooms` (mã 6 ký tự, 30 phút, 2–4 bé), vào phòng, WebSocket `/ws/room` (phòng chờ, bắt đầu, vị trí ~5 lần/giây, về đích, mất mạng 20 giây, chống bấm quá nhanh) | Test WebSocket: 4 client đua hết trận, 1 client rớt mạng rồi vào lại |
| 2B2-2 | Cảnh đua **2–4 làn** (`StarPath` mở rộng), tên lửa bạn có avatar, camera theo bé | Test không chồng làn 320–1366; đo `--profile` máy thật |
| 2B2-3 | App: "Mời bạn đua" (ba mẹ tạo mã, sau cổng), "Nhập mã", phòng chờ, trận qua mạng (câu hỏi theo trình độ từng bé, sinh trên máy), màn kết quả có thứ hạng + "Đua lại!" | Hai máy giả lập đua với nhau qua máy chủ local |
| 2B2-4 | Sticker cảm xúc Chíp (bộ có sẵn, ảnh nền xanh tách bằng `chroma_key.py`), biệt danh đua (mặc định tên gọi ở nhà, ba mẹ đổi ở Góc ba mẹ) | Không có ô nhập chữ nào trong phòng |
| 2B2-5 | Đua với bóng: lưu bóng mỗi trận, đồng bộ lên, danh sách "bạn đua" (đã chung phòng + ba mẹ đồng ý), "Đua với bóng của <bạn>" trong Góc Chơi | Đua bóng chạy offline sau khi đã tải về |

## Việc nhỏ xen kẽ (khi chờ chủ dự án chuẩn bị)

- Trang chủ và Sưu tập không nháy số 0 lúc tải.
- Góc Chơi báo "Quà chờ bé!"; `GameRepository.select()` kiểm loại món, `select`/`markSeen` trong transaction.
- `_letterNames` trong màn đua đọc từ `speech` của glyph.
- Bản đồ Toán bỏ `Opacity` ô khóa.
- Sửa lỗi từ đợt chủ dự án chạy `--profile` máy thật.

## Để sau 2D + 2B-2

Chữ hoa tập viết (2G), Vở của bé, Toán nâng cao (số đến 100, đồng hồ, tiền), tách file lớn, 2E gói trả phí (dùng lại tài khoản + máy chủ của 2D).

## Cần chủ dự án quyết

1. ~~Duyệt spec~~ — đã duyệt 2026-11-21 (gồm đổi quy tắc "không gọi mạng").
2. ~~Tên trong phòng đua~~ — hiện ảnh đại diện + biệt danh đua (mặc định tên gọi ở nhà, ba mẹ đổi được).
3. Có cần mời ba/mẹ thứ hai vào cùng tài khoản gia đình ngay ở 2D không, hay để sau?
