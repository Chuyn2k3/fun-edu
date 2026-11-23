// HUD pieces of the race screen: stage bar, buttons, bubbles, pause.
part of 'race_screen.dart';

class _StageProgressBar extends StatelessWidget {
  const _StageProgressBar({
    required this.kidSteps,
    required this.stage,
    required this.inSprint,
    required this.tablet,
  });

  final int kidSteps;
  final int stage;
  final bool inSprint;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final h = tablet ? 10.0 : 7.0;
    return Row(
      key: const ValueKey('stage-progress-bar'),
      children: [
        for (var i = 1; i <= 3; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: _stageSegment(i, h),
          ),
        ],
      ],
    );
  }

  Widget _stageSegment(int idx, double height) {
    final start = (idx - 1) * onlineStageQuestions;
    final fill = ((kidSteps - start) / onlineStageQuestions).clamp(0.0, 1.0);
    final isCurrent = stage == idx;
    final isSprint = idx == 3 && (inSprint || isCurrent);
    final fillColor = isSprint
        ? GameColors.sprintBadgeBg
        : (fill >= 1.0 ? GameColors.stageDone : GameColors.stageActive);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: GameColors.stageTrack,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: isCurrent
            ? Border.all(
                color: isSprint ? GameColors.cometRim : GameColors.stageActive,
                width: 1.2,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fill,
            heightFactor: 1.0,
            child: ColoredBox(color: fillColor),
          ),
        ),
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticsLabel: 'Tạm dừng',
      builder: (pressed) => Container(
        width: size,
        height: size,
        decoration: raisedKeyDecoration(
          top: AppColors.card,
          body: AppColors.card,
          edge: GameColors.hudEdge,
          radius: 20,
          lip: 5,
          pressed: pressed,
        ),
        child:
            Icon(Icons.pause_rounded, size: size * 0.5, color: GameColors.ink),
      ),
    );
  }
}

class _TryAgainBubble extends StatelessWidget {
  const _TryAgainBubble();

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(color: GameColors.hudEdge, offset: Offset(0, 5)),
          BoxShadow(
              color: GameColors.hudShadow,
              blurRadius: 16,
              offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppImages.chipEncourage,
              width: tablet ? 64 : 48, height: tablet ? 64 : 48),
          const SizedBox(width: 6),
          Text(
            _tryAgain,
            style: TextStyle(
              fontSize: tablet ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: GameColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RivalWaitingBadge extends StatelessWidget {
  const _RivalWaitingBadge({required this.avatar, required this.name});

  final String avatar;
  final String name;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final img = kidAvatars.contains(avatar) ? avatar : kidAvatars[1];
    return Container(
      key: const ValueKey('rival-waiting-badge'),
      margin: EdgeInsets.only(right: tablet ? 28 : 16),
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 12 : 10,
        vertical: tablet ? 6 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [
          BoxShadow(color: GameColors.hudEdge, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.4,
            child: ClipOval(
              child: Image.asset(
                img,
                width: tablet ? 32 : 24,
                height: tablet ? 32 : 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Đang chờ',
            style: TextStyle(
              fontSize: tablet ? 15 : 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onLeave});

  final VoidCallback onResume;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return ColoredBox(
      color: GameColors.skyTop.withOpacity(0.7),
      child: Center(
        child: Container(
          width: tablet ? 440 : 320,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: raisedDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AppImages.chipMain, height: tablet ? 140 : 110),
              const SizedBox(height: 8),
              Text(
                'Tạm dừng',
                style: TextStyle(
                  fontSize: tablet ? 34 : 28,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
              const SizedBox(height: 18),
              BigGameButton(label: 'Đua tiếp', onTap: onResume),
              const SizedBox(height: 14),
              BigGameButton(
                  label: 'Về Góc Chơi', onTap: onLeave, primary: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width game button: orange "go" key, or a white one.
class BigGameButton extends StatelessWidget {
  const BigGameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final h = primary ? (tablet ? 96.0 : 76.0) : (tablet ? 80.0 : 64.0);
    return Pressable(
      onTap: onTap,
      semanticsLabel: label,
      builder: (pressed) => Container(
        height: h,
        alignment: Alignment.center,
        decoration: primary
            ? raisedKeyDecoration(
                top: GameColors.goTop,
                body: GameColors.go,
                edge: GameColors.goEdge,
                pressed: pressed,
                lip: 8,
              )
            : raisedKeyDecoration(
                top: AppColors.card,
                body: GameColors.questionCardTint,
                edge: GameColors.questionCardEdge,
                pressed: pressed,
                lip: 7,
              ),
        child: ExcludeSemantics(
          child: Text(
            label,
            style: TextStyle(
              fontSize: primary ? (tablet ? 34 : 28) : (tablet ? 26 : 21),
              fontWeight: FontWeight.w900,
              color: primary ? GameColors.goInk : GameColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
