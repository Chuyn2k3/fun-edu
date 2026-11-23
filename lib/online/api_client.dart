import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'net/network_status.dart';
import 'online_config.dart';

/// A non-2xx answer from the server ([status] 0 = no connection).
class ApiException implements Exception {
  const ApiException(this.status, [this.code]);

  final int status;
  final String? code;

  bool get unauthorized => status == 401;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Thin JSON client for the FunEdu server.
class ApiClient {
  ApiClient(
    this._config,
    this._http, {
    void Function(bool ok)? onNetResult,
    Duration timeout = const Duration(seconds: 15),
  })  : _onNetResult = onNetResult,
        _timeout = timeout;

  final OnlineConfig _config;
  final http.Client _http;
  final void Function(bool ok)? _onNetResult;
  final Duration _timeout;

  Future<Map<String, Object?>?> post(
    String path,
    Map<String, Object?> body, {
    String? accessToken,
  }) =>
      _send('POST', path, body: body, accessToken: accessToken);

  Future<Map<String, Object?>?> get(String path, {String? accessToken}) =>
      _send('GET', path, accessToken: accessToken);

  Future<Map<String, Object?>?> delete(String path, {String? accessToken}) =>
      _send('DELETE', path, accessToken: accessToken);

  Future<Map<String, Object?>?> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    if (!_config.enabled) throw const ApiException(0, 'offline_build');
    final req = http.Request(method, _config.uri(path));
    req.headers['Accept'] = 'application/json';
    if (accessToken != null) req.headers['Authorization'] = 'Bearer $accessToken';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(_timeout));
    } on TimeoutException {
      _onNetResult?.call(false);
      throw const ApiException(0, 'timeout');
    } catch (_) {
      _onNetResult?.call(false);
      throw const ApiException(0, 'network');
    }
    _onNetResult?.call(true);

    Map<String, Object?>? json;
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, Object?>) json = decoded;
      } catch (_) {}
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, json?['error'] as String?);
    }
    return json;
  }
}

/// Created on first use only: an offline build never opens a connection.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(onlineConfigProvider),
    ref.watch(httpClientProvider),
    onNetResult: (ok) {
      final net = ref.read(networkStatusProvider.notifier);
      if (ok) {
        net.reportOk();
      } else {
        net.reportNetworkError();
      }
    },
  ),
);
