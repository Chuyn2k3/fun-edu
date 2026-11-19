# Kế hoạch Triển khai: Chuyển màn 1-chạm mượt mà, tức thì, 0 vòng xoay loading (Offline 100%)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi 4 tab chính sang `StatefulShellRoute.indexedStack` (chuyển tab tức thì 0ms, giữ nguyên scroll), loại bỏ 100% `CircularProgressIndicator` trên mọi màn hình của bé bằng Optimistic Rendering, chống giật layout buồng lái đua, và áp dụng micro-transitions 160ms phong cách game Apple Arcade.

**Architecture:** 
1. Sử dụng `StatefulShellRoute.indexedStack` bọc 4 tab chính (`/`, `/game`, `/collection`, `/house`) với vỏ `KidScaffoldShell` giữ cố định `FloatingNavBar` (điện thoại) và `NavRail` (tablet).
2. Xóa bỏ các nhánh `loading: () => Center(child: CircularProgressIndicator())` ở các màn hình chính và bản đồ môn học, thay bằng Optimistic Structural Rendering với fallback đồng bộ an toàn.
3. Thay `SizedBox.shrink()` ở bàn điều khiển buồng lái `AnswerDesk` bằng `_CockpitReadyPlaceholder` kích thước cố định để loại bỏ nhảy giật layout.
4. Xây dựng `buildSmoothTransitionPage` dùng `CustomTransitionPage` 160ms (Fade + Scale nhẹ 0.97 $\to$ 1.0) cho các màn hình con.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5, GoRouter 15.1, Riverpod, Drift SQLite offline.

---

### Task 1: Xây dựng `KidScaffoldShell` & Cấu hình `StatefulShellRoute.indexedStack` trong Router

**Files:**
- Create: `lib/features/shell/kid_scaffold_shell.dart`
- Modify: `lib/router.dart`
- Modify: `lib/features/home/home_screen.dart` (loại bỏ navbar trùng lặp khi chạy trong shell)
- Test: `test/features/shell/kid_scaffold_shell_test.dart`

- [ ] **Step 1: Viết test cho `KidScaffoldShell`**
  Tạo `test/features/shell/kid_scaffold_shell_test.dart` kiểm tra:
  - Hiển thị `FloatingNavBar` ở đáy màn hình trên điện thoại (`FormFactor.phone`).
  - Hiển thị `NavRail` ở cạnh trái trên tablet (`FormFactor.tabletPortrait` và `FormFactor.tabletLandscape`).
  - Nhận sự kiện chọn tab và gọi `navigationShell.goBranch(index)`.

- [ ] **Step 2: Chạy test để xác nhận FAIL**
  Chạy: `flutter test test/features/shell/kid_scaffold_shell_test.dart`
  Kết quả mong đợi: FAIL vì file chưa được tạo.

- [ ] **Step 3: Hiện thực `KidScaffoldShell`**
  Tạo `lib/features/shell/kid_scaffold_shell.dart`:
  - `class KidScaffoldShell extends StatelessWidget`: nhận `StatefulNavigationShell navigationShell`.
  - Kiểm tra `context.isTablet`:
    - Nếu tablet: `Row` với `NavRail` ở bên trái (`selected: navigationShell.currentIndex`) và `Expanded(child: navigationShell)`.
    - Nếu phone: `Stack` với `navigationShell` ở dưới và `Positioned(bottom: 0, child: FloatingNavBar(selected: navigationShell.currentIndex, onSelect: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex)))`.

- [ ] **Step 4: Tích hợp `StatefulShellRoute.indexedStack` vào `lib/router.dart`**
  - Cấu hình 4 nhánh `StatefulShellBranch`:
    - Branch 0: `GoRoute(path: '/', builder: (context, state) => const HomeScreen())`
    - Branch 1: `GoRoute(path: '/game', builder: (context, state) => const GameHubScreen())`
    - Branch 2: `GoRoute(path: '/collection', builder: (context, state) => const CollectionScreen())`
    - Branch 3: `GoRoute(path: '/house', builder: (context, state) => const HouseScreen())`
  - Đảm bảo các route con độc lập (`/subject/*`, `/game/race/*`, `/game/garage`, `/game/badges`, `/game/stickers`, `/parent`...) đẩy lên `rootNavigatorKey`.

