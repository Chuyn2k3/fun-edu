import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/features/online_race/room_lobby_screen.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/contrast.dart';
import 'package:funedu/ui/theme/depth.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/voice/speaker.dart';

import '../../voice/fake_speaker.dart';
import '../game/game_test_helpers.dart';
import '../setup_helpers.dart';
import 'online_race_test.dart';

RoomPlayer _player(
  String id, {
  String name = '',
  String? avatar,
  String rocket = 'rocket_orange',
  bool connected = true,
  bool away = false,
  int? awayMsLeft,
  bool left = false,
}) =>
    RoomPlayer(
      id: id,
      name: name.isEmpty ? id : name,
      avatar: avatar ?? kidAvatars[0],
      rocket: rocket,
      steps: 0,
      connected: connected,
      away: away,
      awayMsLeft: awayMsLeft,
      left: left,
    );

RoomState _lobbyState({
  RoomPhase phase = RoomPhase.lobby,
  String code = 'AB12CD',
  String you = 'p1',
  String host = 'p1',
  List<RoomPlayer>? players,
  DateTime? startsAt,
  RoomSticker? sticker,
}) =>
    RoomState(
      phase: phase,
      code: code,
      you: you,
      host: host,
      startsAt: startsAt,
      sticker: sticker,
      players: players ??
          [
            _player('p1', name: 'Na', avatar: kidAvatars[0], rocket: 'rocket_orange'),
            _player('p2', name: 'Bo', avatar: kidAvatars[1], rocket: 'rocket_blue'),
          ],
    );

