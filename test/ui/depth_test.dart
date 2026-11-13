import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/app_theme.dart';
import 'package:funedu/ui/theme/depth.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/ui/widgets/app_card.dart';
import 'package:funedu/ui/widgets/floating_nav_bar.dart';
import 'package:funedu/ui/widgets/info_pill.dart';
import 'package:funedu/ui/widgets/pressable.dart';
import 'package:funedu/ui/widgets/speech_bubble.dart';
import 'package:funedu/ui/widgets/subject_card.dart';

Widget host(Widget child, {double? width}) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );

double lipOf(BoxDecoration d) => (d.border! as Border).bottom.width;

BoxDecoration outerDecoration(WidgetTester tester, Finder f) {
  final box = tester
      .widgetList<DecoratedBox>(find.descendant(
        of: f,
        matching: find.byType(DecoratedBox),
      ))
      .map((b) => b.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.gradient != null);
  return box;
}

void main() {
  test(
      'raisedDecoration has a gradient, a 5px tinted bottom lip and two shadows',
      () {
    final d = raisedDecoration(
      accent: Subject.viet.color,
      tint: Subject.viet.tint,
    );
    final g = d.gradient! as LinearGradient;
    expect(g.begin, Alignment.topCenter);
    expect(g.end, Alignment.bottomCenter);
    expect(g.colors.first, AppColors.card);
    expect(g.colors.last, Color.lerp(AppColors.card, Subject.viet.tint, 0.9));
    final border = d.border! as Border;
    expect(border.bottom.width, 5);
    expect(border.bottom.color, Subject.viet.color.withOpacity(0.28));
    expect(border.top, BorderSide.none);
    expect(d.boxShadow, hasLength(2));
    expect(d.boxShadow![0].color, Subject.viet.color.withOpacity(0.16));
    expect(d.boxShadow![0].blurRadius, 22);
    expect(d.boxShadow![0].offset, const Offset(0, 12));
    expect(d.boxShadow![1].color, const Color(0x14503C28));
    expect(d.boxShadow![1].blurRadius, 3);
    expect(d.boxShadow![1].offset, const Offset(0, 1));
    expect(d.borderRadius, BorderRadius.circular(AppRadii.card));
  });

  test('pressed lowers the lip to 2px and tightens the shadow', () {
    final d = raisedDecoration(pressed: true);
    expect(lipOf(d), 2);
    expect(d.boxShadow![0].blurRadius, 12);
    expect(d.boxShadow![0].offset, const Offset(0, 5));
    expect(d.boxShadow![1].blurRadius, 3);
  });

  testWidgets('shared widgets use raisedDecoration', (tester) async {
    final cases = <String, Widget>{
      'SubjectCard': SubjectCard(
        subject: Subject.viet,
        imagePath: AppImages.icStar,
        title: 'Viết',
        subtitle: 'x',
        onTap: () {},
      ),
      'AppCard': const AppCard(child: Text('x')),
      'InfoPill': const InfoPill(leading: SizedBox(), label: '3'),
      'SpeechBubble': const SpeechBubble(text: 'x'),
      'FloatingNavBar': FloatingNavBar(
        items: const [NavItem(icon: Icons.home, label: 'a')],
        selected: 0,
        onSelect: (_) {},
      ),
    };
    for (final e in cases.entries) {
      await tester.pumpWidget(host(e.value, width: 300));
      final d = outerDecoration(tester, find.byType(e.value.runtimeType));
      expect(d.gradient, isNotNull, reason: e.key);
      expect(lipOf(d), 5, reason: e.key);
    }
  });

  testWidgets('Pressable moves its child 3px while pressed and taps once',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(Pressable(
      onTap: () => taps++,
      builder: (pressed) => SizedBox(
        key: const ValueKey('c'),
        width: 100,
        height: 60,
        child: Text(pressed ? 'down' : 'up'),
      ),
    )));
    final before = tester.getTopLeft(find.byKey(const ValueKey('c')));
    final g = await tester
        .startGesture(tester.getCenter(find.byKey(const ValueKey('c'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.byKey(const ValueKey('c'))) - before,
        const Offset(0, 3));
    expect(find.text('down'), findsOneWidget);
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    expect(tester.getTopLeft(find.byKey(const ValueKey('c'))), before);

    final g2 = await tester
        .startGesture(tester.getCenter(find.byKey(const ValueKey('c'))));
    await tester.pump();
    await g2.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    expect(tester.getTopLeft(find.byKey(const ValueKey('c'))), before);
  });

  testWidgets('raised card grows with text scale 2.0 without overflow',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: SubjectCard(
                subject: Subject.toan,
                imagePath: AppImages.icStar,
                title: 'Toán',
                subtitle: 'Đếm và so sánh',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final d = outerDecoration(tester, find.byType(SubjectCard));
    expect(lipOf(d), 5);
  });
}
