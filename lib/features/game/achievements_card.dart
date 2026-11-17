import 'package:flutter/material.dart';

import '../../game/data/game_repository.dart';
import '../../game/engine/race_question.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import 'game_widgets.dart';

/// "Thành tích": per subject the races, wins, best finish time (m:ss) and
/// answers right on the first try. Game numbers only (never the learning
/// stars or levels).
class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key, required this.stats});

  final Map<RaceSubject, GameStats> stats;

  static const _subjects = [
    (RaceSubject.toan, 'Toán', AppImages.icToan, Subject.toan),
    (
      RaceSubject.tiengViet,
      'Tiếng Việt',
      AppImages.icTiengViet,
      Subject.tiengViet
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Container(
      padding: EdgeInsets.fromLTRB(tablet ? 22 : 16, tablet ? 18 : 14,
          tablet ? 22 : 16, tablet ? 20 : 16),
      decoration: whiteChunkyDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(AppImages.icCrown, height: tablet ? 40 : 30),
              const SizedBox(width: 8),
              Text(
                'Thành tích',
                style: TextStyle(
                  fontSize: tablet ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: tablet ? 14 : 10),
          for (final (i, (s, name, icon, color)) in _subjects.indexed) ...[
            if (i > 0) SizedBox(height: tablet ? 12 : 10),
            _SubjectRow(
              subject: s,
              name: name,
              icon: icon,
              color: color,
              stats: stats[s] ??
                  const GameStats(
                      races: 0, wins: 0, bestTime: null, firstTryCorrect: 0),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.name,
    required this.icon,
    required this.color,
    required this.stats,
  });

  final RaceSubject subject;
  final String name;
  final String icon;
  final Subject color;
  final GameStats stats;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final key = subject.name;
    final best = stats.bestTime;
    final cells = [
      ('races', '${stats.races}', 'Số trận'),
      ('wins', '${stats.wins}', 'Về nhất'),
      ('best', best == null ? '—' : formatRaceTime(best), 'Nhanh nhất'),
      ('first', '${stats.firstTryCorrect}', 'Câu đúng'),
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(10, tablet ? 10 : 8, 10, tablet ? 12 : 10),
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(icon, height: tablet ? 30 : 24),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: tablet ? 19 : 15,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: tablet ? 8 : 6),
          Row(
            children: [
              for (final (id, value, label) in cells)
                Expanded(
                  child: Semantics(
                    label: '$label $name: $value',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            key: ValueKey('ach-$key-$id'),
                            style: TextStyle(
                              fontSize: tablet ? 30 : 22,
                              fontWeight: FontWeight.w900,
                              color: GameColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: tablet ? 15 : 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
