import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../online_config.dart';

/// Gets an id token from Google or Apple; null when the parent cancels.
abstract class IdentityProviders {
  bool get appleAvailable;
  Future<String?> googleIdToken();
  Future<String?> appleIdToken();
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
    final account = await _google.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  @override
  Future<String?> appleIdToken() async {
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
      return cred.identityToken;
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
