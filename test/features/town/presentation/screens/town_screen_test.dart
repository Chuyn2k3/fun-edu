import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/screens/town_screen.dart';

void main() {
  testWidgets('TownScreen renders buildings and Pippo guide properly on Mobile',
      (tester) async {
    // Set mobile phone screen size (iPhone 16 Pro Max style: 430 x 932)
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: TownScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Làng Cổ Tích FunEdu'), findsOneWidget);
    expect(find.text('Siêu Thị Pippo'), findsOneWidget);
    expect(find.text('Cây Tri Thức'), findsOneWidget);
    expect(find.text('Nhà Toán Học'), findsOneWidget);
    expect(find.text('Trại Ấp Thú'), findsOneWidget);
    expect(find.text('Lâu Đài Chữ Cái'), findsOneWidget);

    // Unmount widget cleanly so all animation controllers are disposed
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TownScreen renders panoramic valley layout properly on Tablet / iPad',
      (tester) async {
    // Set tablet screen size (iPad Pro 11": 834 x 1194 or 1024 x 768)
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: TownScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Làng Cổ Tích FunEdu'), findsOneWidget);
    expect(find.text('Siêu Thị Pippo'), findsOneWidget);
    expect(find.text('Cây Tri Thức'), findsOneWidget);
    expect(find.text('Nhà Toán Học'), findsOneWidget);
    expect(find.text('Trại Ấp Thú'), findsOneWidget);
    expect(find.text('Lâu Đài Chữ Cái'), findsOneWidget);

    // Unmount widget cleanly so all animation controllers are disposed
    await tester.pumpWidget(const SizedBox());
  });
}
