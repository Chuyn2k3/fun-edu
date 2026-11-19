import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/data/game_repository.dart';
import '../../game/data/reward_pool.dart';
import '../../game/engine/race_question.dart';
import '../../game/scene/flame_painter.dart';
import '../../game/scene/rocket_sprite.dart';
import '../../game/scene/trails.dart';
import '../../math/math_question.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../voice/speaker.dart';
import '../../voice/voice_lines.dart';
import 'badge_popup.dart';
import 'fireworks.dart';
import 'glyph_view.dart';
import 'item_art.dart';
import 'race_controller.dart';
import 'race_screen.dart';
import 'reward_offer_sheet.dart';

/// Stars toward the next milestone and the item waiting there.
class NextReward {
  const NextReward({
    required this.total,
    required this.from,
    required this.to,
    required this.itemId,
  });

  final int total;
  final int from;
  final int to;

  /// Null once every pool item is owned.
  final String? itemId;

  int get left => math.max(0, to - total);
  double get progress =>
      to == from ? 1 : ((total - from) / (to - from)).clamp(0, 1);
}

final nextRewardProvider = FutureProvider.autoDispose<NextReward>((ref) async {
  ref.watch(gameDataRevisionProvider);
  final repo = await ref.watch(gameRepositoryProvider.future);
  final total = await repo.totalStars();
  final owned = await repo.owned();
  final ms = milestones(upTo: total + 60);
  final to = ms.firstWhere((m) => m > total, orElse: () => total);
  final from = ms.lastWhere((m) => m <= total, orElse: () => 0);
  final offer = nextOffer(owned);
  return NextReward(
    total: total,
    from: from,
    to: to,
    itemId: offer.isEmpty ? null : offer.first,
  );
});

const _winTitle = 'Về đích rồi!';
const _unsavedLine = 'Chíp chưa ghi được sao lần này. Bé đua lại nhé!';

/// The race result: a landing cut-scene for a win, then the stars, the
/// record or Chíp's tip, new badges and milestone gifts, and "Đua lại!".
class RaceResultScreen extends ConsumerStatefulWidget {
  const RaceResultScreen({super.key, required this.args});

  final RaceResultArgs args;

  @override
  ConsumerState<RaceResultScreen> createState() => _RaceResultScreenState();
}

class _RaceResultScreenState extends ConsumerState<RaceResultScreen> {
  late final Speaker _speaker;
  late bool _intro = widget.args.won;

  RaceResultArgs get a => widget.args;

