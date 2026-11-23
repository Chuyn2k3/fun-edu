import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../api_client.dart';
import '../auth/session_controller.dart';
import '../link/link_controller.dart';
import '../net/network_status.dart';
import 'refresh_after_sync.dart';
import 'sync_health.dart';
import 'sync_store.dart';

/// Sends [body] to `/api/v1/sync` and returns the decoded answer.
typedef SyncTransport = Future<Map<String, Object?>?> Function(
    Map<String, Object?> body);

/// One sync: push local changes, pull page by page and merge in one transaction
/// per page, repeat while changes remain (up to a cap).
class SyncEngine {
  SyncEngine(this._db, this._transport, {void Function(int)? onPendingChanged})
      : _store = SyncStore(_db),
        _onPendingChanged = onPendingChanged;

  final AppDatabase _db;
  final SyncTransport _transport;
  final SyncStore _store;
  final void Function(int)? _onPendingChanged;

  static const cursorKey = 'sync.cursor';
  static const lastSyncKey = 'sync.lastAt';
  static const batchKey = 'sync.batch';
  static const batchOkKey = 'sync.batchOk';
  static const defaultBatch = 500;
  static const minBatch = 50;
  static const maxBatch = 500;
  static const _maxRounds = 5;
  static const _maxTotalRounds = 100;

  /// Returns true when anything was pulled into the local database.
  Future<bool> run({bool pushLocal = true}) async {
    var pulledAny = false;
    final batch = await _currentBatch();
    var stalledRounds = 0;
    try {
      for (var round = 0; round < _maxTotalRounds; round++) {
        final pending =
            pushLocal ? await _store.pendingChanges() : const <SyncChange>[];
        _onPendingChanged?.call(countDisplayablePending(pending));
        final push = pending.take(batch).toList();
        final ownKeys = push.map((c) => c.key).toSet();

        var cursor = await _cursor();
        var first = true;
        while (true) {
          final res = await _transport({
            'since': cursor,
            'changes': first && pushLocal
                ? push.map((c) => c.toJson()).toList()
                : const [],
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
          final v = (res?['version'] as num?)?.toInt() ?? cursor;
          if (v > cursor) cursor = v;
          await _store.applyPage(records, cursor);
          if (records.any((r) => !ownKeys.contains(r.key))) pulledAny = true;
          if (res?['hasMore'] != true) break;
        }

        await _store.applyWaiting();
        if (!pushLocal) break;
        final left = await _store.pendingChanges();
        _onPendingChanged?.call(countDisplayablePending(left));
        if (left.isEmpty) break;
        if (left.length >= pending.length) {
          stalledRounds++;
          if (stalledRounds >= _maxRounds) break;
        } else {
          stalledRounds = 0;
        }
      }
      await _recordSuccess(batch);
      await _setSetting(lastSyncKey, DateTime.now().toIso8601String());
      return pulledAny;
    } on ApiException catch (e) {
      if ((e.status == 0 && e.code == 'timeout') || e.status == 413) {
        await _recordTimeout(batch);
      }
      rethrow;
    } on TimeoutException {
      await _recordTimeout(batch);
      rethrow;
    }
  }

  Future<int> _currentBatch() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(batchKey)))
        .getSingleOrNull();
    final v = int.tryParse(row?.value ?? '');
    if (v == null) return defaultBatch;
    return v.clamp(minBatch, maxBatch);
  }

  Future<void> _recordTimeout(int currentBatch) async {
    final next = math.max(minBatch, currentBatch ~/ 2);
    await _setSetting(batchKey, '$next');
    await _setSetting(batchOkKey, '0');
  }

  Future<void> _recordSuccess(int currentBatch) async {
    if (currentBatch >= maxBatch) return;
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(batchOkKey)))
        .getSingleOrNull();
    final okCount = (int.tryParse(row?.value ?? '') ?? 0) + 1;
    if (okCount >= 3) {
      final next = math.min(maxBatch, currentBatch * 2);
      await _setSetting(batchKey, '$next');
      await _setSetting(batchOkKey, '0');
    } else {
      await _setSetting(batchOkKey, '$okCount');
    }
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

const syncRetryDelays = [
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(seconds: 120),
  Duration(seconds: 240),
  Duration(seconds: 480),
];
const syncRetryMaxDelay = Duration(seconds: 600);
const syncRegularInterval = Duration(minutes: 5);

