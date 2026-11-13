import 'package:flutter/material.dart';

import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/speech_bubble.dart';

const _gap = 20.0;
const _landscapeHeroHeight = 320.0;
const _landscapeHeroMaxHeight = 380.0;
const _portraitHeroHeight = 360.0;
const _playSize = 110.0;
const _minSideBySideWidth = 900.0;

/// Tablet home content beside the navigation rail. Landscape: hero lesson
/// card and [weekPanel] side by side, then the four subjects in one row.
/// Portrait: full-width hero, subjects 2x2, then [weekPanel].
class HomeTabletBody extends StatelessWidget {
  const HomeTabletBody({
    super.key,
    required this.landscape,
    required this.sky,
    required this.navRail,
    required this.topBar,
    required this.hero,
    required this.weekPanel,
    required this.subjects,
    this.reward,
  });

  final bool landscape;

  /// Positioned sky backdrop shared with the phone layout.
  final Widget sky;
  final Widget navRail;
  final Widget topBar;
  final Widget hero;
  final Widget weekPanel;

  /// Builds the subject grid with the given number of columns.
  final Widget Function(int columns) subjects;
  final Widget? reward;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        sky,
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              right: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: navRail),
              ),
            ),
            Expanded(
              child: SafeArea(
                left: false,
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, c) => _content(
                    // Narrow landscape windows (small Android tablets,
                    // split view) fall back to the portrait arrangement.
                    landscape && c.maxWidth >= _minSideBySideWidth,
                    // Taller screens get a taller hero so the page does
                    // not end in a band of empty space.
                    (c.maxHeight * 0.36).clamp(
                      _landscapeHeroHeight,
                      _landscapeHeroMaxHeight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _content(bool landscape, double heroHeight) {
    return TabletTextScale(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 24, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            topBar,
            const SizedBox(height: _gap),
            if (landscape)
              SizedBox(
                height: heroHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 62, child: hero),
                    const SizedBox(width: _gap),
                    Expanded(flex: 38, child: weekPanel),
                  ],
                ),
              )
            else
              SizedBox(height: _portraitHeroHeight, child: hero),
            if (reward != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: reward,
                ),
              ),
            ],
            const SizedBox(height: 28),
            const Text(
              'Hôm nay học gì?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            subjects(landscape ? 4 : 2),
            if (!landscape) ...[
              const SizedBox(height: 28),
              weekPanel,
            ],
          ],
        ),
      ),
    );
  }
}

/// Big "today's lesson" card for tablets: Chíp's line, the title, a 110 pt
/// play button and a large Chíp on the right.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    required this.bubbleText,
    required this.progressText,
    required this.onStart,
  });

  final String bubbleText;
  final String progressText;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: const ValueKey('home-hero'),
      onTap: onStart,
      semanticsLabel: 'Bài hôm nay',
      builder: (pressed) => Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
        decoration: raisedDecoration(
          accent: AppColors.accent,
          tint: Subject.viet.tint,
          pressed: pressed,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: SpeechBubble(text: bubbleText),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Flexible(
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Bài hôm nay',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  progressText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _PlayButton(onTap: onStart),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: ExcludeSemantics(
                child: Image.asset(
                  AppImages.chipMain,
                  key: const ValueKey('home-hero-chip'),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bắt đầu bài hôm nay',
      excludeSemantics: true,
      child: Material(
        color: AppColors.accent,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.card, width: 5),
        ),
        elevation: 8,
        shadowColor: AppColors.accent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            key: ValueKey('home-hero-play'),
            width: _playSize,
            height: _playSize,
            child:
                Icon(Icons.play_arrow_rounded, size: 68, color: AppColors.card),
          ),
        ),
      ),
    );
  }
}
