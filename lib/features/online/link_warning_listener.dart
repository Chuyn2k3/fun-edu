import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/auth/session_controller.dart';
import '../../online/link/link_controller.dart';
import '../../router.dart';
import '../../router_location.dart';
import 'replace_data_dialog.dart';

/// Returns true if [path] is a screen where the child is learning or writing.
/// The replace-data warning dialog is deferred while on these screens so the
/// child's concentration is never interrupted.
bool isKidWritingRoute(String path) {
  if (path == '/lesson' || path.startsWith('/lesson/')) return true;
  if (path.startsWith('/trace')) return true;
  if (path.startsWith('/practice')) return true;
  if (path.contains('race')) return true;
  return false;
}

/// Listens to [linkControllerProvider] and displays [ReplaceDataDialog] when
/// the account has existing data that would replace the local guest data.
///
/// It does not interrupt active learning/writing screens (`/lesson`, `/trace/*`,
/// `/practice*`, `/game/*race*`), waiting until the user returns to a safe
/// route (such as `/` or `/parent`).
class LinkWarningListener extends ConsumerStatefulWidget {
  const LinkWarningListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LinkWarningListener> createState() =>
      _LinkWarningListenerState();
}

class _LinkWarningListenerState extends ConsumerState<LinkWarningListener> {
  bool _open = false;

  RouterLocation get _location => RouterLocation.of(appRouter);

  @override
  void initState() {
    super.initState();
    _location.addListener(_onLocationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeShowWarning(ref.read(linkControllerProvider));
      }
    });
  }

  @override
  void dispose() {
    _location.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeShowWarning(ref.read(linkControllerProvider));
      }
    });
  }

  void _maybeShowWarning(LinkState state) {
    if (state is! LinkNeedsWarning) return;
    if (_open) return;

    final path = _location.path;
    if (isKidWritingRoute(path)) return;

    final navContext =
        appRouter.routerDelegate.navigatorKey.currentContext ??
        Navigator.maybeOf(context)?.context;
    if (navContext == null || !navContext.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowWarning(ref.read(linkControllerProvider));
      });
      return;
    }

    final session = ref.read(sessionProvider).valueOrNull;
    final who = session?.email ??
        (session?.provider == 'apple' ? 'Apple' : 'Google');

    _open = true;
    showReplaceDataDialog(
      navContext,
      local: state.local,
      account: state.account,
      accountLabel: who,
    ).whenComplete(() {
      if (mounted) {
        setState(() => _open = false);
      } else {
        _open = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LinkState>(linkControllerProvider, (_, next) {
      _maybeShowWarning(next);
    });
    return widget.child;
  }
}
