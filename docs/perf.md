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
