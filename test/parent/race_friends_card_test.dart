import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/online/online_consent_dialog.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/friends/friends_controller.dart';
import 'package:funedu/online/friends/lobby_client.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/room_transport.dart';
import 'package:funedu/parent/parent_unlock.dart';
import 'package:funedu/parent/screens/parent_home.dart';
import 'package:funedu/parent/screens/privacy_screen.dart';
import 'package:funedu/parent/widgets/race_friends_card.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/setup_helpers.dart';
import '../online/online_fakes.dart';

class _NoopTransport implements RoomTransport {
  final _in = StreamController<Map<String, Object?>>.broadcast();

  @override
  Stream<Map<String, Object?>> get messages => _in.stream;

  @override
  void send(Map<String, Object?> message) {}

  @override
  Future<void> close() async {
    if (!_in.isClosed) await _in.close();
  }
}

void main() {
  late AppDatabase db;
  late MemoryTokenStore store;
  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;
  late DateTime fakeNow;
  late int na;
  late int bo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = MemoryTokenStore();
    requests = [];
    fakeNow = DateTime.utc(2026, 11, 23, 12, 0);
    handler = fakeServer;
    final kids = KidRepository(db);
    na = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    bo = await kids.addKid(nickname: 'Bo', avatar: kidAvatars[1], age: 6);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpCard(
    WidgetTester t, {
    int? kidId,
    bool signedIn = true,
    Size size = const Size(390, 844),
    VoidCallback? onSignInTap,
  }) async {
    setSize(t, size.width, size.height);
    if (signedIn) {
      store.session = const StoredSession(
        accessToken: 'a1',
        refreshToken: 'r1',
        familyId: 'fam-1',
        provider: 'google',
        email: 'me@x.vn',
        linked: true,
      );
    }
    await t.pumpWidget(ProviderScope(
      overrides: [
        onlineConfigProvider
            .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
        httpClientProvider.overrideWithValue(MockClient((req) async {
          requests.add(req);
          return handler(req);
        })),
        tokenStoreProvider.overrideWithValue(store),
        identityProvidersProvider.overrideWithValue(FakeIds()),
        databaseProvider.overrideWithValue(db),
        friendsClockProvider.overrideWithValue(() => fakeNow),
        lobbyConnectorProvider.overrideWithValue((_) async => _NoopTransport()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RaceFriendsCard(
              kidId: kidId ?? na,
              onSignInTap: onSignInTap,
            ),
          ),
        ),
      ),
    ));
    await settle(t);
  }

  Future<void> pumpParentSettings(
    WidgetTester t, {
    required Size size,
    bool signedIn = true,
  }) async {
    setSize(t, size.width, size.height);
    if (signedIn) {
      store.session = const StoredSession(
        accessToken: 'a1',
        refreshToken: 'r1',
        familyId: 'fam-1',
        provider: 'google',
        email: 'me@x.vn',
        linked: true,
      );
    }
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('trang chủ')),
        GoRoute(
          path: '/parent',
          builder: (_, __) => const ParentHome(focus: 'account'),
        ),
      ],
      initialLocation: '/parent',
    );
    await t.pumpWidget(ProviderScope(
      overrides: [
        onlineConfigProvider
            .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
        httpClientProvider.overrideWithValue(MockClient((req) async {
          requests.add(req);
          return handler(req);
        })),
        tokenStoreProvider.overrideWithValue(store),
        identityProvidersProvider.overrideWithValue(FakeIds()),
        databaseProvider.overrideWithValue(db),
        friendsClockProvider.overrideWithValue(() => fakeNow),
        lobbyConnectorProvider.overrideWithValue((_) async => _NoopTransport()),
        parentUnlockedUntilProvider
            .overrideWith((ref) => DateTime.now().add(parentUnlockDuration)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await settle(t);
  }

  testWidgets('guest state shows sign-in prompt and makes zero network calls',
      (t) async {
    var tappedSignIn = false;
    await pumpCard(
      t,
      signedIn: false,
      onSignInTap: () => tappedSignIn = true,
    );

    expect(find.text('Bạn đua của bé'), findsOneWidget);
    expect(find.textContaining('Ba mẹ cần đăng nhập'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-friend-code')), findsNothing);
    expect(find.byKey(const ValueKey('redeem-friend-code-input')), findsNothing);
    expect(requests, isEmpty);

    final goSignIn = find.byKey(const ValueKey('friends-go-sign-in'));
    expect(t.getSize(goSignIn).height, greaterThanOrEqualTo(48));
    await t.tap(goSignIn);
    await t.pump();
    expect(tappedSignIn, isTrue);
  });

  testWidgets('create code shows spaced code, expiry, and copies raw code',
      (t) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    handler = (req) {
      if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
        return jsonResponse([]);
      }
      if (req.url.path == '/api/v1/friends/code' && req.method == 'POST') {
        return jsonResponse({
          'code': 'AB23CD',
          'expiresAt':
              fakeNow.add(const Duration(minutes: 45)).toIso8601String(),
        });
      }
      return fakeServer(req);
    };

    await pumpCard(t);

    final createBtn = find.byKey(const ValueKey('create-friend-code'));
    expect(t.getSize(createBtn).height, greaterThanOrEqualTo(48));
    await t.tap(createBtn);
    await settle(t);

    expect(find.text('AB2 3CD'), findsOneWidget);
    expect(find.text('Hết hạn sau 45 phút'), findsOneWidget);

    final copyBtn = find.byKey(const ValueKey('copy-friend-code'));
    expect(t.getSize(copyBtn).height, greaterThanOrEqualTo(48));
    await t.tap(copyBtn);
    await settle(t);
    expect(copiedText, 'AB23CD');
  });

  testWidgets('redeem code uppercases, shows Vietnamese errors, and adds friend',
      (t) async {
    String? nextErr;
    int nextStatus = 404;
    handler = (req) {
      if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
        return jsonResponse([]);
      }
      if (req.url.path == '/api/v1/friends/redeem' && req.method == 'POST') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['code'], 'XY78KM');
        if (nextErr != null) {
          return jsonResponse({'error': nextErr}, nextStatus);
        }
        return jsonResponse({
          'friend': {
            'familyId': 'fam-2',
            'online': true,
            'kids': [
              {
                'kidUuid': 'k-2',
                'nickname': 'Bin',
                'avatar': kidAvatars[2],
                'rocket': 'rocket_blue',
              }
            ],
          },
        });
      }
      return fakeServer(req);
    };

    await pumpCard(t);

    final input = find.byKey(const ValueKey('redeem-friend-code-input'));
    final submit = find.byKey(const ValueKey('redeem-friend-code-button'));
    expect(t.getSize(submit).height, greaterThanOrEqualTo(48));

    for (final (code, status, msg) in [
      ('code_invalid', 404, 'Mã không đúng hoặc đã hết hạn'),
      ('self', 409, 'Đây là mã của chính nhà mình'),
      ('already_friends', 409, 'Hai nhà đã là bạn rồi'),
      ('too_many_friends', 409, 'Đã đủ 50 bạn'),
    ]) {
      nextErr = code;
      nextStatus = status;
      await t.enterText(input, ' xy7 8km ');
      await t.tap(submit);
      await settle(t);
      expect(find.text(msg), findsOneWidget);
    }

    nextErr = null;
    await t.enterText(input, 'xy78km');
    await t.tap(submit);
    await settle(t);
    expect(find.byKey(const ValueKey('friend-code-error')), findsNothing);
    expect(find.text('Bin'), findsOneWidget);
    expect(find.text('Đang mở app'), findsOneWidget);
  });

  testWidgets('remove friend asks confirmation with danger dialog before deleting',
      (t) async {
    var deleted = false;
    handler = (req) {
      if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
        if (deleted) return jsonResponse([]);
        return jsonResponse([
          {
            'familyId': 'fam-2',
            'online': false,
            'kids': [
              {
                'kidUuid': 'k-2',
                'nickname': 'Mít',
                'avatar': 'not-an-asset',
                'rocket': 'rocket_orange',
              }
            ],
          },
        ]);
      }
      if (req.url.path == '/api/v1/friends/fam-2' && req.method == 'DELETE') {
        deleted = true;
        return http.Response('', 204);
      }
      return fakeServer(req);
    };

    await pumpCard(t);
    expect(find.text('Mít'), findsOneWidget);
    expect(find.text('Ngoại tuyến'), findsOneWidget);

    final dot = t.widget<Container>(
      find.byKey(const ValueKey('presence-dot-fam-2')),
    );
    expect((dot.decoration! as BoxDecoration).color, AppColors.textMuted);

    final removeBtn = find.byKey(const ValueKey('remove-friend-fam-2'));
    expect(t.getSize(removeBtn).height, greaterThanOrEqualTo(48));
    await t.tap(removeBtn);
    await settle(t);
    expect(find.text('Xóa bạn đua?'), findsOneWidget);

    // Cancel keeps the friend and sends no DELETE.
    await t.tap(find.text('Giữ lại'));
    await settle(t);
    expect(find.text('Mít'), findsOneWidget);
    expect(requests.where((r) => r.method == 'DELETE'), isEmpty);

    // Confirm sends DELETE and removes friend.
    await t.tap(removeBtn);
    await settle(t);
    await t.tap(find.byKey(const ValueKey('confirm-remove-friend')));
    await settle(t);
    expect(requests.where((r) => r.method == 'DELETE'), hasLength(1));
    expect(find.text('Mít'), findsNothing);
  });

  testWidgets('per-kid privacy switches persist independently per kid', (t) async {
    handler = (req) {
      if (req.url.path == '/api/v1/friends') return jsonResponse([]);
      return fakeServer(req);
    };
    await pumpCard(t, kidId: na);

    final tease = find.byKey(const ValueKey('tease-stickers-switch'));
    final showcaseOn = find.byKey(const ValueKey('showcase-on-switch'));
    final showcaseLearning =
        find.byKey(const ValueKey('showcase-learning-switch'));

    expect(t.widget<Switch>(tease).value, isTrue);
    expect(t.widget<Switch>(showcaseOn).value, isTrue);
    expect(t.widget<Switch>(showcaseLearning).value, isFalse);

    await t.ensureVisible(showcaseOn);
    await t.tap(showcaseOn);
    await settle(t);
    await t.ensureVisible(showcaseLearning);
    await t.tap(showcaseLearning);
    await settle(t);

    final kids = KidRepository(db);
    expect(await t.runAsync(() => kids.setting(showcaseOnKey(na))), 'false');
    expect(
      await t.runAsync(() => kids.setting(showcaseLearningKey(na))),
      'true',
    );
    expect(await t.runAsync(() => kids.setting(showcaseOnKey(bo))), isNull);
    expect(
      await t.runAsync(() => kids.setting(showcaseLearningKey(bo))),
      isNull,
    );
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1366, 1024),
    const Size(1024, 1366),
  ]) {
    testWidgets('no overflow in ParentHome settings tab at $size', (t) async {
      handler = (req) {
        if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
          return jsonResponse([
            {
              'familyId': 'fam-2',
              'online': true,
              'kids': [
                {
                  'kidUuid': 'k-2',
                  'nickname': 'Bé Sóc Rất Dài Tên',
                  'avatar': kidAvatars[0],
                  'rocket': 'rocket_orange',
                }
              ],
            },
          ]);
        }
        if (req.url.path == '/api/v1/friends/code' && req.method == 'POST') {
          return jsonResponse({
            'code': 'AB23CD',
            'expiresAt':
                fakeNow.add(const Duration(hours: 24)).toIso8601String(),
          });
        }
        return fakeServer(req);
      };

      await pumpParentSettings(t, size: size);
      expect(find.text('Bạn đua của bé'), findsOneWidget);
      // Exactly one tease-stickers-switch (no duplicate in SettingsTab).
      expect(find.byKey(const ValueKey('tease-stickers-switch')), findsOneWidget);
      final createBtn = find.byKey(const ValueKey('create-friend-code'));
      await t.ensureVisible(createBtn);
      await t.tap(createBtn);
      await settle(t);
      expect(find.text('AB2 3CD'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('privacy policy and online consent cover friends and showcase',
      (t) async {
    setSize(t, 375, 667);
    await t.pumpWidget(const MaterialApp(home: PrivacyScreen()));
    for (final s in [
      'biệt danh đua, ảnh đại diện, tên lửa và Tủ khoe',
      'mục tiến độ học mặc định tắt',
      'xóa bạn xóa liên kết',
      'không có chữ tự do',
    ]) {
      await t.scrollUntilVisible(find.textContaining(s), 200);
      expect(find.textContaining(s), findsOneWidget);
    }

    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showOnlineConsentDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await settle(t);
    expect(find.textContaining('Tủ khoe'), findsOneWidget);
    expect(find.textContaining('kết nối bạn đua'), findsOneWidget);
  });
}
