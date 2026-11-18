import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../features/writing/ruled_paper.dart';
import '../stroke/geometry.dart';
import '../stroke/glyph.dart';
import '../ui/theme/tokens.dart';
import 'worksheet_model.dart';

/// Bundled Vietnamese-ready fonts loaded offline from `assets/fonts/`.
class WorksheetPdfFonts {
  const WorksheetPdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  static Future<WorksheetPdfFonts> loadFromAssets([
    AssetBundle? bundle,
  ]) async {
    final b = bundle ?? rootBundle;
    final regularData = await b.load('assets/fonts/Nunito-Regular.ttf');
    final boldData = await b.load('assets/fonts/Nunito-Bold.ttf');
    return WorksheetPdfFonts(
      regular: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );
  }
}

PdfColor _pdfColor(Color c) => PdfColor.fromInt(c.value);

final _cPaper = _pdfColor(WorksheetColors.paper);
final _cGridLight = _pdfColor(WorksheetColors.gridLight);
final _cGridHeavy = _pdfColor(WorksheetColors.gridHeavy);
final _cCellBorder = _pdfColor(WorksheetColors.cellBorder);
final _cContext = _pdfColor(WorksheetColors.contextLetter);
final _cModelInk = _pdfColor(WorksheetColors.modelInk);
final _cTraceInk = _pdfColor(WorksheetColors.traceInk);
final _cAccent = _pdfColor(WorksheetColors.accent);
final _cStartMuted = _pdfColor(WorksheetColors.startDotMuted);
final _cSub = _pdfColor(WorksheetColors.headerSubtitle);
final _cStarStroke = _pdfColor(WorksheetColors.rewardStarStroke);

const double _eps = 1e-6;

/// Builds a printable A4 portrait Vietnamese ô li worksheet PDF completely
/// offline using the bundled [fonts] and reference [glyphs].
Future<Uint8List> buildWorksheetPdf({
  required WorksheetConfig config,
  required Map<String, Glyph> glyphs,
  required WorksheetPdfFonts fonts,
}) async {
  final doc = pw.Document(
    title: 'Phiếu tập tô — ${config.displayKidName}',
    author: 'Chíp Chíp',
  );

  final resolvedIds = [
    for (final id in config.glyphIds)
      if (glyphs.containsKey(id)) id,
  ];
  final pages = paginateGlyphs(resolvedIds);
  final cellKinds = cellKindsFor(config.style);

  if (pages.isEmpty) {
    doc.addPage(_emptyPage(config, fonts));
    return doc.save();
  }

  for (var p = 0; p < pages.length; p++) {
    final pageIds = pages[p];
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 28),
        theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              config: config,
              pageIndex: p,
              pageCount: pages.length,
              fonts: fonts,
            ),
            pw.SizedBox(height: 16),
            for (var r = 0; r < pageIds.length; r++) ...[
              _buildRow(
                rawGlyph: glyphs[pageIds[r]]!,
                allGlyphs: glyphs,
                cellKinds: cellKinds,
                fonts: fonts,
              ),
              if (r < pageIds.length - 1) pw.SizedBox(height: 16),
            ],
            pw.Spacer(),
            _buildFooter(fonts),
          ],
        ),
      ),
    );
  }

  return doc.save();
}

pw.Page _emptyPage(WorksheetConfig config, WorksheetPdfFonts fonts) => pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 28),
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            config: config,
            pageIndex: 0,
            pageCount: 1,
            fonts: fonts,
          ),
          pw.Spacer(),
          pw.Center(
            child: pw.Text(
              'Chưa chọn chữ nào cho phiếu tập tô.',
              style: pw.TextStyle(fontSize: 14, color: _cSub),
            ),
          ),
          pw.Spacer(),
          _buildFooter(fonts),
        ],
      ),
    );

pw.Widget _buildHeader({
  required WorksheetConfig config,
  required int pageIndex,
  required int pageCount,
  required WorksheetPdfFonts fonts,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: _cCellBorder, width: 1.0),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Phiếu tập tô — ${config.displayKidName}',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 20,
                  color: _cModelInk,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Ngày ${config.formattedDate} · ${config.style.label} · '
                'Cùng Chíp Chíp luyện nét đẹp mỗi ngày!',
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 10,
                  color: _cSub,
                ),
              ),
            ],
          ),
        ),
        if (pageCount > 1)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _cCellBorder, width: 0.8),
            ),
            child: pw.Text(
              'Trang ${pageIndex + 1}/$pageCount',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 9.5,
                color: _cSub,
              ),
            ),
          ),
      ],
    ),
  );
}

