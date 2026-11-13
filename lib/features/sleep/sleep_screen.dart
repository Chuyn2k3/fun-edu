import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../parent/parent_gate_route.dart';
import '../../profile/kid_repository.dart';
import '../../screen_time/screen_time_service.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/message_card.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../voice/speaker.dart';

const sleepLimitLine = 'Chíp Chíp buồn ngủ rồi. Mai mình học tiếp nhé!';
const sleepBedtimeLine = 'Đến giờ đi ngủ rồi. Chúc bé ngủ ngon!';

/// "Chíp Chíp is sleepy": shown instead of a kid screen when the daily limit
/// is used up or it is bedtime. Parents can pass the gate to add time.
class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({
    required this.status,
    required this.onExtraGranted,
    this.onOpenParentCorner,
    super.key,
  });

  final ScreenTimeStatus status;

  /// Called after the parent granted extra minutes.
  final VoidCallback onExtraGranted;

  /// Opens the parent corner; null hides that option (route not available).
  final VoidCallback? onOpenParentCorner;

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

enum _Choice { fifteen, thirty, corner }

class _SleepScreenState extends ConsumerState<SleepScreen> {
  late final Speaker _speaker;
  bool _busy = false;

  String get _line => widget.status == ScreenTimeStatus.bedtime
      ? sleepBedtimeLine
      : sleepLimitLine;

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _speaker.speak(_line);
  }

  @override
  void dispose() {
    _speaker.stop();
    super.dispose();
  }

  Future<void> _parent() async {
    if (_busy) return;
    _busy = true;
    try {
      final passed = await showParentGate(context);
      if (!passed || !mounted) return;
      final choice = await showDialog<_Choice>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Dành cho ba mẹ'),
          children: [
            // Extra minutes do not lift bedtime, so offer them only for the limit.
            if (widget.status == ScreenTimeStatus.limitReached) ...[
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(_Choice.fifteen),
                child: const Text('15 phút'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(_Choice.thirty),
                child: const Text('30 phút'),
              ),
            ],
            if (widget.onOpenParentCorner != null)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(_Choice.corner),
                child: const Text('Góc ba mẹ'),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == _Choice.corner) {
        widget.onOpenParentCorner?.call();
        return;
      }
      final kid = await ref.read(currentKidIdProvider.future);
      if (kid == null) return;
      await ref
          .read(screenTimeServiceProvider)
          .grantExtra(kid, choice == _Choice.fifteen ? 15 : 30);
      widget.onExtraGranted();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final chipSize = tablet ? 200 * tabletChipScale : 200.0;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(AppImages.chipSleep, width: chipSize, height: chipSize),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tablet ? 520 : 420),
          child: SpeechBubble(text: _line),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DottedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: tablet
                      ? TabletTextScale(child: MessageCard(child: content))
                      : content,
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: TextButton(
                  onPressed: _parent,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 48),
                    foregroundColor: AppColors.textMuted,
                  ),
                  child: const Text('Ba mẹ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
