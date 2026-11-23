import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/collection/showcase_editor.dart';
import 'package:funedu/features/collection/showcase_screen.dart';
import 'package:funedu/game/data/badges.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/online/friends/showcase.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';

class _FakeShowcaseApi implements ShowcaseApi {
  ShowcaseData? showcaseData;
  final List<String> reactionsSent = [];
  bool throwOnGet = false;

  @override
  Future<ShowcaseData?> getShowcase(String familyId, String kidUuid) async {
    if (throwOnGet) throw Exception('not_found');
    return showcaseData;
  }

  @override
  Future<void> react(String familyId, String kidUuid, String kind) async {
    reactionsSent.add(kind);
  }

  @override
  Future<void> putShowcase(String kidUuid, Map<String, dynamic> payload) async {}
}

class _FakeGameRepository extends Fake implements GameRepository {
  @override
  Future<Set<GameBadge>> badges([int? targetKidId]) async {
    return {
      GameBadge.speedKing,
      GameBadge.scholar,
      GameBadge.chipBuddy,
    };
  }

  @override
  Future<Set<String>> newGarageItems() async => {};

  @override
  Future<({int races, int wins})> overallStats([int? targetKidId]) async {
    return (races: 10, wins: 5);
  }
}

class _FakeKidRepository extends Fake implements KidRepository {
  final Map<String, String> settings = {};

