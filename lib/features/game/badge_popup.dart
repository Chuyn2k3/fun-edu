import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/badges.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import 'fireworks.dart';

/// Shows [badge] earned: the medal flies in over fireworks and Chíp reads
/// its name. Closes with "Tuyệt quá!".
Future<void> showBadgePopup(BuildContext context, GameBadge badge) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: GameColors.skyTop.withOpacity(0.72),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => BadgePopup(badge: badge),
  );
}

class BadgePopup extends ConsumerStatefulWidget {
  const BadgePopup({super.key, required this.badge});

  final GameBadge badge;

  @override
  ConsumerState<BadgePopup> createState() => _BadgePopupState();
}

class _BadgePopupState extends ConsumerState<BadgePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _fly =
      CurvedAnimation(parent: _c, curve: Curves.elasticOut);
  late final Speaker _speaker = ref.read(speakerProvider);
  bool _decided = false;

  @override
  void initState() {
    super.initState();
    _speaker.speak('Huy hiệu mới: ${widget.badge.title}!');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final medal = tablet ? 300.0 : 210.0;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Fireworks(bursts: 6, repeat: !reduce),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Huy hiệu mới!',
                      style: TextStyle(
                        fontSize: tablet ? 34 : 26,
                        fontWeight: FontWeight.w900,
                        color: GameColors.starWarm,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _fly,
                      builder: (context, child) {
                        final v = _fly.value;
                        return Transform.translate(
                          offset: Offset(0, (1 - v) * -260),
                          child: Transform.scale(
                            scale: 0.4 + 0.6 * v,
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        widget.badge.image,
                        width: medal,
                        height: medal,
                        fit: BoxFit.contain,
                        semanticLabel: widget.badge.title,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                      decoration: raisedDecoration(
                        accent: GameColors.keyOrangeEdge,
                        tint: GameColors.keyOrangeTop,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.badge.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: tablet ? 34 : 28,
                              fontWeight: FontWeight.w900,
                              color: GameColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.badge.howTo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: tablet ? 20 : 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      semanticsLabel: 'Tuyệt quá!',
                      builder: (pressed) => Container(
                        height: tablet ? 88 : 72,
                        width: tablet ? 320 : 240,
                        alignment: Alignment.center,
                        decoration: raisedKeyDecoration(
                          top: GameColors.goTop,
                          body: GameColors.go,
                          edge: GameColors.goEdge,
                          pressed: pressed,
                        ),
                        child: Text(
                          'Tuyệt quá!',
                          style: TextStyle(
                            fontSize: tablet ? 30 : 24,
                            fontWeight: FontWeight.w900,
                            color: GameColors.goInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
