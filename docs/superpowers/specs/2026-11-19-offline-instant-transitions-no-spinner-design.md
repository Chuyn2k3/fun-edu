# Thiết kế Chuyển màn 1-chạm mượt mà, tức thì, 0 vòng xoay loading (Offline 100%)

Ngày: 2026-11-19  
Nhánh: `chipchip`  
Trạng thái: Đã duyệt thiết kế (Brainstorming approved)  
Phạm vi: Tối ưu hoá toàn bộ trải nghiệm điều hướng và hiển thị của app Chíp Chíp (100% offline): chuyển tab tức thì 0ms với `StatefulShellRoute`, loại bỏ hoàn toàn các vòng xoay `CircularProgressIndicator` bằng cơ chế Optimistic Rendering, buồng lái đua `RaceScreen` vững chãi không giật layout, và hiệu ứng chuyển màn con nhẹ êm 160ms phong cách game Apple Arcade.

---

## 1. Bối cảnh & Vấn đề hiện tại

Dù Chíp Chíp là ứng dụng chạy **100% offline** (toàn bộ âm thanh, ảnh, nét chữ, cơ sở dữ liệu SQLite cục bộ trên máy với thời gian đọc chỉ 5–15ms), trải nghiệm sử dụng thực tế vẫn gặp các vấn đề làm giảm cảm giác phản hồi xúc giác như đồ chơi (tactile toy):
1. **Chớp xoay tròn loading (`CircularProgressIndicator`):** Các màn hình (`HomeScreen`, `MathMapScreen`, `WritingMapScreen`, `VietnameseMapScreen`, `EnglishMapScreen`, `CollectionScreen`, `HouseScreen`) đều dùng `ref.watch(futureProvider).when(loading: () => Center(child: CircularProgressIndicator()), ...)`. Khi vào màn, Flutter vẽ 1–2 frame đầu tiên là vòng xoay tròn rồi mới nhảy dữ liệu ra, tạo cảm giác chớp giật layout.
2. **Huỷ và dựng lại 4 Tab chính từ đầu:** Thanh điều hướng bé (`kidNavItems`: Học `/`, Chơi `/game`, Sưu tập `/collection`, Nhà Chíp `/house`) hiện gọi `context.go()`. Mỗi lần bấm tab là huỷ sạch màn cũ, dựng màn mới từ số 0, mất trạng thái cuộn, thanh bottom bar/rail cũng bị vẽ lại.
3. **Buồng lái đua (`RaceScreen`) trễ vài frame:** Khi vào đua, bàn điều khiển buồng lái (`AnswerDesk`) bị `q == null` nên render rỗng (`SizedBox.shrink()`), HUD hiện "Chuẩn bị…", sau khi `RaceController.start()` query SQLite xong thì câu hỏi mới giật nảy ra.
4. **Hiệu ứng chuyển trang mặc định của OS:** `GoRouter` dùng animation trượt mặc định (300ms–400ms). Trong lúc thanh trượt đang chạy thì SQLite trả về làm rebuild giữa chừng, gây khựng (jank/dropped frame).

---

## 2. Mục tiêu thiết kế

- **0ms chuyển tab:** Chạm vào bất kỳ tab nào trong 4 tab chính là chuyển ngay tức khắc, giữ nguyên trạng thái cuộn và bộ nhớ của từng tab.
- **Xóa sổ 100% `CircularProgressIndicator` ở luồng người dùng của bé:** Toàn bộ màn hình hiển thị cấu trúc giao diện chuẩn trong Frame đầu tiên (Optimistic Structural Rendering), dữ liệu SQLite cập nhật tại chỗ êm ru.
- **Thanh điều hướng cố định, vững chãi:** `FloatingNavBar` (điện thoại) và `NavRail` (tablet) không bao giờ bị unmount hoặc nhấp nháy khi chuyển giữa 4 tab.
- **Buồng lái đua sẵn sàng ngay lập tức:** Bàn điều khiển buồng lái render khung vững chãi với đèn hiệu "Sẵn sàng xuất phát!", kích thước giữ nguyên vẹn, câu hỏi xuất hiện mượt mà không dịch chuyển layout.
- **Chuyển màn con êm ái (Micro-transition 160ms):** Sử dụng `CustomTransitionPage` siêu nhẹ (Fade + Scale nhẹ 0.97 $\to$ 1.0 trong 160ms `Curves.easeOutCubic`) cho các màn hình con (Bản đồ môn, Tủ đồ, Vào đua, Kết quả đua, Góc ba mẹ...).
- **Giữ tương thích 100%:** Giữ nguyên toàn bộ URL routes hiện hành (`/`, `/game`, `/collection`, `/house`, `/subject/*`, `/game/race/*`...) và đảm bảo toàn bộ 2,673 tests hiện có đều pass.

