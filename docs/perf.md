# Hiệu năng (perf)

## Cách đo
- Luôn đo bằng bản profile trên máy thật: `flutter run --profile`.
- Mở DevTools, tab Performance. Bật "Track widget rebuilds" để thấy widget nào dựng lại.
- Bản debug giật hơn nhiều (JIT, assert, không tối ưu shader) nên không dùng để kết luận.
- Mục tiêu: không khung hình nào quá 16 ms khi cuộn trang chủ và khi bé đang viết, trên Android tầm trung và trên iPad.

## Điểm nóng đã xử lý
- Bảng viết (`TracePad`): lớp gợi ý nét đứt tách riêng, có `RepaintBoundary`, chỉ vẽ lại khi đổi nét gợi ý hoặc kích thước. Lớp mực dùng `ChangeNotifier`, thêm điểm tại chỗ, không `setState` mỗi lần chạm di chuyển.
- Nền chấm (`DottedBackground`): lớp chấm nằm trong `RepaintBoundary`, `isComplex: true`, `willChange: false`.
- Ảnh: `precacheAppImages` nạp sẵn mọi ảnh trong `AppImages.all`.

## §screenshots
Render a screen to a PNG with a purpose-built widget test. The harness is `tools/shot/home_shot_test.dart` (it is not under `test/`, so `flutter test` never runs it). It draws `HomeScreen` with fake providers; edit the overrides and `home:` to shoot another screen.

```
export PATH=$HOME/flutter324/bin:$PATH
mkdir -p test/_shot && cp tools/shot/home_shot_test.dart test/_shot/
W=1024 H=1366 SHOT_OUT=/tmp/home-ipad.png FLUTTER_ROOT=$HOME/flutter324 \
  flutter test test/_shot/home_shot_test.dart
rm -rf test/_shot
```

- `W`, `H` are logical points (default 390x844; iPad portrait 1024x1366, landscape 1366x1024); `SHOT_OUT` is the PNG path.
- `TEXT_SCALE`: tỷ lệ cỡ chữ hệ thống cho `home_shot_test.dart` (mặc định 1.0; ví dụ `TEXT_SCALE=1.3`, `1.6`, `2.0` để kiểm thử khả năng đáp ứng cỡ chữ lớn).
- `flutter_tester` draws shadows without blur, so they look harsher than on a device.
- Always delete `test/_shot/` before committing.
- Rocket race scene: `tools/shot/race_shot_test.dart` (same steps; env `ROCKET`, `TRAIL`, `KID`, `CHIP`) writes `$SHOT_OUT-0.png`, `-0.5.png`, `-1.png` around a comet answer. Race screens (race, comet, Tiếng Việt, cut-scene, badge, offer, win, lose): `tools/shot/game_shot_test.dart` writes `$SHOT_OUT-<name>.png` (env `ONLY=name,...`). Góc Chơi (hub, hub-end, garage, garage-fly, garage-trails, badges, stickers): `tools/shot/hub_shot_test.dart`, same env. "Vở của bé": `tools/shot/notebook_shot_test.dart`. Toán nâng cao: `tools/shot/math_adv_shot_test.dart`. Online room of 4 (standings column): `tools/shot/standings_shot_test.dart` with `--update-goldens` (PNGs in `test/_shot/goldens/`). Frame-cost bench (flutter_tester, debug JIT, not a device verdict): `tools/shot/race_bench_test.dart` with `W`/`H` of the scene box.

## Race scene (2B-1)
- One `Ticker` drives `SceneClock`; the two moving layers repaint from it (`CustomPainter(repaint:)`), no widget rebuild per frame. Static sky and track sit in their own `RepaintBoundary`.
- No Paint/Path/Shader/List allocation per frame: flame paths and shaders live in a unit box and are moved by canvas transforms; smoke, sparkles and stars are typed arrays drawn with one `drawRawAtlas` each.
- Blur (`MaskFilter.blur`) per frame, exactly: the outer flame layer of each rocket (2 draws every frame, `FlameRenderer` `_FlamePaints.outer`) and the comet streak (1 draw, only during the 1.3 s fly-by, `_ForegroundPainter._streakPaint`). Nothing else blurs: nozzle glow, cloud highlights, smoke, sparkles and stars are radial gradients or atlas sprites. If a device drops frames, remove those two blurs first.
- flutter_tester numbers (2026-11-16): UI frame avg 0.70 ms, p99 1.45 ms at 390×480; 0.45 / 1.07 ms at 683×1024. Device `--profile` numbers still to record.

