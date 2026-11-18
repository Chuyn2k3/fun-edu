import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../features/writing/ruled_paper.dart';
import '../stroke/geometry.dart';
import '../stroke/glyph.dart';
import '../ui/theme/tokens.dart';
import 'worksheet_model.dart';

const double _eps = 1e-6;

/// Live instant preview of one A4 portrait worksheet page, mirroring the layout
/// and Vietnamese ô li rulings of `buildWorksheetPdf`.
class WorksheetPreview extends StatelessWidget {
  const WorksheetPreview({
    super.key,
    required this.config,
    required this.glyphs,
    required this.pageIndex,
  });

  final WorksheetConfig config;
  final Map<String, Glyph> glyphs;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final resolvedIds = [
      for (final id in config.glyphIds)
        if (glyphs.containsKey(id)) id,
    ];
    final pages = paginateGlyphs(resolvedIds);
    final pageCount = math.max(1, pages.length);
    final safePage = pageIndex.clamp(0, pageCount - 1);
    final pageIds = pages.isEmpty ? const <String>[] : pages[safePage];

    return AspectRatio(
      aspectRatio: 210 / 297,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WorksheetColors.paper,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          border: Border.all(color: AppColors.dot),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: RepaintBoundary(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
              width: 595.28,
              height: 841.89,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 30, 34, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PreviewHeader(
                      config: config,
                      pageIndex: safePage,
                      pageCount: pageCount,
                    ),
                    const SizedBox(height: 16),
                    if (pageIds.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Hãy chọn ít nhất 1 chữ để tạo phiếu tập tô',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: WorksheetColors.headerSubtitle,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      for (var r = 0; r < pageIds.length; r++) ...[
                        _PreviewRow(
                          rawGlyph: glyphs[pageIds[r]]!,
                          allGlyphs: glyphs,
                          cellKinds: cellKindsFor(config.style),
                        ),
                        if (r < pageIds.length - 1) const SizedBox(height: 16),
                      ],
                      const Spacer(),
                    ],
                    const _PreviewFooter(),
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

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.config,
    required this.pageIndex,
    required this.pageCount,
  });

  final WorksheetConfig config;
  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: WorksheetColors.cellBorder, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phiếu tập tô — ${config.displayKidName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: WorksheetColors.modelInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ngày ${config.formattedDate} · ${config.style.label} · '
                  'Cùng Chíp Chíp luyện nét đẹp mỗi ngày!',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: WorksheetColors.headerSubtitle,
                  ),
                ),
              ],
            ),
          ),
          if (pageCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: WorksheetColors.cellBorder,
                  width: 0.8,
                ),
              ),
              child: Text(
                'Trang ${pageIndex + 1}/$pageCount',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: WorksheetColors.headerSubtitle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.rawGlyph,
    required this.allGlyphs,
    required this.cellKinds,
  });

  final Glyph rawGlyph;
  final Map<String, Glyph> allGlyphs;
  final List<WorksheetCellKind> cellKinds;

  @override
  Widget build(BuildContext context) {
    final glyph = rawGlyph.inWindow();
    final ctxId = rawGlyph.context;
    final ctxGlyph = ctxId == null ? null : allGlyphs[ctxId];
    final ctxStrokes =
        ctxGlyph == null ? null : contextInWindow(rawGlyph, ctxGlyph);
    const cellSize = 74.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rawGlyph.label,
                style: TextStyle(
                  fontSize: rawGlyph.label.length <= 2 ? 15 : 10,
                  fontWeight: FontWeight.w900,
                  color: WorksheetColors.modelInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${glyph.strokes.length} nét',
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: WorksheetColors.headerSubtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        for (var i = 0; i < cellKinds.length; i++) ...[
          _PreviewCell(
            glyph: glyph,
            contextStrokes: ctxStrokes,
            kind: cellKinds[i],
            size: cellSize,
          ),
          if (i < cellKinds.length - 1) const SizedBox(width: 5.4),
        ],
      ],
    );
  }
}

class _PreviewCell extends StatelessWidget {
  const _PreviewCell({
    required this.glyph,
    required this.contextStrokes,
    required this.kind,
    required this.size,
  });

