import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/online_race/room_lobby_screen.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/friends/friends_api.dart';
import 'package:funedu/online/friends/friends_controller.dart';
import 'package:funedu/online/friends/lobby_client.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/router.dart';
import 'package:funedu/ui/theme/tokens.dart';

import 'game_test_helpers.dart';

class FakeSession extends SessionController {
  @override
  Future<StoredSession?> build() async => const StoredSession(
        accessToken: 'a',
        refreshToken: 'r',
        familyId: 'me',
        provider: 'google',
      );
}

class FakeLobby extends LobbyClient {
  FakeLobby({this.connected = true});

  final bool connected;
  final invites = <(String, String, String)>[];

  @override
  LobbyState build() => LobbyState(connected: connected);

  @override
  void onAppResumed() {}

  @override
  void onAppPaused() {}

  @override
  void setRouteEligible(bool eligible) {}

  @override
  void setRouteBusy(bool busy) {}

  @override
  void sendInvite({
    required String toFamilyId,
    required String roomCode,
    required String kidUuid,
  }) =>
      invites.add((toFamilyId, roomCode, kidUuid));

  void fail(String code, int seq) =>
      state = state.copyWith(lastError: LobbyErrorEvent(code: code, seq: seq));
}

class FakeCreateRoom extends RoomController {
  FakeCreateRoom([this.initial = const RoomState()]);

  final RoomState initial;
  int creates = 0;
  bool fail = false;

  @override
  RoomState build() => initial;

  @override
  Future<void> create(RoomKid kid) async {
    creates++;
    state = fail
        ? const RoomState(phase: RoomPhase.error, error: 'server_unreachable')
        : RoomState(phase: RoomPhase.lobby, code: 'ROOM42', you: kid.uuid);
  }

  @override
  Future<void> leave() async => state = const RoomState();
}

FriendFamily _family(String id, String name, {bool online = true}) =>
    FriendFamily(
      familyId: id,
      online: online,
      kids: [
        FriendKid(
          kidUuid: 'kid-$id',
          nickname: name,
          avatar: kidAvatars[2],
          rocket: 'rocket_blue',
        ),
      ],
    );

List<Override> _overrides({
  required FakeLobby lobby,
  required FakeCreateRoom room,
  List<FriendFamily> friends = const [],
  bool enabled = true,
  bool signedIn = true,
}) =>
    [
      onlineConfigProvider.overrideWithValue(
        enabled ? const OnlineConfig(apiUrl: 'https://api.test') : const OnlineConfig(apiUrl: ''),
      ),
      if (signedIn) sessionProvider.overrideWith(FakeSession.new),
      friendsProvider.overrideWithValue(AsyncData(friends)),
      lobbyClientProvider.overrideWith(() => lobby),
      roomControllerProvider.overrideWith(() => room),
    ];

