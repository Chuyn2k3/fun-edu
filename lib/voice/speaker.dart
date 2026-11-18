import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../profile/kid_repository.dart';

/// Speaks Vietnamese lines aloud.
abstract class Speaker {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Optional capability for speakers that can switch TTS languages (e.g.
/// `'en-US'` for English practice and `'vi-VN'` for Vietnamese).
abstract interface class MultilingualSpeaker implements Speaker {
  Future<void> speakWithLanguage(String text, String language);
}

/// Convenience helper so any screen can speak in a target [language] while
/// staying backward-compatible with test spies that only implement [Speaker].
extension SpeakerLanguage on Speaker {
  Future<void> speakInLanguage(String text, String language) {
    final self = this;
    if (self is MultilingualSpeaker) {
      return self.speakWithLanguage(text, language);
    }
    return speak(text);
  }
}

/// Does nothing; used in tests and when sound is off.
class SilentSpeaker implements MultilingualSpeaker {
  const SilentSpeaker();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> speakWithLanguage(String text, String language) async {}

  @override
  Future<void> stop() async {}
}

/// Device text-to-speech through flutter_tts. Never throws: if the plugin is
/// missing or no voice exists, every call becomes a no-op.
class TtsSpeaker implements MultilingualSpeaker {
  TtsSpeaker({FlutterTts? tts}) : _tts = tts;

  FlutterTts? _tts;
  Future<bool>? _ready;
  String _language = 'vi-VN';

  Future<bool> _init() async {
    try {
      final tts = _tts ??= FlutterTts();
      await _configureIosAudio(tts);
      final lang = await tts.setLanguage('vi-VN');
      if (lang != 1) return false;
      _language = 'vi-VN';
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
  Future<void> speak(String text) => speakWithLanguage(text, 'vi-VN');

  @override
  Future<void> speakWithLanguage(String text, String language) async {
    try {
      if (!await (_ready ??= _init())) return;
      final tts = _tts!;
      if (_language != language) {
        final ok = await tts.setLanguage(language);
        if (ok == 1) _language = language;
      }
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
class SettingGatedSpeaker implements MultilingualSpeaker {
  SettingGatedSpeaker(this._device, this._enabled);

  final Speaker _device;
  final bool Function() _enabled;

  @override
  Future<void> speak(String text) async {
    if (_enabled()) await _device.speak(text);
  }

  @override
  Future<void> speakWithLanguage(String text, String language) async {
    if (_enabled()) await _device.speakInLanguage(text, language);
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
