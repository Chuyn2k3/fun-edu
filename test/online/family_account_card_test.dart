import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/online/link_warning_listener.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:funedu/parent/screens/family_account_card.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'online_fakes.dart';

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;
  late MemoryTokenStore store;
  late FakeIds ids;
  late AppDatabase db;

  setUp(() {
    requests = [];
    handler = fakeServer;
    store = MemoryTokenStore();
    ids = FakeIds();
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester t, {String apiUrl = 'https://api.test'}) async {
    await t.pumpWidget(ProviderScope(
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
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LinkWarningListener(child: FamilyAccountCard()),
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('a build without a server shows nothing', (t) async {
    await pump(t, apiUrl: '');
    expect(find.text('Lưu tiến độ online'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('signed out: Google and Apple buttons, guest hint shows', (t) async {
    await pump(t);
    expect(find.text('Lưu tiến độ online'), findsOneWidget);
    expect(find.text('Đang dùng thử: dữ liệu chỉ ở trên máy này'), findsOneWidget);
    for (final k in ['sign-in-google', 'sign-in-apple']) {
      expect(t.getSize(find.byKey(ValueKey(k))).height, greaterThanOrEqualTo(48));
    }
    expect(requests, isEmpty);
  });

  testWidgets('no Apple button where Apple sign-in is unavailable', (t) async {
    ids.apple_ = false;
    await pump(t);
    expect(find.byKey(const ValueKey('sign-in-apple')), findsNothing);
  });

  testWidgets('declining consent sends nothing', (t) async {
    await pump(t);
    await t.tap(find.byKey(const ValueKey('sign-in-google')));
    await t.pumpAndSettle();
    expect(find.text('Lưu dữ liệu của bé lên máy chủ?'), findsOneWidget);
    await t.tap(find.text('Để sau'));
    await t.pumpAndSettle();
    expect(requests, isEmpty);
    expect(store.session, isNull);
  });

  testWidgets('consent then Google sign-in shows the account and syncs', (t) async {
    await pump(t);
    await t.tap(find.byKey(const ValueKey('sign-in-google')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('consent-online')));
    await t.pumpAndSettle();

    expect(find.text('Đã đăng nhập: me@x.vn'), findsOneWidget);
    expect(store.session?.familyId, 'fam-1');
    await t.tap(find.byKey(const ValueKey('sync-now')));
    await t.pumpAndSettle();
    expect(requests.where((r) => r.url.path == '/api/v1/sync'), isNotEmpty);
    expect(find.textContaining('Đã lưu online lúc'), findsOneWidget);

    final c = ProviderScope.containerOf(t.element(find.byType(FamilyAccountCard)));
    c.read(syncControllerProvider.notifier).stop();
  });

  testWidgets('second tap while signing in is ignored', (t) async {
    await pump(t);
    // Tap sign-in-google
    await t.tap(find.byKey(const ValueKey('sign-in-google')));
    await t.pump(); // Start dialog

    // While consent dialog is open, tapping the underlying button is blocked or ignored
    expect(find.text('Lưu dữ liệu của bé lên máy chủ?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('consent-online')));
    await t.pumpAndSettle();

    expect(requests.where((r) => r.url.path == '/api/v1/auth/google'), hasLength(1));

    final c = ProviderScope.containerOf(t.element(find.byType(FamilyAccountCard)));
    c.read(syncControllerProvider.notifier).stop();
  });

  testWidgets('sign out shows updated message', (t) async {
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: true,
    );
    await pump(t);
    expect(find.text('Đã đăng nhập: me@x.vn'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('sign-out')));
    await t.pumpAndSettle();

    expect(find.text('Đã đăng xuất. Dữ liệu vẫn ở trên máy này'), findsOneWidget);
    expect(store.session, isNull);
  });

  testWidgets('signing in with existing account data on guest device shows replace warning dialog', (t) async {
    await KidRepository(db).addKid(nickname: 'Bé Na', avatar: kidAvatars.first, age: 5);

    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'familyId': 'fam-1',
          'device': {'linked': false},
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

    await pump(t);
    await t.tap(find.byKey(const ValueKey('sign-in-google')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('consent-online')));
    await t.pumpAndSettle();

    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
    expect(find.textContaining('Bé Na'), findsOneWidget);
    expect(find.textContaining('Bé Cloud'), findsOneWidget);
  });

  testWidgets('deleting the online account asks first, then signs out', (t) async {
    store.session = const StoredSession(
        accessToken: 'a1', refreshToken: 'r1', familyId: 'fam-1', provider: 'apple');
    await pump(t);
    expect(find.text('Đã đăng nhập: Apple'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('delete-account')));
    await t.pumpAndSettle();
    await t.tap(find.text('Giữ lại'));
    await t.pumpAndSettle();
    expect(requests.where((r) => r.method == 'DELETE'), isEmpty);

    await t.tap(find.byKey(const ValueKey('delete-account')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await t.pumpAndSettle();
    expect(requests.where((r) => r.method == 'DELETE'), hasLength(1));
    expect(store.session, isNull);
    expect(find.text('Lưu tiến độ online'), findsOneWidget);
  });
}
