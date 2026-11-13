import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../progress/progress_repository.dart';
import '../assets.dart';
import '../theme/depth.dart';
import '../theme/tokens.dart';
import 'info_pill.dart';

/// Top row of a session screen: back button, title, optional lesson-step
/// progress bar and the star pill.
class SessionHeader extends ConsumerWidget {
  const SessionHeader({
    required this.title,
    required this.onBack,
    this.step,
    this.totalSteps,
    super.key,
  });

  final String title;
  final int? step;
  final int? totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ref.watch(homeSummaryProvider).valueOrNull?.totalStars ?? 0;
    final showProgress = step != null && totalSteps != null && totalSteps! > 0;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Semantics(
            label: 'Quay lại',
            button: true,
            excludeSemantics: true,
            child: InkResponse(
              onTap: onBack,
              radius: 32,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: raisedDecoration(radius: 24),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 36,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          if (showProgress) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: _ProgressBar(step: step!, total: totalSteps!),
            ),
          ],
          const SizedBox(width: 8),
          InfoPill(
            leading: Image.asset(
              AppImages.icStar,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            label: '$stars',
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$step/$total',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: SizedBox(
              width: 48,
              height: 8,
              child: LinearProgressIndicator(
                value: (step / total).clamp(0.0, 1.0),
                backgroundColor: AppColors.dot,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$step/$total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
