import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/screens/town_screen.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_valley_canvas.dart';

void main() {
  testWidgets('TownScreen renders DioramaValleyCanvas and 5 stations on Mobile',
      (tester) async {
    // Mobile phone screen size (iPhone 16 Pro Max style: 430 x 932)
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: TownScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DioramaValleyCanvas), findsOneWidget);
    expect(find.text('Tiệm Tạp Hóa Nhí'), findsOneWidget);
    expect(find.text('Cây Tri Thức'), findsOneWidget);
    expect(find.text('Nhà Nấm Toán Học'), findsOneWidget);
    expect(find.text('Trại Ấp Thú'), findsOneWidget);
    expect(find.text('Lâu Đài Chữ Cái'), findsOneWidget);

    // Unmount widget cleanly
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TownScreen renders panoramic valley layout properly on Tablet / iPad',
      (tester) async {
    // Tablet screen size (iPad Pro 11": 1024 x 768)
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: TownScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DioramaValleyCanvas), findsOneWidget);
    expect(find.text('Tiệm Tạp Hóa Nhí'), findsOneWidget);
    expect(find.text('Cây Tri Thức'), findsOneWidget);
    expect(find.text('Nhà Nấm Toán Học'), findsOneWidget);
    expect(find.text('Trại Ấp Thú'), findsOneWidget);
    expect(find.text('Lâu Đài Chữ Cái'), findsOneWidget);

    // Unmount widget cleanly
    await tester.pumpWidget(const SizedBox());
  });
}