## Đua Bạn Bè (2D/2B2) — Sảnh, Phòng đua 4 người, Tải máy chủ & App

### Đo màn đua online trên máy thật (một lệnh)

Cắm điện thoại (Android tầm trung hoặc iPhone 11), rồi:

```
flutter run --profile -t tools/perf/online_race_perf_main.dart
```

Màn này chạy cảnh đua online 4 tên lửa như trận thật (cập nhật vị trí mỗi 200 ms, sticker bay mỗi 0,8 s), không cần máy chủ. Sau khoảng 25 giây, kết quả hiện trên màn hình và in ra console giữa hai dòng `===== PERF ONLINE RACE =====`. **Đạt** khi: fps ≥ 58, không khung nào > 32 ms, build và raster trung bình ≤ 8 ms (spec §9.1). Dán kết quả vào bảng dưới.

| Máy | Ngày | fps | Build avg / p99 | Raster avg / p99 | Khung > 32 ms | Kết luận |
|---|---|---|---|---|---|---|
| (chưa đo) | | | | | | |

### Đo máy chủ trên Oracle A1

Trên máy Oracle (đã có Java 21 và PostgreSQL theo `server/deploy`), chạy đúng lệnh kiểm tải ở mục 1 với mục tiêu spec §9.2 (5.000 kết nối sảnh + 1.000 phòng): `LOAD_LOBBY_FAMILIES=1250 LOAD_ROOMS=1000 LOAD_TEST_SECONDS=60 ./gradlew loadTest`. Đạt khi p99 phòng ≤ 150 ms, p99 lời mời ≤ 300 ms, CPU ≤ 60 %. Ghi số vào bảng mục 1.

### 1. Kết quả kiểm tải máy chủ (`LobbyRoomLoadTest`)

Kiểm thử chạy trên môi trường thực tế (Java 21, Spring Boot 3.3.5, PostgreSQL 16 local, virtual threads) theo đúng quy mô Spec §9.2:
- **2.000 kết nối `/ws/lobby` đồng thời** (500 gia đình × 4 thiết bị, mỗi gia đình 10 bạn bè)
- **300 phòng đua đồng thời (1.200 kết nối `/ws/room`)**, mỗi phòng 4 người bước đều đặn mỗi 200 ms liên tục trong 60 giây, gửi sticker trêu
- **1 kết nối chậm/stalled có chủ ý (Room 0 peer 3)**: raw TCP socket với bộ đệm nhận nhỏ (1 KB) và không đọc dữ liệu, kiểm tra cơ chế ngắt backpressure của server (`ConcurrentWebSocketSessionDecorator`) mà không gây ảnh hưởng tới 3 người chơi cùng phòng
- **REST `GET /api/v1/friends` đồng thời** từ 4 luồng song song liên tục suốt bài test

**Số liệu đo thực tế (2026-11-24):**
- Thời gian chạy tải: 128.5 s (chu kỳ tải liên tục 60 s)
- Số vòng đua 18 bước hoàn thành: **4.775 vòng**
- Tổng sticker chuyển giao: **76.508**
- Tổng lời mời sảnh chuyển giao: **4.776**
- Số lỗi không mong muốn (unexpected errors): **0**
- Số request REST không phải 200: **0**

