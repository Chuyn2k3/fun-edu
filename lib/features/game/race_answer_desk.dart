// The answer desk of the race screen: question card and answer keys.
part of 'race_screen.dart';

/// The warm cream toy cockpit console at the bottom of the race screen.
/// Replaces FloatingCockpitHUD, eliminating BackdropFilter and dark neon glass.
class AnswerDesk extends ConsumerWidget {
  const AnswerDesk({
    super.key,
    required this.onKey,
    required this.onListen,
    this.comboStreak = 0,
    this.nitroActive = false,
  });

  final ValueChanged<int> onKey;
  final VoidCallback onListen;
  final int comboStreak;
  final bool nitroActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(raceControllerProvider.select((s) => (
          phase: s.phase,
          online: s.online,
          questions: s.questions,
          questionIndex: s.questionIndex,
          wrongKey: s.wrongKey,
          wrongSeq: s.wrongSeq,
          correctKey: s.correctKey,
          paused: s.paused,
          comboStreak: s.comboStreak,
          starGateStage: s.starGateStage,
        )));
    final tablet = context.isTablet;
    final landscape = context.formFactor == FormFactor.tabletLandscape;
    final q =
        state.questions.isEmpty ? null : state.questions[state.questionIndex];
    final enabled = state.phase == RacePhase.racing &&
        !state.paused &&
        state.correctKey == null &&
        state.starGateStage == null;

    final liveCombo = math.max(comboStreak, state.comboStreak);
    final isNitro = nitroActive || liveCombo >= 2;

    return Container(
      decoration: const BoxDecoration(
        color: GameColors.cockpitBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.cockpitShadow,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          border: Border(
            top: BorderSide(
              color: GameColors.star.withOpacity(0.95),
              width: 3.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: landscape ? 32 : (tablet ? 32 : 16),
              vertical: state.online && !tablet ? 10 : (tablet ? 18 : 14),
            ),
            child: q == null
                ? _CockpitPlaceholder(tablet: tablet, landscape: landscape)
                : state.starGateStage != null
                    ? _StarGateBoard(
                        stage: state.starGateStage!,
                        tablet: tablet,
                        landscape: landscape,
                      )
                    : Column(
                        mainAxisSize:
                            landscape ? MainAxisSize.max : MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (landscape) const Spacer(),
                          if (state.online) ...[
                            const _OnlineStickerBar(),
                            SizedBox(height: tablet ? 10 : 6),
                          ],

                          // Top instrument bar: Speed Gauge (left) & Co-pilot Chíp (right)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Toy Speed / Energy Gauge
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: tablet ? 12 : 8,
                                    vertical: tablet ? 5 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GameColors.gaugeBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: GameColors.gaugeBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isNitro
                                              ? Icons.bolt_rounded
                                              : Icons.speed_rounded,
                                          size: tablet ? 20 : 16,
                                          color: GameColors.gaugeIcon,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isNitro
                                              ? 'BỨT TỐC x$liveCombo!'
                                              : 'NĂNG LƯỢNG',
                                          style: TextStyle(
                                            fontSize: tablet ? 14 : 11,
                                            fontWeight: FontWeight.w900,
                                            color: GameColors.gaugeText,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Right: Co-pilot Chíp reaction / speech bubble
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: tablet ? 10 : 8,
                                          vertical: tablet ? 5 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.card,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.accent,
                                            width: 1.5,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: GameColors.hudShadow,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isNitro
                                                ? 'Nhanh quá!'
                                                : (q.comet
                                                    ? 'Sao chổi!'
                                                    : 'Cố lên!'),
                                            style: TextStyle(
                                              fontSize: tablet ? 14 : 11,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: tablet ? 42 : 32,
                                      height: tablet ? 42 : 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: GameColors.coPilotBg,
                                        border: Border.all(
                                          color: AppColors.accent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          isNitro
                                              ? AppImages.chipSurprise
                                              : AppImages.chipJoy,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: tablet ? 14 : 10),

                          // Central Question Card (with perched comet if comet question)
                          RaceQuestionCard(
                            key: ValueKey('q-${state.questionIndex}'),
                            question: q,
                            onListen: onListen,
                          ),
                          SizedBox(height: tablet ? 16 : 10),

                          // 3 Chunky 3D Arcade Keys
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (tablet ? 80.0 : 64.0) + 10,
                              maxHeight: tablet ? 280 : 160,
                            ),
                            child: SizedBox(
                              height: landscape ? 240 : (tablet ? 100 : 76),
                              child: AnswerKeys(
                                labelOf: (i, ink) =>
                                    raceKeyLabel(q, i, ink, tablet),
                                semanticsOf: (i) => raceKeySemantics(q, i),
                                onPressed: enabled ? onKey : null,
                                wrongKey: state.wrongKey,
                                wrongSeq: state.wrongSeq,
                                correctKey: state.correctKey,
                                gap: tablet ? 16 : 12,
                              ),
                            ),
                          ),
                          if (landscape) const Spacer(),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _CockpitPlaceholder extends StatelessWidget {
  const _CockpitPlaceholder({required this.tablet, required this.landscape});

  final bool tablet;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final keyHeight = tablet ? 88.0 : 66.0;
    return Column(
      mainAxisSize: landscape ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (landscape) const Spacer(),
        // Top instrument row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? 12 : 8,
                vertical: tablet ? 5 : 4,
              ),
              decoration: BoxDecoration(
                color: GameColors.gaugeBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GameColors.gaugeBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: tablet ? 20 : 16,
                    color: GameColors.gaugeIcon,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'NĂNG LƯỢNG',
                    style: TextStyle(
                      fontSize: tablet ? 14 : 11,
                      fontWeight: FontWeight.w900,
                      color: GameColors.gaugeText,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tablet ? 10 : 8,
                    vertical: tablet ? 5 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: GameColors.hudShadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Cố lên!',
                    style: TextStyle(
                      fontSize: tablet ? 14 : 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: tablet ? 42 : 32,
                  height: tablet ? 42 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GameColors.coPilotBg,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppImages.chipJoy,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: tablet ? 12 : 8),

        // Placeholder question card
        Container(
          width: double.infinity,
          height: tablet ? 104 : 80,
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 20 : 14,
            vertical: tablet ? 14 : 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: GameColors.questionCardEdge,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: GameColors.questionCardEdge,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.rocketOrange,
                  width: tablet ? 32 : 24,
                  height: tablet ? 32 : 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Sẵn sàng xuất phát!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: tablet ? 20 : 15,
                      fontWeight: FontWeight.w900,
                      color: GameColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tablet ? 14 : 10),

        // 3 inactive placeholder keys
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: tablet ? 14 : 10),
              Expanded(
                child: Container(
                  height: keyHeight,
                  decoration: raisedKeyDecoration(
                    top: GameColors.keyOrangeTop.withOpacity(0.5),
                    body: GameColors.keyOrange.withOpacity(0.5),
                    edge: GameColors.keyOrangeEdge.withOpacity(0.5),
                    radius: tablet ? 26 : 20,
                    lip: tablet ? 9 : 7,
                    pressed: false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

typedef FloatingCockpitHUD = AnswerDesk;
