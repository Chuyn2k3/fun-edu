import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../profile/kid_repository.dart';

/// Speaks Vietnamese lines aloud.
abstract class Speaker {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Does nothing; used in tests and when sound is off.
class SilentSpeaker implements Speaker {
  const SilentSpeaker();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

/// Device text-to-speech through flutter_tts. Never throws: if the plugin is
/// missing or no Vietnamese voice exists, every call becomes a no-op.
class TtsSpeaker implements Speaker {
  TtsSpeaker({FlutterTts? tts}) : _tts = tts;

  FlutterTts? _tts;
  Future<bool>? _ready;

  Future<bool> _init() async {
    try {
      final tts = _tts ??= FlutterTts();
      await _configureIosAudio(tts);
      final lang = await tts.setLanguage('vi-VN');
      if (lang != 1) return false;
      await tts.setSpeechRate(0.45);
      await tts.setPitch(1.1);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lets speech play with the iOS ringer switch off. Failure here must not
  /// disable speech, so it has its own guard.
  Future<void> _configureIosAudio(FlutterTts tts) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await tts.setSharedInstance(true);
      await tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
      );
    } catch (_) {}
  }

  @override
  Future<void> speak(String text) async {
    try {
      if (!await (_ready ??= _init())) return;
      final tts = _tts!;
      await tts.stop();
      await tts.speak(text);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      if (_ready == null || !await _ready!) return;
      await _tts!.stop();
    } catch (_) {}
  }
}

/// Passes speech to [_device] only while [_enabled] says so. The setting is
/// read at each call, so screens that keep a speaker follow later changes.
class SettingGatedSpeaker implements Speaker {
  SettingGatedSpeaker(this._device, this._enabled);

  final Speaker _device;
  final bool Function() _enabled;

  @override
  Future<void> speak(String text) async {
    if (_enabled()) await _device.speak(text);
  }

  @override
  Future<void> stop() => _device.stop();
}

/// The device voice; tests override it to record speech.
final deviceSpeakerProvider = Provider<Speaker>((ref) => TtsSpeaker());

/// Speaks only when the parent's voice setting is known to be on: silent
/// while the setting loads or fails to load, and when switched off.
final speakerProvider = Provider<Speaker>((ref) {
  // Start loading the setting now so it is known by the first line.
  ref.listen<AsyncValue<bool>>(voiceEnabledProvider, (_, __) {});
  return SettingGatedSpeaker(
    ref.watch(deviceSpeakerProvider),
    () => ref.read(voiceEnabledProvider).valueOrNull ?? false,
  );
});
