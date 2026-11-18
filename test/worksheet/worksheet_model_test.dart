import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/learning/writing_ladder.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/worksheet/worksheet_model.dart';

void main() {
  group('weakGlyphIds', () {
    test('falls back to first 6 ladder glyphs when kid has no stats yet', () {
      expect(weakGlyphIds(const {}), equals(writingLadder.take(6).toList()));
    });

    test('prioritizes highest mistake gap, then practicing, then unlearned', () {
      final stats = <String, GlyphStat>{
        // Mastered with 0 mistakes -> not weak
        'net-ngang': const GlyphStat(completions: 2, cleanCompletions: 2),
        // Mistake gap = 1
        'chu-a': const GlyphStat(completions: 2, cleanCompletions: 1),
        // Mistake gap = 4 (highest)
        'chu-s': const GlyphStat(completions: 4, cleanCompletions: 0),
        // Mistake gap = 2
        'so-3': const GlyphStat(completions: 3, cleanCompletions: 1),
        // Practicing with 0 clean & gap = 1 (earlier in ladder than chu-a)
        'net-cong': const GlyphStat(completions: 1, cleanCompletions: 0),
      };

      final result = weakGlyphIds(stats, maxCount: 6);
      expect(result.length, 6);
      // Highest mistake gaps first: chu-s (4), so-3 (2), then net-cong (1) & chu-a (1) in ladder order
      expect(result.take(4).toList(), ['chu-s', 'so-3', 'net-cong', 'chu-a']);
      // Remaining 2 filled from unlearned ladder entries (skipping mastered net-ngang)
      expect(result[4], 'net-thang-dung');
      expect(result[5], 'net-xien');
    });

    test('never returns duplicates and respects maxCount', () {
      final result = weakGlyphIds(const {}, maxCount: 3);
      expect(result.length, 3);
      expect(result.toSet().length, 3);
    });
  });

  group('paginateGlyphs', () {
    test('returns empty list for empty input', () {
      expect(paginateGlyphs(const []), isEmpty);
    });

    test('splits glyphs into pages of 6 rows', () {
      final pages = paginateGlyphs(writingLadder.take(14).toList());
      expect(pages.length, 3);
      expect(pages[0].length, 6);
      expect(pages[1].length, 6);
      expect(pages[2].length, 2);
    });
  });

  group('cellKindsFor', () {
    test('guided has 1 model, 3 trace, 2 blank', () {
      expect(cellKindsFor(WorksheetStyle.guided), const [
        WorksheetCellKind.model,
        WorksheetCellKind.trace,
        WorksheetCellKind.trace,
        WorksheetCellKind.trace,
        WorksheetCellKind.blank,
        WorksheetCellKind.blank,
      ]);
    });

    test('traceHeavy has 1 model and 5 trace', () {
      final kinds = cellKindsFor(WorksheetStyle.traceHeavy);
      expect(kinds.length, 6);
      expect(kinds.first, WorksheetCellKind.model);
      expect(kinds.skip(1).every((k) => k == WorksheetCellKind.trace), isTrue);
    });

    test('practice has 1 model, 1 trace, 4 blank', () {
      expect(cellKindsFor(WorksheetStyle.practice), const [
        WorksheetCellKind.model,
        WorksheetCellKind.trace,
        WorksheetCellKind.blank,
        WorksheetCellKind.blank,
        WorksheetCellKind.blank,
        WorksheetCellKind.blank,
      ]);
    });
  });

  group('worksheetFileName', () {
    test('strips Vietnamese diacritics and produces clean ascii filename', () {
      final d = DateTime(2026, 11, 18);
      expect(
        worksheetFileName('Bé Đạt', d),
        'phieu-tap-to-be-dat-20261118.pdf',
      );
      expect(
        worksheetFileName('  Mèo Ú  ', d),
        'phieu-tap-to-meo-u-20261118.pdf',
      );
      expect(
        worksheetFileName('   ', d),
        'phieu-tap-to-be-20261118.pdf',
      );
    });
  });
}
