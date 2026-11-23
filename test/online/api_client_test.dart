import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/online_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('request exceeding timeout throws ApiException(0, timeout) and reports error', () async {
    bool? lastNetResult;
    final mockClient = MockClient((req) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return http.Response('{}', 200);
    });

    final client = ApiClient(
      const OnlineConfig(apiUrl: 'https://api.test'),
      mockClient,
      onNetResult: (ok) => lastNetResult = ok,
      timeout: const Duration(milliseconds: 20),
    );

    dynamic error;
    try {
      await client.get('/test');
    } catch (e) {
      error = e;
    }

    expect(error, isA<ApiException>());
    final apiEx = error as ApiException;
    expect(apiEx.status, equals(0));
    expect(apiEx.code, equals('timeout'));
    expect(lastNetResult, isFalse);
  });

  test('a body that stalls after the headers also times out', () async {
    bool? lastNetResult;
    // Headers arrive at once, then the body never finishes (weak network).
    final stalled = MockClient.streaming((req, body) async =>
        http.StreamedResponse(StreamController<List<int>>().stream, 200));
    final client = ApiClient(
      const OnlineConfig(apiUrl: 'https://api.test'),
      stalled,
      onNetResult: (ok) => lastNetResult = ok,
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
      client.post('/api/v1/sync', const {}),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 0)
          .having((e) => e.code, 'code', 'timeout')),
    );
    expect(lastNetResult, isFalse);
  });

  test('socket exception throws ApiException(0, network) and reports error', () async {
    bool? lastNetResult;
    final mockClient = MockClient((req) async {
      throw const SocketException('Connection refused');
    });

    final client = ApiClient(
      const OnlineConfig(apiUrl: 'https://api.test'),
      mockClient,
      onNetResult: (ok) => lastNetResult = ok,
    );

    expect(
      () => client.get('/test'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 0)
            .having((e) => e.code, 'code', 'network'),
      ),
    );
    // Give async event loop a tick
    await Future<void>.delayed(Duration.zero);
    expect(lastNetResult, isFalse);
  });

  test('200 response reports ok true', () async {
    bool? lastNetResult;
    final mockClient = MockClient((req) async {
      return http.Response('{"ok": true}', 200);
    });

    final client = ApiClient(
      const OnlineConfig(apiUrl: 'https://api.test'),
      mockClient,
      onNetResult: (ok) => lastNetResult = ok,
    );

    final res = await client.get('/test');
    expect(res?['ok'], isTrue);
    expect(lastNetResult, isTrue);
  });

  test('4xx response reports ok true because server is reachable', () async {
    bool? lastNetResult;
    final mockClient = MockClient((req) async {
      return http.Response('{"error": "bad_request"}', 400);
    });

    final client = ApiClient(
      const OnlineConfig(apiUrl: 'https://api.test'),
      mockClient,
      onNetResult: (ok) => lastNetResult = ok,
    );

    expect(
      () => client.get('/test'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(lastNetResult, isTrue);
  });

  test('getList decodes JSON array responses', () async {
    final mockClient = MockClient((req) async {
      expect(req.method, 'GET');
      return http.Response('[{"familyId":"f1","online":true}]', 200);
    });

    final client = ApiClient(
      const OnlineConfig(apiUrl: 'https://api.test'),
      mockClient,
    );

    final res = await client.getList('/api/v1/friends');
    expect(res, hasLength(1));
    expect((res!.first as Map)['familyId'], 'f1');
  });
}
