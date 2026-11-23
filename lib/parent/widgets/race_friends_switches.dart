// Privacy switches and friend-code text helpers.
part of 'race_friends_card.dart';

class _PrivacySwitches extends ConsumerWidget {
  const _PrivacySwitches({
    required this.kidId,
    required this.onTeaseChanged,
    required this.onShowcaseChanged,
    required this.onShowcaseLearningChanged,
  });

  final int kidId;
  final ValueChanged<bool> onTeaseChanged;
  final ValueChanged<bool> onShowcaseChanged;
  final ValueChanged<bool> onShowcaseLearningChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tease =
        ref.watch(kidTeaseStickersProvider(kidId)).valueOrNull ?? true;
    final showcaseOn =
        ref.watch(kidShowcaseOnProvider(kidId)).valueOrNull ?? true;
    final showcaseLearning =
        ref.watch(kidShowcaseLearningProvider(kidId)).valueOrNull ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SwitchRow(
          switchKey: const ValueKey('tease-stickers-switch'),
          title: 'Sticker trêu',
          subtitle: 'Hiện và gửi sticker trêu vui khi đua cùng bạn',
          value: tease,
          onChanged: onTeaseChanged,
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          switchKey: const ValueKey('showcase-on-switch'),
          title: 'Cho bạn xem Tủ khoe',
          subtitle: 'Bạn bè đã kết nối xem được Tủ khoe của bé',
          value: showcaseOn,
          onChanged: onShowcaseChanged,
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          switchKey: const ValueKey('showcase-learning-switch'),
          title: 'Cho bạn xem tiến độ học',
          subtitle: 'Hiện số chữ, bài học và sao trong Tủ khoe',
          value: showcaseLearning,
          onChanged: onShowcaseLearningChanged,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchKey,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            key: switchKey,
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Formats a 6- or 8-character code into two evenly spaced groups (`AB2 3CD`).
String formatFriendCode(String code) {
  final clean = normalizeFriendCode(code);
  if (clean.length < 4) return clean;
  final mid = clean.length ~/ 2;
  return '${clean.substring(0, mid)} ${clean.substring(mid)}';
}

/// Formats remaining lifetime of a friend code in Vietnamese.
String formatFriendCodeExpiry(Duration remaining) {
  if (remaining <= Duration.zero) return 'Đã hết hạn';
  final totalMinutes = remaining.inMinutes;
  if (totalMinutes < 1) return 'Hết hạn sau 1 phút';
  if (totalMinutes < 60) return 'Hết hạn sau $totalMinutes phút';
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (mins == 0) return 'Hết hạn sau $hours giờ';
  return 'Hết hạn sau $hours giờ $mins phút';
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(text: upper);
  }
}
