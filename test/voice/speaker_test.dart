import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/voice/speaker.dart';

import 'fake_speaker.dart';

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

  test(
      'iOS: sets shared instance (plugin sends the category only on a real iOS host); failure there '
      'does not stop speech', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final args = <String, Object?>{};
    mock((c) async {
      args[c.method] = c.arguments;
      if (c.method == 'setSharedInstance') throw PlatformException(code: 'x');
      return 1;
    });
    final s = TtsSpeaker();
    await s.speak('xin chào');
    expect(args['setSharedInstance'], true);
    expect(args['speak'], 'xin chào');
  });

  group('speakerProvider follows the voice setting', () {
    test('silent while the setting is still loading', () async {
      final device = FakeSpeaker();
      final container = ProviderContainer(overrides: [
        deviceSpeakerProvider.overrideWithValue(device),
        voiceEnabledProvider.overrideWith((ref) => Completer<bool>().future),
      ]);
      addTearDown(container.dispose);
      await container.read(speakerProvider).speak('xin chào');
      expect(device.spoken, isEmpty);
    });

    test('a speaker kept by a screen goes silent when switched off', () async {
      final device = FakeSpeaker();
      var on = true;
      final container = ProviderContainer(overrides: [
        deviceSpeakerProvider.overrideWithValue(device),
        voiceEnabledProvider.overrideWith((ref) async => on),
      ]);
      addTearDown(container.dispose);
      final kept = container.read(speakerProvider);
      await container.read(voiceEnabledProvider.future);
      await kept.speak('một');
      expect(device.spoken, ['một']);

      on = false;
      container.invalidate(voiceEnabledProvider);
      await container.read(voiceEnabledProvider.future);
      await kept.speak('hai');
      expect(device.spoken, ['một']);
    });
  });
}
