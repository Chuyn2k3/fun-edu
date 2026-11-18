import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/collection/certificate_pdf.dart';
import 'package:funedu/collection/collection_model.dart';
import 'package:funedu/worksheet/worksheet_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildCertificatePdf generates a valid offline A4 landscape PDF',
      () async {
    final fonts = await WorksheetPdfFonts.loadFromAssets();
    final snap = LearningSnapshot(
      kidName: 'Nguyễn Minh Khôi',
      totalStars: 55,
      totalLessons: 6,
      totalLearnedDays: 5,
      learnedDaysThisWeek: 3,
      masteredWriting: 12,
      mathLevelIndex: 3,
      vietnameseLevelIndex: 3,
      englishLevelIndex: 3,
      viewedYear: 2026,
      viewedMonth: 11,
      learnedDaysInMonth: const {1, 5, 10, 15, 18},
      learnedToday: true,
    );
    final cert = buildLearningCertificates(snap).first;

    final bytes = await buildCertificatePdf(
      certificate: cert,
      kidName: snap.kidName,
      issuedAt: DateTime(2026, 11, 18),
      fonts: fonts,
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
