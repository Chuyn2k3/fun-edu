import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/data/reward_pool.dart';
import '../../game/scene/flame_painter.dart';
import '../../game/scene/rocket_sprite.dart';
import '../../game/scene/trails.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';

/// The picture of a garage item: the 3D image when there is one (rockets,
/// rainbow smoke), otherwise a simple code-drawn stand-in (flame trails,
/// sparkles, stickers) until their art exists. Static: nothing animates.
class ItemArt extends StatelessWidget {
  const ItemArt(this.itemId, {super.key});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final Widget art;
    if (itemId.startsWith('rocket_')) {
      art =
          Image.asset(RocketSprite.forItem(itemId).asset, fit: BoxFit.contain);
    } else if (itemId == 'trail_rainbow') {
      art = Image.asset(AppImages.trailRainbow, fit: BoxFit.contain);
    } else if (itemId == 'trail_flame' || itemId == 'trail_blue_flame') {
      art = CustomPaint(
        painter: FlamePainter(
          time: 0,
          intensity: 1.3,
          palette: TrailStyle.fromId(itemId).palette,
        ),
      );
    } else if (itemId == 'trail_sparkle') {
      art = const CustomPaint(painter: _SparklePainter());
    } else {
      art = _StickerStandIn(itemId);
    }
    return Semantics(
      label: itemTitle(itemId),
      image: true,
      child: ExcludeSemantics(child: art),
    );
  }
}

/// A few four-point stars in the sparkle trail colours.
class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  static const _stars = [
    (0.5, 0.42, 0.30, 0),
    (0.24, 0.72, 0.16, 2),
    (0.78, 0.70, 0.18, 3),
    (0.30, 0.20, 0.11, 1),
    (0.74, 0.18, 0.10, 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final p = Paint()..isAntiAlias = true;
    for (final (x, y, r, c) in _stars) {
      p.color = GameColors.sparkles[c];
      final cx = x * size.width, cy = y * size.height, rr = r * s;
      final path = Path()
        ..moveTo(cx, cy - rr)
        ..quadraticBezierTo(cx, cy, cx + rr, cy)
        ..quadraticBezierTo(cx, cy, cx, cy + rr)
        ..quadraticBezierTo(cx, cy, cx - rr, cy)
        ..quadraticBezierTo(cx, cy, cx, cy - rr)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..color = GameColors.goEdge.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, rr * 0.08));
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => false;
}

/// A sticker without art yet: a white die-cut badge with a smiling face.
class _StickerStandIn extends StatelessWidget {
  const _StickerStandIn(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StickerPainter(laugh: id.contains('laugh')));
  }
}

class _StickerPainter extends CustomPainter {
  const _StickerPainter({required this.laugh});

  final bool laugh;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.42;
    canvas.drawCircle(
        c.translate(0, r * 0.06), r, Paint()..color = GameColors.hudEdge);
    canvas.drawCircle(c, r, Paint()..color = AppColors.card);
    canvas.drawCircle(c, r * 0.8, Paint()..color = GameColors.keyOrangeTop);
    final ink = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.09;
    // Eyes: happy arcs.
    for (final dx in [-0.3, 0.3]) {
      canvas.drawArc(
          Rect.fromCenter(
              center: c.translate(dx * r, -0.12 * r),
              width: r * 0.26,
              height: r * 0.22),
          math.pi,
          math.pi,
          false,
          ink);
    }
    final mouth = Rect.fromCenter(
        center: c.translate(0, 0.16 * r), width: r * 0.6, height: r * 0.5);
    if (laugh) {
      canvas.drawArc(
          mouth, 0, math.pi, true, Paint()..color = GameColors.keyOrangeInk);
    } else {
      canvas.drawArc(mouth, 0.15, math.pi - 0.3, false, ink);
      // Two little hands clapping.
      final hand = Paint()..color = GameColors.keyOrangeEdge;
      canvas.drawCircle(c.translate(-0.62 * r, 0.42 * r), r * 0.16, hand);
      canvas.drawCircle(c.translate(0.62 * r, 0.42 * r), r * 0.16, hand);
    }
  }

  @override
  bool shouldRepaint(_StickerPainter old) => old.laugh != laugh;
}
