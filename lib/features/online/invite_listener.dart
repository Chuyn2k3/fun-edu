import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/friends/lobby_client.dart';
import '../../online/online_config.dart';
import '../../online/room/room_controller.dart';
import '../../profile/avatars.dart';
import '../../profile/kid_repository.dart';
import '../../router.dart';
import '../../router_location.dart';
import '../../screen_time/screen_time_guard.dart';
import '../../ui/assets.dart';
import '../../ui/feedback/feedback.dart';
import '../online_race/room_widgets.dart';

/// Returns true when [path] hosts lobby presence/invites (`/game*`,
/// `/collection`, or `/parent*`).
bool isLobbyEligibleRoute(String path) {
  if (path == '/game' || path.startsWith('/game/')) return true;
  if (path == '/collection' || path.startsWith('/collection/')) return true;
  if (path == '/parent' || path.startsWith('/parent/')) return true;
  return false;
}

/// Returns true when [path] is an active learning, writing, racing, or setup
/// screen where an incoming invite dialog must wait in the queue.
bool isInviteDeferredRoute(String path) {
  if (path == '/lesson' || path.startsWith('/lesson/')) return true;
  if (path.startsWith('/trace')) return true;
  if (path.startsWith('/practice')) return true;
  if (path.startsWith('/game/race/') || path == '/game/room/race') return true;
  if (path == '/placement' || path == '/setup' || path == '/restore') {
    return true;
  }
  return false;
}

/// Observes app foreground/background lifecycle, active route, and
/// [lobbyClientProvider] to:
/// - keep `/ws/lobby` connected only on eligible routes (with a 30 s grace
///   period after leaving) while signed in and in the foreground,
/// - show a kid-friendly invite modal when an unexpired invite is ready (never
///   interrupting lessons, races, or [SleepScreen]),
/// - auto-dismiss the exact modal route if cancelled or expired, and
/// - surface warm toasts for showcase reactions and invite replies.
class InviteListener extends ConsumerStatefulWidget {
  const InviteListener({
    super.key,
    required this.child,
    this.pathResolver,
    this.navigatorKey,
    this.onNavigateToLobby,
  });

  final Widget child;
  final String Function()? pathResolver;
  final GlobalKey<NavigatorState>? navigatorKey;
  final VoidCallback? onNavigateToLobby;

  @override
  ConsumerState<InviteListener> createState() => _InviteListenerState();
}

