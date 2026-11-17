import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/engine/chip_pacer.dart';

void main() {
  group('ChipPacer rubberband', () {
    test('rubberbanding: Chíp accelerates when kid is ahead', () {
      final pacer = ChipPacer(initialMean: const Duration(seconds: 4));
      // Standard interval is 4s * 1.25 = 5s.
      // With kid 2 steps ahead, interval should drop by 15% (rubberband acceleration)
      final normal = pacer.intervalFor(chipSteps: 2, kidSteps: 2);
      final catchingUp = pacer.intervalFor(chipSteps: 2, kidSteps: 4);
      expect(catchingUp.inMicroseconds, lessThan(normal.inMicroseconds));
    });

    test('rubberbanding: Chíp slows down in final 2 steps (steps 8-10)', () {
      final pacer = ChipPacer(initialMean: const Duration(seconds: 4));
      final early = pacer.intervalFor(chipSteps: 3, kidSteps: 3);
      final endgame = pacer.intervalFor(chipSteps: 8, kidSteps: 8);
      expect(endgame.inMicroseconds, greaterThan(early.inMicroseconds));
    });

    test('never exceeds kid + 1 when chipSteps >= 2', () {
      final pacer = ChipPacer();
      expect(pacer.shouldStep(const Duration(hours: 1), chipSteps: 2, kidSteps: 1),
          isFalse);
      expect(pacer.shouldStep(const Duration(hours: 1), chipSteps: 3, kidSteps: 1),
          isFalse);
      expect(pacer.shouldStep(const Duration(hours: 1), chipSteps: 1, kidSteps: 0),
          isTrue);
      expect(pacer.shouldStep(const Duration(hours: 1), chipSteps: 1, kidSteps: 1),
          isTrue);
    });
  });
}
