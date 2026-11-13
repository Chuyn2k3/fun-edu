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
Chụp màn hình bằng test dựng riêng (không đưa vào repo):
- Sao chép mẫu `home_shot_test2.dart` (trong thư mục scratchpad của phiên) vào `test/_shot/`.
- Chạy với biến môi trường `W`, `H`, `SHOT_OUT` và `FLUTTER_ROOT=$HOME/flutter324`.
- `flutter_tester` vẽ bóng không có độ mờ, nên bóng trông gắt hơn máy thật.
- Xoá `test/_shot/` trước khi commit.
