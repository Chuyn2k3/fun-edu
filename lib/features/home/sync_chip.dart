import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/auth/session_controller.dart';
import '../../online/online_config.dart';
import '../../online/sync/sync_health.dart';
import '../../parent/parent_gate_route.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';

/// Top-bar cloud chip on Home showing online sync status to parents.
/// Completely hidden in guest mode. Minimum interactive size 48×48.
class SyncChip extends ConsumerStatefulWidget {
  const SyncChip({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<SyncChip> createState() => _SyncChipState();
}

class _SyncChipState extends ConsumerState<SyncChip> {
  static const _savedHideDelay = Duration(seconds: 3);
  bool _showSavedLabel = true;
  Timer? _hideTimer;
  bool _wasSaved = false;

  @override
  void initState() {
    super.initState();
    _scheduleSavedHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleSavedHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_savedHideDelay, () {
      if (mounted) {
        setState(() => _showSavedLabel = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(onlineConfigProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    if (!config.enabled || session == null) {
      return const SizedBox.shrink();
    }

    final health = ref.watch(syncHealthProvider);
    final isSaved = !health.running && health.pending == 0;

    if (isSaved && !_wasSaved) {
      _showSavedLabel = true;
      _scheduleSavedHide();
    } else if (!isSaved) {
      _hideTimer?.cancel();
      _showSavedLabel = true;
    }
    _wasSaved = isSaved;

    final IconData icon;
    final Color iconColor;
    final String? label;
    final String semanticsLabel;

    if (health.running) {
      icon = Icons.cloud_upload_rounded;
      iconColor = const Color(0xFF0B57D0);
      label = 'Đang lưu…';
      semanticsLabel = 'Đang lưu…';
    } else if (health.pending > 0) {
      icon = Icons.cloud_off_rounded;
      iconColor = const Color(0xFFA04000);
      label = '${health.pending} bài chưa lưu';
      semanticsLabel = label;
    } else {
      icon = Icons.cloud_done_rounded;
      iconColor = const Color(0xFF137333);
      label = _showSavedLabel ? 'Đã lưu' : null;
      semanticsLabel = 'Đã lưu';
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: raisedDecoration(radius: AppRadii.pill),
          child: InkWell(
            key: const ValueKey('sync-chip'),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: () => openParentCorner(context, focus: 'account'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: label == null ? 12 : (widget.compact ? 10 : 12),
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: iconColor),
                    if (label != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Parent reminder banner shown on Home when progress has been unsaved for
/// more than 24 hours and there are pending items.
class SyncReminderBanner extends ConsumerWidget {
  const SyncReminderBanner({super.key});

  static int? staleDays(SyncHealth health, DateTime now) {
    final last = health.lastOkAt;
    if (last == null || health.pending <= 0) return null;
    final diff = now.difference(last);
    if (diff <= const Duration(hours: 24)) return null;
    final days = (diff.inMinutes / (24 * 60)).ceil();
    return math.max(1, days);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(onlineConfigProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    if (!config.enabled || session == null) {
      return const SizedBox.shrink();
    }
    final health = ref.watch(syncHealthProvider);
    final now = ref.watch(syncHealthClockProvider)();
    final days = staleDays(health, now);
    if (days == null) return const SizedBox.shrink();

    return AppStatusBanner(
      key: const ValueKey('sync-reminder-banner'),
      kind: AppToastKind.warning,
      text:
          'Ba mẹ ơi, tiến độ $days ngày nay chưa lưu online. Kiểm tra mạng giúp bé nhé',
      onTap: () => openParentCorner(context, focus: 'account'),
    );
  }
}
