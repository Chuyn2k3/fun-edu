import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/dev/gallery_screen.dart';
import 'package:funedu/ui/theme/app_theme.dart';
import 'package:funedu/ui/theme/contrast.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/ui/widgets/dotted_background.dart';
import 'package:funedu/ui/widgets/floating_nav_bar.dart';
import 'package:funedu/ui/widgets/nav_rail.dart';
import 'package:funedu/ui/widgets/primary_button.dart';
import 'package:funedu/ui/widgets/progress_ring.dart';
import 'package:flutter/material.dart';

Widget host(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('DottedBackground wraps its painter in a RepaintBoundary',
      (tester) async {
    await tester.pumpWidget(host(const DottedBackground(child: Text('x'))));
    final boundary = find.descendant(
      of: find.byType(DottedBackground),
      matching: find.byType(RepaintBoundary),
    );
    expect(boundary, findsAtLeastNWidgets(1));
    final paints = tester
        .widgetList<CustomPaint>(find.descendant(
          of: find.byType(DottedBackground),
          matching: find.byType(CustomPaint),
        ))
        .where((c) => c.painter != null);
    expect(paints, isNotEmpty);
    for (final c in paints) {
      expect(c.isComplex, isTrue);
      expect(c.willChange, isFalse);
    }
  });

  testWidgets('PrimaryButton is at least 64 tall and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(PrimaryButton(label: 'Bắt đầu', onPressed: () => taps++)));
    expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(64));
    await tester.tap(find.text('Bắt đầu'));
    expect(taps, 1);
  });

  testWidgets('disabled PrimaryButton ignores taps', (tester) async {
    await tester.pumpWidget(host(const PrimaryButton(label: 'Bắt đầu', onPressed: null)));
    await tester.tap(find.text('Bắt đầu'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(64));
  });

  testWidgets('ProgressRing shows done/total, total 0 is safe', (tester) async {
    await tester.pumpWidget(host(const ProgressRing(done: 6, total: 14, color: Colors.blue)));
    expect(find.text('6/14'), findsOneWidget);
    await tester.pumpWidget(host(const ProgressRing(done: 0, total: 0, color: Colors.blue)));
    expect(find.text('0/0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FloatingNavBar reports tapped index', (tester) async {
    int? picked;
    await tester.pumpWidget(host(FloatingNavBar(
      items: const [
        NavItem(icon: Icons.edit, label: 'Học'),
        NavItem(icon: Icons.star, label: 'Chơi'),
      ],
      selected: 0,
      onSelect: (i) => picked = i,
    )));
    await tester.tap(find.text('Chơi'));
    expect(picked, 1);
  });

  testWidgets('NavRail shows every item at least 80x80 and reports index',
      (tester) async {
    int? picked;
    await tester.pumpWidget(host(NavRail(
      items: const [
        NavItem(icon: Icons.edit, label: 'Học'),
        NavItem(icon: Icons.star, label: 'Chơi'),
        NavItem(icon: Icons.home, label: 'Nhà'),
      ],
      selected: 0,
      onSelect: (i) => picked = i,
    )));
    for (final label in ['Học', 'Chơi', 'Nhà']) {
      final size = tester.getSize(find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first);
      expect(size.width, greaterThanOrEqualTo(80));
      expect(size.height, greaterThanOrEqualTo(80));
    }
    await tester.tap(find.text('Chơi'));
    expect(picked, 1);
  });

  testWidgets('NavRail selected label meets 4.5:1 on its pill',
      (tester) async {
    await tester.pumpWidget(host(NavRail(
      items: const [
        NavItem(icon: Icons.edit, label: 'Học'),
        NavItem(icon: Icons.star, label: 'Chơi'),
      ],
      selected: 0,
      onSelect: (_) {},
    )));
    final label = tester.widget<Text>(find.text('Học'));
    final pill = tester
        .widgetList<Container>(find.ancestor(
            of: find.text('Học'), matching: find.byType(Container)))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.color != null)
        .color!;
    // The pill is translucent over the white rail.
    final fill = Color.alphaBlend(pill, AppColors.card);
    expect(contrastRatio(label.style!.color!, fill), greaterThanOrEqualTo(4.5));
  });

  testWidgets('GalleryScreen shows the NavRail on a tablet', (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const GalleryScreen()));
    expect(find.byType(NavRail), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GalleryScreen builds at 390x844 without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const GalleryScreen()));
    expect(tester.takeException(), isNull);
    expect(find.byType(GalleryScreen), findsOneWidget);
  });
}
