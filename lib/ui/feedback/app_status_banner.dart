import 'package:flutter/material.dart';

import '../layout/form_factor.dart';
import '../theme/tokens.dart';
import 'app_toast.dart';

/// A persistent or contextual status banner displayed inline (e.g. at the top
/// of the home screen or settings screen) to notify parents about sync/network state.
class AppStatusBanner extends StatelessWidget {
  final String text;
  final AppToastKind kind;
  final VoidCallback? onTap;

  const AppStatusBanner({
    super.key,
    required this.text,
    required this.kind,
    this.onTap,
  });

  IconData _iconForKind(AppToastKind kind) {
    switch (kind) {
      case AppToastKind.info:
        return Icons.info_outline_rounded;
      case AppToastKind.success:
        return Icons.check_circle_rounded;
      case AppToastKind.warning:
        return Icons.warning_amber_rounded;
      case AppToastKind.offline:
        return Icons.cloud_off_rounded;
      case AppToastKind.online:
        return Icons.cloud_done_rounded;
    }
  }

  Color _accentColor(AppToastKind kind) {
    switch (kind) {
      case AppToastKind.info:
        return AppColors.primary;
      case AppToastKind.success:
        return const Color(0xFF137333);
      case AppToastKind.warning:
        return const Color(0xFFE37400);
      case AppToastKind.offline:
        return AppColors.textMuted;
      case AppToastKind.online:
        return AppColors.primary;
    }
  }

  Color _bgColor(AppToastKind kind) {
    switch (kind) {
      case AppToastKind.info:
        return const Color(0xFFE8F0FE);
      case AppToastKind.success:
        return const Color(0xFFE6F4EA);
      case AppToastKind.warning:
        return const Color(0xFFFEF7E0);
      case AppToastKind.offline:
        return const Color(0xFFF1F3F4);
      case AppToastKind.online:
        return const Color(0xFFE8F0FE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final accent = _accentColor(kind);
    final bg = _bgColor(kind);

    Widget content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 14,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _iconForKind(kind),
            color: accent,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: accent,
              size: isTablet ? 24 : 20,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: content,
        ),
      );
    }

    return content;
  }
}