  String get _loseTitle => 'Suýt nữa thôi! Chỉ còn ${a.stepsShort} bước!';

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    if (!_intro) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }
  }

  @override
  void dispose() {
    _speaker.stop();
    super.dispose();
  }

  void _endIntro() {
    if (!_intro || !mounted) return;
    setState(() => _intro = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  /// Badges first, then one gift sheet per milestone waiting, then (after a
  /// loss) Chíp's gentle tip.
  Future<void> _celebrate() async {
    for (final b in a.newBadges) {
      if (!mounted) return;
      await showBadgePopup(context, b);
    }
    if (!mounted) return;
    if (a.saved) await _offerGifts();
    if (!mounted) return;
    // Gifts may have been picked: refresh every game screen (the hub stays
    // mounted under the result).
    ref.read(gameDataRevisionProvider.notifier).state++;
    if (!a.saved) {
      _speaker.speak(_unsavedLine);
    } else if (!a.won) {
      _speaker.speak('$_loseTitle ${_tipSpoken()}');
    } else {
      _speaker.speak('Bé được ${a.record!.starsEarned} sao vũ trụ!');
    }
  }

  /// One sheet per milestone waiting. A failed read or pick ends the
  /// sheets quietly (the offer stays pending for next time).
  Future<void> _offerGifts() async {
    try {
      final repo = await ref.read(gameRepositoryProvider.future);
      for (var guard = 0; guard < 20 && mounted; guard++) {
        final offer = await repo.pendingOffer();
        if (offer.isEmpty || !mounted) break;
        final picked = await showRewardOfferSheet(context, offer);
        if (picked == null) break;
        await repo.pick(picked);
      }
    } catch (e) {
      debugPrint('Gift offer failed: $e');
    }
  }

  String _tipSpoken() {
    final m = a.outcome.missed;
    if (m.isEmpty) {
      return 'Bí kíp của Chíp: lần sau mình nhanh tay hơn chút nhé.';
    }
    return 'Bí kíp của Chíp: ${switch (m.first) {
      MathRaceQuestion(question: final ArithmeticQuestion q) =>
        '${_num(q.a)} ${q.plus ? 'cộng' : 'trừ'} ${_num(q.b)} bằng ${_num(q.answer)} nhé.',
      MathRaceQuestion q => 'có ${_num(q.answer)} ngôi sao nhé.',
      LetterRaceQuestion q => 'đây là ${q.speech} nhé.',
      ToneRaceQuestion q => 'đây là ${q.spoken} nhé.',
    }}';
  }

  static String _num(int n) => n >= 0 && n <= 20 ? numberToVietnamese(n) : '$n';

  void _again() => context.go('/game/race/${subjectSlug(a.subject)}',
      extra: RaceArgs(retryAfterLoss: !a.won));

  @override
  Widget build(BuildContext context) {
    final form = context.formFactor;
    final hero = _Hero(args: a);
    final panel = _panel(context);
    final body = form == FormFactor.tabletLandscape
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: hero),
              Expanded(child: panel),
            ],
          )
        : Column(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height *
                    (form == FormFactor.phone ? 0.34 : 0.38),
                child: hero,
              ),
              Expanded(child: panel),
            ],
          );
    return Scaffold(
      backgroundColor: GameColors.panelTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          body,
          if (_intro)
            LandingCutScene(
              key: const ValueKey('landing-cutscene'),
              rocket: a.rocket,
              trail: a.trail,
              onDone: _endIntro,
            ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final tablet = context.isTablet;
    final landscape = context.formFactor == FormFactor.tabletLandscape;
    final faster = a.secondsFaster;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.panelTop, GameColors.panelBottom],
        ),
      ),
      child: SafeArea(
        top: landscape,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                math.max(tablet ? 32.0 : 18.0, (c.maxWidth - 620) / 2),
                tablet ? 24 : 16,
                math.max(tablet ? 32.0 : 18.0, (c.maxWidth - 620) / 2),
                tablet ? 28 : 16),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: c.maxHeight - (tablet ? 52 : 32)),
              child: IntrinsicHeight(
                child: Builder(
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (a.won)
                            Text(
                              _winTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: tablet ? 38 : 28,
                                fontWeight: FontWeight.w900,
                                color: GameColors.ink,
                                height: 1.15,
                              ),
                            )
                          else ...[
                            Text(
                              'Suýt nữa thôi!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: tablet ? 38 : 28,
                                fontWeight: FontWeight.w900,
                                color: GameColors.ink,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chỉ còn ${a.stepsShort} bước!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: tablet ? 24 : 18,
                                fontWeight: FontWeight.w800,
                                color: GameColors.ink.withOpacity(0.85),
                              ),
                            ),
                          ],
                          if (faster != null) ...[
                            SizedBox(height: tablet ? 12 : 8),
                            _RecordBadge(seconds: faster),
                          ],
                          SizedBox(height: tablet ? 16 : 12),
                          if (a.saved)
                            _StarsPill(
                              stars: a.record!.starsEarned,
                              won: a.won,
                              luckyStars: a.luckyStarsCollected,
                            )
                          else
                            _UnsavedNote(text: _unsavedLine, tablet: tablet),
                          if (!a.won) ...[
                            SizedBox(height: tablet ? 16 : 12),
                            _TipCard(args: a),
                          ],
                          if (a.saved) ...[
                            SizedBox(height: tablet ? 16 : 12),
                            const _NextRewardBar(),
                          ],
                        ],
                      ),
                      // Chíp cheers in the room left above the buttons.
                      if (a.won)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: tablet ? 20 : 12),
                            child: Stack(
                              children: [
                                SizedBox(height: tablet ? 140 : 96),
                                Positioned.fill(
                                  child: Image.asset(AppImages.chipJoy,
                                      fit: BoxFit.contain),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Padding(
                        padding: EdgeInsets.only(top: tablet ? 24 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BigGameButton(label: 'Đua lại!', onTap: _again),
                            SizedBox(height: tablet ? 16 : 12),
                            BigGameButton(
                              label: 'Về Góc Chơi',
                              primary: false,
                              onTap: () => context.go('/game'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The purple sky with the finish planet: the kid's rocket landed on top
/// with a flag after a win; just short of it (Chíp on top) after a loss.
class _Hero extends StatelessWidget {
  const _Hero({required this.args});

  final RaceResultArgs args;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.skyTop,
            GameColors.skyUpper,
            GameColors.skyLower,
            GameColors.panelTop,
          ],
          stops: [0.0, 0.30, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight;
          final w = c.maxWidth;
          final planet = math.min(w * 0.62, h * 0.62);
          final rocketH = planet * 0.58;
          // Short heroes crop the planet's bottom; tall ones centre it.
          final planetTop =
              math.min(h - planet * 0.92, h * 0.55 - planet * 0.3);
          final cx = w / 2;
          final kid = RocketSprite.forItem(args.rocket);
          final chipW = rocketH / RocketSprite.chip.aspect;
          final kidH = rocketH * 0.9;
          final kidW = kidH / kid.aspect;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _StarDust()),
              Positioned(
                left: cx - planet / 2,
                top: planetTop,
                width: planet,
                height: planet,
                child: Image.asset(AppImages.planet, fit: BoxFit.contain),
              ),
              if (args.won) ...[
                Positioned(
                  left: cx + planet * 0.06,
                  top: planetTop - planet * 0.3,
                  width: planet * 0.3,
                  height: planet * 0.42,
                  child: const CustomPaint(painter: _FlagPainter()),
                ),
                Positioned(
                  left: cx - planet * 0.32,
                  top: planetTop - rocketH * 0.78,
                  height: rocketH,
                  child: Image.asset(kid.asset, fit: BoxFit.contain),
                ),
              ] else ...[
                // Chíp landed on top; the kid's rocket waits beside the
                // planet. Both are kept fully inside the hero.
                Positioned(
                  left:
                      (cx - chipW / 2).clamp(4.0, math.max(4.0, w - chipW - 4)),
                  top: math.max(4.0, planetTop - rocketH * 0.82),
                  width: chipW,
                  height: rocketH,
                  child: Image.asset(AppImages.rocketChip, fit: BoxFit.contain),
                ),
                Positioned(
                  left: (cx - planet * 0.5 - kidW * 0.8)
                      .clamp(8.0, math.max(8.0, w - kidW - 8)),
                  top: math.min(planetTop + planet * 0.28, h - kidH - 4),
                  width: kidW,
                  height: kidH,
                  child: Image.asset(kid.asset, fit: BoxFit.contain),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// A few fixed stars on the hero sky.
class _StarDust extends StatelessWidget {
  const _StarDust();

  @override
  Widget build(BuildContext context) =>
      const RepaintBoundary(child: CustomPaint(painter: _StarDustPainter()));
}

class _StarDustPainter extends CustomPainter {
  const _StarDustPainter();

  static const _stars = [
    (0.08, 0.12, 1.6),
    (0.22, 0.30, 1.1),
    (0.35, 0.08, 1.3),
    (0.62, 0.16, 1.7),
    (0.78, 0.34, 1.2),
    (0.9, 0.1, 1.5),
    (0.12, 0.52, 1.2),
    (0.86, 0.6, 1.4),
    (0.5, 0.3, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = GameColors.starWarm;
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(Offset(x * size.width, y * size.height), r * 1.4, p);
    }
  }

  @override
  bool shouldRepaint(_StarDustPainter old) => false;
}

/// A pole with an orange pennant (the kid's flag on the planet).
class _FlagPainter extends CustomPainter {
  const _FlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pole = Paint()
      ..color = AppColors.card
      ..strokeWidth = math.max(3, w * 0.06)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.2, h), Offset(w * 0.2, h * 0.04), pole);
    final flag = Path()
      ..moveTo(w * 0.22, h * 0.06)
      ..quadraticBezierTo(w * 0.6, h * 0.0, w * 0.98, h * 0.2)
      ..quadraticBezierTo(w * 0.6, h * 0.34, w * 0.22, h * 0.42)
      ..close();
    canvas.drawPath(flag, Paint()..color = GameColors.go);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, h * 0.06)
        ..quadraticBezierTo(w * 0.6, h * 0.0, w * 0.98, h * 0.2)
        ..quadraticBezierTo(w * 0.6, h * 0.16, w * 0.22, h * 0.2)
        ..close(),
      Paint()..color = GameColors.goTop,
    );
    final star = Paint()..color = GameColors.flameMid;
    canvas.drawCircle(Offset(w * 0.5, h * 0.2), w * 0.07, star);
  }

  @override
  bool shouldRepaint(_FlagPainter old) => false;
}

class _UnsavedNote extends StatelessWidget {
  const _UnsavedNote({required this.text, required this.tablet});

  final String text;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      decoration: raisedDecoration(),
      child: Row(
        children: [
          Image.asset(AppImages.chipEncourage, height: tablet ? 80 : 60),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: tablet ? 22 : 18,
                fontWeight: FontWeight.w900,
                color: GameColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  const _RecordBadge({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: raisedKeyDecoration(
        top: GameColors.keyGreenTop,
        body: GameColors.keyGreen,
        edge: GameColors.keyGreenEdge,
        radius: 22,
        lip: 6,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.icCrown, height: tablet ? 40 : 30),
              const SizedBox(width: 8),
              Text(
                'Kỷ lục mới!',
                style: TextStyle(
                  fontSize: tablet ? 30 : 24,
                  fontWeight: FontWeight.w900,
                  color: GameColors.keyGreenInk,
                ),
              ),
            ],
          ),
          Text(
            'nhanh hơn $seconds giây',
            style: TextStyle(
              fontSize: tablet ? 22 : 17,
              fontWeight: FontWeight.w800,
              color: GameColors.keyGreenInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarsPill extends StatelessWidget {
  const _StarsPill({
    required this.stars,
    required this.won,
    this.luckyStars = 0,
  });

  final int stars;
  final bool won;
  final int luckyStars;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 24 : 18,
            vertical: tablet ? 12 : 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: const [
              BoxShadow(
                color: GameColors.questionCardEdge,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AppImages.icStar, height: tablet ? 42 : 32),
              const SizedBox(width: 8),
              Text(
                '+$stars',
                style: TextStyle(
                  fontSize: tablet ? 32 : 26,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
              if (luckyStars > 0) ...[
                const SizedBox(width: 14),
                Container(
                  width: 2,
                  height: tablet ? 24 : 18,
                  color: GameColors.questionCardEdge,
                ),
                const SizedBox(width: 14),
                Row(
                  key: const ValueKey('lucky-stars-reward'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppImages.icStar,
                      height: tablet ? 32 : 24,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+$luckyStars',
                      style: TextStyle(
                        fontSize: tablet ? 28 : 22,
                        fontWeight: FontWeight.w900,
                        color: GameColors.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (!won) ...[
          const SizedBox(height: 8),
          Text(
            'Về nhì vẫn được sao. Bé giỏi lắm!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tablet ? 20 : 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// "Bí kíp của Chíp": the first question the kid missed and its answer.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.args});

  final RaceResultArgs args;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final missed = args.outcome.missed;
    final text = TextStyle(
      fontSize: tablet ? 28 : 22,
      fontWeight: FontWeight.w900,
      color: GameColors.ink,
    );
    final glyphBox = tablet ? 84.0 : 64.0;
    Widget question;
    Widget answer;
    if (missed.isEmpty) {
      question = Text('Bé trả lời đúng hết!', style: text);
      answer = Text('Lần sau nhanh tay hơn chút nhé.',
          style: text.copyWith(fontSize: text.fontSize! * 0.8));
    } else {
      switch (missed.first) {
        case MathRaceQuestion(question: final ArithmeticQuestion q):
          question = Text(q.prompt, style: text);
          answer = Text('${q.answer}', style: text);
        case final MathRaceQuestion q:
          question = Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(AppImages.icStar, height: tablet ? 34 : 26),
            Text(' ×?', style: text),
          ]);
          answer = Text('${q.answer}', style: text);
        case final LetterRaceQuestion q:
          question = Text('“${q.speech}”', style: text);
          answer = SizedBox(
              width: glyphBox,
              height: glyphBox,
              child:
                  GlyphView(q.targetGlyphId, color: GameColors.keyOrangeInk));
        case final ToneRaceQuestion q:
          question = Text('“${q.spoken}”', style: text);
          answer = SizedBox(
              width: glyphBox,
              height: glyphBox,
              child: GlyphView(q.targetMarkId, color: GameColors.keyOrangeInk));
      }
    }
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, tablet ? 20 : 14, 14),
      decoration: raisedDecoration(
        accent: GameColors.keyOrangeEdge,
        tint: GameColors.keyOrangeTop,
      ),
      child: Row(
        children: [
          Image.asset(AppImages.chipThumb, height: tablet ? 104 : 76),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bí kíp của Chíp',
                  style: TextStyle(
                    fontSize: tablet ? 22 : 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryOnTint,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    KeyedSubtree(
                        key: const ValueKey('tip-question'), child: question),
                    if (missed.isNotEmpty)
                      Icon(Icons.arrow_forward_rounded,
                          size: tablet ? 32 : 26, color: GameColors.ink),
                    if (missed.isNotEmpty)
                      Container(
                        key: const ValueKey('tip-answer'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: GameColors.keyOrangeTop,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: answer,
                      )
                    else
                      answer,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stars still needed for the next gift, with that gift shown blurred.
class _NextRewardBar extends ConsumerWidget {
  const _NextRewardBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextRewardProvider).valueOrNull;
    final tablet = context.isTablet;
    if (next == null) return SizedBox(height: tablet ? 100 : 84);
    final item = next.itemId;
    final art = tablet ? 76.0 : 60.0;
    return Container(
      key: const ValueKey('next-reward'),
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
      decoration: raisedDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: art,
            height: art,
            child: item == null
                ? Image.asset(AppImages.icCrown)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          GameColors.lockedSilhouette,
                          BlendMode.srcIn,
                        ),
                        child: ItemArt(item),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GameColors.star.withOpacity(0.85),
                        ),
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: tablet ? 24 : 18,
                            fontWeight: FontWeight.w900,
                            color: GameColors.lockedSilhouette,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item == null
                      ? 'Bé đã mở hết quà rồi!'
                      : 'Còn ${next.left} sao nữa là có quà mới!',
                  style: TextStyle(
                    fontSize: tablet ? 22 : 17,
                    fontWeight: FontWeight.w900,
                    color: GameColors.ink,
                  ),
                ),
                if (item != null) ...[
                  const SizedBox(height: 8),
                  _Progress(value: next.progress, height: tablet ? 18 : 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.height});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: GameColors.questionCardEdge,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: math.max(0.06, value),
        child: Container(
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [GameColors.goTop, GameColors.go]),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),
    );
  }
}

/// About 3 s: the kid's rocket flies up and lands on the planet, a flag
/// pops up, fireworks, Chíp claps. Tap anywhere to skip. Under reduce
/// motion it shows the final frame for the same time.
class LandingCutScene extends ConsumerStatefulWidget {
  const LandingCutScene({
    super.key,
    required this.rocket,
    required this.trail,
    required this.onDone,
  });

  final String rocket;
  final String trail;
  final VoidCallback onDone;

  static const duration = Duration(milliseconds: 3000);

  @override
  ConsumerState<LandingCutScene> createState() => _LandingCutSceneState();
}

class _LandingCutSceneState extends ConsumerState<LandingCutScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: LandingCutScene.duration);

  /// How long the cut-scene has been on screen. Ticker-bound (it stops under
  /// the sleep screen) and held while the app is not in front, so the badge
  /// popups and gift sheets never open in the background. Linear and not
  /// shortened by reduce motion.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: LandingCutScene.duration,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _done();
    });
  bool _decided = false;
  bool _ended = false;
  late final Speaker _speaker = ref.read(speakerProvider);

  @override
  void initState() {
    super.initState();
    _speaker.speak('Về đích rồi! Bé thắng Chíp rồi!');
    WidgetsBinding.instance.addObserver(this);
    _syncHold();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _syncHold();

  void _syncHold() {
    if (_ended) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life == null || life == AppLifecycleState.resumed) {
      _hold.forward();
    } else {
      _hold.stop();
    }
  }

  void _done() {
    if (_ended) return;
    _ended = true;
    _hold.stop();
    widget.onDone();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hold.dispose();
    _c.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final sprite = RocketSprite.forItem(widget.rocket);
    final palette = TrailStyle.fromId(widget.trail).palette;
    final tablet = context.isTablet;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _done,
      child: Semantics(
        button: true,
        label: '$_winTitle Chạm để xem kết quả',
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameColors.skyTop,
                GameColors.skyUpper,
                GameColors.skyLower,
                GameColors.skyHorizon,
              ],
              stops: [0, 0.4, 0.75, 1],
            ),
          ),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            final planet = math.min(w * 0.7, h * 0.42);
            final planetTop = h * 0.5;
            final rocketH = planet * 0.6;
            final rocketW = rocketH / sprite.aspect;
            final restY = planetTop - rocketH * 0.8;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(child: _StarDust()),
                Positioned(
                  left: (w - planet) / 2,
                  top: planetTop,
                  width: planet,
                  height: planet,
                  child: Image.asset(AppImages.planet, fit: BoxFit.contain),
                ),
                Positioned.fill(
                  child: Fireworks(
                    bursts: 6,
                    delay: const Duration(milliseconds: 1500),
                    duration: const Duration(milliseconds: 1500),
                    repeat: false,
                    key: ValueKey(reduce),
                  ),
                ),
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final t = _c.value;
                    final fly = Curves.easeOutBack.transform(_seg(t, 0, 0.5));
                    final y = h + rocketH - (h + rocketH - restY) * fly;
                    final flag =
                        Curves.elasticOut.transform(_seg(t, 0.5, 0.72));
                    final chip =
                        Curves.elasticOut.transform(_seg(t, 0.55, 0.8));
                    final clap =
                        math.sin(t * math.pi * 14) * 0.08 * _seg(t, 0.6, 0.7);
                    final title =
                        Curves.easeOutBack.transform(_seg(t, 0.45, 0.65));
                    final flame = 1 - _seg(t, 0.42, 0.55);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (flame > 0)
                          Positioned(
                            left: w / 2 - rocketW * 0.3,
                            top: y + rocketH * sprite.nozzle - 4,
                            width: rocketW * 0.6,
                            height: rocketH * 0.9 * flame,
                            child: CustomPaint(
                              painter: FlamePainter(
                                time: t * 3,
                                intensity: 1.6,
                                palette: palette,
                              ),
                            ),
                          ),
                        Positioned(
                          left: w / 2 - rocketW / 2,
                          top: y,
                          width: rocketW,
                          height: rocketH,
                          child: Image.asset(sprite.asset, fit: BoxFit.contain),
                        ),
                        Positioned(
                          left: w / 2 + planet * 0.12,
                          top: planetTop - planet * 0.34,
                          width: planet * 0.3,
                          height: planet * 0.42,
                          child: Transform.scale(
                            scale: flag,
                            alignment: Alignment.bottomLeft,
                            child: const CustomPaint(painter: _FlagPainter()),
                          ),
                        ),
                        Positioned(
                          left: w * 0.04,
                          bottom: h * 0.04,
                          height: h * 0.26,
                          child: Transform.rotate(
                            angle: clap,
                            child: Transform.scale(
                              scale: chip,
                              alignment: Alignment.bottomCenter,
                              child: Image.asset(AppImages.chipJoy,
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: MediaQuery.paddingOf(context).top + h * 0.08,
                          child: Transform.scale(
                            scale: title,
                            child: Text(
                              _winTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: tablet ? 64 : 44,
                                fontWeight: FontWeight.w900,
                                color: AppColors.card,
                                shadows: const [
                                  Shadow(
                                      color: GameColors.skyTop,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
