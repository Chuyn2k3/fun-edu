import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../rewards/reward_repository.dart';
import '../../ui/theme/tokens.dart';
import 'parent_card.dart';

/// "Phần thưởng" tab: real-life rewards of one kid, unlocked by total stars.
class RewardsTab extends ConsumerStatefulWidget {
  const RewardsTab({super.key, required this.kidId});

  final int kidId;

  @override
  ConsumerState<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends ConsumerState<RewardsTab> {
  final _title = TextEditingController();
  double _stars = minRewardStars.toDouble();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(rewardsDataProvider(widget.kidId));
    ref.invalidate(pendingRewardProvider);
  }

  Future<void> _add() async {
    if (_busy || _title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(rewardRepositoryProvider)
          .add(widget.kidId, _title.text, _stars.round());
      _title.clear();
      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeem(RealReward r) async {
    await ref.read(rewardRepositoryProvider).redeem(r.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(rewardsDataProvider(widget.kidId)).valueOrNull;
    final pending = data?.rewards.where((r) => r.redeemedAt == null).toList();
    final given = data?.rewards.where((r) => r.redeemedAt != null).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentCard(
            title: 'Phần thưởng cho bé',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _title,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxRewardTitleLength),
                  ],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Đi công viên',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.tile),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cần ${_stars.round()} sao',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                Slider(
                  min: minRewardStars.toDouble(),
                  max: maxRewardStars.toDouble(),
                  divisions: (maxRewardStars - minRewardStars) ~/ 10,
                  value: _stars,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _stars = v),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed:
                      _title.text.trim().isEmpty || _busy ? null : _add,
                  child: const Text(
                    'Thêm phần thưởng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (pending != null && pending.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Heading('Đang chờ'),
            for (final r in pending) ...[
              const SizedBox(height: 10),
              _PendingCard(
                reward: r,
                stars: data!.stars,
                onRedeem: () => _redeem(r),
              ),
            ],
          ],
          if (given != null && given.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Heading('Đã thưởng'),
            for (final r in given) ...[
              const SizedBox(height: 10),
              ParentCard(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
        ),
      );
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.reward,
    required this.stars,
    required this.onRedeem,
  });

  final RealReward reward;
  final int stars;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final needed = reward.starsNeeded;
    final enough = stars >= needed;
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            reward.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: (stars / needed).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppColors.dot,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$stars/$needed sao',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: enough ? onRedeem : null,
            child: const Text(
              'Đã thưởng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