  final Glyph glyph;
  final List<Stroke>? contextStrokes;
  final WorksheetCellKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final showNumbers =
        kind == WorksheetCellKind.model && glyph.strokes.length >= 2;
    final badgeCoords = showNumbers
        ? badgePositionsForStrokes(glyph.strokes, cellSize: size)
        : const <(double, double)>[];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CellPainter(
                glyph: glyph,
                contextStrokes: contextStrokes,
                kind: kind,
              ),
            ),
          ),
          if (showNumbers)
            for (var i = 0; i < glyph.strokes.length; i++)
              if (glyph.strokes[i].points.isNotEmpty)
                _numberBadge(i + 1, badgeCoords[i].$1, badgeCoords[i].$2),
        ],
      ),
    );
  }

  Widget _numberBadge(int index, double left, double top) {
    const badgeSize = 10.0;
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: badgeSize,
        height: badgeSize,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: WorksheetColors.accent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$index',
          style: const TextStyle(
            fontSize: 6.5,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: WorksheetColors.paper,
          ),
        ),
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  const _CellPainter({
    required this.glyph,
    required this.contextStrokes,
    required this.kind,
  });

  final Glyph glyph;
  final List<Stroke>? contextStrokes;
  final WorksheetCellKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = WorksheetColors.paper);

    _paintGrid(canvas, size, glyph.ruling);

    canvas.save();
    canvas.clipRect(rect);
    if (contextStrokes != null) {
      _paintStrokes(
        canvas,
        size,
        contextStrokes!,
        color: WorksheetColors.contextLetter,
        width: size.width * 0.032,
        dotRadius: size.width * 0.018,
      );
    }

    switch (kind) {
      case WorksheetCellKind.model:
        _paintStrokes(
          canvas,
          size,
          glyph.strokes,
          color: WorksheetColors.modelInk,
          width: size.width * 0.036,
          dotRadius: size.width * 0.024,
        );
        _paintStartGuides(canvas, size, glyph.strokes);
      case WorksheetCellKind.trace:
        _paintDashedStrokes(
          canvas,
          size,
          glyph.strokes,
          color: WorksheetColors.traceInk,
          width: size.width * 0.028,
          dotRadius: size.width * 0.020,
        );
        _paintFirstDot(canvas, size, glyph.strokes, 1.7);
      case WorksheetCellKind.blank:
        _paintFirstDot(canvas, size, glyph.strokes, 1.6);
    }
    canvas.restore();

    canvas.drawRect(
      rect,
      Paint()
        ..color = WorksheetColors.cellBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
    );
  }

  void _paintGrid(Canvas canvas, Size size, GlyphRuling? r) {
    final light = Paint()
      ..color = WorksheetColors.gridLight
      ..strokeWidth = 0.5;
    final heavy = Paint()
      ..color = WorksheetColors.gridHeavy
      ..strokeWidth = 1.0;

    if (r != null) {
      final heavies = RuledPaper.heavyLines(r);
      bool isHeavy(double y) => heavies.any((h) => (h - y).abs() < _eps);
      for (final x in RuledPaper.verticalLines(r)) {
        canvas.drawLine(
          Offset(x * size.width, 0),
          Offset(x * size.width, size.height),
          light,
        );
      }
      final ys = RuledPaper.horizontalLines(r);
      for (final y in [...ys.where((y) => !isHeavy(y)), ...ys.where(isHeavy)]) {
        canvas.drawLine(
          Offset(0, y * size.height),
          Offset(size.width, y * size.height),
          isHeavy(y) ? heavy : light,
        );
      }
    } else {
      const lines = 5;
      for (var i = 0; i < lines; i++) {
        final y = size.height * (i + 0.5) / lines;
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          (i == 2 || i == lines - 1) ? heavy : light,
        );
      }
    }
  }

  void _paintStrokes(
    Canvas canvas,
    Size size,
    List<Stroke> strokes, {
    required Color color,
    required double width,
    required double dotRadius,
  }) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..color = color;

    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final first = s.points.first;
      if (s.points.length == 1) {
        canvas.drawCircle(
          Offset(first.x * size.width, first.y * size.height),
          dotRadius,
          fillPaint,
        );
        continue;
      }
      final path = Path()
        ..moveTo(first.x * size.width, first.y * size.height);
      for (var i = 1; i < s.points.length; i++) {
        final p = s.points[i];
        path.lineTo(p.x * size.width, p.y * size.height);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  void _paintDashedStrokes(
    Canvas canvas,
    Size size,
    List<Stroke> strokes, {
    required Color color,
    required double width,
    required double dotRadius,
  }) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..color = color;

    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final first = s.points.first;
      if (s.points.length == 1) {
        canvas.drawCircle(
          Offset(first.x * size.width, first.y * size.height),
          dotRadius,
          fillPaint,
        );
        continue;
      }
      final path = Path()
        ..moveTo(first.x * size.width, first.y * size.height);
      for (var i = 1; i < s.points.length; i++) {
        final p = s.points[i];
        path.lineTo(p.x * size.width, p.y * size.height);
      }
      const dashLen = 3.2;
      const gapLen = 2.8;
      for (final metric in path.computeMetrics()) {
        var dist = 0.0;
        while (dist < metric.length) {
          final next = math.min(dist + dashLen, metric.length);
          canvas.drawPath(metric.extractPath(dist, next), strokePaint);
          dist = next + gapLen;
        }
      }
    }
  }

  void _paintStartGuides(Canvas canvas, Size size, List<Stroke> strokes) {
    final dotPaint = Paint()..color = WorksheetColors.accent;
    final arrowPaint = Paint()
      ..color = WorksheetColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final p0 = s.points.first;
      final o0 = Offset(p0.x * size.width, p0.y * size.height);
      canvas.drawCircle(o0, 2.2, dotPaint);

      final tip = _directionPoint(s.points);
      if (tip != null) {
        final ot = Offset(tip.x * size.width, tip.y * size.height);
        final angle = math.atan2(ot.dy - o0.dy, ot.dx - o0.dx);
        const headLen = 4.2;
        const spread = 0.52;
        final a1 = Offset(
          ot.dx - headLen * math.cos(angle - spread),
          ot.dy - headLen * math.sin(angle - spread),
        );
        final a2 = Offset(
          ot.dx - headLen * math.cos(angle + spread),
          ot.dy - headLen * math.sin(angle + spread),
        );
        canvas.drawPath(
          Path()
            ..moveTo(a1.dx, a1.dy)
            ..lineTo(ot.dx, ot.dy)
            ..lineTo(a2.dx, a2.dy),
          arrowPaint,
        );
      }
    }
  }

  void _paintFirstDot(
    Canvas canvas,
    Size size,
    List<Stroke> strokes,
    double radius,
  ) {
    if (strokes.isEmpty || strokes.first.points.isEmpty) return;
    final p0 = strokes.first.points.first;
    canvas.drawCircle(
      Offset(p0.x * size.width, p0.y * size.height),
      radius,
      Paint()..color = WorksheetColors.startDotMuted,
    );
  }

  Point2? _directionPoint(List<Point2> points) {
    if (points.length < 2) return null;
    final p0 = points.first;
    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      final dx = p.x - p0.x;
      final dy = p.y - p0.y;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d >= 0.08) {
        final scale = 0.11 / d;
        return Point2(p0.x + dx * scale, p0.y + dy * scale);
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(_CellPainter old) =>
      old.glyph != glyph ||
      old.contextStrokes != contextStrokes ||
      old.kind != kind;
}

class _PreviewFooter extends StatelessWidget {
  const _PreviewFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: WorksheetColors.gridLight, width: 0.8),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Chíp Chíp — Học vui mỗi ngày · Ba mẹ tô sao thưởng cho bé nhé!',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: WorksheetColors.headerSubtitle,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          CustomPaint(
            size: Size(56, 16),
            painter: _FooterStarsPainter(),
          ),
        ],
      ),
    );
  }
}

class _FooterStarsPainter extends CustomPainter {
  const _FooterStarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WorksheetColors.rewardStarStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round;

    for (var k = 0; k < 3; k++) {
      final cx = 9.0 + k * 19.0;
      final cy = size.height / 2;
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final angle = -math.pi / 2 + i * math.pi / 5;
        final r = i.isEven ? 6.8 : 3.0;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FooterStarsPainter old) => false;
}
