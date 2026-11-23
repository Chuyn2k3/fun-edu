import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/online/replace_data_dialog.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/link/account_summary.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/ui/theme/contrast.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../online/online_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryTokenStore store;
  late FakeIds ids;
  late AppDatabase db;
  late List<http.Request> requests;

  setUp(() {
    requests = [];
    store = MemoryTokenStore();
    ids = FakeIds();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  final localKid = const KidSummary(
    nickname: 'Na',
    avatar: 'chip',
    stars: 120,
    glyphs: 8,
    pages: 5,
    items: 2,
    badges: 1,
  );

  final accountSummary = const AccountSummary(
    hasData: true,
    kids: [
      KidSummary(
        nickname: 'Na',
        avatar: 'chip',
        stars: 540,
        glyphs: 18,
        pages: 16,
        items: 7,
        badges: 3,
      ),
      KidSummary(
        nickname: 'Bin',
        avatar: 'chip',
        stars: 30,
        glyphs: 2,
        pages: 0,
        items: 0,
        badges: 0,
      ),
    ],
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    Size size = const Size(375, 667),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    BuildContext? hostContext;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onlineConfigProvider.overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
          httpClientProvider.overrideWithValue(MockClient((req) async {
            requests.add(req);
            return fakeServer(req);
          })),
          tokenStoreProvider.overrideWithValue(store),
          identityProvidersProvider.overrideWithValue(ids),
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: Builder(builder: (ctx) {
                hostContext = ctx;
                return const SizedBox.shrink();
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    showReplaceDataDialog(
      hostContext!,
      local: [localKid],
      account: accountSummary,
      accountLabel: 'me@x.vn',
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dialog shows both sides with names and numbers', (tester) async {
    await pumpDialog(tester);

    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
    expect(find.text('Trên máy này (dùng thử)'), findsOneWidget);
    expect(find.text('Tài khoản me@x.vn'), findsOneWidget);

    expect(find.textContaining('120⭐'), findsOneWidget);
    expect(find.textContaining('540⭐'), findsOneWidget);
    expect(find.textContaining('Bin'), findsOneWidget);
    expect(find.textContaining('Nếu tiếp tục, dữ liệu trên máy này'), findsOneWidget);
  });

  testWidgets('cancel keeps guest data and signs out', (tester) async {
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
    );
    await pumpDialog(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('cancel-replace')));
    await tester.tap(find.byKey(const ValueKey('cancel-replace')));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản này đã có dữ liệu'), findsNothing);
    expect(store.session, isNull);
  });

  testWidgets('delete needs a second confirmation before confirming', (tester) async {
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
    );
    await pumpDialog(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('confirm-replace-danger')));
    await tester.tap(find.byKey(const ValueKey('confirm-replace-danger')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Xóa dữ liệu của Na trên máy này?'), findsOneWidget);

    // Cancel 2nd dialog
    await tester.tap(find.byKey(const ValueKey('cancel-second-delete')));
    await tester.pumpAndSettle();

    // Main dialog is still open
    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);

    // Tap danger button again and confirm
    await tester.ensureVisible(find.byKey(const ValueKey('confirm-replace-danger')));
    await tester.tap(find.byKey(const ValueKey('confirm-replace-danger')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('confirm-second-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản này đã có dữ liệu'), findsNothing);
  });

  testWidgets('tapping outside and back does not close', (tester) async {
    await pumpDialog(tester);

    // Tap outside (top left corner)
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);

    // System back
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản này đã có dữ liệu'), findsOneWidget);
  });

  testWidgets('phone stacks vertically', (tester) async {
    await pumpDialog(tester, size: const Size(375, 667));
    final localPhone = tester.getTopLeft(find.byKey(const ValueKey('local-data-box')));
    final accountPhone = tester.getTopLeft(find.byKey(const ValueKey('account-data-box')));
    expect(accountPhone.dy, greaterThan(localPhone.dy));
    expect(accountPhone.dx, equals(localPhone.dx));
  });

  testWidgets('tablet displays boxes side by side', (tester) async {
    await pumpDialog(tester, size: const Size(800, 1000));
    final localTablet = tester.getTopLeft(find.byKey(const ValueKey('local-data-box')));
    final accountTablet = tester.getTopLeft(find.byKey(const ValueKey('account-data-box')));
    expect(accountTablet.dy, equals(localTablet.dy));
    expect(accountTablet.dx, greaterThan(localTablet.dx));
  });

  testWidgets('danger and cancel buttons meet WCAG AA contrast ratio', (tester) async {
    expect(contrastRatio(Colors.white, AppColors.primary), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(AppColors.text, AppColors.card), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(AppColors.textMuted, AppColors.card), greaterThanOrEqualTo(4.5));
  });
}