class _InviteListenerState extends ConsumerState<InviteListener>
    with WidgetsBindingObserver {
  bool _dialogShowing = false;
  bool _programmaticClose = false;
  bool _joining = false;
  String? _shownInviteId;
  NavigatorState? _dialogNavigator;
  Route<dynamic>? _dialogRoute;
  final Set<String> _handledInviteIds = {};

  RouterLocation get _location => RouterLocation.of(appRouter);

  String _currentPath() => widget.pathResolver?.call() ?? _location.path;

  NavigatorState? get _navState =>
      widget.navigatorKey?.currentState ??
      appRouter.routerDelegate.navigatorKey.currentState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_onLocationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(onlineConfigProvider).enabled) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      final lobby = ref.read(lobbyClientProvider.notifier);
      if (lifecycle == AppLifecycleState.paused ||
          lifecycle == AppLifecycleState.hidden ||
          lifecycle == AppLifecycleState.detached) {
        lobby.onAppPaused();
      } else {
        lobby.onAppResumed();
      }
      _syncRouteState();
      _maybeShowInvite();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _location.removeListener(_onLocationChanged);
    _closeOpenDialog(disposing: true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(onlineConfigProvider).enabled) return;
    final lobby = ref.read(lobbyClientProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        lobby.onAppResumed();
        _maybeShowInvite();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        lobby.onAppPaused();
      case AppLifecycleState.inactive:
        // Transient overlays (Control Center, notification shade, OAuth sheet)
        // must not tear down the lobby socket.
        break;
    }
  }

  void _onLocationChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(onlineConfigProvider).enabled) return;
      _syncRouteState();
      _maybeShowInvite();
    });
  }

  void _syncRouteState() {
    if (!ref.read(onlineConfigProvider).enabled) return;
    final path = _currentPath();
    final asleep = ref.read(screenTimeBlockedProvider);
    final lobby = ref.read(lobbyClientProvider.notifier);
    lobby.setRouteEligible(isLobbyEligibleRoute(path));
    lobby.setRouteBusy(isInviteDeferredRoute(path) || asleep);
  }

  void _recordHandled(String inviteId) {
    if (_handledInviteIds.length >= 50) {
      _handledInviteIds.clear();
    }
    _handledInviteIds.add(inviteId);
  }

  void _closeOpenDialog({bool disposing = false}) {
    final route = _dialogRoute;
    final nav = _dialogNavigator;
    if (!_dialogShowing && route == null) return;

    _programmaticClose = true;
    _dialogShowing = false;
    _shownInviteId = null;
    _dialogRoute = null;
    _dialogNavigator = null;

    if (route != null && route.isActive && nav != null && nav.mounted) {
      if (disposing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (route.isActive && nav.mounted) {
            nav.removeRoute(route);
          }
        });
      } else {
        nav.removeRoute(route);
      }
    }
  }

  void _maybeShowInvite() {
    if (!mounted || _dialogShowing || _joining) return;

    final path = _currentPath();
    if (isInviteDeferredRoute(path) ||
        ref.read(lobbyBusyProvider) ||
        ref.read(screenTimeBlockedProvider)) {
      return;
    }

    final invite = ref.read(lobbyClientProvider).pendingInvite;
    if (invite == null || _handledInviteIds.contains(invite.inviteId)) return;

    final now = ref.read(lobbyClockProvider)();
    if (invite.isExpiredAt(now)) {
      ref.read(lobbyClientProvider.notifier).dismissPendingInvite();
      return;
    }

    final kidId = ref.read(currentKidIdProvider).valueOrNull;
    if (kidId == null) return;

    final navContext =
        _navState?.context ?? Navigator.maybeOf(context)?.context;
    if (navContext == null || !navContext.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowInvite();
      });
      return;
    }

    final navigator = Navigator.maybeOf(navContext, rootNavigator: true);
    if (navigator == null) return;

    final avatar =
        kidAvatars.contains(invite.avatar) ? invite.avatar : AppImages.chipMain;
    final nick =
        invite.nickname.trim().isEmpty ? 'Bạn đua' : invite.nickname.trim();

    Route<dynamic>? capturedRoute;
    BuildContext? capturedDialogContext;
    var userActionTaken = false;

    _dialogShowing = true;
    _programmaticClose = false;
    _shownInviteId = invite.inviteId;
    _dialogNavigator = navigator;
    _dialogRoute = null;

    void closeCapturedDialog(bool result) {
      final ctx = capturedDialogContext;
      if (ctx != null && ctx.mounted) {
        Navigator.of(ctx).pop(result);
      } else if (capturedRoute != null &&
          capturedRoute!.isActive &&
          navigator.mounted) {
        navigator.removeRoute(capturedRoute!);
      }
    }

    showAppDialog<bool>(
      navContext,
      audience: AppAudience.kid,
      image: avatar,
      title: '$nick mời con đua tên lửa!',
      body: Builder(
        builder: (dialogCtx) {
          capturedDialogContext = dialogCtx;
          capturedRoute = ModalRoute.of(dialogCtx);
          if (_dialogShowing && _shownInviteId == invite.inviteId) {
            _dialogRoute = capturedRoute;
          }
          return const SizedBox.shrink();
        },
      ),
      primaryLabel: 'Vào đua',
      primaryKey: const ValueKey('invite-accept'),
      secondaryLabel: 'Để sau',
      secondaryKey: const ValueKey('invite-decline'),
      onPrimaryPressed: () {
        if (userActionTaken || _handledInviteIds.contains(invite.inviteId)) {
          return;
        }
        userActionTaken = true;
        _recordHandled(invite.inviteId);
        _dialogShowing = false;
        _shownInviteId = null;
        _dialogRoute = null;
        _dialogNavigator = null;
        closeCapturedDialog(true);
        unawaited(_acceptInvite(invite));
      },
      onSecondaryPressed: () {
        if (userActionTaken || _handledInviteIds.contains(invite.inviteId)) {
          return;
        }
        userActionTaken = true;
        _recordHandled(invite.inviteId);
        _dialogShowing = false;
        _shownInviteId = null;
        _dialogRoute = null;
        _dialogNavigator = null;
        closeCapturedDialog(false);
        ref
            .read(lobbyClientProvider.notifier)
            .replyInvite(inviteId: invite.inviteId, accept: false);
      },
    ).then((accepted) {
      final wasProgrammatic = _programmaticClose;
      _programmaticClose = false;
      if (_shownInviteId == invite.inviteId) {
        _dialogShowing = false;
        _shownInviteId = null;
        _dialogRoute = null;
        _dialogNavigator = null;
      }
      if (!mounted ||
          wasProgrammatic ||
          userActionTaken ||
          _handledInviteIds.contains(invite.inviteId)) {
        return;
      }
      // Dismissed via barrier tap or system back button.
      _recordHandled(invite.inviteId);
      ref
          .read(lobbyClientProvider.notifier)
          .replyInvite(inviteId: invite.inviteId, accept: false);
    });
  }

  Future<void> _acceptInvite(LobbyInvite invite) async {
    _joining = true;
    try {
      final lobby = ref.read(lobbyClientProvider.notifier);
      lobby.replyInvite(inviteId: invite.inviteId, accept: true);

      final kid = await currentRoomKid(ref);
      if (!mounted) return;
      if (kid == null) {
        _showToast('Chưa có hồ sơ bé', AppToastKind.warning);
        return;
      }

      final room = ref.read(roomControllerProvider.notifier);
      if (ref.read(roomControllerProvider).phase != RoomPhase.idle) {
        await room.leave();
        if (!mounted) return;
      }
      await room.join(invite.roomCode, kid);
      if (!mounted) return;

      final roomState = ref.read(roomControllerProvider);
      final canEnterLobby = roomState.phase == RoomPhase.lobby ||
          roomState.phase == RoomPhase.connecting ||
          roomState.phase == RoomPhase.countdown;
      if (!canEnterLobby) {
        _showToast(roomErrorText(roomState.error), AppToastKind.warning);
        return;
      }

      if (widget.onNavigateToLobby != null) {
        widget.onNavigateToLobby!();
      } else {
        appRouter.go('/game/room/lobby');
      }
    } catch (_) {
      if (mounted) {
        _showToast(roomErrorText(null), AppToastKind.warning);
      }
    } finally {
      _joining = false;
    }
  }

  void _showToast(String text, AppToastKind kind) {
    final navState = _navState;
    final navContext = navState?.context ?? context;
    if (!navContext.mounted) return;
    showAppToast(
      navContext,
      text,
      kind: kind,
      overlayState: navState?.overlay,
    );
  }

  void _handleReaction(LobbyReactionEvent event) {
    final who = event.fromNickname.trim().isEmpty
        ? 'Bạn đua'
        : event.fromNickname.trim();
    final text = switch (event.kind) {
      'clap' => '$who vừa vỗ tay khen Tủ khoe của bé!',
      'heart' => '$who vừa thả tim cho Tủ khoe của bé!',
      'star' => '$who vừa tặng sao cho Tủ khoe của bé!',
      _ => '$who vừa thả cảm xúc cho Tủ khoe của bé!',
    };
    _showToast(text, AppToastKind.success);
  }

  void _handleInviteReply(LobbyInviteReplyEvent event) {
    if (event.accept) {
      _showToast('Bạn đang vào phòng đua cùng bé!', AppToastKind.success);
    } else {
      _showToast('Bạn hẹn chút nữa cùng đua nhé!', AppToastKind.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(onlineConfigProvider).enabled) {
      ref.listen<LobbyState>(lobbyClientProvider, (prev, next) {
        if (_dialogShowing && next.pendingInvite?.inviteId != _shownInviteId) {
          _closeOpenDialog();
        }
        if (next.pendingInvite != null &&
            prev?.pendingInvite?.inviteId != next.pendingInvite?.inviteId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeShowInvite();
          });
        }
        if (next.lastReaction != null &&
            next.lastReaction?.seq != prev?.lastReaction?.seq) {
          _handleReaction(next.lastReaction!);
        }
        if (next.lastInviteReply != null &&
            next.lastInviteReply?.seq != prev?.lastInviteReply?.seq) {
          _handleInviteReply(next.lastInviteReply!);
        }
      });

      ref.listen<AsyncValue<int?>>(currentKidIdProvider, (_, next) {
        if (next.valueOrNull != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeShowInvite();
          });
        }
      });

      ref.listen<bool>(lobbyBusyProvider, (_, next) {
        if (!next) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeShowInvite();
          });
        }
      });

      ref.listen<bool>(screenTimeBlockedProvider, (_, blocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (blocked) {
            _closeOpenDialog();
          }
          _syncRouteState();
          if (!blocked) {
            _maybeShowInvite();
          }
        });
      });
    }

    return widget.child;
  }
}
