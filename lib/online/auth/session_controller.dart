import 'package:drift/drift.dart' show StringExpressionOperators;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../api_client.dart';
import '../device_id.dart';
import '../link/account_summary.dart';
import '../online_config.dart';
import 'identity_providers.dart';
import 'token_store.dart';

/// Result of signing in: includes whether the device is linked on the server
/// and a high-level summary of the account's data.
class SignInResult {
  const SignInResult({
    required this.linked,
    required this.account,
  });

  final bool linked;
  final AccountSummary account;
}

/// Why a sign-in did not finish.
enum SignInFailure {
  /// The parent closed the Google / Apple sheet.
  cancelled,

  /// Google / Apple refused or the build is not set up for it (client id,
  /// SHA-1, Play services...). [SignInException.detail] has the code.
  setup,

  /// The FunEdu server could not be reached.
  network,

  /// The FunEdu server refused the id token (usually its client id list).
  rejected,
}

class SignInException implements Exception {
  const SignInException(this.failure, [this.detail]);
  final SignInFailure failure;

  /// Technical reason, shown to developers in debug builds.
  final String? detail;

  @override
  String toString() => 'SignInException($failure, $detail)';
}

/// The family session: null while signed out. Only a parent, inside Góc ba
/// mẹ, starts one; until then nothing in the app touches the network.
class SessionController extends AsyncNotifier<StoredSession?> {
  TokenStore get _store => ref.read(tokenStoreProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<StoredSession?> build() => _store.read();

  /// [provider] is 'google' or 'apple'.
  Future<SignInResult> signIn(String provider) async {
    final ids = ref.read(identityProvidersProvider);
    String? idToken;
    String? appleCode;
    try {
      if (provider == 'apple') {
        final apple = await ids.appleSignIn();
        idToken = apple?.idToken;
        appleCode = apple?.authorizationCode;
      } else {
        idToken = await ids.googleIdToken();
      }
    } on PlatformException catch (e) {
      // e.g. sign_in_failed + "ApiException: 10" = package name / SHA-1 not
      // registered for this app in Google Cloud; 12501 = the sheet closed.
      if ('${e.code} ${e.message}'.contains('12501')) {
        throw const SignInException(SignInFailure.cancelled);
      }
      throw SignInException(SignInFailure.setup, '${e.code}: ${e.message}');
    } on MissingIdTokenException catch (e) {
      throw SignInException(SignInFailure.setup, e.detail);
    } catch (e) {
      throw SignInException(SignInFailure.setup, '$e');
    }
    if (idToken == null) throw const SignInException(SignInFailure.cancelled);

    final deviceId = await ensureDeviceId(ref.read(databaseProvider));

    Map<String, Object?>? res;
    try {
      res = await _api.post('/api/v1/auth/$provider', {
        'idToken': idToken,
        'deviceId': deviceId,
        // Lets the server revoke Apple's access when the account is deleted.
        if (appleCode != null) 'authorizationCode': appleCode,
      });
    } on ApiException catch (e) {
      throw e.status == 0
          ? SignInException(SignInFailure.network,
              'không tới được ${ref.read(onlineConfigProvider).apiUrl} (${e.code})')
          : SignInException(SignInFailure.rejected, 'máy chủ trả ${e.status} ${e.code ?? ''}');
    }
    final access = res?['accessToken'] as String?;
    final refresh = res?['refreshToken'] as String?;
    final family = res?['familyId'] as String?;
    if (access == null || refresh == null || family == null) {
      throw const SignInException(SignInFailure.rejected, 'máy chủ trả thiếu token');
    }
    String? email;
    try {
      email = (await _api.get('/api/v1/me', accessToken: access))?['email'] as String?;
    } on ApiException catch (_) {}

    final deviceMap = res?['device'] as Map<String, dynamic>?;
    final linked = deviceMap?['linked'] as bool? ?? false;
    final accountMap = res?['account'] as Map<String, dynamic>?;
    final account = accountMap != null
        ? AccountSummary.fromJson(accountMap)
        : const AccountSummary(hasData: false);

    final session = StoredSession(
      accessToken: access,
      refreshToken: refresh,
      familyId: family,
      provider: provider,
      email: email,
      linked: linked,
    );
    // Another family's sync history must not leak into this one.
    await _resetSyncState();
    await _store.write(session);
    state = AsyncData(session);
    return SignInResult(linked: linked, account: account);
  }

  /// Marks this device as linked to the family account in local session state.
  Future<void> markLinked() async {
    final s = state.valueOrNull;
    if (s == null) return;
    final updated = s.copyWith(linked: true);
    await _store.write(updated);
    state = AsyncData(updated);
  }

  /// Marks this device as unlinked in local session state.
  Future<void> markUnlinked() async {
    final s = state.valueOrNull;
    if (s == null) return;
    final updated = s.copyWith(linked: false);
    await _store.write(updated);
    state = AsyncData(updated);
  }

  /// Runs [call] with a valid access token, refreshing it once on 401.
  /// A refused refresh ends the session.
  Future<T> authorized<T>(Future<T> Function(String accessToken) call) async {
    final s = state.valueOrNull ?? await _store.read();
    if (s == null) throw const ApiException(401, 'signed_out');
    try {
      return await call(s.accessToken);
    } on ApiException catch (e) {
      if (!e.unauthorized) rethrow;
    }
    final renewed = await _refresh(s);
    return call(renewed.accessToken);
  }

  Future<StoredSession> _refresh(StoredSession s) async {
    try {
      final res = await _api.post('/api/v1/auth/refresh', {'refreshToken': s.refreshToken});
      final renewed = s.copyWith(
        accessToken: res?['accessToken'] as String?,
        refreshToken: res?['refreshToken'] as String?,
      );
      await _store.write(renewed);
      state = AsyncData(renewed);
      return renewed;
    } on ApiException catch (e) {
      if (e.unauthorized) await _endLocally();
      rethrow;
    }
  }

  /// Signs out on this device; the data on it stays.
  Future<void> signOut() async {
    final s = state.valueOrNull;
    if (s != null) {
      try {
        await _api.post('/api/v1/auth/logout', {'refreshToken': s.refreshToken});
      } on ApiException catch (_) {
        // Offline: the refresh token simply expires on the server.
      }
    }
    await _endLocally();
  }

  /// Deletes the family's online account and all its online data. The data
  /// on this device stays.
  Future<void> deleteAccount() async {
    await authorized((t) => _api.delete('/api/v1/account', accessToken: t));
    await _endLocally();
  }

  Future<void> _endLocally() async {
    await ref.read(identityProvidersProvider).signOut();
    await _store.clear();
    await _resetSyncState();
    state = const AsyncData(null);
  }

  Future<void> _resetSyncState() async {
    final db = ref.read(databaseProvider);
    await db.delete(db.syncedRecords).go();
    await (db.delete(db.appSettings)..where((t) => t.key.like('sync.%'))).go();
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, StoredSession?>(SessionController.new);
