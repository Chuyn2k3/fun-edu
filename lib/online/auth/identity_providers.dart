import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../online_config.dart';

/// What Sign in with Apple gives: the id token, and a one-time code the
/// server exchanges so that deleting the account can revoke Apple's access.
typedef AppleSignIn = ({String idToken, String? authorizationCode});

/// The platform signed the parent in but gave no id token: the build lacks
/// its client id (GOOGLE_SERVER_CLIENT_ID on Android, GIDClientID on iOS).
class MissingIdTokenException implements Exception {
  const MissingIdTokenException(this.detail);
  final String detail;
  @override
  String toString() => detail;
}

/// Gets an id token from Google or Apple; null when the parent cancels.
abstract class IdentityProviders {
  bool get appleAvailable;
  Future<String?> googleIdToken();
  Future<AppleSignIn?> appleSignIn();
  Future<void> signOut();
}

class PlatformIdentityProviders implements IdentityProviders {
  PlatformIdentityProviders(this._config);

  final OnlineConfig _config;

  late final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId:
        _config.googleServerClientId.isEmpty ? null : _config.googleServerClientId,
  );

  /// Native on iOS; on Android through Apple's web page, which needs the
  /// Services ID and the server's callback.
  @override
  bool get appleAvailable =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      (defaultTargetPlatform == TargetPlatform.android &&
          _config.appleServiceId.isNotEmpty);

  @override
  Future<String?> googleIdToken() async {
    // Sign out locally first so the Google Account Picker sheet is always shown,
    // allowing the parent to pick or switch accounts.
    try {
      await _google.signOut();
    } catch (_) {}
    final account = await _google.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final token = auth.idToken;
    if (token == null) {
      // Not a cancel: Google gives no id token without the web client id.
      throw MissingIdTokenException(_config.googleServerClientId.isEmpty
          ? 'GOOGLE_SERVER_CLIENT_ID chưa được truyền khi build'
          : 'Google không trả id token');
    }
    return token;
  }

  @override
  Future<AppleSignIn?> appleSignIn() async {
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
        webAuthenticationOptions: defaultTargetPlatform == TargetPlatform.android
            ? WebAuthenticationOptions(
                clientId: _config.appleServiceId,
                redirectUri: _config.uri('/api/v1/auth/apple/callback'),
              )
            : null,
      );
      final token = cred.identityToken;
      if (token == null) return null;
      return (idToken: token, authorizationCode: cred.authorizationCode);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}

final identityProvidersProvider = Provider<IdentityProviders>(
  (ref) => PlatformIdentityProviders(ref.watch(onlineConfigProvider)),
);