  @override
  Future<String?> setting(String key) async => settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<List<KidProfile>> kids() async => [
        KidProfile(
          id: 1,
          nickname: 'Bé Na',
          avatar: kidAvatars[0],
          age: 5,
          createdAt: DateTime.now(),
          uuid: 'kid-uuid-1',
          updatedAt: DateTime.now(),
        ),
      ];
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShowcaseScreen', () {
    testWidgets('friend showcase shows learning only when shared', (tester) async {
      _setSize(tester, const Size(400, 800));

      const withoutLearning = ShowcaseData(
        nickname: 'Bạn Bo',
        avatar: 'assets/avatars/avatar_2.png',
        rocket: 'rocket_orange',
        trail: 'flame',
        learning: null,
      );

      await tester.pumpWidget(_wrap(
        const ShowcaseScreen(initialData: withoutLearning),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bạn Bo'), findsOneWidget);
      expect(find.text('Thành tích đua'), findsOneWidget);
      expect(find.text('Tiến độ học tập'), findsNothing);

      const withLearning = ShowcaseData(
        nickname: 'Bạn Bo',
        avatar: 'assets/avatars/avatar_2.png',
        rocket: 'rocket_orange',
        trail: 'flame',
        learning: ShowcaseLearning(glyphs: 15, lessons: 8, stars: 25),
      );

      await tester.pumpWidget(_wrap(
        const ShowcaseScreen(initialData: withLearning),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tiến độ học tập'), findsOneWidget);
      expect(find.text('Chữ thuộc'), findsOneWidget);
      expect(find.text('Bài xong'), findsOneWidget);
      expect(find.text('Ngôi sao'), findsOneWidget);
    });

    testWidgets('reaction button lights and counts once', (tester) async {
      _setSize(tester, const Size(400, 800));
      final fakeApi = _FakeShowcaseApi();

      const initialData = ShowcaseData(
        nickname: 'Bạn Bo',
        avatar: 'assets/avatars/avatar_2.png',
        rocket: 'rocket_orange',
        trail: 'flame',
        reactions: {'clap': 0, 'heart': 2, 'star': 5},
        mine: {'heart'},
      );

      await tester.pumpWidget(_wrap(
        const ShowcaseScreen(
          familyId: 'fam-2',
          kidUuid: 'kid-2',
          initialData: initialData,
        ),
        overrides: [
          showcaseApiProvider.overrideWithValue(fakeApi),
        ],
      ));
      await tester.pumpAndSettle();

      // Initially clap has count 0
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reaction-clap')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reaction-heart')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reaction-star')),
          matching: find.text('5'),
        ),
        findsOneWidget,
      );

      // Tap clap button
      await tester.tap(find.byKey(const ValueKey('reaction-clap')));
      await tester.pumpAndSettle();

      // Count for clap should optimistically increment to 1
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reaction-clap')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(fakeApi.reactionsSent, ['clap']);

      // Tapping again does not increment
      await tester.tap(find.byKey(const ValueKey('reaction-clap')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('reaction-clap')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(fakeApi.reactionsSent.length, 1);
    });

    testWidgets('shows closed showcase message on error', (tester) async {
      _setSize(tester, const Size(400, 800));
      final fakeApi = _FakeShowcaseApi()..throwOnGet = true;

      await tester.pumpWidget(_wrap(
        const ShowcaseScreen(
          familyId: 'fam-closed',
          kidUuid: 'kid-closed',
        ),
        overrides: [
          showcaseApiProvider.overrideWithValue(fakeApi),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tủ khoe đang đóng'), findsOneWidget);
    });

    testWidgets('no overflow on 320x568 and tablet 1024x768', (tester) async {
      const data = ShowcaseData(
        nickname: 'Bé Na Siêu Nhân',
        avatar: 'assets/avatars/avatar_2.png',
        rocket: 'rocket_orange',
        trail: 'flame',
        pinned: ['speed_king', 'scholar'],
        learning: ShowcaseLearning(glyphs: 10, lessons: 5, stars: 15),
      );

      // Small phone 320x568
      _setSize(tester, const Size(320, 568));
      await tester.pumpWidget(_wrap(
        const ShowcaseScreen(initialData: data),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tablet 1024x768
      _setSize(tester, const Size(1024, 768));
      await tester.pumpWidget(_wrap(
        const ShowcaseScreen(initialData: data),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('ShowcaseEditor', () {
    testWidgets('own showcase editor pins at most three and saves', (tester) async {
      _setSize(tester, const Size(400, 800));
      final fakeKidRepo = _FakeKidRepository();
      final fakeGameRepo = _FakeGameRepository();

      await tester.pumpWidget(_wrap(
        const ShowcaseEditor(
          kidId: 1,
          initialPinned: ['speed_king', 'scholar'],
        ),
        overrides: [
          kidRepositoryProvider.overrideWithValue(fakeKidRepo),
          gameRepositoryProvider.overrideWith((ref) => Future.value(fakeGameRepo)),
          ownedBadgesProvider.overrideWith((ref) => Future.value({
            GameBadge.speedKing,
            GameBadge.scholar,
            GameBadge.chipBuddy,
          })),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Đã chọn 2/3 món'), findsOneWidget);
      expect(find.byKey(const ValueKey('pinned-slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('pinned-slot-1')), findsOneWidget);

      // Tap 3rd item in grid to pin it
      final thirdItem = find.byKey(const ValueKey('showcase-item-chip_buddy'));
      expect(thirdItem, findsOneWidget);
      await tester.tap(thirdItem);
      await tester.pumpAndSettle();
      expect(find.text('Đã chọn 3/3 món'), findsOneWidget);

      // Try tapping another item when already 3 pinned - should stay 3
      final anotherItem = find.byKey(const ValueKey('showcase-item-sticker_rare_rocket_chip'));
      if (anotherItem.evaluate().isNotEmpty) {
        await tester.tap(anotherItem);
        await tester.pumpAndSettle();
        expect(find.text('Đã chọn 3/3 món'), findsOneWidget);
      }

      // Tap pinned slot to unpin
      await tester.tap(find.byKey(const ValueKey('pinned-slot-0')));
      await tester.pumpAndSettle();
      expect(find.text('Đã chọn 2/3 món'), findsOneWidget);

      // Tap Save button
      await tester.tap(find.byKey(const ValueKey('showcase-save-button')));
      await tester.pumpAndSettle();

      expect(fakeKidRepo.settings[showcasePinnedKey(1)], isNotNull);
    });

    testWidgets('ShowcaseEditor no overflow on 320x568 and tablet 1024x768', (tester) async {
      final fakeKidRepo = _FakeKidRepository();
      final fakeGameRepo = _FakeGameRepository();

      // Phone 320x568
      _setSize(tester, const Size(320, 568));
      await tester.pumpWidget(_wrap(
        const ShowcaseEditor(
          kidId: 1,
          initialPinned: ['speed_king'],
        ),
        overrides: [
          kidRepositoryProvider.overrideWithValue(fakeKidRepo),
          gameRepositoryProvider.overrideWith((ref) => Future.value(fakeGameRepo)),
          ownedBadgesProvider.overrideWith((ref) => Future.value({
            GameBadge.speedKing,
            GameBadge.scholar,
            GameBadge.chipBuddy,
          })),
        ],
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tablet 1024x768
      _setSize(tester, const Size(1024, 768));
      await tester.pumpWidget(_wrap(
        const ShowcaseEditor(
          kidId: 1,
          initialPinned: ['speed_king'],
        ),
        overrides: [
          kidRepositoryProvider.overrideWithValue(fakeKidRepo),
          gameRepositoryProvider.overrideWith((ref) => Future.value(fakeGameRepo)),
          ownedBadgesProvider.overrideWith((ref) => Future.value({
            GameBadge.speedKing,
            GameBadge.scholar,
            GameBadge.chipBuddy,
          })),
        ],
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
