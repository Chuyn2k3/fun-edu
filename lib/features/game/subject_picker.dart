import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../game/engine/race_question.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import 'game_widgets.dart';
import 'race_controller.dart';

/// "Đua với Chíp": pick Toán or Tiếng Việt, then race. Two big raised
/// cards (side by side on a tablet).
class SubjectPickerScreen extends StatelessWidget {
  const SubjectPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final cards = [
      _SubjectCard(
        subject: RaceSubject.toan,
        title: 'Toán',
        image: AppImages.icToan,
        color: Subject.toan,
      ),
      _SubjectCard(
        subject: RaceSubject.tiengViet,
        title: 'Tiếng Việt',
        image: AppImages.icTiengViet,
        color: Subject.tiengViet,
      ),
    ];
    return Scaffold(
      backgroundColor: GameColors.panelTop,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameColors.panelTop, GameColors.panelBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tablet ? 32 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GameBackButton(onTap: () => context.go('/game')),
                ),
                SizedBox(height: tablet ? 12 : 4),
                Image.asset(AppImages.rocketChip, height: tablet ? 180 : 130),
                const SizedBox(height: 8),
                Text(
                  'Đua với Chíp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tablet ? 44 : 32,
                    fontWeight: FontWeight.w900,
                    color: GameColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bé muốn đua môn nào?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tablet ? 26 : 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: tablet ? 32 : 22),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: tablet
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 24),
                                Expanded(child: cards[1]),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                cards[0],
                                const SizedBox(height: 18),
                                cards[1],
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.title,
    required this.image,
    required this.color,
  });

  final RaceSubject subject;
  final String title;
  final String image;
  final Subject color;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Pressable(
      key: ValueKey('pick-${subjectSlug(subject)}'),
      onTap: () => context.go('/game/race/${subjectSlug(subject)}'),
      semanticsLabel: 'Đua môn $title',
      builder: (pressed) => Container(
        height: tablet ? 280 : 132,
        padding: const EdgeInsets.all(18),
        decoration: raisedDecoration(
          accent: color.color,
          tint: color.tint,
          pressed: pressed,
        ),
        child: tablet
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(image, height: 150),
                  const SizedBox(height: 12),
                  _title(42),
                ],
              )
            : Row(
                children: [
                  Image.asset(image, height: 96),
                  const SizedBox(width: 16),
                  Expanded(child: _title(32)),
                  Icon(Icons.play_arrow_rounded, size: 44, color: color.color),
                ],
              ),
      ),
    );
  }

  Widget _title(double size) => Text(
        title,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: GameColors.ink,
        ),
      );
}