void main() {
  testWidgets('row hidden for guests, disabled online or no friends', (t) async {
    for (final (enabled, signedIn, friends) in [
      (true, false, [_family('f1', 'Bo')]),
      (false, true, [_family('f1', 'Bo')]),
      (true, true, <FriendFamily>[]),
    ]) {
      await bootGame(t,
          extra: _overrides(
            lobby: FakeLobby(),
            room: FakeCreateRoom(),
            friends: friends,
            enabled: enabled,
            signedIn: signedIn,
          ));
      appRouter.go('/game');
      await pumpReal(t, times: 4);
      expect(find.byKey(const ValueKey('friends-row')), findsNothing);
      expect(find.text('Bạn đua'), findsNothing);
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets('offline friend is greyed and not tappable', (t) async {
    final lobby = FakeLobby();
    final room = FakeCreateRoom();
    await bootGame(t,
        extra: _overrides(
          lobby: lobby,
          room: room,
          friends: [_family('f1', 'Bo', online: false)],
        ));
    appRouter.go('/game');
    await pumpReal(t, times: 4);

    expect(find.text('Bạn đua'), findsOneWidget);
    expect(find.text('Bo'), findsOneWidget);
    final dot = t.widget<Container>(find.byKey(const ValueKey('friend-dot-kid-f1')));
    expect((dot.decoration as BoxDecoration).color, AppColors.textMuted);
    expect(find.byTooltip('Bạn Bo đang không online'), findsOneWidget);

    await t.tap(find.text('Bo'), warnIfMissed: false);
    await pumpReal(t, times: 3);
    expect(room.creates, 0);
    expect(lobby.invites, isEmpty);
  });

  testWidgets('online friend tap creates a room, invites, opens lobby', (t) async {
    final lobby = FakeLobby();
    final room = FakeCreateRoom();
    await bootGame(t,
        extra: _overrides(
          lobby: lobby,
          room: room,
          friends: [_family('f1', 'Bo')],
        ));
    appRouter.go('/game');
    await pumpReal(t, times: 4);

    final dot = t.widget<Container>(find.byKey(const ValueKey('friend-dot-kid-f1')));
    expect((dot.decoration as BoxDecoration).color, AppColors.online);
    expect(t.getSize(find.byKey(const ValueKey('friend-kid-f1'))).height,
        greaterThanOrEqualTo(64));

    await t.tap(find.byKey(const ValueKey('friend-kid-f1')));
    await pumpReal(t, times: 6);

    expect(room.creates, 1);
    expect(lobby.invites.length, 1);
    expect(lobby.invites.single.$1, 'f1');
    expect(lobby.invites.single.$2, 'ROOM42');
    expect(find.byType(RoomLobbyScreen), findsOneWidget);
  });

  testWidgets('tap reuses the room the kid is already in', (t) async {
    final lobby = FakeLobby();
    final room = FakeCreateRoom(const RoomState(phase: RoomPhase.lobby, code: 'KEEP11'));
    await bootGame(t,
        extra: _overrides(
          lobby: lobby,
          room: room,
          friends: [_family('f1', 'Bo')],
        ));
    appRouter.go('/game');
    await pumpReal(t, times: 4);
    await t.tap(find.byKey(const ValueKey('friend-kid-f1')));
    await pumpReal(t, times: 6);
    expect(room.creates, 0);
    expect(lobby.invites.single.$2, 'KEEP11');
  });

  testWidgets('refusal code shows a friendly toast', (t) async {
    final lobby = FakeLobby();
    await bootGame(t,
        extra: _overrides(
          lobby: lobby,
          room: FakeCreateRoom(),
          friends: [_family('f1', 'Bo')],
        ));
    appRouter.go('/game');
    await pumpReal(t, times: 4);

    lobby.fail('friend_offline', 1);
    await pumpReal(t, times: 3);
    expect(find.text('Bạn ấy vừa thoát rồi, lát nữa mời lại nhé'), findsOneWidget);
    await pumpReal(t, times: 12, step: const Duration(milliseconds: 400));

    lobby.fail('invite_pending', 2);
    await pumpReal(t, times: 3);
    expect(find.textContaining('đang xem lời mời'), findsOneWidget);
  });

  testWidgets('lobby not connected: toast, no room created', (t) async {
    final lobby = FakeLobby(connected: false);
    final room = FakeCreateRoom();
    await bootGame(t,
        extra: _overrides(
          lobby: lobby,
          room: room,
          friends: [_family('f1', 'Bo')],
        ));
    appRouter.go('/game');
    await pumpReal(t, times: 4);
    await t.tap(find.byKey(const ValueKey('friend-kid-f1')));
    await pumpReal(t, times: 4);
    expect(room.creates, 0);
    expect(find.textContaining('Chưa kết nối'), findsOneWidget);
  });

  testWidgets('room creation failure shows toast and does not invite', (t) async {
    final lobby = FakeLobby();
    final room = FakeCreateRoom()..fail = true;
    await bootGame(t,
        extra: _overrides(
          lobby: lobby,
          room: room,
          friends: [_family('f1', 'Bo')],
        ));
    appRouter.go('/game');
    await pumpReal(t, times: 4);
    await t.tap(find.byKey(const ValueKey('friend-kid-f1')));
    await pumpReal(t, times: 6);
    expect(lobby.invites, isEmpty);
    expect(find.textContaining('máy chủ FunEdu'), findsOneWidget);
  });

  group('layouts', () {
    for (final entry in <Size, bool>{
      const Size(320, 568): false,
      const Size(390, 844): false,
      const Size(768, 1024): true,
      const Size(1024, 768): true,
    }.entries) {
      testWidgets('no overflow with 6 friends at ${entry.key}', (t) async {
        await bootGame(
          t,
          size: entry.key,
          extra: _overrides(
            lobby: FakeLobby(),
            room: FakeCreateRoom(),
            friends: [
              for (var i = 0; i < 6; i++)
                _family('f$i', 'Bạn có tên rất là dài $i', online: i.isEven),
            ],
          ),
        );
        appRouter.go('/game');
        await pumpReal(t, times: 4);
        expect(t.takeException(), isNull);
        final tile = find.byKey(const ValueKey('friend-kid-f0'));
        expect(tile, findsOneWidget);
        expect(t.getSize(tile).height,
            greaterThanOrEqualTo(entry.value ? 80 : 64));
      });
    }
  });

  group('lobby empty slot modal', () {
    Future<void> openLobby(WidgetTester t, List<FriendFamily> friends,
        {Size size = const Size(390, 844), FakeLobby? lobby}) async {
      await bootGame(
        t,
        size: size,
        extra: _overrides(
          lobby: lobby ?? FakeLobby(),
          room: FakeCreateRoom(const RoomState(
            phase: RoomPhase.lobby,
            code: 'K9M2P4',
            you: 'p1',
            host: 'p1',
            players: [
              RoomPlayer(
                id: 'p1',
                name: 'Na',
                avatar: 'assets/images/avatars/fox.png',
                rocket: 'rocket_orange',
                steps: 0,
                connected: true,
              ),
            ],
          )),
          friends: friends,
        ),
      );
      appRouter.go('/game/room/lobby');
      await pumpReal(t, times: 4);
      await t.tap(find.byKey(const ValueKey('lobby-empty-slot-1')));
      await pumpReal(t, times: 3);
    }

    testWidgets('lists online friends and invites with the room code', (t) async {
      final lobby = FakeLobby();
      await openLobby(
        t,
        [_family('f1', 'Bo'), _family('f2', 'Mi', online: false)],
        lobby: lobby,
      );
      expect(find.text('Mời bạn vào đua!'), findsOneWidget);
      expect(find.text('Bo'), findsOneWidget);
      expect(find.text('Mi'), findsNothing);
      await t.tap(find.byKey(const ValueKey('invite-kid-f1')));
      await pumpReal(t, times: 2);
      expect(lobby.invites.single, ('f1', 'K9M2P4', 'p1'));
      expect(find.text('Đã mời'), findsOneWidget);
      expect(find.text('Chép mã phòng'), findsOneWidget);
    });

    testWidgets('no friends falls back to the room code', (t) async {
      await openLobby(t, const []);
      expect(find.text('K 9 M 2 P 4'), findsOneWidget);
      expect(find.text('Chép mã'), findsNWidgets(2)); // header pill + modal button
    });

    testWidgets('no overflow at 320x568 with many friends', (t) async {
      await openLobby(
        t,
        [for (var i = 0; i < 5; i++) _family('f$i', 'Bạn $i')],
        size: const Size(320, 568),
      );
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('invite-kid-f0')), findsOneWidget);
    });
  });
}
