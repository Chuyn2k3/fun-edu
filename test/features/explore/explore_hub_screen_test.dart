import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/explore/explore_hub_screen.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:go_router/go_router.dart';

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1.0;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
}

Future<GoRouter> _pump(WidgetTester t, {double textScale = 1.0}) async {
  final router = GoRouter(initialLocation: '/kham-pha', routes: [
    GoRoute(path: '/', builder: (_, __) => const Text('home')),
    GoRoute(path: '/kham-pha', builder: (_, __) => const ExploreHubScreen()),
    GoRoute(
        path: '/subject/dia-ly', builder: (_, __) => const Text('bản đồ')),
  ]);
  addTearDown(router.dispose);
  await t.pumpWidget(ProviderScope(
    overrides: [geographyLevelIndexProvider.overrideWith((_) async => 3)],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  ));
  await t.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('geography island opens the geography map', (t) async {
    _setSize(t, 390, 844);
    await _pump(t);
    expect(find.text('Đảo Khám phá'), findsOneWidget);
    expect(find.text('4/9'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('island-dia-ly')));
    await t.pumpAndSettle();
    expect(find.text('bản đồ'), findsOneWidget);
  });

  for (final id in ['island-sinh-hoc', 'island-lich-su']) {
    testWidgets('$id says coming soon and stays put', (t) async {
      _setSize(t, 390, 844);
      final router = await _pump(t);
      await t.ensureVisible(find.byKey(ValueKey(id)));
      // Both locked cards say it; the toast adds a third.
      expect(find.text('Sắp có'), findsNWidgets(2));
      await t.tap(find.byKey(ValueKey(id)));
      await t.pump();
      expect(find.text('Sắp có'), findsNWidgets(3));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/kham-pha');
      await t.pump(const Duration(seconds: 5));
    });
  }

  for (final (size, scale) in const [
    (Size(375, 667), 2.0),
    (Size(390, 844), 1.0),
    (Size(820, 1180), 1.0),
    (Size(1180, 820), 1.0),
  ]) {
    testWidgets('lays out cleanly at $size, text x$scale', (t) async {
      _setSize(t, size.width, size.height);
      await _pump(t, textScale: scale);
      expect(t.takeException(), isNull);
    });
  }
}
