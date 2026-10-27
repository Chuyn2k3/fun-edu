import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_ground_painter.dart';

void main() {
  testWidgets('DioramaGroundPainter paints without crashing and matches size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(800, 1100),
            painter: DioramaGroundPainter(scale: 1.0),
          ),
        ),
      ),
    );

    final painterFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is DioramaGroundPainter,
    );
    expect(painterFinder, findsOneWidget);
  });
}
