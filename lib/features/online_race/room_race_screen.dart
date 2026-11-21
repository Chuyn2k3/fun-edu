import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/engine/race_question.dart';
import '../../online/room/online_rival.dart';
import '../../online/room/room_controller.dart';
import '../game/race_screen.dart';

/// `/game/room/race`: the usual race screen with the friends' rocket in
/// place of Chíp's.
class RoomRaceScreen extends ConsumerStatefulWidget {
  const RoomRaceScreen({super.key, required this.subject});

  final RaceSubject subject;

  @override
  ConsumerState<RoomRaceScreen> createState() => _RoomRaceScreenState();
}

class _RoomRaceScreenState extends ConsumerState<RoomRaceScreen> {
  late final OnlineRival _rival = OnlineRival(
    ref.read(roomControllerProvider.notifier),
    ref.read(roomControllerProvider),
  );

  @override
  void initState() {
    super.initState();
    ref.listenManual(roomControllerProvider, (_, s) => _rival.update(s));
  }

  @override
  void dispose() {
    _rival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RaceScreen(subject: widget.subject, rival: _rival);
}
