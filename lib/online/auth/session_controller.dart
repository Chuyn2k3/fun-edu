import 'package:drift/drift.dart' show StringExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../api_client.dart';
import 'identity_providers.dart';
import 'token_store.dart';

/// Why a sign-in did not finish.
enum SignInFailure { cancelled, rejected, network }

class SignInException implements Exception {
  const SignInException(this.failure);
  final SignInFailure failure;
}

/// The family session: null while signed out. Only a parent, inside Góc ba
/// mẹ, starts one; until then nothing in the app touches the network.
class SessionController extends AsyncNotifier<StoredSession?> {
  TokenStore get _store => ref.read(tokenStoreProvider);
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<StoredSession?> build() => _store.read();

  /// [provider] is 'google' or 'apple'.
  Future<void> signIn(String provider) async {
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
    } catch (_) {
      throw const SignInException(SignInFailure.rejected);
    }
    if (idToken == null) throw const SignInException(SignInFailure.cancelled);

    Map<String, Object?>? res;
    try {
      res = await _api.post('/api/v1/auth/$provider', {
        'idToken': idToken,
        // Lets the server revoke Apple's access when the account is deleted.
        if (appleCode != null) 'authorizationCode': appleCode,
      });
    } on ApiException catch (e) {
      throw SignInException(
          e.status == 0 ? SignInFailure.network : SignInFailure.rejected);
    }
    final access = res?['accessToken'] as String?;
    final refresh = res?['refreshToken'] as String?;
    final family = res?['familyId'] as String?;
    if (access == null || refresh == null || family == null) {
      throw const SignInException(SignInFailure.rejected);
    }
    String? email;
    try {
      email = (await _api.get('/api/v1/me', accessToken: access))?['email'] as String?;
    } on ApiException catch (_) {}
    final session = StoredSession(
      accessToken: access,
      refreshToken: refresh,
      familyId: family,
      provider: provider,
      email: email,
    );
    // Another family's sync history must not leak into this one.
    await _resetSyncState();
    await _store.write(session);
    state = AsyncData(session);
  }

  /// Runs [call] with a valid access token, refreshing it once on 401.
  /// A refused refresh ends the session.
  Future<T> authorized<T>(Future<T> Function(String accessToken) call) async {
    final s = state.valueOrNull ?? await future;
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
