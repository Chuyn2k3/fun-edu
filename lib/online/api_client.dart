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

  Future<List<Object?>?> getList(String path, {String? accessToken}) async {
    final decoded = await _sendRaw('GET', path, accessToken: accessToken);
    if (decoded is List<Object?>) return decoded;
    return null;
  }

  Future<Map<String, Object?>?> delete(String path, {String? accessToken}) =>
      _send('DELETE', path, accessToken: accessToken);

  Future<Map<String, Object?>?> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    final decoded = await _sendRaw(
      method,
      path,
      body: body,
      accessToken: accessToken,
    );
    if (decoded is Map<String, Object?>) return decoded;
    return null;
  }

  Future<Object?> _sendRaw(
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
      // One deadline for the whole exchange: a weak network can deliver the
      // headers and then stall in the middle of a 1000-record page.
      res = await _http
          .send(req)
          .then(http.Response.fromStream)
          .timeout(_timeout);
    } on TimeoutException {
      _onNetResult?.call(false);
      throw const ApiException(0, 'timeout');
    } catch (_) {
      _onNetResult?.call(false);
      throw const ApiException(0, 'network');
    }
    _onNetResult?.call(true);

    Object? decoded;
    if (res.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {}
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final errMap = decoded is Map<String, Object?> ? decoded : null;
      throw ApiException(res.statusCode, errMap?['error'] as String?);
    }
    return decoded;
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
