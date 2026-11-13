import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// The path of the screen on top, for listeners outside the navigator.
///
/// go_router 15 notifies route-information listeners on go/push but not on
/// pop, and after a push its route information soon reverts to the base
/// location. So this follows both sources: route information for go/push
/// (also while the router is not mounted), and the router delegate, which
/// notifies on every change including pops. Listeners hear only real path
/// changes, never in the middle of a build.
class RouterLocation extends ChangeNotifier {
  RouterLocation._(this._router)
      : _path = _router.routeInformationProvider.value.uri.path {
    _router.routeInformationProvider.addListener(_fromInformation);
    _router.routerDelegate.addListener(_fromDelegate);
  }

  static final _cache = Expando<RouterLocation>();

  /// The shared location of [router].
  static RouterLocation of(GoRouter router) =>
      _cache[router] ??= RouterLocation._(router);

  final GoRouter _router;
  String _path;
  bool _notifyScheduled = false;

  String get path => _path;

  void _fromInformation() =>
      _set(_router.routeInformationProvider.value.uri.path);

  void _fromDelegate() {
    final delegate = _router.routerDelegate;
    if (delegate.currentConfiguration.matches.isEmpty) return;
    // `state` is the top route, including pushed ones.
    _set(delegate.state.uri.path);
  }

  void _set(String path) {
    if (path == _path) return;
    _path = path;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final building = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!building) {
      notifyListeners();
    } else if (!_notifyScheduled) {
      _notifyScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyScheduled = false;
        notifyListeners();
      });
    }
  }
}
