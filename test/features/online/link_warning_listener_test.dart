import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/link/account_summary.dart';
import 'package:funedu/online/link/link_controller.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:funedu/parent/screens/family_account_card.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../online/online_fakes.dart';
import '../setup_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;
  late MemoryTokenStore store;
  late FakeIds ids;
  late AppDatabase db;

  setUp(() {
    requests = [];
    store = MemoryTokenStore();
    ids = FakeIds();
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    handler = fakeServer;
  });

  Future<void> pumpOnlineApp(
    WidgetTester t, {
    String initialLocation = '/',
  }) async {
    setSize(t, 375, 667);
    appRouter.go(initialLocation);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          onlineConfigProvider
              .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
          httpClientProvider.overrideWithValue(MockClient((req) async {
            requests.add(req);
            return handler(req);
          })),
          tokenStoreProvider.overrideWithValue(store),
          identityProvidersProvider.overrideWithValue(ids),
          databaseProvider.overrideWithValue(db),
        ],
        child: const App(),
      ),
    );
    await settle(t);
  }

  testWidgets('warning at launch is shown on home', (t) async {
    final kidId = await KidRepository(db)
        .addKid(nickname: 'Bé Na', avatar: kidAvatars.first, age: 5);
    await placeKid(db, kidId);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: false,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({
          'linked': false,
          'account': {
            'hasData': true,
            'kids': [
              {'nickname': 'Bé Cloud', 'avatar': 'chip', 'stars': 50},
            ],
          },
        });
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t);

    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
  });

  testWidgets('warning waits while the kid is writing', (t) async {
    final kidId = await KidRepository(db)
        .addKid(nickname: 'Bé Na', avatar: kidAvatars.first, age: 5);
    await placeKid(db, kidId);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: false,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({
          'linked': false,
          'account': {
            'hasData': true,
            'kids': [
              {'nickname': 'Bé Cloud', 'avatar': 'chip', 'stars': 50},
            ],
          },
        });
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t, initialLocation: '/trace/chu-a');

    // While on /trace/chu-a, no warning dialog should appear
    expect(find.text('Tài khoản này đã có dữ liệu'), findsNothing);

    // Navigate to home screen
    appRouter.go('/');
    await settle(t);

    // The dialog should now appear
    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
  });

  testWidgets('warning after link_required from sync', (t) async {
    final kidId = await KidRepository(db)
        .addKid(nickname: 'Bé Na', avatar: kidAvatars.first, age: 5);
    await placeKid(db, kidId);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: true,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/sync') {
        return jsonResponse({'error': 'link_required'}, 409);
      }
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({
          'linked': false,
          'account': {
            'hasData': true,
            'kids': [
              {'nickname': 'Bé Cloud', 'avatar': 'chip', 'stars': 50},
            ],
          },
        });
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t);

    final c = ProviderScope.containerOf(t.element(find.byType(App)));
    await c.read(syncControllerProvider.notifier).syncNow();
    await settle(t);

    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
    c.read(syncControllerProvider.notifier).stop();
  });

  testWidgets('warning shown once', (t) async {
    final kidId = await KidRepository(db)
        .addKid(nickname: 'Bé Na', avatar: kidAvatars.first, age: 5);
    await placeKid(db, kidId);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: false,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({
          'linked': false,
          'account': {
            'hasData': true,
            'kids': [
              {'nickname': 'Bé Cloud', 'avatar': 'chip', 'stars': 50},
            ],
          },
        });
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t);
    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);

    final c = ProviderScope.containerOf(t.element(find.byType(App)));
    await c.read(linkControllerProvider.notifier).resumeIfPending();
    await settle(t);

    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
  });

  testWidgets('card offers to reopen the warning', (t) async {
    final kidId = await KidRepository(db)
        .addKid(nickname: 'Bé Na', avatar: kidAvatars.first, age: 5);
    await placeKid(db, kidId);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: false,
    );

    const account = AccountSummary(
      hasData: true,
      kids: [KidSummary(nickname: 'Bé Cloud', avatar: 'chip', stars: 50)],
    );

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          onlineConfigProvider
              .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
          httpClientProvider
              .overrideWithValue(MockClient((req) async => fakeServer(req))),
          tokenStoreProvider.overrideWithValue(store),
          identityProvidersProvider.overrideWithValue(ids),
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: FamilyAccountCard()),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();

    final c =
        ProviderScope.containerOf(t.element(find.byType(FamilyAccountCard)));
    await c
        .read(linkControllerProvider.notifier)
        .afterSignIn(const SignInResult(linked: false, account: account));
    await t.pumpAndSettle();

    expect(find.text('Chưa lưu online: cần ba mẹ chọn dữ liệu'), findsOneWidget);
    expect(find.text('Xem'), findsOneWidget);

    await t.tap(find.text('Xem'));
    await t.pumpAndSettle();

    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
  });
}