- [ ] **Step 5: Chạy test và xác nhận PASS**
  Chạy: `flutter test test/features/shell/kid_scaffold_shell_test.dart`
  Kết quả mong đợi: PASS.

- [ ] **Step 6: Commit**
  `git add lib/features/shell/ lib/router.dart test/features/shell/ && git commit -m "feat: implement KidScaffoldShell with StatefulShellRoute"`

---

### Task 2: Loại bỏ Spinner trên các màn hình chính (`HomeScreen`, `CollectionScreen`, `HouseScreen`)

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/collection/collection_screen.dart`
- Modify: `lib/features/house/house_screen.dart`
- Test: `test/features/home/home_screen_test.dart`
- Test: `test/features/collection_test.dart`
- Test: `test/features/house_test.dart`

- [ ] **Step 1: Viết test xác nhận không còn `CircularProgressIndicator` khi màn hình đang nạp**
  Trong `test/features/home/home_screen_test.dart`, `test/features/collection_test.dart`, `test/features/house_test.dart`:
  - Bơm widget với provider ở trạng thái `loading`.
  - `expect(find.byType(CircularProgressIndicator), findsNothing)`.

- [ ] **Step 2: Chạy test để xác nhận FAIL**
  Chạy: `flutter test test/features/home/home_screen_test.dart`
  Kết quả mong đợi: FAIL vì code hiện tại trả về `CircularProgressIndicator()`.

- [ ] **Step 3: Cập nhật `HomeScreen` sang Optimistic Rendering**
  Trong `lib/features/home/home_screen.dart`:
  - Bỏ `loading ? const Center(child: CircularProgressIndicator()) : _HomeBody(...)`.
  - Luôn render `_HomeBody` ngay frame đầu tiên:
    ```dart
    final summary = summaryAsync.valueOrNull ??
        const HomeSummary(
          totalStars: 0,
          learnedDaysThisWeek: 0,
          masteredWriting: 0,
        );
    final lesson = lessonAsync.valueOrNull ?? const <LessonItem>[];
    ```

- [ ] **Step 4: Cập nhật `CollectionScreen` sang Optimistic Rendering**
  Trong `lib/features/collection/collection_screen.dart`:
  - Thay vì `snapAsync.when(loading: () => Center(child: CircularProgressIndicator()), ...)`:
  - Đọc `final snap = snapAsync.valueOrNull ?? _emptySnapshot;` và gọi `buildBody(snap)` ngay frame đầu.

- [ ] **Step 5: Cập nhật `HouseScreen` sang Optimistic Rendering**
  Trong `lib/features/house/house_screen.dart`:
  - Thay vì `dataAsync.when(loading: () => Center(child: CircularProgressIndicator()), ...)`:
  - Đọc `final data = dataAsync.valueOrNull ?? _defaultHouseData;` và gọi `buildBody(data)` ngay frame đầu.

- [ ] **Step 6: Chạy test xác nhận PASS**
  Chạy: `flutter test test/features/home/home_screen_test.dart test/features/collection_test.dart test/features/house_test.dart`
  Kết quả mong đợi: PASS.

- [ ] **Step 7: Commit**
  `git add lib/features/home/ lib/features/collection/ lib/features/house/ && git commit -m "feat: eliminate loading spinners on primary screens"`

---

### Task 3: Pre-warm dữ liệu & Loại bỏ Spinner trên các bản đồ môn học

**Files:**
- Modify: `lib/app.dart` (pre-warm `mathLevelIndexProvider`, `glyphListProvider` khi hiển thị Splash)
- Modify: `lib/features/subject/math_map_screen.dart`
- Modify: `lib/features/subject/vietnamese_map_screen.dart`
- Modify: `lib/features/subject/english_map_screen.dart`
- Modify: `lib/features/subject/writing_map_screen.dart`
- Create: `test/features/subject/subject_maps_no_spinner_test.dart`

- [ ] **Step 1: Viết test xác nhận không có `CircularProgressIndicator` trên các bản đồ môn học**
  Tạo `test/features/subject/subject_maps_no_spinner_test.dart`:
  - Bơm `MathMapScreen`, `VietnameseMapScreen`, `EnglishMapScreen`, `WritingMapScreen` khi provider chưa có kết quả.
  - Khẳng định không tìm thấy `CircularProgressIndicator`, các ô level được hiển thị ngay.

- [ ] **Step 2: Chạy test để xác nhận FAIL**
  Chạy: `flutter test test/features/subject/subject_maps_no_spinner_test.dart`
  Kết quả mong đợi: FAIL.

- [ ] **Step 3: Cập nhật `MathMapScreen`, `VietnameseMapScreen`, `EnglishMapScreen`**
  - Thay `current == null ? const Center(child: CircularProgressIndicator()) : ...`:
  - Lấy `final current = level.valueOrNull ?? 0;` và luôn hiển thị `LayoutBuilder` / danh sách level ngay frame đầu tiên.

- [ ] **Step 4: Cập nhật `WritingMapScreen` & Pre-warm `glyphListProvider`**
  - Trong `lib/app.dart`: kích hoạt đọc `ref.watch(glyphListProvider)` và các `*LevelIndexProvider` trong lúc `SplashView` đang chạy.
  - Trong `WritingMapScreen`: nếu `available` rỗng thì fallback hiển thị lưới placeholder hoặc ladder chuẩn để không bị nhảy layout.

- [ ] **Step 5: Chạy test xác nhận PASS**
  Chạy: `flutter test test/features/subject/subject_maps_no_spinner_test.dart`
  Kết quả mong đợi: PASS.

- [ ] **Step 6: Commit**
  `git add lib/app.dart lib/features/subject/ test/features/subject/ && git commit -m "feat: zero spinner on subject maps and pre-warm glyphs"`

---

### Task 4: Chống giật layout buồng lái Đua Tên Lửa (`RaceScreen` & `RaceController`)

**Files:**
- Modify: `lib/features/game/race_screen.dart`
- Modify: `lib/features/game/race_controller.dart`
- Create: `test/features/game/race_cockpit_no_jank_test.dart`

- [ ] **Step 1: Viết test cho trạng thái sẵn sàng buồng lái**
  Tạo `test/features/game/race_cockpit_no_jank_test.dart`:
  - Khởi tạo `RaceScreen` ở `RacePhase.loading`.
  - Khẳng định chiều cao bàn điều khiển `AnswerDesk` giữ nguyên, không render `SizedBox.shrink()`.
  - Thẻ câu hỏi hiển thị placeholder "Sẵn sàng xuất phát!", phím bấm ở trạng thái sẵn sàng.

- [ ] **Step 2: Chạy test để xác nhận FAIL**
  Chạy: `flutter test test/features/game/race_cockpit_no_jank_test.dart`
  Kết quả mong đợi: FAIL vì hiện tại trả về `SizedBox.shrink()`.

- [ ] **Step 3: Cập nhật `AnswerDesk` trong `lib/features/game/race_screen.dart`**
  - Khi `q == null`, thay vì `SizedBox.shrink()`, render `_CockpitReadyPlaceholder`:
    - Thẻ câu hỏi giữ đúng kích thước padding và bo góc của `_QuestionCard`.
    - Tiêu đề: "Chuẩn bị xuất phát!", biểu tượng tên lửa sẵn sàng.
    - 3 phím đáp án hiển thị phím trống màu buồng lái (`GameColors.keyOrange` / `cockpitBg`).
  - Khi `RaceController` chuyển sang `RacePhase.racing`, thẻ câu hỏi và các đáp án hiện ra tại đúng vị trí đó $\rightarrow$ 0 pixel dịch chuyển giật cục.

- [ ] **Step 4: Chạy test xác nhận PASS**
  Chạy: `flutter test test/features/game/race_cockpit_no_jank_test.dart`
  Kết quả mong đợi: PASS.

- [ ] **Step 5: Commit**
  `git add lib/features/game/race_screen.dart test/features/game/race_cockpit_no_jank_test.dart && git commit -m "feat: stable cockpit placeholder in RaceScreen during loading"`

---

### Task 5: Hiệu ứng chuyển màn con êm dịu (Arcade Micro-Transitions 160ms)

**Files:**
- Create: `lib/ui/transitions/smooth_page_transition.dart`
- Modify: `lib/router.dart`
- Create: `test/ui/transitions/smooth_page_transition_test.dart`

- [ ] **Step 1: Viết test cho `buildSmoothTransitionPage`**
  Tạo `test/ui/transitions/smooth_page_transition_test.dart`:
  - Kiểm tra `CustomTransitionPage` được tạo với `transitionDuration == Duration(milliseconds: 160)`.
  - Kiểm tra các transitions được áp dụng gồm `FadeTransition` và `ScaleTransition`.

- [ ] **Step 2: Chạy test để xác nhận FAIL**
  Chạy: `flutter test test/ui/transitions/smooth_page_transition_test.dart`
  Kết quả mong đợi: FAIL vì file chưa được tạo.

- [ ] **Step 3: Hiện thực `buildSmoothTransitionPage`**
  Tạo `lib/ui/transitions/smooth_page_transition.dart`:
  ```dart
  CustomTransitionPage<T> buildSmoothTransitionPage<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 160),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final scale = Tween<double>(begin: 0.97, end: 1.0).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
  ```

- [ ] **Step 4: Áp dụng `buildSmoothTransitionPage` cho các màn con trong `lib/router.dart`**
  - Chuyển các `GoRoute` của màn con (`/subject/*`, `/game/race/*`, `/game/garage`, `/game/badges`, `/game/stickers`, `/parent`...) từ `builder: ...` sang `pageBuilder: (context, state) => buildSmoothTransitionPage(...)`.

- [ ] **Step 5: Chạy test xác nhận PASS**
  Chạy: `flutter test test/ui/transitions/smooth_page_transition_test.dart`
  Kết quả mong đợi: PASS.

- [ ] **Step 6: Commit**
  `git add lib/ui/transitions/ lib/router.dart test/ui/transitions/ && git commit -m "feat: arcade micro-transitions for sub-screens"`

---

### Task 6: Kiểm thử toàn diện, Phân tích Code & Cập nhật Tài liệu

**Files:**
- Modify: `docs/PROJECT_STATE.md` (cập nhật mục 6 và 8)

- [ ] **Step 1: Chạy `flutter analyze`**
  Chạy: `flutter analyze`
  Kết quả mong đợi: 0 issues found.

- [ ] **Step 2: Chạy toàn bộ test suite `flutter test`**
  Chạy: `flutter test`
  Kết quả mong đợi: Vượt qua toàn bộ 2,673+ tests.

- [ ] **Step 3: Cập nhật `docs/PROJECT_STATE.md`**
  Cập nhật trạng thái dự án: đã tối ưu hóa điều hướng chuyển màn 0ms với StatefulShellRoute và xóa sạch 100% spinner xoay loading.

- [ ] **Step 4: Commit tài liệu & hoàn tất**
  `git add docs/PROJECT_STATE.md && git commit -m "docs: update PROJECT_STATE with instant transitions and zero-spinner overhaul"`
