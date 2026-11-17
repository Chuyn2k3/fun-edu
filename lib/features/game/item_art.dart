import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/data/reward_pool.dart';
import '../../game/scene/flame_painter.dart';
import '../../game/scene/rocket_sprite.dart';
import '../../game/scene/trails.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';

/// The picture of a garage item: the 3D image for rockets, rainbow smoke and
/// stickers; flame and sparkle trails are drawn in code. Static: nothing
/// animates.
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
      art = Image.asset(AppImages.stickers[itemId] ?? AppImages.chipMain,
          fit: BoxFit.contain);
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
