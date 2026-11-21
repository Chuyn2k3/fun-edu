import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/parent/screens/family_account_card.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'online_fakes.dart';

void main() {
  late List<http.Request> requests;
  late MemoryTokenStore store;
  late FakeIds ids;
  late AppDatabase db;

  setUp(() {
    requests = [];
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
          return fakeServer(req);
        })),
        tokenStoreProvider.overrideWithValue(store),
        identityProvidersProvider.overrideWithValue(ids),
        databaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: FamilyAccountCard())),
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('a build without a server shows nothing', (t) async {
    await pump(t, apiUrl: '');
    expect(find.text('Lưu tiến độ online'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('signed out: Google and Apple buttons, at least 48 tall', (t) async {
    await pump(t);
    expect(find.text('Lưu tiến độ online'), findsOneWidget);
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
