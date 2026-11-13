import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

final speakerProvider = Provider<Speaker>((ref) => TtsSpeaker());
