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
                          _QuestionCard(
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
                                    _keyLabel(q, i, ink, tablet),
                                semanticsOf: (i) => _keySemantics(q, i),
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

  Widget _keyLabel(RaceQuestion q, int i, Color ink, bool tablet) {
    switch (q) {
      case MathRaceQuestion():
        return Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            child: Text(
              '${q.choices[i]}',
              style: TextStyle(
                fontSize: tablet ? 64 : 46,
                fontWeight: FontWeight.w900,
                color: ink,
                height: 1.1,
              ),
            ),
          ),
        );
      case LetterRaceQuestion():
        return _GlyphKey(ids: q.choiceGlyphIds, index: i, ink: ink);
      case ToneRaceQuestion():
        return _GlyphKey(ids: q.choiceMarkIds, index: i, ink: ink);
    }
  }

  String _keySemantics(RaceQuestion q, int i) => switch (q) {
        MathRaceQuestion() => '${q.choices[i]}',
        LetterRaceQuestion() => q.choiceGlyphIds[i],
        ToneRaceQuestion() => toneLabels[q.choiceMarkIds[i]] ?? '',
      };
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

/// One glyph key: drawn at the scale shared by the question's three glyphs.
class _GlyphKey extends ConsumerWidget {
  const _GlyphKey({required this.ids, required this.index, required this.ink});

  final List<String> ids;
  final int index;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var tallest = 0.0;
    for (final id in ids) {
      final g = ref.watch(glyphProvider(id)).valueOrNull;
      if (g != null) tallest = math.max(tallest, glyphHeightCells(g));
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GlyphView(
        ids[index],
        color: ink,
        heightCells: tallest == 0 ? null : tallest,
      ),
    );
  }
}

/// The white question card: a sum, stars to count, or (Tiếng Việt) a big
/// speaker button to hear the letter or tone mark again.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard(
      {super.key, required this.question, required this.onListen});

  final RaceQuestion question;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    debugQuestionCardBuilds++;
    final tablet = context.isTablet;
    final q = question;
    final Widget child = switch (q) {
      MathRaceQuestion(question: final ArithmeticQuestion a) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                child: Text(
                  a.prompt,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: tablet ? 60 : 44,
                    fontWeight: FontWeight.w900,
                    color: GameColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ListenButton(onTap: onListen, size: tablet ? 80 : 64),
          ],
        ),
      MathRaceQuestion(question: final CountQuestion c) =>
        _countCard(c.n, tablet),
      MathRaceQuestion(question: final MatchQuestion m) =>
        _countCard(m.n, tablet),
      MathRaceQuestion() => const SizedBox.shrink(),
      LetterRaceQuestion() => _listenCard('Chíp đọc chữ nào?', tablet),
      ToneRaceQuestion() => _listenCard('Chíp đọc dấu nào?', tablet),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: tablet ? 20 : 14, vertical: tablet ? 14 : 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color:
                  q.comet ? GameColors.cometRim : GameColors.questionCardEdge,
              width: q.comet ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: q.comet
                    ? GameColors.stoneLuckyGlow.withOpacity(0.35)
                    : GameColors.questionCardEdge,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: GameColors.keyOrangeEdge.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        if (q.comet)
          Positioned(
            left: -10,
            top: -12,
            child: Image.asset(
              AppImages.comet,
              width: tablet ? 42 : 32,
              height: tablet ? 42 : 32,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }

  Widget _countCard(int n, bool tablet) {
    final star = tablet ? 46.0 : 30.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Có bao nhiêu ngôi sao?',
                style: TextStyle(
                  fontSize: tablet ? 26 : 19,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: star * 5 + 4 * 4),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < n; i++)
                      Image.asset(
                        AppImages.icStar,
                        width: star,
                        height: star,
                        fit: BoxFit.contain,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ListenButton(onTap: onListen, size: tablet ? 80 : 64),
      ],
    );
  }

  Widget _listenCard(String prompt, bool tablet) {
    return Row(
      children: [
        Expanded(
          child: Text(
            prompt,
            style: TextStyle(
              fontSize: tablet ? 26 : 19,
              fontWeight: FontWeight.w900,
              color: GameColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ListenButton(onTap: onListen, size: tablet ? 80 : 64, big: true),
      ],
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton(
      {required this.onTap, required this.size, this.big = false});

  final VoidCallback onTap;
  final double size;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final face = big ? size * 0.9 : size * 0.72;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Pressable(
          key: ValueKey(big ? 'listen-big' : 'listen'),
          onTap: onTap,
          semanticsLabel: 'Nghe câu hỏi',
          builder: (pressed) => Container(
            width: face,
            height: face,
            decoration: raisedKeyDecoration(
              top: GameColors.listenFill,
              body: GameColors.listenFill,
              edge: GameColors.listenEdge,
              radius: face / 2,
              lip: big ? 6 : 4,
              pressed: pressed,
            ),
            child: Icon(Icons.volume_up_rounded,
                size: face * 0.5, color: GameColors.listenInk),
          ),
        ),
      ),
    );
  }
}
