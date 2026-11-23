import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/engine/race_question.dart';
import '../../online/room/room_controller.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';
import 'room_widgets.dart';

/// Which subject this kid answers in the online race (each kid picks their
/// own; questions follow each kid's level).
final roomSubjectProvider = StateProvider<RaceSubject>((_) => RaceSubject.toan);

/// `/game/room/lobby`: the room code, who is in, stickers, and the host's
/// "Bắt đầu!". Moves to the race when the room starts.
class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Redraws the 3-2-1 countdown.
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted && ref.read(roomControllerProvider).phase == RoomPhase.countdown) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _leave() async {
    await ref.read(roomControllerProvider.notifier).leave();
    if (mounted) context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomControllerProvider.select((s) => s.phase), (_, phase) {
      if (phase == RoomPhase.racing && mounted) {
        context.go('/game/room/race', extra: ref.read(roomSubjectProvider));
      }
    });
    final room = ref.watch(roomControllerProvider);
    final tablet = context.isTablet;

    if (room.phase == RoomPhase.error || room.phase == RoomPhase.idle) {
      return _Message(
        text: roomErrorText(room.error),
        onBack: () => context.go('/game'),
      );
    }

    final countdown = room.phase == RoomPhase.countdown && room.startsAt != null
        ? (room.startsAt!.difference(DateTime.now()).inMilliseconds / 1000).ceil().clamp(1, 9)
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: DottedBackground(
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tablet ? 720 : 480),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            _BackButton(onTap: _leave),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Phòng đua',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _CodeCard(code: room.code ?? ''),
                        const SizedBox(height: 16),
                        if (room.phase == RoomPhase.connecting)
                          const Text('Đang vào phòng…', textAlign: TextAlign.center, style: _muted),
                        for (final p in room.players) ...[
                          RoomPlayerTile(
                            player: p,
                            isYou: p.id == room.you,
                            isHost: p.id == room.host,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (room.players.length < 2 && room.phase == RoomPhase.lobby)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Đang chờ bạn vào phòng…',
                                textAlign: TextAlign.center, style: _muted),
                          ),
                        const SizedBox(height: 8),
                        const Text('Bé đua môn', style: _label),
                        const SizedBox(height: 8),
                        const _SubjectPicker(),
                        const SizedBox(height: 16),
                        const StickerBar(),
                        const SizedBox(height: 16),
                        if (room.isHost)
                          RoomBigButton(
                            key: const ValueKey('room-start'),
                            label: 'Bắt đầu!',
                            onTap: room.phase == RoomPhase.lobby && room.connectedCount >= 2
                                ? () => ref.read(roomControllerProvider.notifier).start()
                                : null,
                          )
                        else
                          const Text('Chờ chủ phòng bắt đầu nhé!',
                              textAlign: TextAlign.center, style: _label),
                      ],
                    ),
                  ),
                ),
                const Positioned(top: 80, left: 0, right: 0, child: Center(child: StickerToast())),
                if (countdown != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.text.withOpacity(0.55),
                      child: Center(
                        child: Text(
                          '$countdown',
                          key: const ValueKey('room-countdown'),
                          style: const TextStyle(
                            fontSize: 140,
                            fontWeight: FontWeight.w900,
                            color: AppColors.card,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _muted = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
  );
  static const _label = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: raisedDecoration(accent: AppColors.accent),
      child: Column(
        children: [
          const Text(
            'Mã phòng — gửi cho ba mẹ của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code.split('').join(' '),
              key: const ValueKey('room-code-text'),
              style: TextStyle(
                fontSize: tablet ? 56 : 44,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: code.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    showAppToast(context, 'Đã chép mã phòng',
                        kind: AppToastKind.success);
                  },
            icon: const Icon(Icons.copy_rounded, color: AppColors.primaryOnTint),
            label: const Text(
              'Chép mã',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryOnTint),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectPicker extends ConsumerWidget {
  const _SubjectPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(roomSubjectProvider);
    final tablet = context.isTablet;
    Widget option(RaceSubject s, String label) => Expanded(
          child: Pressable(
            key: ValueKey('room-subject-${s.name}'),
            semanticsLabel: label,
            onTap: () => ref.read(roomSubjectProvider.notifier).state = s,
            builder: (pressed) => Container(
              constraints: BoxConstraints(minHeight: tablet ? 80 : 64),
              alignment: Alignment.center,
              decoration: raisedDecoration(
                accent: current == s ? AppColors.primary : AppDepth.neutral,
                pressed: pressed || current == s,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: tablet ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: current == s ? AppColors.primaryOnTint : AppColors.text,
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        option(RaceSubject.toan, 'Toán'),
        const SizedBox(width: 10),
        option(RaceSubject.tiengViet, 'Tiếng Việt'),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = context.isTablet ? 80.0 : 64.0;
    return Pressable(
      onTap: onTap,
      semanticsLabel: 'Rời phòng',
      builder: (pressed) => Container(
        width: size,
        height: size,
        decoration: raisedDecoration(pressed: pressed),
        child: const Icon(Icons.arrow_back_rounded, size: 32, color: AppColors.text),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onBack});

  final String text;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    key: const ValueKey('room-message'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RoomBigButton(label: 'Về Góc Chơi', onTap: onBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