/// Runs a sync when the parent signs in, when the app comes back to the
/// front, every 5 minutes while it is open, on reconnect, and on demand.
/// Signed out: does nothing.
class SyncController extends Notifier<SyncStatus> {
  Timer? _timer;
  Timer? _retryTimer;
  Timer? _reconnectTimer;
  Timer? _requestTimer;
  StreamSubscription<void>? _maybeBackSub;
  AppLifecycleListener? _lifecycle;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;
  int _retryStep = 0;

  int get retryStep => _retryStep;

  @override
  SyncStatus build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      stop();
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
        stop();
        if (!_disposed) state = const SyncStatus();
      }
    }, fireImmediately: true);
    return const SyncStatus();
  }

  void _start() {
    _scheduleRegular();
    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(syncNow()),
      onHide: _onBackground,
      onPause: _onBackground,
    );
    _maybeBackSub?.cancel();
    _maybeBackSub =
        ref.read(networkStatusProvider.notifier).maybeBack.listen((_) {
      _onMaybeBack();
    });
  }

  void _onBackground() {
    _timer?.cancel();
    _timer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _requestTimer?.cancel();
    _requestTimer = null;
  }

  void stop() {
    _again = false;
    _onBackground();
    _maybeBackSub?.cancel();
    _maybeBackSub = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _retryStep = 0;
  }

  void _onMaybeBack() {
    if (_disposed) return;
    final s = ref.read(sessionProvider).valueOrNull;
    if (s == null || !s.linked) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      syncNow();
    });
  }

  /// Non-blocking trigger that coalesces requests in a 3-second window.
  void requestSync() {
    if (_disposed) return;
    final s = ref.read(sessionProvider).valueOrNull;
    if (s == null || !s.linked) return;
    unawaited(ref.read(syncHealthProvider.notifier).refreshPending());
    _requestTimer ??= Timer(const Duration(seconds: 3), () {
      _requestTimer = null;
      syncNow();
    });
  }

  void _scheduleRegular() {
    _timer?.cancel();
    _timer = Timer(syncRegularInterval, () => syncNow());
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delay = _retryStep < syncRetryDelays.length
        ? syncRetryDelays[_retryStep]
        : syncRetryMaxDelay;
    _retryStep++;
    _retryTimer = Timer(delay, () => syncNow());
  }

  Future<void> syncNow() {
    if (_disposed) return Future.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    final future = _runLoop();
    _running = future;
    return future;
  }

  Future<void> _runLoop() async {
    try {
      do {
        _again = false;
        await _sync();
        if (_disposed) return;
      } while (_again);
    } finally {
      _running = null;
    }
  }

  Future<void> _sync() async {
    if (_disposed) return;
    final s = ref.read(sessionProvider).valueOrNull;
    if (s == null || !s.linked) return;

    _timer?.cancel();
    _timer = null;
    _retryTimer?.cancel();
    _retryTimer = null;

    state = SyncStatus(running: true, lastAt: state.lastAt);
    final health = ref.read(syncHealthProvider.notifier);
    health.setRunning(true);
    var lastPending = ref.read(syncHealthProvider).pending;
    final session = ref.read(sessionProvider.notifier);
    final api = ref.read(apiClientProvider);
    final engine = SyncEngine(
      ref.read(databaseProvider),
      (body) => session.authorized(
          (token) => api.post('/api/v1/sync', body, accessToken: token)),
      onPendingChanged: (count) {
        lastPending = count;
        if (!_disposed) health.setPending(count);
      },
    );
    try {
      final pulled = await engine.run();
      if (_disposed) return;
      final now = ref.read(syncHealthClockProvider)();
      state = SyncStatus(lastAt: now);
      health.recordSyncSuccess(pending: lastPending, at: now);
      if (pulled) refreshAfterSync(ref);
      _retryStep = 0;
      _scheduleRegular();
    } on ApiException catch (e) {
      if (_disposed) return;
      health.recordSyncFailure(pending: lastPending);
      if (e.status == 409 && e.code == 'link_required') {
        await ref.read(sessionProvider.notifier).markUnlinked();
        ref.read(linkControllerProvider.notifier).resumeIfPending();
        state = SyncStatus(lastAt: state.lastAt, failed: true);
        return;
      }
      state = SyncStatus(lastAt: state.lastAt, failed: true);
      _scheduleRetry();
    } catch (_) {
      if (_disposed) return;
      health.recordSyncFailure(pending: lastPending);
      // Offline or server down: try again on the next trigger.
      state = SyncStatus(lastAt: state.lastAt, failed: true);
      _scheduleRetry();
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncStatus>(SyncController.new);
