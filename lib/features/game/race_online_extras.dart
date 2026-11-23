// Online-only parts of the race screen: star gate board and sticker bar.
part of 'race_screen.dart';

/// Temporary board + live sticker/quick-phrase row shown while the 2.5 s
/// Star Gate scene plays between online stages so the kid cannot tap answers.
class _StarGateBoard extends StatelessWidget {
  const _StarGateBoard({
    required this.stage,
    required this.tablet,
    required this.landscape,
  });

  final int stage;
  final bool tablet;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('star-gate-board'),
      mainAxisSize: landscape ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (landscape) const Spacer(),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 20 : 14,
            vertical: tablet ? 18 : 14,
          ),
          decoration: BoxDecoration(
            color: GameColors.rareGoldTint,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: GameColors.rareGold, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: GameColors.questionCardEdge,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.icStar,
                width: tablet ? 40 : 30,
                height: tablet ? 40 : 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qua Cổng Sao chặng $stage!',
                      style: TextStyle(
                        fontSize: tablet ? 24 : 18,
                        fontWeight: FontWeight.w900,
                        color: GameColors.rareInk,
                      ),
                    ),
                    Text(
                      'Chuẩn bị vào chặng ${stage + 1}…',
                      style: TextStyle(
                        fontSize: tablet ? 17 : 13,
                        fontWeight: FontWeight.w800,
                        color: GameColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tablet ? 14 : 10),
        const _OnlineStickerBar(),
        if (landscape) const Spacer(),
      ],
    );
  }
}

String? _bestActiveRivalId(RoomState room) {
  final activeOthers = room.others.where((p) => !p.left).toList();
  if (activeOthers.isEmpty) return null;
  activeOthers.sort((a, b) {
    final ar = a.rank ?? 99, br = b.rank ?? 99;
    return ar != br ? ar - br : b.steps - a.steps;
  });
  return activeOthers.first.id;
}

/// Compact horizontal bar of cheer stickers, tease stickers (when enabled by
/// parent), and quick phrases in online races. Isolated in its own
/// [RepaintBoundary] so cooldown locks never rebuild [_QuestionCard].
class _OnlineStickerBar extends ConsumerWidget {
  const _OnlineStickerBar();

  static const _cheerIds = ['cheer', 'love', 'party'];
  static const _teaseIds = [
    'bubble',
    'tongue',
    'byebye',
    'rain',
    'sleepy',
    'turtle',
    'smoke',
  ];
  static const _phraseIds = [
    'q_almost',
    'q_fast',
    'q_oops',
    'q_chase',
    'q_again',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablet = context.isTablet;
    final btnSize = tablet ? 80.0 : 64.0;
    final teaseOn = ref.watch(teaseStickersProvider).valueOrNull ?? true;
    final lockedUntil =
        ref.watch(roomControllerProvider.select((s) => s.stickerLockedUntil));
    final locked = lockedUntil != null &&
        lockedUntil.isAfter(ref.read(stickerClockProvider)());

    final ids = <String>[
      ..._cheerIds,
      if (teaseOn) ..._teaseIds,
      ..._phraseIds,
    ];

    return RepaintBoundary(
      child: SizedBox(
        key: const ValueKey('online-sticker-bar'),
        height: btnSize,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: ids.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final id = ids[index];
            final phrase = quickPhraseTexts[id];
            final art = roomStickerArt[id];
            void onTap() {
              final roomState = ref.read(roomControllerProvider);
              final target =
                  isTeaseSticker(id) ? _bestActiveRivalId(roomState) : null;
              ref.read(roomControllerProvider.notifier).sticker(id, to: target);
            }

            if (phrase != null) {
              return Pressable(
                key: ValueKey('race-sticker-$id'),
                semanticsLabel: phrase,
                onTap: locked ? null : onTap,
                builder: (pressed) => Container(
                  constraints: BoxConstraints(
                    minWidth: btnSize,
                    minHeight: btnSize,
                  ),
                  height: btnSize,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: tablet ? 16 : 12),
                  decoration: raisedDecoration(
                    tint: locked ? GameColors.lockedFill : AppColors.card,
                    pressed: pressed,
                  ),
                  child: Text(
                    phrase,
                    style: TextStyle(
                      fontSize: tablet ? 16 : 13,
                      fontWeight: FontWeight.w800,
                      color: locked ? GameColors.lockedInk : GameColors.ink,
                    ),
                  ),
                ),
              );
            }

            if (art == null) {
              return SizedBox(width: btnSize, height: btnSize);
            }
            return StickerImageTile(
              tileKey: ValueKey('race-sticker-$id'),
              size: btnSize,
              asset: art.$1,
              label: art.$2,
              locked: locked,
              onTap: onTap,
            );
          },
        ),
      ),
    );
  }
}
