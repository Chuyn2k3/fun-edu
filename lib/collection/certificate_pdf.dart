import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../ui/theme/tokens.dart';
import '../worksheet/worksheet_pdf.dart';
import 'collection_model.dart';

PdfColor _pdfColor(Color c) => PdfColor.fromInt(c.value);

final _cPaper = _pdfColor(CollectionColors.certPaper);
final _cFrameOuter = _pdfColor(CollectionColors.certFrameOuter);
final _cFrameInner = _pdfColor(CollectionColors.certFrameInner);
final _cGoldFill = _pdfColor(CollectionColors.goldFill);
final _cGoldInk = _pdfColor(CollectionColors.goldInk);
final _cText = _pdfColor(AppColors.text);
final _cMuted = _pdfColor(AppColors.textMuted);
final _cPrimary = _pdfColor(AppColors.primary);

String _formatVietnameseDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return 'Ngày $day tháng $month năm ${d.year}';
}

/// Builds a printable A4 landscape Vietnamese certificate PDF completely
/// offline using the bundled [fonts].
Future<Uint8List> buildCertificatePdf({
  required LearningCertificate certificate,
  required String kidName,
  required DateTime issuedAt,
  required WorksheetPdfFonts fonts,
}) async {
  final displayName = kidName.trim().isEmpty ? 'Bé' : kidName.trim();
  final accent = _pdfColor(certificate.accentColor);

  final doc = pw.Document(
    title: 'Giấy khen ${certificate.title} — $displayName',
    author: 'Chíp Chíp',
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
      build: (_) => pw.Container(
        decoration: pw.BoxDecoration(
          color: _cPaper,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(18)),
          border: pw.Border.all(color: _cFrameOuter, width: 4),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(color: _cFrameInner, width: 1.5),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 30),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Top ribbon + title
              pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _cGoldFill,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(999)),
                      border: pw.Border.all(color: _cFrameOuter, width: 1.2),
                    ),
                    child: pw.Text(
                      'CHÍP CHÍP — HỌC VUI MỖI NGÀY',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _cGoldInk,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'GIẤY KHEN',
                    style: pw.TextStyle(
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                      color: _cPrimary,
                      letterSpacing: 2.5,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'TRÂN TRỌNG TRAO TẶNG BÉ',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _cMuted,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),

              // Kid's nickname + achievement title + citation
              pw.Column(
                children: [
                  pw.Text(
                    displayName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 44,
                      fontWeight: pw.FontWeight.bold,
                      color: _cText,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _cGoldFill,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(14)),
                      border: pw.Border.all(color: accent, width: 2),
                    ),
                    child: pw.Text(
                      'Danh hiệu: ${certificate.title}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  pw.SizedBox(
                    width: 560,
                    child: pw.Text(
                      certificate.citation,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: _cText,
                        lineSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),

              // Footer with date & Chíp Chíp signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cột mốc đạt được',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _cMuted,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        certificate.requirement,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _cText,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        _formatVietnameseDate(issuedAt),
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: _cMuted,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Bạn nhỏ Chíp Chíp',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: _cPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return doc.save();
}
