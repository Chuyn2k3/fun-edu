import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/home/week_panel.dart';
import 'package:funedu/ui/theme/tokens.dart';

void main() {
  Future<void> pump(WidgetTester t, Set<int> days) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: WeekPanel(
              learnedWeekdays: days,
              masteredWriting: 2,
              writingTotal: 15,
              mathLevel: 1,
              mathTotal: 9,
            ),
          ),
        ),
      ),
    ));
  }

  bool filled(WidgetTester t, int day) {
    final box = t.widget<Container>(find.byKey(ValueKey('week-dot-$day')));
    return (box.decoration! as BoxDecoration).color == AppColors.accent;
  }

  testWidgets('fills exactly the learned weekdays', (t) async {
    await pump(t, {1, 2, 4});
    expect(find.text('Tuần này'), findsOneWidget);
    for (final label in const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']) {
      expect(find.text(label), findsOneWidget);
    }
    expect([
      for (var d = 1; d <= 7; d++)
        if (filled(t, d)) d
    ], [
      1,
      2,
      4
    ]);
    expect(find.text('3 ngày học'), findsOneWidget);
    expect(find.text('Chữ đã thuộc: 2/15'), findsOneWidget);
    expect(find.text('Cấp Toán: 1/9'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('no learned days: all dots empty', (t) async {
    await pump(t, const {});
    expect([
      for (var d = 1; d <= 7; d++)
        if (filled(t, d)) d
    ], isEmpty);
    expect(find.text('0 ngày học'), findsOneWidget);
  });
}
