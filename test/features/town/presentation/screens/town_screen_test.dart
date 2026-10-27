import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/screens/town_screen.dart';

void main() {
  testWidgets('TownScreen renders buildings and Pippo guide properly',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TownScreen(),
      ),
    );

    expect(find.text('Làng Cổ Tích FunEdu'), findsOneWidget);
    expect(find.text('Siêu Thị Pippo'), findsOneWidget);
    expect(find.text('Cây Tri Thức'), findsOneWidget);
    expect(find.text('Nhà Toán Học'), findsOneWidget);
    expect(find.text('Trại Ấp Thú'), findsOneWidget);
  });
}
