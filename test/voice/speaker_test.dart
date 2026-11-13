import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/voice/speaker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <String>[];

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    calls.clear();
  });

  void mock(Future<Object?> Function(MethodCall) h) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (c) {
      calls.add(c.method);
      return h(c);
    });
  }

  test('speak does not throw when setLanguage throws, and stays silent',
      () async {
    mock((c) async {
      if (c.method == 'setLanguage') throw PlatformException(code: 'x');
      return 1;
    });
    final s = TtsSpeaker();
    await s.speak('xin chào');
    await s.stop();
    expect(calls, isNot(contains('speak')));
  });

  test('speak does not throw when the plugin is missing', () async {
    final s = TtsSpeaker();
    await s.speak('xin chào');
    await s.stop();
  });

  test('speaks Vietnamese at the configured rate and pitch', () async {
    final args = <String, Object?>{};
    mock((c) async {
      args[c.method] = c.arguments;
      return 1;
    });
    final s = TtsSpeaker();
    await s.speak('xin chào');
    expect(args['setLanguage'], 'vi-VN');
    expect(args['setSpeechRate'], 0.45);
    expect(args['setPitch'], 1.1);
    expect(args['speak'], 'xin chào');
    expect(calls.indexOf('stop'), lessThan(calls.indexOf('speak')));
  });

  test('no Vietnamese voice (setLanguage returns 0) makes it a no-op',
      () async {
    mock((c) async => c.method == 'setLanguage' ? 0 : 1);
    final s = TtsSpeaker();
    await s.speak('xin chào');
    expect(calls, isNot(contains('speak')));
  });
}
