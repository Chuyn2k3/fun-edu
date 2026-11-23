import 'dart:convert';

import 'package:funedu/online/auth/identity_providers.dart';
import 'package:http/http.dart' as http;

class FakeIds implements IdentityProviders {
  String? google = 'google-id-token';
  Object? googleError;
  String? apple = 'apple-id-token';
  String? appleCode = 'apple-code';
  bool apple_ = true;
  int signOuts = 0;

  @override
  bool get appleAvailable => apple_;
  @override
  Future<String?> googleIdToken() async {
    if (googleError != null) throw googleError!;
    return google;
  }
  @override
  Future<AppleSignIn?> appleSignIn() async =>
      apple == null ? null : (idToken: apple!, authorizationCode: appleCode);
  @override
  Future<void> signOut() async => signOuts++;
}

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// Answers like the FunEdu server for one family.
http.Response fakeServer(http.Request req) => switch (req.url.path) {
      '/api/v1/auth/google' || '/api/v1/auth/apple' => jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'expiresIn': 900,
          'familyId': 'fam-1',
          'device': {'linked': true},
          'account': {'hasData': false, 'kids': []},
        }),
      '/api/v1/sync/link' => jsonResponse({
          'linked': true,
          'account': {'hasData': false, 'kids': []},
        }),
      '/api/v1/me' => jsonResponse({'familyId': 'fam-1', 'provider': 'google', 'email': 'me@x.vn'}),
      '/api/v1/auth/refresh' =>
        jsonResponse({'accessToken': 'a2', 'refreshToken': 'r2', 'familyId': 'fam-1'}),
      '/api/v1/auth/logout' => http.Response('', 204),
      '/api/v1/account' => http.Response('', 204),
      '/api/v1/sync' => jsonResponse({'version': 0, 'records': [], 'conflicts': [], 'hasMore': false}),
      _ => http.Response('', 404),
    };
