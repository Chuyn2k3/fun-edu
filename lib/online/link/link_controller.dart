import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../profile/kid_refresh.dart';
import '../../profile/kid_repository.dart';
import '../../ui/feedback/feedback.dart';
import '../api_client.dart';
import '../auth/session_controller.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_store.dart';
import 'account_summary.dart';

sealed class LinkState {
  const LinkState();
}

class LinkIdle extends LinkState {
  const LinkIdle();
}

class LinkNeedsWarning extends LinkState {
  const LinkNeedsWarning(this.account, this.local);
  final AccountSummary account;
  final List<KidSummary> local;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkNeedsWarning &&
          runtimeType == other.runtimeType &&
          account == other.account &&
          _listEquals(local, other.local);

  @override
  int get hashCode => Object.hash(account, Object.hashAll(local));
}

class LinkRestoring extends LinkState {
  const LinkRestoring();
}

class LinkFailed extends LinkState {
  const LinkFailed(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkFailed &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

class LinkRestoreFailed extends LinkFailed {
  const LinkRestoreFailed(super.message);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class LinkController extends Notifier<LinkState> {
  @override
  LinkState build() {
    return const LinkIdle();
  }

  ApiClient get _api => ref.read(apiClientProvider);
  AppDatabase get _db => ref.read(databaseProvider);
  SessionController get _session => ref.read(sessionProvider.notifier);

  /// Called after a successful sign-in to decide whether to upload guest data,
  /// restore an existing family, or display a replace-data warning.
  Future<void> afterSignIn(SignInResult r) async {
    final s = ref.read(sessionProvider).valueOrNull;
    if (s == null) return;

    if (r.linked) {
      final localKids = await KidRepository(_db).kids();
      final owner = await KidRepository(_db).setting(dataOwnerKey);

      if (owner != s.familyId) {
        if (localKids.isNotEmpty && r.account.hasData) {
          final local = await localSummary(SyncStore(_db));
          state = LinkNeedsWarning(r.account, local);
          return;
        }
        if (localKids.isEmpty) {
          await KidRepository(_db).setSetting(restorePendingKey, restoreStagePull);
          ref.invalidate(restorePendingSettingProvider);
          await _ensureLinkedThenPull(restoreStagePull);
          return;
        }
      }

      await _session.markLinked();
      await KidRepository(_db).setSetting(dataOwnerKey, s.familyId);
      ref.read(syncControllerProvider.notifier).syncNow();
      state = const LinkIdle();
      return;
    }

    final localKids = await KidRepository(_db).kids();
    if (localKids.isEmpty) {
      // Empty device: fresh link + restore
      await KidRepository(_db).setSetting(restorePendingKey, restoreStageFresh);
      ref.invalidate(restorePendingSettingProvider);
      await _ensureLinkedThenPull(restoreStageFresh);
      return;
    }

    // Device has local data
    if (r.account.hasData) {
      final local = await localSummary(SyncStore(_db));
      state = LinkNeedsWarning(r.account, local);
      return;
    }

    // Device has local data and account is empty: try automatic upload
    try {
      await _session.authorized((token) => _api.post(
            '/api/v1/sync/link',
            {'mode': 'upload'},
            accessToken: token,
          ));
      await _session.markLinked();
      await KidRepository(_db).setSetting(dataOwnerKey, s.familyId);
      ref.read(syncControllerProvider.notifier).syncNow();
      state = const LinkIdle();
    } on ApiException catch (e) {
      if (e.status == 409) {
        // Account has data (e.g. concurrent upload) -> warning dialog
        AccountSummary acc = r.account;
        try {
          final res = await _session.authorized((token) =>
              _api.get('/api/v1/sync/link', accessToken: token));
          if (res?['account'] != null) {
            acc = AccountSummary.fromJson(res!['account'] as Map<String, dynamic>);
          }
        } catch (_) {}
        final local = await localSummary(SyncStore(_db));
        state = LinkNeedsWarning(acc, local);
      } else {
        state = LinkFailed(e.toString());
      }
    } catch (e) {
      state = LinkFailed(e.toString());
    }
  }

  /// Parent confirmed replacing local guest data with account data.
  Future<void> confirmReplace() async {
    final s = ref.read(sessionProvider).valueOrNull;
    if (s == null) return;

    await KidRepository(_db).setSetting(restorePendingKey, restoreStageReplace);
    ref.invalidate(restorePendingSettingProvider);
    await _ensureLinkedThenPull(restoreStageReplace);
  }

  /// Parent cancelled the replace warning: sign out and preserve guest data.
  Future<void> cancelReplace() async {
    await _session.signOut();
    state = const LinkIdle();
  }

  /// Resumes any pending restore or re-runs unlinked device link decision.
  Future<void> resumeIfPending() async {
    final pending = await KidRepository(_db).setting(restorePendingKey);
    if (pending != null) {
      final stage = (pending == restoreStageFresh ||
              pending == restoreStageReplace ||
              pending == restoreStagePull)
          ? pending
          : restoreStagePull;
      await _ensureLinkedThenPull(stage);
      return;
    }

    final s = ref.read(sessionProvider).valueOrNull;
    if (s != null && !s.linked) {
      try {
        final res = await _session.authorized(
            (token) => _api.get('/api/v1/sync/link', accessToken: token));
        final linked = res?['linked'] as bool? ?? false;
        final accMap = res?['account'] as Map<String, dynamic>?;
        final acc = accMap != null
            ? AccountSummary.fromJson(accMap)
            : const AccountSummary(hasData: false);
        await afterSignIn(SignInResult(linked: linked, account: acc));
      } catch (_) {}
    }
  }

  /// Retries a failed family restore.
  Future<void> retryRestore() async {
    final pending = await KidRepository(_db).setting(restorePendingKey);
    final stage = (pending == restoreStageFresh ||
            pending == restoreStageReplace ||
            pending == restoreStagePull)
        ? pending!
        : restoreStagePull;
    await _ensureLinkedThenPull(stage);
  }

  Future<void> _ensureLinkedThenPull(String stage) async {
    state = const LinkRestoring();
    var currentStage = stage;
    try {
      final s = ref.read(sessionProvider).valueOrNull ??
          await ref.read(sessionProvider.future);
      if (s == null) {
        throw const ApiException(401, 'signed_out');
      }

      if (currentStage == restoreStageFresh) {
        await _session.authorized((token) => _api.post(
              '/api/v1/sync/link',
              {'mode': 'fresh'},
              accessToken: token,
            ));
      } else if (currentStage == restoreStageReplace) {
        await _session.authorized((token) => _api.post(
              '/api/v1/sync/link',
              {'mode': 'replace_local'},
              accessToken: token,
            ));
        await KidRepository(_db).wipeKidData();
        currentStage = restoreStagePull;
        await KidRepository(_db).setSetting(restorePendingKey, restoreStagePull);
        ref.invalidate(restorePendingSettingProvider);
      }

      await _session.markLinked();
      await KidRepository(_db).setSetting(dataOwnerKey, s.familyId);

      final engine = SyncEngine(
        _db,
        (body) => _session.authorized(
            (token) => _api.post('/api/v1/sync', body, accessToken: token)),
      );
      await engine.run(pushLocal: false);

      final kids = await KidRepository(_db).kids();
      if (kids.isNotEmpty) {
        await KidRepository(_db).setCurrentKid(kids.first.id);
      }
      invalidateKidData(ref.invalidate);

      await KidRepository(_db).removeSetting(restorePendingKey);
      ref.invalidate(restorePendingSettingProvider);
      state = const LinkIdle();
    } on ApiException catch (e) {
      if (e.unauthorized) {
        if (currentStage == restoreStageFresh) {
          await KidRepository(_db).setSetting(
            consentAtKey,
            DateTime.now().toIso8601String(),
          );
          ref.invalidate(consentAtProvider);
          await KidRepository(_db).removeSetting(restorePendingKey);
          ref.invalidate(restorePendingSettingProvider);
          state = const LinkIdle();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showAppToast(
              null,
              'Phiên đăng nhập đã hết, ba mẹ đăng nhập lại nhé',
              kind: AppToastKind.warning,
            );
          });
          return;
        }
        state = const LinkRestoreFailed('signed_out');
        ref.invalidate(restorePendingSettingProvider);
        return;
      }
      state = LinkRestoreFailed(e.toString());
      ref.invalidate(restorePendingSettingProvider);
    } catch (e) {
      state = LinkRestoreFailed(e.toString());
      ref.invalidate(restorePendingSettingProvider);
    }
  }
}

final linkControllerProvider =
    NotifierProvider<LinkController, LinkState>(LinkController.new);

final restorePendingSettingProvider = FutureProvider<bool>((ref) async {
  final v = await ref.watch(kidRepositoryProvider).setting(restorePendingKey);
  return v != null;
});

final restoringProvider = Provider<bool>((ref) {
  final linkState = ref.watch(linkControllerProvider);
  if (linkState is LinkRestoring || linkState is LinkRestoreFailed) {
    return true;
  }
  final pendingSetting =
      ref.watch(restorePendingSettingProvider).valueOrNull ?? false;
  return pendingSetting;
});