---

## 3. Kiến trúc Router: `StatefulShellRoute.indexedStack`

### 3.1 Khung vỏ Shell (`KidScaffoldShell`)
Tạo widget vỏ `KidScaffoldShell` bọc ngoài 4 tab chính:
- Nhận `StatefulNavigationShell navigationShell`.
- Trên điện thoại (`FormFactor.phone`):
  - Dùng `Stack`:
    - Lớp dưới: `navigationShell` (hiển thị tab hiện tại từ `IndexedStack`).
    - Lớp trên: `Positioned(bottom: 0, child: FloatingNavBar(...))`.
    - `FloatingNavBar` nhận `selected: navigationShell.currentIndex`, khi bấm tab gọi `navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex)`.
- Trên tablet (`FormFactor.tabletPortrait` & `FormFactor.tabletLandscape`):
  - Dùng `Row`:
    - Cột trái: `NavRail` cố định nhận `selected: navigationShell.currentIndex`.
    - Phần còn lại: `Expanded(child: navigationShell)`.

### 3.2 Cấu hình 4 Nhánh StatefulShellBranch
```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => KidScaffoldShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]),
    StatefulShellBranch(routes: [GoRoute(path: '/game', builder: (context, state) => const GameHubScreen())]),
    StatefulShellBranch(routes: [GoRoute(path: '/collection', builder: (context, state) => const CollectionScreen())]),
    StatefulShellBranch(routes: [GoRoute(path: '/house', builder: (context, state) => const HouseScreen())]),
  ],
)
```
- Các màn hình con độc lập (Fullscreen) nằm ngoài `StatefulShellRoute` (hoặc dùng `parentNavigatorKey: rootNavigatorKey`):
  - `/subject/toan`, `/subject/viet`, `/subject/tieng-viet`, `/subject/tieng-anh`
  - `/practice-math/:levelIndex`, `/practice-vietnamese/:levelIndex`, `/practice-english/:levelIndex`, `/practice/:glyphId`
  - `/game/pick`, `/game/garage`, `/game/badges`, `/game/stickers`, `/game/race/:subject`, `/game/result`
  - `/parent`, `/placement`, `/setup`, `/lesson`, `/lesson/done`

---

## 4. Chiến lược Optimistic Rendering (Loại bỏ 100% Spinner)

### 4.1 Trang chủ (`HomeScreen`)
- **Vấn đề:** `loading = !summaryAsync.hasValue && summaryAsync.isLoading || !lessonAsync.hasValue && lessonAsync.isLoading;` $\rightarrow$ hiện `CircularProgressIndicator()`.
- **Giải pháp:** Bỏ điều kiện `loading ? CircularProgressIndicator() : ...`. Luôn render `_HomeBody` ngay lập tức với dữ liệu dự phòng có sẵn:
  ```dart
  final summary = summaryAsync.valueOrNull ?? const HomeSummary(totalStars: 0, learnedDaysThisWeek: 0, masteredWriting: 0);
  final lesson = lessonAsync.valueOrNull ?? const <LessonItem>[];
  ```
- Khi SQLite hoàn tất trong 5ms, Riverpod cập nhật dữ liệu tự động, giao diện đổi số sao và chữ viết êm ru, không chớp giật.

### 4.2 Bản đồ môn học Toán, Tiếng Anh, Tiếng Việt (`*_map_screen.dart`)
- **Vấn đề:** `current == null ? const Center(child: CircularProgressIndicator()) : LayoutBuilder(...)`.
- **Giải pháp:**
  - Nạp ấm (pre-warm) `mathLevelIndexProvider`, `vietnameseLevelIndexProvider`, `englishLevelIndexProvider` trong `SplashView` hoặc khi nạp hồ sơ bé.
  - Tại màn hình bản đồ, thay vì hiện spinner khi `current == null`, render ngay lập tức lưới bài tập với `current = level.valueOrNull ?? 0`. Lưới bài học hiện diện ngay khi mở màn hình, các ô hoàn thành và mở khóa xuất hiện tức thì.

