import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/ui/widgets/subject_card.dart';

void main() {
  Widget card({VoidCallback? onTap}) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: SubjectCard(
                subject: Subject.toan,
                imagePath: AppImages.icToan,
                title: 'Toán',
                subtitle: 'Đếm, cộng trừ',
                done: 1,
                total: 9,
                onTap: onTap,
              ),
            ),
          ),
        ),
      );

  SemanticsData data(WidgetTester t) =>
      t.getSemantics(find.byType(SubjectCard)).getSemanticsData();

  testWidgets('an available SubjectCard is its own enabled button node',
      (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(card(onTap: () {}));
    final d = data(t);
    expect(d.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(d.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    expect(d.hasFlag(SemanticsFlag.isEnabled), isTrue);
    expect(d.label, contains('Toán'));
    handle.dispose();
  });

  testWidgets('a "Sắp có" SubjectCard stays a button, marked disabled',
      (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(card());
    final d = data(t);
    expect(d.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(d.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    expect(d.hasFlag(SemanticsFlag.isEnabled), isFalse);
    expect(d.label, contains('Toán'));
    handle.dispose();
  });
}
