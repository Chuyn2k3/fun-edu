import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stroke/glyph.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/theme/tokens.dart';

/// Height of a glyph's ink in ruling cells (at least [minCells]), used to
/// draw the three letters of one question at one shared scale.
double glyphHeightCells(Glyph g, {double minCells = 1.6}) {
  final w = g.inWindow();
  final cell = w.ruling?.cell ?? 1;
  final b = _inkBounds(w);
  if (b == null) return minCells;
  return math.max(b.height / cell, minCells);
}

Rect? _inkBounds(Glyph g) {
  double? l, t, r, b;
  for (final s in g.strokes) {
    for (final p in s.points) {
      l = l == null ? p.x : math.min(l, p.x);
      r = r == null ? p.x : math.max(r, p.x);
      t = t == null ? p.y : math.min(t, p.y);
      b = b == null ? p.y : math.max(b, p.y);
    }
  }
  if (l == null) return null;
  return Rect.fromLTRB(l, t!, r!, b!);
}

/// A glyph's reference strokes (in its writing window, [Glyph.inWindow])
/// drawn as solid ink, centred in the box. Strokes keep the school letter
/// shapes (no font). A tone mark (`dau-*`) draws only the mark.
///
/// [heightCells] is the tallest ink of the glyphs drawn side by side, in
/// ruling cells, so b/d/h and n/m/u keep their true relative size; it
/// defaults to this glyph's own height.
class GlyphView extends ConsumerWidget {
  const GlyphView(
    this.glyphId, {
    super.key,
    this.color = GameColors.ink,
    this.heightCells,
    this.fill = 0.62,
  });

  final String glyphId;
  final Color color;
  final double? heightCells;

  /// Share of the box height the tallest ink may take.
  final double fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glyph = ref.watch(glyphProvider(glyphId)).valueOrNull;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: glyph == null
              ? null
              : GlyphInkPainter(
                  glyph.inWindow(),
                  color: color,
                  heightCells: heightCells ?? glyphHeightCells(glyph),
                  fill: fill,
                ),
        ),
      ),
    );
  }
}

class GlyphInkPainter extends CustomPainter {
  GlyphInkPainter(
    this.glyph, {
    required this.color,
    required this.heightCells,
    required this.fill,
  })  : _bounds = _inkBounds(glyph),
        _paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

  /// Already in window coordinates.
  final Glyph glyph;
  final Color color;
  final double heightCells;
  final double fill;
  final Rect? _bounds;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final b = _bounds;
    if (b == null || size.isEmpty) return;
    final cell = glyph.ruling?.cell ?? 0.25;
    // One cell in pixels: the tallest sibling fills [fill] of the height,
    // never wider than the box allows.
    var px = size.height * fill / heightCells;
    final widthCells = b.width / cell;
    if (widthCells > 0) {
      px = math.min(px, size.width * 0.8 / widthCells);
    }
    final scale = px / cell;
    _paint.strokeWidth = px * 0.34;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-b.center.dx, -b.center.dy);
    final path = Path();
    for (final s in glyph.strokes) {
      if (s.points.isEmpty) continue;
      final first = s.points.first;
      path.moveTo(first.x, first.y);
      if (s.points.length == 1) {
        path.lineTo(first.x + 1e-4, first.y);
      }
      for (final p in s.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
    }
    _paint.strokeWidth = _paint.strokeWidth / scale;
    canvas.drawPath(path, _paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlyphInkPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.heightCells != heightCells ||
      oldDelegate.fill != fill;
}
