import 'package:flutter/material.dart';

import '../../game/engine/race.dart';
import '../../profile/avatars.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import 'race_rival.dart';

/// Online rooms with 3-4 kids: a slim column at the left edge, under the
/// pause button (the sky there stays empty: the planet and the landed
/// rockets are in the middle), with every racer's avatar, a progress bar
/// and their place once landed. The scene itself still shows the kid and
/// the leading friend (2 lanes).
class RaceStandingsStrip extends StatelessWidget {
  const RaceStandingsStrip({super.key, required this.standings});

  final List<RacerStanding> standings;

  /// Only rooms of 3 or more need it: with 2 the scene shows everyone.
  static bool shows(List<RacerStanding>? s) => s != null && s.length >= 3;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Container(
      key: const ValueKey('race-standings'),
      width: tablet ? 172 : 124,
      margin: EdgeInsets.only(left: tablet ? 28 : 16),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: tablet ? 8 : 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        boxShadow: const [
          BoxShadow(color: GameColors.hudEdge, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in standings)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tablet ? 3 : 2),
              child: _Racer(s, tablet: tablet),
            ),
        ],
      ),
    );
  }
}

class _Racer extends StatelessWidget {
  const _Racer(this.s, {required this.tablet});

  final RacerStanding s;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final avatar = kidAvatars.contains(s.avatar) ? s.avatar : kidAvatars[1];
    final size = tablet ? 38.0 : 28.0;
    final progress = (s.steps / onlineRaceLength).clamp(0.0, 1.0);
    final place = switch (s.rank) {
      1 => 'Nhất',
      2 => 'Nhì',
      3 => 'Ba',
      4 => 'Tư',
      _ => null,
    };
    final faded = s.left || s.away;
    final statusLabel = s.left
        ? '${s.name}: đã rời trận'
        : s.away
            ? '${s.name}: đang chờ'
            : place != null
                ? '${s.name}: về ${place.toLowerCase()}'
                : '${s.name}: ${s.steps} trên $onlineRaceLength nấc';

    Widget trailing;
    if (s.left && place == null) {
      trailing = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'Rời trận',
          style: TextStyle(
            fontSize: tablet ? 14 : 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      );
    } else if (s.away && place == null) {
      trailing = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'Đang chờ',
          style: TextStyle(
            fontSize: tablet ? 14 : 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      );
    } else if (place != null) {
      trailing = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          place,
          style: TextStyle(
            fontSize: tablet ? 18 : 14,
            fontWeight: FontWeight.w900,
            color: s.rank == 1 ? AppColors.primaryOnTint : AppColors.text,
          ),
        ),
      );
    } else {
      trailing = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: tablet ? 8 : 6,
          backgroundColor: AppColors.dot,
          color: s.isYou ? AppColors.accent : GameColors.keyBlueEdge,
        ),
      );
    }

    return Semantics(
      label: statusLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: faded ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(
                    // The kid's own rocket stands out in the brand orange.
                    color: s.isYou ? AppColors.primary : AppColors.dot,
                    width: s.isYou ? 3 : 2,
                  ),
                ),
                child: ClipOval(child: Image.asset(avatar, fit: BoxFit.contain)),
              ),
              const SizedBox(width: 4),
              Expanded(child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}
