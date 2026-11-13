import 'package:flutter/material.dart';

import '../../ui/layout/scale_down_to_fit.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';

const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// "This week" card for tablets: seven day dots (filled on days with a
/// finished lesson), the number of learned days and progress per subject.
class WeekPanel extends StatelessWidget {
  const WeekPanel({
    super.key,
    required this.learnedWeekdays,
    required this.masteredWriting,
    required this.writingTotal,
    required this.mathLevel,
    required this.mathTotal,
  });

  /// Weekdays with a finished lesson, 1 = Monday .. 7 = Sunday.
  final Set<int> learnedWeekdays;
  final int masteredWriting;
  final int writingTotal;
  final int mathLevel;
  final int mathTotal;

  static const _muted = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: raisedDecoration(),
      // In a fixed-height row, large system text scales the content down
      // instead of overflowing; in the portrait scroll it just grows.
      child: ScaleDownToFit(
        fillHeight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tuần này',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var d = 1; d <= 7; d++)
                  Expanded(
                      child: _DayDot(
                          day: d, learned: learnedWeekdays.contains(d))),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${learnedWeekdays.length} ngày học',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Chữ đã thuộc: $masteredWriting/$writingTotal',
                    style: _muted),
                Text('Cấp Toán: $mathLevel/$mathTotal', style: _muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.learned});

  final int day;
  final bool learned;

  @override
  Widget build(BuildContext context) {
    final label = _dayLabels[day - 1];
    return Semantics(
      label: learned ? '$label, đã học' : label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final size = (c.maxWidth - 6).clamp(16.0, 40.0);
              return Container(
                key: ValueKey('week-dot-$day'),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: learned ? AppColors.accent : AppColors.dot,
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
