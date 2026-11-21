import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../api_client.dart';
import '../auth/session_controller.dart';
import 'refresh_after_sync.dart';
import 'sync_store.dart';

/// Sends [body] to `/api/v1/sync` and returns the decoded answer.
typedef SyncTransport = Future<Map<String, Object?>?> Function(
    Map<String, Object?> body);

/// One sync: push local changes, pull everything new, merge, repeat while
/// merges produced changes (at most a few rounds).
class SyncEngine {
  SyncEngine(this._db, this._transport) : _store = SyncStore(_db);

  final AppDatabase _db;
  final SyncTransport _transport;
  final SyncStore _store;

  static const cursorKey = 'sync.cursor';
  static const lastSyncKey = 'sync.lastAt';
  static const _batch = 500;
  static const _maxRounds = 5;

  /// Returns true when anything was pulled into the local database.
  Future<bool> run() async {
    var pulledAny = false;
    for (var round = 0; round < _maxRounds; round++) {
      final pending = await _store.pendingChanges();
      final push = pending.take(_batch).toList();
      final pulled = <SyncRecord>[];

      var cursor = await _cursor();
      var first = true;
      while (true) {
        final res = await _transport({
          'since': cursor,
          'changes': first ? push.map((c) => c.toJson()).toList() : const [],
        });
        first = false;
        final records = (res?['records'] as List? ?? const [])
            .whereType<Map>()
            .map((r) => SyncRecord(
                  r['key'] as String,
                  r['deleted'] == true
                      ? null
                      : (r['payload'] as Map).cast<String, Object?>(),
                  version: (r['version'] as num).toInt(),
                ))
            .toList();
        pulled.addAll(records);
        final v = (res?['version'] as num?)?.toInt() ?? cursor;
        if (v > cursor) cursor = v;
        if (res?['hasMore'] != true) break;
      }

      // Whole pull first, then one merge: kids before their progress.
      await _store.applyRemote(pulled);
      await _setSetting(cursorKey, '$cursor');
      final ownKeys = push.map((c) => c.key).toSet();
      if (pulled.any((r) => !ownKeys.contains(r.key))) pulledAny = true;

      final left = await _store.pendingChanges();
      if (left.isEmpty) break;
    }
    await _setSetting(lastSyncKey, DateTime.now().toIso8601String());
    return pulledAny;
  }

  Future<int> _cursor() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(cursorKey)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }

  Future<void> _setSetting(String key, String value) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: key, value: value),
          );
}

/// State shown in Góc ba mẹ.
class SyncStatus {
  const SyncStatus({this.running = false, this.lastAt, this.failed = false});

  final bool running;
  final DateTime? lastAt;
  final bool failed;
}

/// Runs a sync when the parent signs in, when the app comes back to the
/// front, every 5 minutes while it is open, and on demand. Signed out:
/// does nothing.
class SyncController extends Notifier<SyncStatus> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  Future<void>? _running;

  @override
  SyncStatus build() {
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    ref.listen(sessionProvider, (prev, next) {
      final was = prev?.valueOrNull != null;
      final now = next.valueOrNull != null;
      if (now && !was) {
        _start();
        // Not during build (state is not set yet when already signed in at
        // launch): right after it.
        Future.microtask(syncNow);
      } else if (!now && was) {
        _stop();
        state = const SyncStatus();
      }
    }, fireImmediately: true);
    return const SyncStatus();
  }

  void _start() {
    _timer ??= Timer.periodic(const Duration(minutes: 5), (_) => syncNow());
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(syncNow()));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  Future<void> syncNow() => _running ??= _sync().whenComplete(() => _running = null);

  Future<void> _sync() async {
    final session = ref.read(sessionProvider.notifier);
    if (ref.read(sessionProvider).valueOrNull == null) return;
    state = SyncStatus(running: true, lastAt: state.lastAt);
    final api = ref.read(apiClientProvider);
    final engine = SyncEngine(
      ref.read(databaseProvider),
      (body) => session.authorized(
          (token) => api.post('/api/v1/sync', body, accessToken: token)),
    );
    try {
      final pulled = await engine.run();
      state = SyncStatus(lastAt: DateTime.now());
      if (pulled) refreshAfterSync(ref);
    } catch (_) {
      // Offline or server down: try again on the next trigger.
      state = SyncStatus(lastAt: state.lastAt, failed: true);
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncStatus>(SyncController.new);
