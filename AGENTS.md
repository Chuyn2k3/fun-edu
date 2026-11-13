# Hướng dẫn cho AI / người mới tiếp nhận

**Đọc `docs/PROJECT_STATE.md` trước khi làm bất cứ việc gì.** File đó tóm tắt app Chíp Chíp là gì, phong cách giao diện, kiến trúc, đã làm tới đâu, còn dở gì và việc tiếp theo.

Quy tắc ngắn (chi tiết trong `docs/PROJECT_STATE.md` mục 3):

- Flutter **3.24.5** / Dart 3.5. Không nâng phiên bản gói; `drift_flutter` ghim 0.2.4. Dùng `withOpacity`, không `withValues`.
- Chỉ dùng Riverpod cho trạng thái. Màu, bo góc, bóng chỉ lấy từ `lib/ui/theme/tokens.dart`; ảnh chỉ qua `lib/ui/assets.dart`.
- Thẻ trắng: một `BoxDecoration` có cả màu và bóng (bóng không màu phủ lên Material sẽ ra xám).
- Nút cho bé ≥ 64, góc ba mẹ ≥ 48, tương phản chữ ≥ 4.5:1. Chuỗi giao diện tiếng Việt.
- Không quảng cáo, không SDK theo dõi, không gọi mạng; dữ liệu của bé tối thiểu và lưu trên máy.
- Đổi bảng drift → tăng `schemaVersion`, thêm migration, chạy build_runner, commit `.g.dart`.
- Trước khi commit: `flutter analyze` sạch và `flutter test` đạt hết.
- Làm việc trên nhánh `chipchip`. Không gộp vào `new-web` khi chưa khôi phục `CNAME`.
- Không đưa khóa API/bí mật vào code hay commit.
- Xong một phần việc thì cập nhật mục 6–8 trong `docs/PROJECT_STATE.md`.
