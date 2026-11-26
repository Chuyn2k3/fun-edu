import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/explore/explore_hub_screen.dart';
import 'package:funedu/explore/explore_flags.dart';
import 'package:funedu/explore/explore_island.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:go_router/go_router.dart';

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1.0;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
}

/// Every asset loads except the island pictures.
class _BrokenIslands extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('island-')) throw FlutterError('broken $key');
    return rootBundle.load(key);
  }
}

final _bio = ExploreIsland(
    id: 'sinh-hoc',
    prefix: 'bio',
    name: 'Sinh học',
    mapTitle: 'Khám phá sự sống',
    subject: Subject.sinhHoc,
    islandImage: AppImages.islandSinhHoc,
    levels: geographyIsland.levels,
    ready: false);

Future<GoRouter> _pump(WidgetTester t,
    {double textScale = 1.0,
    AssetBundle? bundle,
    List<Override> extra = const []}) async {
  final router = GoRouter(initialLocation: '/kham-pha', routes: [
    GoRoute(path: '/', builder: (_, __) => const Text('home')),
    GoRoute(
        path: '/kham-pha',
        builder: (_, __) => bundle == null
            ? const ExploreHubScreen()
            : DefaultAssetBundle(
                bundle: bundle, child: const ExploreHubScreen())),
    GoRoute(
        path: '/subject/dia-ly', builder: (_, __) => const Text('bản đồ')),
    GoRoute(
        path: '/subject/sinh-hoc',
        builder: (_, __) => const Text('bản đồ sinh học')),
  ]);
  addTearDown(router.dispose);
  await t.pumpWidget(ProviderScope(
    overrides: [
      exploreLevelIndexProvider.overrideWith(
          (ref, id) async => id == 'dia-ly' ? 3 : 1),
      exploreIslandsProvider.overrideWithValue([geographyIsland, _bio]),
      ...extra,
    ],
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

  testWidgets('a ready biology island shows its level and opens its map',
      (t) async {
    _setSize(t, 390, 844);
    await _pump(t, extra: [
      exploreReadyProvider.overrideWith((ref, id) => true),
    ]);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('island-sinh-hoc')),
            matching: find.text('2/9')),
        findsOneWidget);
    await t.tap(find.byKey(const ValueKey('island-sinh-hoc')));
    await t.pumpAndSettle();
    expect(find.text('bản đồ sinh học'), findsOneWidget);
  });

  testWidgets('a broken island picture shows the island name', (t) async {
    _setSize(t, 390, 844);
    await _pump(t, bundle: _BrokenIslands());
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('island-sinh-hoc')),
            matching: find.text('Sinh học')),
        findsNWidgets(2));
    expect(t.takeException(), isNull);
  });

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