pw.Widget _buildRow({
  required Glyph rawGlyph,
  required Map<String, Glyph> allGlyphs,
  required List<WorksheetCellKind> cellKinds,
  required WorksheetPdfFonts fonts,
}) {
  final glyph = rawGlyph.inWindow();
  final ctxId = rawGlyph.context;
  final ctxGlyph = ctxId == null ? null : allGlyphs[ctxId];
  final ctxStrokes =
      ctxGlyph == null ? null : contextInWindow(rawGlyph, ctxGlyph);

  // Available width on A4 (595.28 - 68 = 527.28pt):
  // Left label 48pt + gap 8pt + 6 cells * 74pt + 5 gaps * 5pt = 525pt.
  const cellSize = 74.0;
  final strokeCount = glyph.strokes.length;

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.SizedBox(
        width: 48,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              rawGlyph.label,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: rawGlyph.label.length <= 2 ? 15 : 10,
                color: _cModelInk,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '$strokeCount nét',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8.5,
                color: _cSub,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 8),
      for (var i = 0; i < cellKinds.length; i++) ...[
        _buildCell(
          glyph: glyph,
          contextStrokes: ctxStrokes,
          kind: cellKinds[i],
          size: cellSize,
          fonts: fonts,
        ),
        if (i < cellKinds.length - 1) pw.SizedBox(width: 5.4),
      ],
    ],
  );
}

pw.Widget _buildCell({
  required Glyph glyph,
  required List<Stroke>? contextStrokes,
  required WorksheetCellKind kind,
  required double size,
  required WorksheetPdfFonts fonts,
}) {
  final showNumbers =
      kind == WorksheetCellKind.model && glyph.strokes.length >= 2;
  final badgeCoords = showNumbers
      ? badgePositionsForStrokes(glyph.strokes, cellSize: size)
      : const <(double, double)>[];

  return pw.SizedBox(
    width: size,
    height: size,
    child: pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        pw.CustomPaint(
          size: PdfPoint(size, size),
          painter: (canvas, pt) {
            _paintCellBackground(canvas, pt, glyph.ruling);
            if (contextStrokes != null) {
              _paintContextStrokes(canvas, pt, contextStrokes);
            }
            switch (kind) {
              case WorksheetCellKind.model:
                _paintModelGlyph(canvas, pt, glyph.strokes);
              case WorksheetCellKind.trace:
                _paintTraceGlyph(canvas, pt, glyph.strokes);
              case WorksheetCellKind.blank:
                _paintBlankHint(canvas, pt, glyph.strokes);
            }
          },
        ),
        if (showNumbers)
          for (var i = 0; i < glyph.strokes.length; i++)
            if (glyph.strokes[i].points.isNotEmpty)
              _strokeNumberBadge(
                index: i + 1,
                left: badgeCoords[i].$1,
                top: badgeCoords[i].$2,
                fonts: fonts,
              ),
      ],
    ),
  );
}

pw.Widget _strokeNumberBadge({
  required int index,
  required double left,
  required double top,
  required WorksheetPdfFonts fonts,
}) {
  const badgeSize = 10.0;
  return pw.Positioned(
    left: left,
    top: top,
    child: pw.Container(
      width: badgeSize,
      height: badgeSize,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _cAccent,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Text(
        '$index',
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 6.5,
          color: _cPaper,
        ),
      ),
    ),
  );
}

double _pdfY(double normY, PdfPoint size) => (1.0 - normY) * size.y;