### 4.3 Bản đồ Viết chữ cái (`WritingMapScreen`)
- **Vấn đề:** `glyphListProvider` nạp tĩnh từ JSON asset; nếu chưa có giá trị thì `available` là `[]`, gây ra cú nhảy danh sách (layout pop).
- **Giải pháp:**
  - Kích hoạt nạp `glyphListProvider` ngay khi ứng dụng khởi chạy (`SplashView`), đảm bảo danh sách chữ cái luôn có sẵn trong RAM.

### 4.4 Màn hình Sưu tập & Nhà Chíp (`CollectionScreen`, `HouseScreen`)
- **Vấn đề:** `snapAsync.when(loading: () => Center(child: CircularProgressIndicator()), ...)` và `dataAsync.when(...)`.
- **Giải pháp:**
  - Chuyển sang đọc `snapAsync.valueOrNull ?? LearningSnapshot.empty(...)` và `dataAsync.valueOrNull ?? ChipHouseData.initial(...)`.
  - Toàn bộ sân khấu phòng Chíp và tủ nhãn dán hiển thị ngay frame đầu tiên, không có bất kỳ spinner nào.

### 4.5 Màn Đua Tên Lửa (`RaceScreen` & `AnswerDesk`)
- **Vấn đề:** `q == null` khi `s.phase == RacePhase.loading` làm `AnswerDesk` render `SizedBox.shrink()`, sau đó câu hỏi nhảy phốc ra làm giật độ cao màn hình.
- **Giải pháp:**
  - Khi `q == null`, `AnswerDesk` render khung buồng lái với thẻ giữ chỗ ("Sẵn sàng xuất phát!"), kích thước cố định chuẩn xác với chiều cao thẻ câu hỏi bình thường.
  - Cụm phím đáp án hiển thị 3 phím chờ màu sắc buồng lái. Khi `RaceController` chuyển sang `RacePhase.racing`, nội dung câu hỏi xuất hiện êm dịu, không giật dịch chuyển layout 1 pixel nào.

---

## 5. Hiệu ứng chuyển cảnh êm ru (Arcade Micro-Transitions)

### 5.1 Hàm tiện ích `buildSmoothTransitionPage`
Thay thế các `GoRoute(builder: ...)` thông thường của các màn hình con bằng `pageBuilder: (context, state) => buildSmoothTransitionPage(...)`:
- **Widget:** `CustomTransitionPage`
- **Thời lượng:** `160ms` (`Duration(milliseconds: 160)`)
- **Chuyển động (TransitionsBuilder):**
  - `FadeTransition` từ opacity `0.0` đến `1.0`.
  - `ScaleTransition` nhẹ nhàng từ `0.97` đến `1.0` với curve `Curves.easeOutCubic`.
- Cảm giác mượt mà, mở rộng nhẹ nhàng từ trung tâm, không làm trượt cả khung hình và hoàn toàn không gây drop frame trên các thiết bị cấu hình thấp.

---

## 6. Kế hoạch kiểm thử & Đảm bảo an toàn

1. **Kiểm thử Navigation:**
   - Đảm bảo `appRouter.go('/')`, `appRouter.go('/game')`, `appRouter.go('/collection')`, `appRouter.go('/house')` hoạt động chính xác trong cả môi trường thực tế và widget test.
   - Các lệnh `appRouter.push('/subject/toan')`, `appRouter.push('/game/race/toan')`, `appRouter.push('/parent')` mở đúng trang đè lên shell.
2. **Kiểm thử Spinner Elimination:**
   - Viết/chạy widget test xác nhận `find.byType(CircularProgressIndicator)` **bằng 0** trên toàn bộ các màn hình chính và màn con của bé.
3. **Phân tích code & Test suite:**
   - Chạy `flutter analyze` đảm bảo 0 issues.
   - Chạy toàn bộ test suite (`flutter test`) đảm bảo vượt qua 2,673 / 2,673 tests.
