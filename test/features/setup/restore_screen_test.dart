import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/setup/restore_screen.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/link/link_controller.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/ui/widgets/primary_button.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../online/online_fakes.dart';
import '../setup_helpers.dart';

Future<void> _toConsent(WidgetTester t) async {
  await t.tap(find.text('Tôi là ba mẹ'));
  await settle(t);
  await passGate(t);
}

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
    String apiUrl = 'https://api.test',
    Size size = const Size(375, 667),
  }) async {
    setSize(t, size.width, size.height);
    appRouter.go('/');
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          onlineConfigProvider.overrideWithValue(OnlineConfig(apiUrl: apiUrl)),
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

  testWidgets('choose step buttons are big enough on phone and tablet',
      (t) async {
    for (final size in const [Size(375, 667), Size(1024, 1366)]) {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await pumpOnlineApp(t, size: size);

      await _toConsent(t);
      await t.tap(find.text('Tôi đồng ý'));
      await t.pump();
      await t.tap(find.text('Tiếp tục'));
      await t.pumpAndSettle();

      expect(find.text('Lưu tiến độ của bé'), findsOneWidget);
      final googleBtn =
          t.getSize(find.widgetWithText(PrimaryButton, 'Đăng nhập với Google'));
      expect(googleBtn.height, greaterThanOrEqualTo(64));

      final guestBtn = t.getSize(
          find.widgetWithText(TextButton, 'Dùng thử không cần tài khoản'));
      expect(guestBtn.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('no server url hides the choose step', (t) async {
    await pumpOnlineApp(t, apiUrl: '');
    await _toConsent(t);
    await t.tap(find.text('Tôi đồng ý'));
    await t.pump();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();

    expect(find.text('Lưu tiến độ của bé'), findsNothing);
    expect(find.text('Tạo hồ sơ cho bé'), findsOneWidget);
  });

  testWidgets('guest path is unchanged and makes zero requests', (t) async {
    await pumpOnlineApp(t);
    await _toConsent(t);
    await t.tap(find.text('Tôi đồng ý'));
    await t.pump();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();

    expect(find.text('Lưu tiến độ của bé'), findsOneWidget);
    await t.tap(find.text('Dùng thử không cần tài khoản'));
    await t.pumpAndSettle();

    expect(find.text('Tạo hồ sơ cho bé'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Na');
    await t.pump();
    await t.tap(find.byKey(const ValueKey('avatar-1')));
    await t.pump();
    await t.ensureVisible(find.text('5'));
    await t.tap(find.text('5'));
    await t.pump();
    await t.ensureVisible(find.text('Xong'));
    await t.tap(find.text('Xong'));
    await settle(t);

    expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('sign in to empty account creates profile then placement',
      (t) async {
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'expiresIn': 900,
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {'hasData': false, 'kids': []},
        });
      }
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({
          'linked': true,
          'account': {'hasData': false, 'kids': []},
        });
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t);
    await _toConsent(t);
    await t.tap(find.text('Tôi đồng ý'));
    await t.pump();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();

    await t.tap(find.text('Đăng nhập với Google'));
    await t.pumpAndSettle();

    expect(find.text('Lưu dữ liệu của bé lên máy chủ?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('consent-online')));
    await settle(t);

    expect(find.text('Tạo hồ sơ cho bé'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Bé Na');
    await t.pump();
    await t.tap(find.byKey(const ValueKey('avatar-1')));
    await t.pump();
    await t.ensureVisible(find.text('5'));
    await t.tap(find.text('5'));
    await t.pump();
    await t.ensureVisible(find.text('Xong'));
    await t.tap(find.text('Xong'));
    await settle(t);

    expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
    expect(requests.any((r) => r.url.path == '/api/v1/sync/link'), isTrue);
  });

  testWidgets('sign in to account with placed kids goes home', (t) async {
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'expiresIn': 900,
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {
            'hasData': true,
            'kids': [
              {
                'id': 'kid-1',
                'nickname': 'Bé Na',
                'avatar': kidAvatars.first,
                'age': 5,
                'stars': 120,
                'glyphs': 8,
                'notebookPages': 5,
                'items': 2,
                'badges': 1,
              }
            ],
          },
        });
      }
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({
          'linked': true,
          'account': {
            'hasData': true,
            'kids': [
              {'id': 'kid-1', 'nickname': 'Bé Na'}
            ],
          },
        });
      }
      if (req.url.path == '/api/v1/sync') {
        return jsonResponse({
          'version': 3,
          'records': [
            {
              'key': 'kid:kid-1',
              'kind': 'kid',
              'payload': {
                'uuid': 'kid-1',
                'nickname': 'Bé Na',
                'avatar': kidAvatars.first,
                'age': 5,
                'createdAt': 1000,
              },
              'version': 1,
            },
            {
              'key': 'level:kid-1:viet',
              'kind': 'level',
              'payload': {'level': 1, 'placedAt': 1000},
              'version': 2,
            },
            {
              'key': 'level:kid-1:toan',
              'kind': 'level',
              'payload': {'level': 1, 'placedAt': 1000},
              'version': 3,
            },
          ],
          'conflicts': [],
          'hasMore': false,
        });
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t);
    await _toConsent(t);
    await t.tap(find.text('Tôi đồng ý'));
    await t.pump();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();

    await t.tap(find.text('Đăng nhập với Google'));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('consent-online')));
    await settle(t);

    expect(find.text('Tạo hồ sơ cho bé'), findsNothing);
    expect(find.text('Chào bé! Mình là Chíp Chíp'), findsNothing);
    expect(find.textContaining('Bé Na'), findsOneWidget);
  });

  testWidgets('sign-in failure stays on choose step', (t) async {
    handler = (_) => throw const SocketException('offline');

    await pumpOnlineApp(t);
    await _toConsent(t);
    await t.tap(find.text('Tôi đồng ý'));
    await t.pump();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();

    await t.tap(find.text('Đăng nhập với Google'));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('consent-online')));
    await settle(t);

    expect(find.text('Lưu tiến độ của bé'), findsOneWidget);
    expect(find.text('Dùng thử không cần tài khoản'), findsOneWidget);
    expect(find.textContaining('Không kết nối được máy chủ'), findsOneWidget);
  });

  testWidgets('restore failure shows retry button and retries successfully',
      (t) async {
    var syncShouldFail = true;
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'expiresIn': 900,
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {
            'hasData': true,
            'kids': [
              {'id': 'kid-1', 'nickname': 'Bé Na'}
            ],
          },
        });
      }
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({
          'linked': true,
          'account': {
            'hasData': true,
            'kids': [
              {'id': 'kid-1', 'nickname': 'Bé Na'}
            ],
          },
        });
      }
      if (req.url.path == '/api/v1/sync') {
        if (syncShouldFail) {
          return http.Response('server error', 500);
        }
        return jsonResponse({
          'version': 3,
          'records': [
            {
              'key': 'kid:kid-1',
              'kind': 'kid',
              'payload': {
                'uuid': 'kid-1',
                'nickname': 'Bé Na',
                'avatar': kidAvatars.first,
                'age': 5,
                'createdAt': 1000,
              },
              'version': 1,
            },
            {
              'key': 'level:kid-1:viet',
              'kind': 'level',
              'payload': {'level': 1, 'placedAt': 1000},
              'version': 2,
            },
            {
              'key': 'level:kid-1:toan',
              'kind': 'level',
              'payload': {'level': 1, 'placedAt': 1000},
              'version': 3,
            },
          ],
          'conflicts': [],
          'hasMore': false,
        });
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t);
    await _toConsent(t);
    await t.tap(find.text('Tôi đồng ý'));
    await t.pump();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();

    await t.tap(find.text('Đăng nhập với Google'));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('consent-online')));
    await settle(t);

    expect(find.text('Chưa tải được, ba mẹ kiểm tra mạng nhé'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-restore')), findsOneWidget);
    expect(find.text('Tạo hồ sơ cho bé'), findsNothing);

    // Now fix sync and retry
    syncShouldFail = false;
    await t.tap(find.byKey(const ValueKey('retry-restore')));
    await settle(t);

    expect(find.textContaining('Bé Na'), findsOneWidget);
  });

  testWidgets('restore resumes after restart when restorePending flag exists',
      (t) async {
    final repo = KidRepository(db);
    await repo.setSetting(restorePendingKey, 'true');
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      linked: true,
    );

    var syncPulled = false;
    handler = (req) {
      if (req.url.path == '/api/v1/sync') {
        if (!syncPulled) {
          syncPulled = true;
          return jsonResponse({
            'version': 3,
            'records': [
              {
                'key': 'kid:kid-1',
                'kind': 'kid',
                'payload': {
                  'uuid': 'kid-1',
                  'nickname': 'Bé Na',
                  'avatar': kidAvatars.first,
                  'age': 5,
                  'createdAt': 1000,
                },
                'version': 1,
              },
              {
                'key': 'level:kid-1:viet',
                'kind': 'level',
                'payload': {'level': 1, 'placedAt': 1000},
                'version': 2,
              },
              {
                'key': 'level:kid-1:toan',
                'kind': 'level',
                'payload': {'level': 1, 'placedAt': 1000},
                'version': 3,
              },
            ],
            'conflicts': [],
            'hasMore': false,
          });
        }
        return jsonResponse(
            {'version': 3, 'records': [], 'conflicts': [], 'hasMore': false});
      }
      return fakeServer(req);
    };

    await pumpOnlineApp(t);
    await settle(t);
    await settle(t);
    expect(find.text('Dành cho ba mẹ'), findsNothing);
    expect(find.textContaining('Bé Na'), findsOneWidget);

    final container = ProviderScope.containerOf(t.element(find.byType(App)));
    container.read(syncControllerProvider.notifier).stop();
  });

  testWidgets('failed replace keeps the restore screen', (t) async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      linked: false,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link' && req.method == 'POST') {
        return http.Response('server error', 500);
      }
      return fakeServer(req);
    };
    await pumpOnlineApp(t);
    final c = ProviderScope.containerOf(t.element(find.byType(App)));
    await c.read(linkControllerProvider.notifier).confirmReplace();
    await settle(t);

    expect(c.read(restoringProvider), isTrue);
    expect(find.byType(RestoreScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-restore')), findsOneWidget);
    expect(find.text('Tạo hồ sơ cho bé'), findsNothing);
  });

  testWidgets('failure after wipe keeps the restore screen', (t) async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      linked: false,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link' && req.method == 'POST') {
        return jsonResponse({'linked': true});
      }
      if (req.url.path == '/api/v1/sync') {
        return http.Response('server error', 500);
      }
      return fakeServer(req);
    };
    await pumpOnlineApp(t);
    final c = ProviderScope.containerOf(t.element(find.byType(App)));
    await c.read(linkControllerProvider.notifier).confirmReplace();
    await settle(t);

    expect(c.read(restoringProvider), isTrue);
    expect(find.byType(RestoreScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-restore')), findsOneWidget);
    expect(await KidRepository(db).setting(restorePendingKey), 'pull');
  });

  testWidgets('restore with ended session returns to choose step', (t) async {
    final repo = KidRepository(db);
    await repo.setSetting(restorePendingKey, 'fresh');
    store.session = const StoredSession(
      accessToken: 'expired',
      refreshToken: 'bad',
      familyId: 'fam-1',
      provider: 'google',
      linked: false,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/auth/refresh') {
        return jsonResponse({'error': 'unauthorized'}, 401);
      }
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({'error': 'unauthorized'}, 401);
      }
      return fakeServer(req);
    };
    await pumpOnlineApp(t);
    await settle(t);
    await settle(t);

    expect(find.text('Lưu tiến độ của bé'), findsOneWidget);
    expect(find.text('Phiên đăng nhập đã hết, ba mẹ đăng nhập lại nhé'),
        findsOneWidget);
  });

  testWidgets('restore with ended session after wipe asks to sign in again',
      (t) async {
    final repo = KidRepository(db);
    await repo.setSetting(restorePendingKey, 'pull');
    store.session = const StoredSession(
      accessToken: 'expired',
      refreshToken: 'bad',
      familyId: 'fam-1',
      provider: 'google',
      linked: true,
    );
    handler = (req) {
      if (req.url.path == '/api/v1/auth/refresh') {
        return jsonResponse({'error': 'unauthorized'}, 401);
      }
      if (req.url.path == '/api/v1/sync') {
        return jsonResponse({'error': 'unauthorized'}, 401);
      }
      return fakeServer(req);
    };
    await pumpOnlineApp(t);
    await settle(t);
    await settle(t);

    expect(find.byType(RestoreScreen), findsOneWidget);
    expect(find.text('Đăng nhập lại'), findsOneWidget);
    expect(find.byKey(const ValueKey('retry-restore')), findsNothing);
    expect(await KidRepository(db).setting(restorePendingKey), 'pull');
  });
}
