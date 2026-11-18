# Kế hoạch triển khai Giai đoạn 3C — Tab "Nhà Chíp" (Offline 100%)

Spec: `docs/superpowers/specs/2026-11-18-giai-doan-3c-nha-chip-design.md`

---

## Task 1: Bảng màu `HouseColors`, mô hình `lib/house/` & lưu trữ theo từng bé
1. Thêm `HouseColors` vào `lib/ui/theme/tokens.dart`.
2. Tạo `lib/house/house_model.dart`:
   - `HouseSlot`, `HouseItem`, `HouseTreat`, `ChipStage`, `ChipHouseState`
   - JSON encode/decode an toàn, hàm thuần `canClaimFreeTreat`, `applyFeed`, `applyBuyOrEquip`.
3. Tạo `lib/house/house_repository.dart`:
   - Đọc/ghi `AppSettings` khóa `'chipHouse.<kidId>'`.
   - `ChipHouseController` / Riverpod providers kết hợp `homeSummaryProvider.totalStars` tính `availableStars`.
4. Cập nhật `KidRepository._deleteProgressOf(id)` xóa kèm `'chipHouse.$id'`.
5. Viết unit test `test/house/house_model_test.dart` kiểm tra cấp độ XP, hạt dẻ miễn phí theo ngày, mua/lắp trang trí, tách biệt theo từng bé và dọn sạch khi xóa bé.

## Task 2: Sân khấu phòng Chíp (`room_stage.dart`), màn hình `HouseScreen` & điều hướng
1. Tạo `lib/features/house/room_stage.dart`:
   - Vẽ phòng ấm cúng theo 4 theme tường, 4 loại thảm, 4 đồ góc phòng, nhân vật Chíp & phụ kiện tương tác (chạm vuốt ve + phản ứng khi cho ăn).
2. Tạo `lib/features/house/house_screen.dart`:
   - Giao diện điện thoại (`FloatingNavBar`) & iPad (`NavRail`, 2 cột khi ngang).
   - 2 mục: **Cho ăn** (4 món, gồm hạt dẻ miễn phí mỗi ngày) và **Trang trí** (4 nhóm × 4 món).
3. Gắn `kidNavHouse = 3` trong `lib/features/home/kid_nav.dart` và route `/house` trong `lib/router.dart`.
4. Cập nhật `test/features/home_screen_test.dart` (tất cả 4 tab điều hướng đều mở khóa, không còn SnackBar "Sắp có").
5. Viết widget test `test/features/house/house_screen_test.dart`:
   - Render điện thoại & iPad (dọc/ngang) không tràn khung.
   - Cho ăn hạt dẻ miễn phí tăng XP, đổi nút thành "Đã nhận hôm nay".
   - Mua & lắp đồ trang trí bằng sao, cập nhật số sao còn lại mà không đụng tổng sao học tập.
   - Vuốt ve Chíp gọi `Speaker`.
6. Chụp ảnh kiểm duyệt giao diện trên điện thoại & iPad (cả Cho ăn & Trang trí).
7. Chạy `flutter analyze && flutter test`, cập nhật `docs/PROJECT_STATE.md`, commit & push lên `origin/chipchip`.
