import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/game/scene/sticker_fx.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/voice/speaker.dart';

import '../game/game_test_helpers.dart';
import 'online_race_test.dart';

class _StickerSpyRoom extends FakeRoom {
  _StickerSpyRoom(super.initial);

  final List<(String id, String? to)> sentStickers = [];

  @override
  void sticker(String id, {String? to, DateTime? now}) {
    final t = now ?? ref.read(stickerClockProvider)();
    final lockedUntil = state.stickerLockedUntil;
    if (lockedUntil != null && t.isBefore(lockedUntil)) return;
    sentStickers.add((id, to));
    state = state.copyWith(
      stickerLockedUntil: () => t.add(const Duration(seconds: 3)),
    );
  }
}

class _ControllableSpeaker implements Speaker {
  final List<String> spoken = [];
  final List<Completer<void>> _pending = [];
  int stops = 0;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    final c = Completer<void>();
    _pending.add(c);
    return c.future;
  }

  void completeOldest() {
    if (_pending.isNotEmpty) {
      final c = _pending.removeAt(0);
      if (!c.isCompleted) c.complete();
    }
  }

  void completeAll() {
    while (_pending.isNotEmpty) {
      completeOldest();
    }
  }

  @override
  Future<void> stop() async {
    stops++;
    completeAll();
  }
}

RoomPlayer _p(
  String id, {
  int steps = 0,
  int? rank,
  String name = '',
  bool left = false,
}) =>
    RoomPlayer(
      id: id,
      name: name.isEmpty ? id : name,
      avatar: kidAvatars[0],
      rocket: 'rocket_orange',
      steps: steps,
      rank: rank,
      left: left,
    );

RoomState _room({
  RoomPhase phase = RoomPhase.racing,
  List<RoomPlayer>? players,
  RoomSticker? sticker,
  DateTime? stickerLockedUntil,
}) =>
    RoomState(
      phase: phase,
      code: 'ABC234',
      you: 'p1',
      host: 'p1',
      sticker: sticker,
      stickerLockedUntil: stickerLockedUntil,
      players: players ??
          [
            _p('p1', steps: 2, name: 'Na'),
            _p('p2', steps: 4, name: 'Bo'),
            _p('p3', steps: 7, name: 'Mi'),
          ],
    );