void _paintCellBackground(
  PdfGraphics canvas,
  PdfPoint size,
  GlyphRuling? ruling,
) {
  canvas.saveContext();
  // White cell fill.
  canvas.setFillColor(_cPaper);
  canvas.drawRect(0, 0, size.x, size.y);
  canvas.fillPath();

  if (ruling != null) {
    final heavy = RuledPaper.heavyLines(ruling);
    bool isHeavy(double y) => heavy.any((h) => (h - y).abs() < _eps);

    // Vertical ô li lines.
    canvas.setStrokeColor(_cGridLight);
    canvas.setLineWidth(0.45);
    for (final x in RuledPaper.verticalLines(ruling)) {
      final px = x * size.x;
      canvas.moveTo(px, 0);
      canvas.lineTo(px, size.y);
    }
    canvas.strokePath();

    // Horizontal light lines first.
    final ys = RuledPaper.horizontalLines(ruling);
    canvas.setStrokeColor(_cGridLight);
    canvas.setLineWidth(0.45);
    for (final y in ys.where((y) => !isHeavy(y))) {
      final py = _pdfY(y, size);
      canvas.moveTo(0, py);
      canvas.lineTo(size.x, py);
    }
    canvas.strokePath();

    // Baseline and x-height heavy lines on top.
    canvas.setStrokeColor(_cGridHeavy);
    canvas.setLineWidth(1.0);
    for (final y in ys.where(isHeavy)) {
      final py = _pdfY(y, size);
      canvas.moveTo(0, py);
      canvas.lineTo(size.x, py);
    }
    canvas.strokePath();
  } else {
    // 5 horizontal exercise lines (basic strokes & digits).
    const lines = 5;
    for (var i = 0; i < lines; i++) {
      final heavy = i == 2 || i == lines - 1;
      final py = _pdfY((i + 0.5) / lines, size);
      canvas.setStrokeColor(heavy ? _cGridHeavy : _cGridLight);
      canvas.setLineWidth(heavy ? 0.95 : 0.45);
      canvas.moveTo(0, py);
      canvas.lineTo(size.x, py);
      canvas.strokePath();
    }
  }

  // Crisp outer square border.
  canvas.setStrokeColor(_cCellBorder);
  canvas.setLineWidth(0.75);
  canvas.drawRect(0, 0, size.x, size.y);
  canvas.strokePath();
  canvas.restoreContext();
}

void _paintContextStrokes(
  PdfGraphics canvas,
  PdfPoint size,
  List<Stroke> strokes,
) {
  canvas.saveContext();
  canvas.drawRect(0, 0, size.x, size.y);
  canvas.clipPath();
  canvas.setStrokeColor(_cContext);
  canvas.setFillColor(_cContext);
  canvas.setLineWidth(size.x * 0.032);
  canvas.setLineCap(PdfLineCap.round);
  canvas.setLineJoin(PdfLineJoin.round);
  _drawStrokes(canvas, size, strokes, dotRadius: size.x * 0.018);
  canvas.restoreContext();
}

void _paintModelGlyph(
  PdfGraphics canvas,
  PdfPoint size,
  List<Stroke> strokes,
) {
  canvas.saveContext();
  canvas.drawRect(0, 0, size.x, size.y);
  canvas.clipPath();
  canvas.setStrokeColor(_cModelInk);
  canvas.setFillColor(_cModelInk);
  canvas.setLineWidth(size.x * 0.036);
  canvas.setLineCap(PdfLineCap.round);
  canvas.setLineJoin(PdfLineJoin.round);
  _drawStrokes(canvas, size, strokes, dotRadius: size.x * 0.024);

  // Start dots and direction arrows for each stroke.
  for (final s in strokes) {
    if (s.points.isEmpty) continue;
    final p0 = s.points.first;
    final x0 = p0.x * size.x;
    final y0 = _pdfY(p0.y, size);
    canvas.setFillColor(_cAccent);
    canvas.drawEllipse(x0, y0, 2.2, 2.2);
    canvas.fillPath();

    // Direction arrowhead along initial tangent for multi-point strokes.
    final tip = _directionPoint(s.points);
    if (tip != null) {
      final tx = tip.x * size.x;
      final ty = _pdfY(tip.y, size);
      final angle = math.atan2(ty - y0, tx - x0);
      const headLen = 4.2;
      const spread = 0.52;
      final ax1 = tx - headLen * math.cos(angle - spread);
      final ay1 = ty - headLen * math.sin(angle - spread);
      final ax2 = tx - headLen * math.cos(angle + spread);
      final ay2 = ty - headLen * math.sin(angle + spread);
      canvas.setStrokeColor(_cAccent);
      canvas.setLineWidth(1.0);
      canvas.moveTo(ax1, ay1);
      canvas.lineTo(tx, ty);
      canvas.lineTo(ax2, ay2);
      canvas.strokePath();
    }
  }
  canvas.restoreContext();
}