| Thao tác | Số mẫu (n) | p50 | p95 | p99 | Tiêu chí Spec §9.2 | Kết luận |
|---|---|---|---|---|---|---|
| **Room Broadcast (bước → snapshot)** | 1.371.773 | 59.21 ms | 122.72 ms | **131.66 ms** | p99 ≤ 150 ms (cả máy dev lẫn Oracle — spec §9.2 đã chốt 150 ms, vì gộp gửi 100 ms nên p50 ≈ 50–60 ms là đúng thiết kế) | **ĐẠT** |
| **Room 0 Fast Peers (cùng phòng peer bị nghẽn)** | 1.944 | 59.16 ms | 110.43 ms | **119.67 ms** | p99 ≤ 150 ms | **ĐẠT** (cô lập hoàn toàn) |
| **Lobby Invite (lời mời sảnh qua socket)** | 4.776 | 21.32 ms | 57.46 ms | **71.73 ms** | p99 ≤ 300 ms | **ĐẠT** |
| **REST `GET /api/v1/friends`** | 4.442 | 2.78 ms | 35.13 ms | **65.00 ms** | p99 ≤ 100 ms | **ĐẠT** |

- **Bộ nhớ máy chủ (JVM test gom cả server + 3.200 WS clients):** Heap đã dùng 1.317,7 MB / committed 1.536,0 MB; RSS 917,9 MB.
- **Xử lý client nghẽn (Stalled Peer Isolation):** Client raw socket nhận dồn 326.350 bytes không đọc đã bị máy chủ đóng ngắt kết nối tự động (`stalled_closed_by_server=true`), 3 peer nhanh trong phòng vẫn hoàn thành 12 vòng đua với p99 119.67 ms mà không bị nghẽn lan tỏa.
- **Lệnh chạy lại trên máy dev / Oracle A1:**
  ```bash
  cd server && TEST_DB_URL=jdbc:postgresql://localhost:5432/funedu_test ./gradlew loadTest
  ```
  Tùy chỉnh thông số qua biến môi trường:
  ```bash
  LOAD_LOBBY_FAMILIES=500 LOAD_ROOMS=300 LOAD_TEST_SECONDS=60 ./gradlew loadTest
  ```

### 2. Hướng dẫn đo App trên máy thật (Spec §9.1)

**Mục tiêu:**
- Màn đua 4 bạn + sticker bay trên Android tầm trung (Galaxy A3x/A5x) và iPhone 11:
  - **≥ 58 fps trung bình**
  - **Không khung hình nào > 32 ms**
  - **Raster thread ≤ 8 ms/khung**
  - **UI thread ≤ 8 ms/khung**
  - Máy 120 Hz không tụt dưới 90 fps khi chỉ có cảnh bay
  - Mở phòng chờ → vào trận đua **≤ 300 ms**
  - Bộ nhớ ảnh tăng ≤ 30 MB so với màn đua 1 mình

**Các bước đo bằng Flutter DevTools:**
1. Cắm thiết bị thật (Android bật USB Debugging hoặc iPhone kết nối qua Xcode).
2. Chạy ứng dụng ở chế độ profile:
   ```bash
   flutter run --profile \
     --dart-define=FUNEDU_API_URL=https://api.yourdomain.com \
     --dart-define=GOOGLE_SERVER_CLIENT_ID=...
   ```
3. Mở link DevTools hiển thị trên terminal (ví dụ `http://127.0.0.1:9100`).
4. Chuyển sang tab **Performance**:
   - Chọn "Record" trước khi bấm "Vào đua" ở sảnh chờ 4 người.
   - Để trận đua diễn ra đủ 3 chặng (18 bước) kèm tương tác thả sticker trêu (`LobbyStickerPicker`).
   - Dừng ghi và quan sát:
     - Biểu đồ Frame time: kiểm tra các cột đỏ (jank > 16.6 ms hoặc > 32 ms).
     - Thời gian Raster và UI trên từng frame.
5. Ghi nhận số đo thực tế vào bảng dưới:
   - *Android (Galaxy A52/tương đương):* Chưa đo máy thật (sẽ bổ sung khi có thiết bị).
   - *iOS (iPhone 11/iPad Pro):* Chưa đo máy thật (sẽ bổ sung khi có thiết bị).