void main() {
  testWidgets('teasing off hides tease row and incoming tease', (t) async {
    final room = _StickerSpyRoom(_room());
    await bootGame(
      t,
      seed: (db, kid) =>
          KidRepository(db).setSetting(teaseStickersKey(kid), 'false'),
      extra: [roomControllerProvider.overrideWith(() => room)],
    );
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    // Cheer and quick phrases remain visible; tease stickers are hidden.
    expect(find.byKey(const ValueKey('race-sticker-cheer')), findsOneWidget);
    expect(find.byKey(const ValueKey('race-sticker-q_almost')), findsOneWidget);
    for (final id in teaseStickerIds) {
      expect(find.byKey(ValueKey('race-sticker-$id')), findsNothing);
    }

    final scene = t.state<RaceSceneState>(find.byType(RaceScene));

    // Incoming tease stickers are ignored (neither animated nor counted for cheer-up).
    room.set(_room(sticker: const RoomSticker('p2', 'bubble', 1, to: 'p1')));
    await t.pump();
    room.set(_room(sticker: const RoomSticker('p3', 'tongue', 2, to: 'p1')));
    await t.pump();
    room.set(_room(sticker: const RoomSticker('p2', 'rain', 3, to: 'p1')));
    await t.pump();

    expect(scene.stickerFx.activeStickers, 0);
    expect(scene.stickerFx.activeBubbleTexts, isEmpty);

    // Cheer sticker still plays normally when teasing is off.
    room.set(_room(sticker: const RoomSticker('p2', 'cheer', 4)));
    await t.pump();
    expect(scene.stickerFx.activeStickerIds, contains('cheer'));
  });

  testWidgets('quick phrase is spoken only when the question is not being read',
      (t) async {
    final room = _StickerSpyRoom(_room());
    final speaker = _ControllableSpeaker();

    await bootGame(
      t,
      extra: [
        roomControllerProvider.overrideWith(() => room),
        speakerProvider.overrideWithValue(speaker),
      ],
    );
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    // Question 1 is currently being spoken (completer still pending).
    expect(speaker.spoken, hasLength(1));

    // Quick phrase arrives while question is speaking: bubble shows, NOT spoken.
    room.set(_room(sticker: const RoomSticker('p2', 'q_fast', 1)));
    await t.pump();

    final scene = t.state<RaceSceneState>(find.byType(RaceScene));
    expect(scene.stickerFx.activeBubbleTexts, contains('Cậu nhanh quá!'));
    expect(speaker.spoken, hasLength(1));

    // Finish speaking question 1 -> now quick phrase IS spoken.
    speaker.completeOldest();
    await t.pump();

    room.set(_room(sticker: const RoomSticker('p3', 'q_almost', 2)));
    await t.pump();
    expect(scene.stickerFx.activeBubbleTexts, contains('Tớ sắp tới rồi!'));
    expect(speaker.spoken.last, 'Tớ sắp tới rồi!');

    // Clean up pending completers before dispose.
    speaker.completeAll();
  });

  testWidgets('cheer-up bubble once per stage', (t) async {
    var clock = DateTime(2026, 11, 23, 10, 0, 0);
    final room = _StickerSpyRoom(_room());

    await bootGame(
      t,
      extra: [
        roomControllerProvider.overrideWith(() => room),
        stickerClockProvider.overrideWithValue(() => clock),
      ],
    );
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    final scene = t.state<RaceSceneState>(find.byType(RaceScene));

    // 2 tease stickers within 10 s -> no cheer-up yet.
    room.set(_room(sticker: const RoomSticker('p2', 'bubble', 1, to: 'p1')));
    await t.pump();
    clock = clock.add(const Duration(seconds: 2));
    room.set(_room(sticker: const RoomSticker('p3', 'tongue', 2, to: 'p1')));
    await t.pump();
    expect(scene.stickerFx.activeBubbleTexts, isNot(contains(chipCheerUpText)));

    // 11 s later (old ones expired): 1 more tease -> only 1 in window -> no cheer-up.
    clock = clock.add(const Duration(seconds: 11));
    room.set(_room(sticker: const RoomSticker('p2', 'rain', 3, to: 'p1')));
    await t.pump();
    expect(scene.stickerFx.activeBubbleTexts, isNot(contains(chipCheerUpText)));

    // 2 more within 10 s (total 3 in 10 s) -> triggers cheer-up in stage 1!
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p3', 'turtle', 4, to: 'p1')));
    await t.pump();
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p2', 'smoke', 5, to: 'p1')));
    await t.pump();
    expect(scene.stickerFx.activeBubbleTexts, contains(chipCheerUpText));

    // Let bubble expire after 2.25 s.
    await t.pump(const Duration(milliseconds: 2300));
    expect(scene.stickerFx.activeBubbleTexts, isEmpty);

    // 3 more teases in stage 1 -> must NOT re-trigger in the same stage.
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p2', 'bubble', 6, to: 'p1')));
    await t.pump();
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p3', 'rain', 7, to: 'p1')));
    await t.pump();
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p2', 'sleepy', 8, to: 'p1')));
    await t.pump();
    expect(scene.stickerFx.activeBubbleTexts, isNot(contains(chipCheerUpText)));

    // Advance into stage 2 (reach 6 steps and wait out the 2.5 s Star Gate).
    while (raceState(t).kidSteps < 6) {
      await answerRight(t);
    }
    expect(raceState(t).starGateStage, 1);
    await t.pump(const Duration(milliseconds: 2600));
    expect(raceState(t).stage, 2);

    // 3 tease stickers within 10 s in stage 2 -> triggers once in stage 2!
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p2', 'bubble', 9, to: 'p1')));
    await t.pump();
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p3', 'tongue', 10, to: 'p1')));
    await t.pump();
    clock = clock.add(const Duration(seconds: 1));
    room.set(_room(sticker: const RoomSticker('p2', 'turtle', 11, to: 'p1')));
    await t.pump();
    expect(scene.stickerFx.activeBubbleTexts, contains(chipCheerUpText));
  });

  testWidgets('tapping tease targets best active rival and locks bar for 3 s',
      (t) async {
    final clock = DateTime(2026, 11, 23, 10, 0, 0);
    // p3 has 7 steps (best active rival), p2 has 4 steps, p4 has 15 steps but left.
    final room = _StickerSpyRoom(_room(players: [
      _p('p1', steps: 2, name: 'Na'),
      _p('p2', steps: 4, name: 'Bo'),
      _p('p3', steps: 7, name: 'Mi'),
      _p('p4', steps: 15, name: 'Su', left: true),
    ]));

    await bootGame(
      t,
      size: const Size(320, 568),
      extra: [
        roomControllerProvider.overrideWith(() => room),
        stickerClockProvider.overrideWithValue(() => clock),
      ],
    );
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    final bubbleFinder = find.byKey(const ValueKey('race-sticker-bubble'));
    final cheerFinder = find.byKey(const ValueKey('race-sticker-cheer'));
    expect(t.getSize(cheerFinder).height, greaterThanOrEqualTo(64.0));

    await t.scrollUntilVisible(
      bubbleFinder,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('online-sticker-bar')),
        matching: find.byType(Scrollable),
      ),
    );
    await t.tap(bubbleFinder);
    await t.pump();

    expect(room.sentStickers, [('bubble', 'p3')]);

    // Locked for 3 s: tapping cheer does not send.
    await t.scrollUntilVisible(
      cheerFinder,
      -120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('online-sticker-bar')),
        matching: find.byType(Scrollable),
      ),
    );
    await t.tap(cheerFinder);
    await t.pump();
    expect(room.sentStickers, hasLength(1));
    expect(t.takeException(), isNull);
  });

  testWidgets('tablet sticker bar buttons are >= 80 pt', (t) async {
    final room = _StickerSpyRoom(_room());
    await bootGame(
      t,
      size: const Size(800, 1280),
      extra: [roomControllerProvider.overrideWith(() => room)],
    );
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    final cheerBtn = find.byKey(const ValueKey('race-sticker-cheer'));
    expect(t.getSize(cheerBtn).height, greaterThanOrEqualTo(80.0));
    expect(t.takeException(), isNull);
  });

  testWidgets('lobby StickerBar hides tease when off and locks for 3 s',
      (t) async {
    final clock = DateTime(2026, 11, 23, 10, 0, 0);
    final room = _StickerSpyRoom(_room(phase: RoomPhase.lobby));
    await bootGame(
      t,
      seed: (db, kid) =>
          KidRepository(db).setSetting(teaseStickersKey(kid), 'false'),
      extra: [
        roomControllerProvider.overrideWith(() => room),
        stickerClockProvider.overrideWithValue(() => clock),
      ],
    );
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 4);

    expect(find.byKey(const ValueKey('sticker-cheer')), findsOneWidget);
    expect(find.byKey(const ValueKey('sticker-party')), findsOneWidget);
    for (final id in teaseStickerIds) {
      expect(find.byKey(ValueKey('sticker-$id')), findsNothing);
    }

    await t.tap(find.byKey(const ValueKey('sticker-cheer')));
    await t.pump();
    expect(room.sentStickers, [('cheer', null)]);

    // Locked for 3 s: tapping again sends nothing.
    await t.tap(find.byKey(const ValueKey('sticker-party')));
    await t.pump();
    expect(room.sentStickers, hasLength(1));
  });
}