void main() {
  test('AppColors.onlineInk meets WCAG AA >= 4.5:1 on lobby cards', () {
    expect(contrastRatio(AppColors.onlineInk, AppColors.card),
        greaterThanOrEqualTo(4.5));
    final tinted = Color.lerp(AppColors.card, AppDepth.neutralTint, 0.9)!;
    expect(contrastRatio(AppColors.onlineInk, tinted),
        greaterThanOrEqualTo(4.5));
  });

  testWidgets('connected shows green dot, away shows grey with countdown',
      (t) async {
    final room = FakeRoom(_lobbyState(players: [
      _player('p1', name: 'Na', avatar: kidAvatars[0], rocket: 'rocket_orange'),
      _player(
        'p2',
        name: 'Bo',
        avatar: kidAvatars[1],
        rocket: 'rocket_blue',
        connected: false,
        away: true,
        awayMsLeft: 11200,
      ),
    ]));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4);

    final dot1 = t.widget<Container>(find.byKey(const ValueKey('lobby-dot-p1')));
    final dot2 = t.widget<Container>(find.byKey(const ValueKey('lobby-dot-p2')));
    expect((dot1.decoration! as BoxDecoration).color, AppColors.online);
    expect((dot2.decoration! as BoxDecoration).color, AppColors.textMuted);

    expect(find.text('✓ Sẵn sàng'), findsOneWidget);
    expect(find.text('Mất mạng · chờ 12s'), findsOneWidget);

    // Bo reconnects -> green dot and ready label.
    room.set(_lobbyState(players: [
      _player('p1', name: 'Na', avatar: kidAvatars[0], rocket: 'rocket_orange'),
      _player('p2', name: 'Bo', avatar: kidAvatars[1], rocket: 'rocket_blue'),
    ]));
    await t.pump();
    final dot2Now =
        t.widget<Container>(find.byKey(const ValueKey('lobby-dot-p2')));
    expect((dot2Now.decoration! as BoxDecoration).color, AppColors.online);
    expect(find.text('✓ Sẵn sàng'), findsNWidgets(2));
  });

  testWidgets('host has crown and mini rockets show for each joined slot',
      (t) async {
    final room = FakeRoom(_lobbyState(
      you: 'p2',
      host: 'p1',
      players: [
        _player('p1', name: 'Na', avatar: kidAvatars[0], rocket: 'rocket_orange'),
        _player('p2', name: 'Bo', avatar: kidAvatars[1], rocket: 'rocket_purple'),
      ],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4);

    expect(find.byKey(const ValueKey('lobby-crown-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('lobby-crown-p2')), findsNothing);
    expect(find.byKey(const ValueKey('lobby-rocket-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('lobby-rocket-p2')), findsOneWidget);
  });

  testWidgets('start enabled only with two connected', (t) async {
    final room = FakeRoom(_lobbyState(players: [
      _player('p1', name: 'Na'),
      _player('p2', name: 'Bo', connected: false, away: true, awayMsLeft: 9000),
    ]));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4);

    expect(find.text('Bắt đầu! 3 chặng'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('room-start')));
    await t.pump();
    expect(room.starts, 0, reason: 'only one player connected');

    room.set(_lobbyState(players: [
      _player('p1', name: 'Na'),
      _player('p2', name: 'Bo', connected: true, away: false),
    ]));
    await t.pump();

    await t.tap(find.byKey(const ValueKey('room-start')));
    await t.pump();
    expect(room.starts, 1);
  });

  testWidgets('empty slot shows invite and tapping reveals room code; copy pill works',
      (t) async {
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map?)?['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final room = FakeRoom(_lobbyState(
      code: 'K9M2P4',
      players: [_player('p1', name: 'Na')],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4);

    expect(find.text('Phòng K9M2P4'), findsOneWidget);
    expect(find.text('+ Chờ bạn'), findsNWidgets(3));
    expect(find.text('Mời bạn'), findsNWidgets(3));

    // Tap header copy pill.
    await t.tap(find.byKey(const ValueKey('room-copy-code')));
    await t.pump();
    expect(copied, 'K9M2P4');
    expect(find.text('Đã chép mã phòng'), findsOneWidget);

    // Clear toast timer before tapping empty slot.
    await pumpReal(t, times: 12, step: const Duration(milliseconds: 300));

    // Tap empty slot -> friendly invite dialog shows room code.
    await t.tap(find.byKey(const ValueKey('lobby-empty-slot-1')));
    await pumpReal(t, times: 2);
    expect(find.text('Mời bạn vào đua!'), findsOneWidget);
    expect(find.text('K 9 M 2 P 4'), findsOneWidget);
    await t.tap(find.text('Đóng'));
    await pumpReal(t, times: 2);
    expect(find.text('Mời bạn vào đua!'), findsNothing);
  });

  group('responsive layout without overflow or forbidden widgets', () {
    for (final entry in <Size, bool>{
      const Size(320, 568): false,
      const Size(390, 844): false,
      const Size(768, 1024): true,
      const Size(1024, 768): true,
      const Size(1366, 1024): true,
    }.entries) {
      final size = entry.key;
      final isTablet = entry.value;
      testWidgets('no overflow at $size (tablet=$isTablet)', (t) async {
        final room = FakeRoom(_lobbyState(players: [
          _player('p1', name: 'Nguyễn Bé Na', avatar: kidAvatars[0], rocket: 'rocket_orange'),
          _player('p2', name: 'Bo Siêu Tốc', avatar: kidAvatars[2], rocket: 'rocket_blue'),
          _player('p3', name: 'Mi', avatar: kidAvatars[4], rocket: 'rocket_green', connected: false, away: true, awayMsLeft: 14500),
        ]));
        if (size == const Size(1024, 768)) {
          // Mount RoomLobbyScreen directly at 1024x768 to isolate lobby layout
          // from the underlying /game route in GoRouter.
          setSize(t, size.width, size.height);
          t.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);
          await t.runAsync(() async {
            final kids = KidRepository(db);
            final kid = await kids.addKid(
              nickname: 'Na',
              avatar: kidAvatars[0],
              age: 5,
            );
            await placeKid(db, kid);
          });
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                speakerProvider.overrideWithValue(FakeSpeaker()),
                raceRandomProvider.overrideWith((_) => Random(7)),
                roomControllerProvider.overrideWith(() => room),
              ],
              child: const MaterialApp(home: RoomLobbyScreen()),
            ),
          );
          await pumpReal(t, times: 4);
        } else {
          await bootGame(
            t,
            size: size,
            extra: [roomControllerProvider.overrideWith(() => room)],
          );
          appRouter.go('/game/room/lobby');
          await pumpReal(t, times: 4);
        }

        expect(
          find.byKey(ValueKey(isTablet ? 'lobby-slots-4x1' : 'lobby-slots-2x2')),
          findsOneWidget,
        );
        expect(
          t.getSize(find.byKey(const ValueKey('room-start'))).height,
          greaterThanOrEqualTo(isTablet ? 80 : 64),
        );
        expect(
          find.descendant(
            of: find.byType(RoomLobbyScreen),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(RoomLobbyScreen),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
        expect(t.takeException(), isNull);
      });
    }
  });

  testWidgets('lobby to race opens within one frame after countdown (precaches once)',
      (t) async {
    final precached = <String>[];
    final room = FakeRoom(_lobbyState(
      phase: RoomPhase.lobby,
      players: [
        _player('p1', name: 'Na', avatar: kidAvatars[0], rocket: 'rocket_orange'),
        _player('p2', name: 'Bo', avatar: kidAvatars[1], rocket: 'rocket_blue'),
        _player('p3', name: 'Mi', avatar: kidAvatars[2], rocket: 'rocket_green'),
        _player('p4', name: 'Su', avatar: kidAvatars[3], rocket: 'rocket_purple'),
      ],
    ));

    await bootGame(
      t,
      extra: [
        roomControllerProvider.overrideWith(() => room),
        lobbyPrecacheImageProvider.overrideWithValue((provider, context) async {
          if (provider is AssetImage) {
            precached.add(provider.assetName);
          }
          return precacheImage(provider, context);
        }),
      ],
    );
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4);
    expect(precached, isEmpty);

    // Enter 3-2-1 countdown.
    room.set(_lobbyState(
      phase: RoomPhase.countdown,
      startsAt: DateTime.now().add(const Duration(seconds: 3)),
      players: room.initial.players,
    ));
    await pumpReal(t, times: 3);

    expect(find.byKey(const ValueKey('room-countdown')), findsOneWidget);
    expect(find.text('Chuẩn bị cất cánh!'), findsOneWidget);
    expect(precached, containsAll([
      AppImages.rocketOrange,
      AppImages.rocketBlue,
      AppImages.rocketGreen,
      AppImages.rocketPurple,
      kidAvatars[0],
      kidAvatars[1],
      kidAvatars[2],
      kidAvatars[3],
      AppImages.planet,
      AppImages.comet,
      AppImages.chipEncourage,
      AppImages.stickerTeaseBubble,
      AppImages.stickerParty,
    ]));
    final countAfterFirstCountdown = precached.length;

    // Additional countdown ticks must not re-precache already decoded assets.
    await t.pump(const Duration(milliseconds: 500));
    expect(precached.length, countAfterFirstCountdown);

    // Transition to racing mounts RaceScreen immediately on the next frame.
    room.set(_lobbyState(
      phase: RoomPhase.racing,
      players: room.initial.players,
    ));
    await t.pump();
    await t.pump();
    expect(find.byType(RaceScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('StickerToast and slot sticker badge show for 2s and respect tease setting',
      (t) async {
    final room = FakeRoom(_lobbyState(
      players: [
        _player('p1', name: 'Na', avatar: kidAvatars[0]),
        _player('p2', name: 'Bo', avatar: kidAvatars[1]),
      ],
    ));
    await bootGame(
      t,
      seed: (db, kid) =>
          KidRepository(db).setSetting(teaseStickersKey(kid), 'false'),
      extra: [roomControllerProvider.overrideWith(() => room)],
    );
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4);

    // Tease sticker ignored when disabled.
    room.set(_lobbyState(
      players: room.initial.players,
      sticker: const RoomSticker('p2', 'bubble', 1),
    ));
    await t.pump();
    expect(find.byKey(const ValueKey('lobby-slot-sticker-p2')), findsNothing);

    // Cheer sticker floats on sender slot and shows StickerToast for 2 s.
    room.set(_lobbyState(
      players: room.initial.players,
      sticker: const RoomSticker('p2', 'cheer', 2),
    ));
    await t.pump();
    expect(find.byKey(const ValueKey('lobby-slot-sticker-p2')), findsOneWidget);
    expect(find.text('Bo: Cố lên!'), findsOneWidget);

    await t.pump(const Duration(seconds: 2, milliseconds: 100));
    expect(find.byKey(const ValueKey('lobby-slot-sticker-p2')), findsNothing);
    expect(find.text('Bo: Cố lên!'), findsNothing);
  });

  testWidgets('animated space backdrop ticks cleanly and mounting in countdown precaches',
      (t) async {
    final precached = <String>[];
    final room = FakeRoom(_lobbyState(
      phase: RoomPhase.countdown,
      startsAt: DateTime.now().add(const Duration(seconds: 3)),
      players: [
        _player('p1', name: 'Na', avatar: kidAvatars[0], rocket: 'rocket_orange'),
        _player('p2', name: 'Bo', avatar: kidAvatars[1], rocket: 'rocket_blue'),
      ],
    ));
    await bootGame(
      t,
      reduceMotion: false,
      extra: [
        roomControllerProvider.overrideWith(() => room),
        lobbyPrecacheImageProvider.overrideWithValue((provider, context) async {
          if (provider is AssetImage) precached.add(provider.assetName);
        }),
      ],
    );
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4, step: const Duration(milliseconds: 32));

    expect(find.byKey(const ValueKey('room-countdown')), findsOneWidget);
    expect(precached, contains(AppImages.planet));
    expect(t.takeException(), isNull);
  });
}
