import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../ui/theme/tokens.dart';
import '../worksheet/worksheet_pdf.dart';
import 'notebook.dart';

/// "Vở của bé" as an A4 PDF: 12 pages of the notebook per sheet (3 x 4),
/// each the kid's own strokes on the glyph's ô li, with its label. Offline.
Future<Uint8List> buildNotebookPdf({
  required List<NotebookPage> pages,
  required String kidName,
  required WorksheetPdfFonts fonts,
  DateTime? printedAt,
}) async {
  final name = kidName.trim().isEmpty ? 'Bé' : kidName.trim();
  final d = printedAt ?? DateTime.now();
  final date =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final ink = PdfColor.fromInt(AppColors.accent.value);
  final text = PdfColor.fromInt(AppColors.text.value);
  final muted = PdfColor.fromInt(AppColors.textMuted.value);
  const perSheet = 12;

  final doc = pw.Document(title: 'Vở của $name', author: 'Chíp Chíp');
  for (var start = 0; start < pages.length || start == 0; start += perSheet) {
    final chunk = pages.skip(start).take(perSheet).toList();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('Vở của $name',
              style: pw.TextStyle(font: fonts.bold, fontSize: 24, color: text)),
          pw.SizedBox(height: 4),
          pw.Text('Những chữ đẹp nhất bé đã viết · in ngày $date',
              style: pw.TextStyle(
                  font: fonts.regular, fontSize: 11, color: muted)),
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final p in chunk) _cell(p, fonts, ink, text),
            ],
          ),
        ],
      ),
    ));
    if (pages.isEmpty) break;
  }
  return doc.save();
}

pw.Widget _cell(
    NotebookPage page, WorksheetPdfFonts fonts, PdfColor ink, PdfColor text) {
  const side = 150.0;
  return pw.Column(
    children: [
      pw.Container(
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.6)),
        child: pw.CustomPaint(
          size: const PdfPoint(side, side),
          painter: (canvas, size) {
            paintWorksheetCellBackground(canvas, size, page.glyph?.ruling);
            canvas
              ..setStrokeColor(ink)
              ..setFillColor(ink)
              ..setLineWidth(side * 0.045)
              ..setLineCap(PdfLineCap.round)
              ..setLineJoin(PdfLineJoin.round);
            for (final s in page.strokes) {
              final pts = s.points;
              if (pts.isEmpty) continue;
              if (pts.length == 1) {
                canvas
                  ..drawEllipse(pts.first.x * size.x,
                      (1 - pts.first.y) * size.y, side * 0.03, side * 0.03)
                  ..fillPath();
                continue;
              }
              canvas.moveTo(pts.first.x * size.x, (1 - pts.first.y) * size.y);
              for (final p in pts.skip(1)) {
                canvas.lineTo(p.x * size.x, (1 - p.y) * size.y);
              }
              canvas.strokePath();
            }
          },
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(page.glyph?.label ?? '',
          style: pw.TextStyle(font: fonts.bold, fontSize: 12, color: text)),
    ],
  );
}
