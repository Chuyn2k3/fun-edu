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
- `flutter_tester` draws shadows without blur, so they look harsher than on a device.
- Always delete `test/_shot/` before committing.
- Rocket race scene: `tools/shot/race_shot_test.dart` (same steps; env `ROCKET`, `TRAIL`, `KID`, `CHIP`) writes `$SHOT_OUT-0.png`, `-0.5.png`, `-1.png` around a comet answer. Race screens (race, comet, Tiếng Việt, cut-scene, badge, offer, win, lose): `tools/shot/game_shot_test.dart` writes `$SHOT_OUT-<name>.png` (env `ONLY=name,...`). Góc Chơi (hub, hub-end, garage, garage-fly, garage-trails, badges, stickers): `tools/shot/hub_shot_test.dart`, same env. Frame-cost bench (flutter_tester, debug JIT, not a device verdict): `tools/shot/race_bench_test.dart` with `W`/`H` of the scene box.

## Race scene (2B-1)
- One `Ticker` drives `SceneClock`; the two moving layers repaint from it (`CustomPainter(repaint:)`), no widget rebuild per frame. Static sky and track sit in their own `RepaintBoundary`.
- No Paint/Path/Shader/List allocation per frame: flame paths and shaders live in a unit box and are moved by canvas transforms; smoke, sparkles and stars are typed arrays drawn with one `drawRawAtlas` each.
- Blur (`MaskFilter.blur`) per frame, exactly: the outer flame layer of each rocket (2 draws every frame, `FlameRenderer` `_FlamePaints.outer`) and the comet streak (1 draw, only during the 1.3 s fly-by, `_ForegroundPainter._streakPaint`). Nothing else blurs: nozzle glow, cloud highlights, smoke, sparkles and stars are radial gradients or atlas sprites. If a device drops frames, remove those two blurs first.
- flutter_tester numbers (2026-11-16): UI frame avg 0.70 ms, p99 1.45 ms at 390×480; 0.45 / 1.07 ms at 683×1024. Device `--profile` numbers still to record.
