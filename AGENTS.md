# Hướng dẫn cho AI / người mới tiếp nhận

**Đọc `docs/PROJECT_STATE.md` trước khi làm bất cứ việc gì.** File đó tóm tắt app Chíp Chíp là gì, phong cách giao diện, kiến trúc, đã làm tới đâu, còn dở gì và việc tiếp theo.

Quy tắc ngắn (chi tiết trong `docs/PROJECT_STATE.md` mục 3):

- Flutter **3.24.5** / Dart 3.5. Không nâng phiên bản gói; `drift_flutter` ghim 0.2.4. Dùng `withOpacity`, không `withValues`.
- Chỉ dùng Riverpod cho trạng thái. Màu, bo góc, bóng chỉ lấy từ `lib/ui/theme/tokens.dart`; ảnh chỉ qua `lib/ui/assets.dart`.
- Thẻ trắng: một `BoxDecoration` có cả màu và bóng (bóng không màu phủ lên Material sẽ ra xám).
- Thẻ dùng `raisedDecoration` (`lib/ui/theme/depth.dart`); thứ bé bấm được bọc `Pressable`.
- Tablet = cạnh ngắn cửa sổ ≥ 600, xét bằng `context.formFactor`. Không phóng to giao diện điện thoại; chỉ trang chủ và Góc ba mẹ có bố cục tablet ở file anh em (`home_tablet.dart`, `parent_home_tablet.dart`); các màn khác rẽ nhánh tablet ngay trong cùng file. Nút bé ≥ 80 trên tablet.
- Chỉ đánh giá hiệu năng bằng `flutter run --profile` (không dùng debug). Chụp màn hình: `docs/perf.md`.
- Nút cho bé ≥ 64, góc ba mẹ ≥ 48, tương phản chữ ≥ 4.5:1. Chuỗi giao diện tiếng Việt.
- Không quảng cáo, không SDK theo dõi. App chạy đầy đủ không cần mạng; **chỉ gọi máy chủ FunEdu (và Google/Apple lúc đăng nhập), chỉ sau khi ba mẹ qua cổng ba mẹ, đồng ý và đăng nhập (ở màn đầu hoặc Góc ba mẹ). Chế độ khách không gọi mạng** (spec `docs/superpowers/specs/2026-11-21-giai-doan-2d-2b2-online-design.md`). Dữ liệu của bé tối thiểu; nét vẽ (`stroke_attempts`) không rời máy; chỉ trang vở đẹp nhất mỗi chữ (`notebook_pages`, đã rút gọn) và tóm tắt Tủ khoe (khi ba mẹ bật; sảnh `/ws/lobby` chỉ báo online và gửi lời mời cho bạn bè đã kết qua mã của ba mẹ) được gửi lên máy chủ.
- Máy chủ: `server/` (Spring Boot 3, Java 21, PostgreSQL, Flyway). Trước khi commit phần máy chủ: `cd server && ./gradlew test`. Bí mật chỉ trong biến môi trường / `.env` không commit.
- Nét chữ cái và dấu thanh nằm ở `tools/glyphs/letters.py`, chữ hoa ở `tools/glyphs/capitals.py`; tạo lại bằng `python3 tools/glyphs/make_glyphs.py`; không sửa tay file JSON sinh ra trong `assets/glyphs/` (chạy `cd tools/glyphs && python3 -m pytest -q`).
- Đổi bảng drift → tăng `schemaVersion`, thêm migration, chạy build_runner, commit `.g.dart`.
- Trước khi commit: `flutter analyze` sạch và `flutter test` đạt hết.
- Làm việc trên nhánh `chipchip`. Không gộp vào `new-web` khi chưa khôi phục `CNAME`.
- Không đưa khóa API/bí mật vào code hay commit.
- Xong một phần việc thì cập nhật mục 6–8 trong `docs/PROJECT_STATE.md`.
- Dữ liệu trò chơi (`lib/game/`, bảng `race_results`, `game_*`) tách khỏi dữ liệu học; engine trò chơi không gọi mạng (phòng đua qua mạng nằm ở `lib/online/`).
- Ảnh trò chơi mới: nền xanh lá, tách bằng `tools/assets/chroma_key.py`.
- Website dùng thử ở `website/` (Vite + TypeScript, không framework): `cd website && npm test && npm run build`. Sửa `lib/stroke/` hoặc chính sách quyền riêng tư thì sinh lại dữ liệu chung (xem `website/README.md`). Web không được gọi ra ngoài tên miền của nó.
