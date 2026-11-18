import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/parent/screens/worksheet_screen.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:funedu/worksheet/worksheet_preview.dart';
import 'package:funedu/worksheet/worksheet_printer.dart';

class _FakePrinter extends WorksheetPrinter {
  Uint8List? printedBytes;
  String? printedJobName;
  Uint8List? sharedBytes;
  String? sharedFileName;

  @override
  Future<void> printPdf(Uint8List bytes, {required String jobName}) async {
    printedBytes = bytes;
    printedJobName = jobName;
  }

  @override
  Future<void> sharePdf(Uint8List bytes, {required String fileName}) async {
    sharedBytes = bytes;
    sharedFileName = fileName;
  }
}

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1.0;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
}

void main() {
  late List<Glyph> allGlyphs;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final repo = GlyphRepository(bundle: rootBundle);
    final ids = await repo.listIds();
    allGlyphs = [for (final id in ids) await repo.load(id)];
  });

  final sampleStats = <String, GlyphStat>{
    'chu-s': const GlyphStat(completions: 4, cleanCompletions: 1),
    'chu-r': const GlyphStat(completions: 3, cleanCompletions: 1),
    'dau-hoi': const GlyphStat(completions: 2, cleanCompletions: 0),
  };

  Widget host(_FakePrinter printer) => ProviderScope(
        overrides: [
          glyphListProvider.overrideWith((_) async => allGlyphs),
          worksheetPrinterProvider.overrideWithValue(printer),
        ],
        child: MaterialApp(
          home: WorksheetScreen(
            kidName: 'Bé Na',
            stats: sampleStats,
            now: DateTime(2026, 11, 18),
          ),
        ),
      );

  testWidgets('defaults to weak mode, switches modes/pages, prints & shares',
      (t) async {
    _setSize(t, 390, 844);
    final printer = _FakePrinter();
    await t.pumpWidget(host(printer));
    await t.pumpAndSettle();

    expect(find.byType(WorksheetPreview), findsOneWidget);
    expect(find.textContaining('Xem trước · 6 mục (1 trang A4)'), findsOneWidget);
    expect(find.textContaining('Phiếu tập tô — Bé Na'), findsOneWidget);

    // Switch to Theo nhóm -> Chữ cái (29 letters -> 5 pages)
    await t.ensureVisible(find.text('Theo nhóm'));
    await t.tap(find.text('Theo nhóm'));
    await t.pumpAndSettle();
    expect(find.textContaining('29 mục (5 trang A4)'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);

    // Next page button works
    await t.ensureVisible(find.byTooltip('Trang sau'));
    await t.tap(find.byTooltip('Trang sau'));
    await t.pumpAndSettle();
    expect(find.text('2/5'), findsOneWidget);

    // Switch to Tự chọn and clear all -> buttons disabled
    await t.ensureVisible(find.text('Tự chọn'));
    await t.tap(find.text('Tự chọn'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Bỏ hết'));
    await t.tap(find.text('Bỏ hết'));
    await t.pumpAndSettle();
    expect(find.textContaining('Đã chọn 0/30 mục'), findsOneWidget);
    final printBtnDisabled = t.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('In phiếu'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(printBtnDisabled.onPressed, isNull);

    // Pick weak glyphs again -> buttons enabled
    await t.ensureVisible(find.text('Chọn chữ yếu'));
    await t.tap(find.text('Chọn chữ yếu'));
    await t.pumpAndSettle();
    expect(find.textContaining('Đã chọn 6/30 mục'), findsOneWidget);

    // Change style to Tô theo nhiều
    await t.ensureVisible(find.text('Tô theo nhiều'));
    await t.tap(find.text('Tô theo nhiều'));
    await t.pumpAndSettle();

    // Tap In phiếu -> invokes printer with valid PDF
    await t.tap(find.text('In phiếu'));
    await t.pumpAndSettle();
    expect(printer.printedBytes, isNotNull);
    expect(latin1.decode(printer.printedBytes!.sublist(0, 5)), '%PDF-');
    expect(printer.printedJobName, 'Phiếu tập tô — Bé Na');

    // Tap Chia sẻ PDF -> invokes share with clean filename
    await t.tap(find.text('Chia sẻ PDF'));
    await t.pumpAndSettle();
    expect(printer.sharedBytes, isNotNull);
    expect(latin1.decode(printer.sharedBytes!.sublist(0, 5)), '%PDF-');
    expect(printer.sharedFileName, 'phieu-tap-to-be-na-20261118.pdf');
  });

  for (final size in const [
    Size(320, 568),
    Size(390, 844),
    Size(768, 1024),
    Size(1024, 768),
  ]) {
    testWidgets('lays out cleanly without overflow at $size', (t) async {
      _setSize(t, size.width, size.height);
      final printer = _FakePrinter();
      await t.pumpWidget(host(printer));
      await t.pumpAndSettle();
      expect(find.byType(WorksheetPreview), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
