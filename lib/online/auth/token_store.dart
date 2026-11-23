import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A signed-in family session as kept on the device.
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.familyId,
    required this.provider,
    this.email,
    this.linked = false,
  });

  final String accessToken;
  final String refreshToken;
  final String familyId;

  /// 'google' or 'apple'.
  final String provider;
  final String? email;
  final bool linked;

  StoredSession copyWith({
    String? accessToken,
    String? refreshToken,
    bool? linked,
  }) =>
      StoredSession(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        familyId: familyId,
        provider: provider,
        email: email,
        linked: linked ?? this.linked,
      );

  Map<String, Object?> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'familyId': familyId,
        'provider': provider,
        'email': email,
        'linked': linked,
      };

  static StoredSession? fromJson(Object? json) {
    if (json is! Map) return null;
    final a = json['accessToken'], r = json['refreshToken'];
    final f = json['familyId'], p = json['provider'];
    if (a is! String || r is! String || f is! String || p is! String) return null;
    return StoredSession(
      accessToken: a,
      refreshToken: r,
      familyId: f,
      provider: p,
      email: json['email'] as String?,
      linked: json['linked'] as bool? ?? false,
    );
  }
}

/// Where the session tokens live: the OS keychain / keystore in the app,
/// memory in tests.
abstract class TokenStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _key = 'funedu.session';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      return raw == null ? null : StoredSession.fromJson(jsonDecode(raw));
    } catch (_) {
      // Unreadable keystore (e.g. restored backup): behave as signed out.
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class MemoryTokenStore implements TokenStore {
  StoredSession? session;

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<void> write(StoredSession s) async => session = s;

  @override
  Future<void> clear() async => session = null;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
