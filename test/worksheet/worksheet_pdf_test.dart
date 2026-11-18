import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:funedu/worksheet/worksheet_model.dart';
import 'package:funedu/worksheet/worksheet_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, Glyph> glyphs;
  late WorksheetPdfFonts fonts;

  setUpAll(() async {
    final repo = GlyphRepository(bundle: rootBundle);
    final ids = await repo.listIds();
    glyphs = {for (final id in ids) id: await repo.load(id)};
    fonts = await WorksheetPdfFonts.loadFromAssets(rootBundle);
  });

  int countPdfPages(Uint8List bytes) {
    final ascii = latin1.decode(bytes, allowInvalid: true);
    return RegExp(r'/Type\s*/Page\b').allMatches(ascii).length;
  }

  test('builds valid single-page A4 PDF across all 4 writing sections',
      () async {
    final config = WorksheetConfig(
      kidName: 'Bé Đạt',
      glyphIds: const [
        'net-ngang',
        'so-3',
        'chu-a',
        'chu-g',
        'dau-hoi',
        'dau-nang',
      ],
      style: WorksheetStyle.guided,
      date: DateTime(2026, 11, 18),
    );

    final bytes = await buildWorksheetPdf(
      config: config,
      glyphs: glyphs,
      fonts: fonts,
    );

    expect(bytes.length, greaterThan(4000));
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(countPdfPages(bytes), 1);
  });

  test('paginates into multiple A4 pages when more than 6 glyphs selected',
      () async {
    final config = WorksheetConfig(
      kidName: 'Na',
      glyphIds: const [
        'chu-a',
        'chu-aw',
        'chu-aa',
        'chu-b',
        'chu-c',
        'chu-d',
        'chu-dd',
        'chu-e',
        'chu-ee',
        'chu-g',
        'chu-h',
        'chu-i',
        'chu-k',
      ],
      style: WorksheetStyle.traceHeavy,
      date: DateTime(2026, 11, 18),
    );

    final bytes = await buildWorksheetPdf(
      config: config,
      glyphs: glyphs,
      fonts: fonts,
    );

    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(countPdfPages(bytes), 3);
  });

  test('handles all 3 styles and empty selection safely', () async {
    for (final style in WorksheetStyle.values) {
      final bytes = await buildWorksheetPdf(
        config: WorksheetConfig(
          kidName: '',
          glyphIds: const ['chu-s', 'chu-r', 'dau-sac'],
          style: style,
          date: DateTime(2026, 11, 18),
        ),
        glyphs: glyphs,
        fonts: fonts,
      );
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(countPdfPages(bytes), 1);
    }

    final emptyBytes = await buildWorksheetPdf(
      config: WorksheetConfig(
        kidName: 'Bi',
        glyphIds: const [],
        style: WorksheetStyle.practice,
        date: DateTime(2026, 11, 18),
      ),
      glyphs: glyphs,
      fonts: fonts,
    );
    expect(latin1.decode(emptyBytes.sublist(0, 5)), '%PDF-');
    expect(countPdfPages(emptyBytes), 1);
  });
}
