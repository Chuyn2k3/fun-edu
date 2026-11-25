// The race question card and answer key labels, shared by the rocket race
// and Chíp du lịch. Nothing here reads the race controller.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/engine/race_question.dart';
import '../../math/math_question.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import 'glyph_view.dart';

/// How many times the question card was built (tests check that Chíp's
/// steps do not rebuild it).
@visibleForTesting
int debugQuestionCardBuilds = 0;

/// Key label for answer [i] of [q], drawn in [ink].
Widget raceKeyLabel(RaceQuestion q, int i, Color ink, bool tablet) {
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

String raceKeySemantics(RaceQuestion q, int i) => switch (q) {
      MathRaceQuestion() => '${q.choices[i]}',
      LetterRaceQuestion() => q.choiceGlyphIds[i],
      ToneRaceQuestion() => toneLabels[q.choiceMarkIds[i]] ?? '',
    };


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
class RaceQuestionCard extends StatelessWidget {
  const RaceQuestionCard(
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
