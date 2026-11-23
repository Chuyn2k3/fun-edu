import 'dart:async';
import 'package:flutter/material.dart';

import '../../router.dart';
import '../layout/form_factor.dart';
import '../theme/tokens.dart';

enum AppToastKind {
  info,
  success,
  warning,
  offline,
  online,
}

OverlayEntry? _currentToastEntry;
Timer? _currentToastTimer;

/// Displays an animated toast message anchored to the top of the screen.
///
/// If a toast is currently displayed, it is immediately dismissed and replaced.
void showAppToast(
  BuildContext? context,
  String text, {
  AppToastKind kind = AppToastKind.info,
  Duration duration = const Duration(seconds: 3),
  OverlayState? overlayState,
}) {
  OverlayState? overlay = overlayState;
  if (overlay == null && context != null) {
    overlay = Overlay.maybeOf(context, rootOverlay: true);
  }
  overlay ??= rootNavigatorKey.currentState?.overlay;
  if (overlay == null) return;

  _currentToastTimer?.cancel();
  _currentToastTimer = null;

  _currentToastEntry?.remove();
  _currentToastEntry = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _ToastWidget(
      text: text,
      kind: kind,
      duration: duration,
      onDismissed: () {
        if (_currentToastEntry == entry) {
          entry.remove();
          _currentToastEntry = null;
        }
      },
    ),
  );

  _currentToastEntry = entry;
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String text;
  final AppToastKind kind;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.text,
    required this.kind,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnim;
  late final Animation<double> _fadeAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        if (mounted) {
          widget.onDismissed();
        }
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

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

  Color _iconColorForKind(AppToastKind kind) {
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isTablet = context.isTablet;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 540 : 420,
            ),
            child: SlideTransition(
              position: _offsetAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF503C28).withOpacity(0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      const BoxShadow(
                        color: Color(0x10503C28),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForKind(widget.kind),
                        color: _iconColorForKind(widget.kind),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
