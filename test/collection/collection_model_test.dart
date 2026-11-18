import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/collection/collection_model.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/progress/progress_repository.dart';

LearningSnapshot _snap({
  String kidName = 'Bông',
  int totalStars = 0,
  int totalLessons = 0,
  int totalLearnedDays = 0,
  int learnedDaysThisWeek = 0,
  int masteredWriting = 0,
  int mathLevelIndex = 0,
  int vietnameseLevelIndex = 0,
  int englishLevelIndex = 0,
  int viewedYear = 2026,
  int viewedMonth = 11,
  Set<int> learnedDaysInMonth = const {},
  bool learnedToday = false,
}) =>
    LearningSnapshot(
      kidName: kidName,
      totalStars: totalStars,
      totalLessons: totalLessons,
      totalLearnedDays: totalLearnedDays,
      learnedDaysThisWeek: learnedDaysThisWeek,
      masteredWriting: masteredWriting,
      mathLevelIndex: mathLevelIndex,
      vietnameseLevelIndex: vietnameseLevelIndex,
      englishLevelIndex: englishLevelIndex,
      viewedYear: viewedYear,
      viewedMonth: viewedMonth,
      learnedDaysInMonth: learnedDaysInMonth,
      learnedToday: learnedToday,
    );

void main() {
  group('buildLearningStickers & buildLearningCertificates', () {
    test('returns 12 unique stickers and 6 unique certificates', () {
      final stickers = buildLearningStickers(_snap());
      final certs = buildLearningCertificates(_snap());

      expect(stickers.length, 12);
      expect(stickers.map((s) => s.id).toSet().length, 12);
      expect(certs.length, 6);
      expect(certs.map((c) => c.id).toSet().length, 6);

      // Fresh kid has 0 stickers and 0 certificates unlocked.
      expect(stickers.where((s) => s.unlocked), isEmpty);
      expect(certs.where((c) => c.unlocked), isEmpty);
    });

    test('unlocks milestones accurately at threshold boundaries', () {
      final s = _snap(
        kidName: 'Minh Khôi',
        totalLessons: 3,
        totalLearnedDays: 3,
        totalStars: 10,
        masteredWriting: 10,
        mathLevelIndex: 2, // level 3
        vietnameseLevelIndex: 2, // level 3
        englishLevelIndex: 2, // level 3
      );
      final stickers = {
        for (final st in buildLearningStickers(s)) st.id: st,
      };
      expect(stickers['first_lesson']!.unlocked, isTrue);
      expect(stickers['three_days']!.unlocked, isTrue);
      expect(stickers['seven_days']!.unlocked, isFalse);
      expect(stickers['ten_stars']!.unlocked, isTrue);
      expect(stickers['thirty_stars']!.unlocked, isFalse);
      expect(stickers['writing_5']!.unlocked, isTrue);
      expect(stickers['writing_20']!.unlocked, isFalse);
      expect(stickers['math_lv3']!.unlocked, isTrue);
      expect(stickers['vn_lv3']!.unlocked, isTrue);
      expect(stickers['en_lv3']!.unlocked, isTrue);
      expect(stickers['all_rounder']!.unlocked, isTrue);
      expect(stickers['first_lesson']!.praise, contains('Minh Khôi'));

      final certs = {
        for (final c in buildLearningCertificates(s)) c.id: c,
      };
      expect(certs['cert_diligent']!.unlocked, isTrue);
      expect(certs['cert_writing']!.unlocked, isTrue);
      expect(certs['cert_math']!.unlocked, isTrue);
      expect(certs['cert_vietnamese']!.unlocked, isTrue);
      expect(certs['cert_english']!.unlocked, isTrue);
      expect(certs['cert_star']!.unlocked, isFalse);
      expect(certs['cert_math']!.citation, contains('Minh Khôi'));
    });

    test('empty kidName falls back to Bé and greeting adapts gently', () {
      final fresh = _snap(kidName: '   ');
      expect(fresh.displayKidName, 'Bé');
      expect(fresh.chipGreeting, contains('bài học đầu tiên'));

      final missedToday = _snap(
        kidName: 'Bông',
        totalLessons: 4,
        learnedToday: false,
      );
      expect(missedToday.chipGreeting, contains('Chíp nhớ Bông'));

      final learnedToday = _snap(
        kidName: 'Bông',
        totalLessons: 4,
        learnedDaysInMonth: {1, 4, 18},
        learnedToday: true,
      );
      expect(learnedToday.chipGreeting, contains('3 ngày'));
    });

    test('calendar helpers handle leap years and weekdays', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2026, 11), 30);
      // 2026-11-01 is a Sunday (weekday == 7).
      expect(firstWeekdayOfMonth(2026, 11), DateTime.sunday);
    });
  });

  group('ProgressRepository attendance & totals', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async => db.close());

    test('counts totalLessons, distinct totalLearnedDays, and month days',
        () async {
      var now = DateTime(2026, 10, 29, 9, 0);
      final repo = ProgressRepository(db, kidId: 1, now: () => now);

      await repo.recordLessonCompleted(itemsCompleted: 3);
      now = DateTime(2026, 11, 2, 10, 0);
      await repo.recordLessonCompleted(itemsCompleted: 4);
      // Second lesson on the same day should count as 1 distinct day.
      now = DateTime(2026, 11, 2, 18, 30);
      await repo.recordLessonCompleted(itemsCompleted: 4);
      now = DateTime(2026, 11, 18, 8, 15);
      await repo.recordLessonCompleted(itemsCompleted: 4);

      expect(await repo.totalLessons(), 4);
      expect(await repo.totalLearnedDays(), 3);
      expect(await repo.learnedDaysInMonth(2026, 11), {2, 18});
      expect(await repo.learnedDaysInMonth(2026, 10), {29});
      expect(await repo.learnedDaysInMonth(2026, 9), isEmpty);

      // Isolated per kid.
      final otherKid = ProgressRepository(db, kidId: 2, now: () => now);
      expect(await otherKid.totalLessons(), 0);
      expect(await otherKid.totalLearnedDays(), 0);
      expect(await otherKid.learnedDaysInMonth(2026, 11), isEmpty);
    });
  });
}