void _paintTraceGlyph(
  PdfGraphics canvas,
  PdfPoint size,
  List<Stroke> strokes,
) {
  canvas.saveContext();
  canvas.drawRect(0, 0, size.x, size.y);
  canvas.clipPath();
  canvas.setStrokeColor(_cTraceInk);
  canvas.setFillColor(_cTraceInk);
  canvas.setLineWidth(size.x * 0.028);
  canvas.setLineCap(PdfLineCap.round);
  canvas.setLineJoin(PdfLineJoin.round);
  canvas.setLineDashPattern([3.0, 2.6]);
  _drawStrokes(canvas, size, strokes, dotRadius: size.x * 0.020);
  canvas.setLineDashPattern();

  // Small start hint dot for the first stroke.
  if (strokes.isNotEmpty && strokes.first.points.isNotEmpty) {
    final p0 = strokes.first.points.first;
    canvas.setFillColor(_cStartMuted);
    canvas.drawEllipse(p0.x * size.x, _pdfY(p0.y, size), 1.7, 1.7);
    canvas.fillPath();
  }
  canvas.restoreContext();
}

void _paintBlankHint(
  PdfGraphics canvas,
  PdfPoint size,
  List<Stroke> strokes,
) {
  if (strokes.isEmpty || strokes.first.points.isEmpty) return;
  final p0 = strokes.first.points.first;
  canvas.saveContext();
  canvas.setFillColor(_cStartMuted);
  canvas.drawEllipse(p0.x * size.x, _pdfY(p0.y, size), 1.6, 1.6);
  canvas.fillPath();
  canvas.restoreContext();
}

void _drawStrokes(
  PdfGraphics canvas,
  PdfPoint size,
  List<Stroke> strokes, {
  required double dotRadius,
}) {
  for (final s in strokes) {
    if (s.points.isEmpty) continue;
    final first = s.points.first;
    if (s.points.length == 1) {
      canvas.drawEllipse(
        first.x * size.x,
        _pdfY(first.y, size),
        dotRadius,
        dotRadius,
      );
      canvas.fillPath();
      continue;
    }
    canvas.moveTo(first.x * size.x, _pdfY(first.y, size));
    for (var i = 1; i < s.points.length; i++) {
      final p = s.points[i];
      canvas.lineTo(p.x * size.x, _pdfY(p.y, size));
    }
    canvas.strokePath();
  }
}

/// Finds a point slightly ahead of `points.first` to place a clean direction
/// arrowhead without cluttering the start dot.
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

pw.Widget _buildFooter(WorksheetPdfFonts fonts) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: _cGridLight, width: 0.8),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Text(
            'Chíp Chíp — Học vui mỗi ngày · Ba mẹ tô sao thưởng cho bé nhé!',
            style: pw.TextStyle(font: fonts.regular, fontSize: 9, color: _cSub),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.CustomPaint(
          size: const PdfPoint(56, 16),
          painter: (canvas, size) {
            canvas.setStrokeColor(_cStarStroke);
            canvas.setLineWidth(1.0);
            for (var k = 0; k < 3; k++) {
              final cx = 9.0 + k * 19.0;
              final cy = size.y / 2;
              _drawOutlineStar(canvas, cx, cy, 6.8, 3.0);
            }
          },
        ),
      ],
    ),
  );
}

void _drawOutlineStar(
  PdfGraphics canvas,
  double cx,
  double cy,
  double outerR,
  double innerR,
) {
  for (var i = 0; i < 10; i++) {
    final angle = math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? outerR : innerR;
    final x = cx + r * math.cos(angle);
    final y = cy + r * math.sin(angle);
    if (i == 0) {
      canvas.moveTo(x, y);
    } else {
      canvas.lineTo(x, y);
    }
  }
  canvas.closePath();
  canvas.strokePath();
}
