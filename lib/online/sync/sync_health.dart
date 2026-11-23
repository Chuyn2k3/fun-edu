import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../auth/session_controller.dart';
import '../net/network_status.dart';
import '../online_config.dart';
import 'sync_store.dart';

const _displayablePendingKinds = {'lesson', 'glyph', 'race'};

/// Counts only user-facing pending items (completed lessons, glyphs written,
/// races finished) so technical sync metadata never inflates the parent badge.
int countDisplayablePending(Iterable<SyncChange> changes) {
  var count = 0;
  for (final c in changes) {
    if (c.payload == null) continue;
    final idx = c.key.indexOf(':');
    if (idx > 0 && _displayablePendingKinds.contains(c.key.substring(0, idx))) {
      count++;
    }
  }
  return count;
}

/// Snapshot of online sync health displayed to parents on Home and in Góc ba mẹ.
class SyncHealth {
  const SyncHealth({
    this.pending = 0,
    this.lastOkAt,
    this.net = NetState.unknown,
    this.running = false,
    this.offlineSince,
  });

  final int pending;
  final DateTime? lastOkAt;
  final NetState net;
  final bool running;
  final DateTime? offlineSince;

  SyncHealth copyWith({
    int? pending,
    DateTime? lastOkAt,
    NetState? net,
    bool? running,
    DateTime? offlineSince,
    bool clearOfflineSince = false,
  }) {
    return SyncHealth(
      pending: pending ?? this.pending,
      lastOkAt: lastOkAt ?? this.lastOkAt,
      net: net ?? this.net,
      running: running ?? this.running,
      offlineSince:
          clearOfflineSince ? null : (offlineSince ?? this.offlineSince),
    );
  }
}

/// Overridable clock for deterministic tests of 1-minute / 24-hour thresholds.
final syncHealthClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class SyncHealthNotifier extends Notifier<SyncHealth> {
  final _savedToastCtrl = StreamController<void>.broadcast();
  DateTime? _offlineSince;
  bool _disposed = false;

  /// Emits once when a sync completes after being offline for at least 1 minute.
  Stream<void> get onSavedAfterOffline => _savedToastCtrl.stream;

  @override
  SyncHealth build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    final config = ref.watch(onlineConfigProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    if (!config.enabled || session == null) {
      _offlineSince = null;
      return const SyncHealth();
    }

    final initialNet = ref.read(networkStatusProvider);
    if (initialNet == NetState.offline && _offlineSince == null) {
      _offlineSince = ref.read(syncHealthClockProvider)();
    }

    ref.listen<NetState>(networkStatusProvider, (_, nextNet) {
      if (_disposed) return;
      if (nextNet == NetState.offline) {
        _offlineSince ??= ref.read(syncHealthClockProvider)();
        state = state.copyWith(net: nextNet, offlineSince: _offlineSince);
      } else {
        state = state.copyWith(net: nextNet);
      }
    });

    Future.microtask(_loadInitialFromDb);

    return SyncHealth(
      net: initialNet,
      offlineSince: _offlineSince,
    );
  }

  Future<void> _loadInitialFromDb() async {
    if (_disposed) return;
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;
    try {
      final db = ref.read(databaseProvider);
      final row = await (db.select(db.appSettings)
            ..where((t) => t.key.equals('sync.lastAt')))
          .getSingleOrNull();
      if (_disposed) return;
      final lastAt = row == null ? null : DateTime.tryParse(row.value);
      final pending = countDisplayablePending(
        await SyncStore(db).pendingChanges(),
      );
      if (_disposed) return;
      state = state.copyWith(
        lastOkAt: state.lastOkAt ?? lastAt,
        pending: pending,
      );
    } catch (_) {
      // Ignore if DB is already closed during test teardown.
    }
  }

  /// Refreshes the displayable pending count from local changes without network.
  Future<void> refreshPending() async {
    if (_disposed) return;
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null || !session.linked) return;
    try {
      final db = ref.read(databaseProvider);
      final count = countDisplayablePending(
        await SyncStore(db).pendingChanges(),
      );
      if (!_disposed) {
        state = state.copyWith(pending: count);
      }
    } catch (_) {
      // Ignore closed DB during teardown.
    }
  }

  void setRunning(bool running) {
    if (_disposed) return;
    state = state.copyWith(running: running);
  }

  void setPending(int pending) {
    if (_disposed) return;
    state = state.copyWith(pending: pending);
  }

  /// Marks a sync as completed, emits on [onSavedAfterOffline] if offline >= 1m,
  /// and resets [offlineSince].
  void recordSyncSuccess({int? pending, DateTime? at}) {
    if (_disposed) return;
    final now = at ?? ref.read(syncHealthClockProvider)();
    final offlineSince = _offlineSince ?? state.offlineSince;
    if (offlineSince != null &&
        now.difference(offlineSince) >= const Duration(minutes: 1)) {
      _savedToastCtrl.add(null);
    }
    _offlineSince = null;
    state = state.copyWith(
      pending: pending ?? 0,
      lastOkAt: now,
      running: false,
      clearOfflineSince: true,
    );
  }

  void recordSyncFailure({int? pending}) {
    if (_disposed) return;
    state = state.copyWith(
      running: false,
      pending: pending ?? state.pending,
    );
  }
}

final syncHealthProvider =
    NotifierProvider<SyncHealthNotifier, SyncHealth>(SyncHealthNotifier.new);
