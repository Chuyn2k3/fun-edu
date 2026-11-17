import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';

/// Building blocks shared by the Góc Chơi screens (hub, garage, badge
/// cabinet, sticker album): the warm cream backdrop, a chunky back key, the
/// cosmic-stars pill, the space-sky card and the grey/silhouette filters.

/// Kid target size: 64 on a phone, 80 on a tablet.
double gameTarget(BuildContext context) =>
    context.isTablet ? TabletSizes.kidTarget : 64;

/// The cream gradient behind every Góc Chơi screen.
class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.panelTop, GameColors.panelBottom],
        ),
      ),
      child: child,
    );
  }
}

/// A white chunky card ("Bản 7"): white → cream, a thick cream-brown lip.
BoxDecoration whiteChunkyDecoration({
  bool pressed = false,
  double radius = 26,
  double lip = 8,
}) =>
    raisedKeyDecoration(
      top: AppColors.card,
      body: GameColors.questionCardTint,
      edge: GameColors.questionCardEdge,
      radius: radius,
      lip: lip,
      pressed: pressed,
    );

/// Square back key; goes to the Góc Chơi hub unless [onTap] says otherwise.
class GameBackButton extends StatelessWidget {
  const GameBackButton({
    super.key,
    required this.onTap,
    this.label = 'Về Góc Chơi',
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final size = gameTarget(context);
    return Pressable(
      onTap: onTap,
      semanticsLabel: label,
      builder: (pressed) => Container(
        width: size,
        height: size,
        decoration: whiteChunkyDecoration(pressed: pressed, radius: 20, lip: 6),
        child: Icon(Icons.arrow_back_rounded,
            size: size * 0.5, color: GameColors.ink),
      ),
    );
  }
}

/// Cosmic stars (the game's own currency, never the learning stars).
class CosmicStarsPill extends StatelessWidget {
  const CosmicStarsPill({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Semantics(
      label: '$stars sao vũ trụ',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 6, tablet ? 20 : 16, 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: const [
            BoxShadow(color: GameColors.questionCardEdge, offset: Offset(0, 5)),
            BoxShadow(
                color: GameColors.hudShadow,
                blurRadius: 14,
                offset: Offset(0, 9)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppImages.icStar, height: tablet ? 40 : 30),
            const SizedBox(width: 6),
            Text(
              '$stars',
              style: TextStyle(
                fontSize: tablet ? 26 : 20,
                fontWeight: FontWeight.w900,
                color: GameColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The deep-purple space card of the hub hero and the garage stage: sky
/// gradient, a soft violet glow at [glow] and a thick dark bottom edge.
BoxDecoration spaceCardDecoration({double radius = 32}) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment(-0.6, -1),
        end: Alignment(0.6, 1),
        colors: [GameColors.skyTop, GameColors.skyUpper, GameColors.skyLower],
        stops: [0, 0.6, 1],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(color: GameColors.stageEdge, offset: Offset(0, 10)),
        BoxShadow(
            color: GameColors.hudShadow, blurRadius: 26, offset: Offset(0, 18)),
      ],
    );

/// Static stars and a soft glow over a space card (drawn once).
class SpaceSkyPainter extends CustomPainter {
  const SpaceSkyPainter({this.glow = const Alignment(0.6, -0.7)});

  final Alignment glow;

  // (x, y, radius, warm) in unit box.
  static const _stars = [
    (0.08, 0.11, 1.6, true),
    (0.33, 0.07, 1.2, false),
    (0.52, 0.23, 1.4, true),
    (0.25, 0.34, 1.0, false),
    (0.47, 0.54, 1.2, false),
    (0.92, 0.71, 1.4, true),
    (0.14, 0.78, 1.1, false),
    (0.70, 0.12, 1.0, false),
    (0.62, 0.86, 1.2, true),
    (0.86, 0.40, 1.0, false),
    (0.04, 0.50, 1.2, true),
    (0.38, 0.92, 1.0, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = glow.alongSize(size);
    final r = size.shortestSide * 0.75;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          GameColors.skyGlow,
          GameColors.skyGlow.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final scale = math.max(1.0, size.shortestSide / 280);
    final p = Paint();
    for (final (x, y, rad, warm) in _stars) {
      p.color = warm ? GameColors.starWarm : GameColors.star;
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), rad * scale, p);
    }
  }

  @override
  bool shouldRepaint(SpaceSkyPainter oldDelegate) => oldDelegate.glow != glow;
}

/// Greys out a locked picture (luminance) and fades it.
class LockedLook extends StatelessWidget {
  const LockedLook({super.key, required this.child, this.opacity = 0.4});

  final Widget child;
  final double opacity;

  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: ColorFiltered(colorFilter: _grey, child: child),
      );
}

/// A flat one-colour silhouette of a picture.
class Silhouette extends StatelessWidget {
  const Silhouette({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColorFiltered(
        colorFilter:
            const ColorFilter.mode(GameColors.silhouette, BlendMode.srcIn),
        child: child,
      );
}

/// A small pill label (white on a tile), e.g. "Còn 25 sao vũ trụ".
class TilePill extends StatelessWidget {
  const TilePill({
    super.key,
    required this.text,
    this.icon,
    this.color = AppColors.card,
    this.ink = GameColors.lockedInk,
    this.edge = GameColors.lockedEdge,
    this.maxLines = 1,
  });

  final String text;
  final IconData? icon;

  /// 1: shrinks to fit one line; more: wraps (centred, rounded box).
  final int maxLines;
  final Color color;
  final Color ink;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final size = tablet ? 16.0 : 12.5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tablet ? 12 : 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(maxLines > 1 ? 12 : AppRadii.pill),
        boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 2, color: ink),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: maxLines > 1
                ? Text(
                    text,
                    maxLines: maxLines,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: size,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Screen header: back key, a centred title, and an optional trailing
/// widget (or a spacer of the same width, so the title stays centred).
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final side = gameTarget(context);
    return Row(
      children: [
        GameBackButton(onTap: onBack),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tablet ? 34 : 24,
              fontWeight: FontWeight.w900,
              color: GameColors.ink,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: side),
          child: Align(
            alignment: Alignment.centerRight,
            widthFactor: 1,
            child: trailing ?? SizedBox(width: side),
          ),
        ),
      ],
    );
  }
}

/// `d/m/yyyy` with two-digit day and month, e.g. 16/11/2026.
String formatDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// m:ss, e.g. 1:15.
String formatRaceTime(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
