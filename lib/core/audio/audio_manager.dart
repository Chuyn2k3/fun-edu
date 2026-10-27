import 'package:just_audio/just_audio.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  AudioPlayer? _sfxPlayer;
  bool _isSoundEnabled = true;

  AudioPlayer get _player => _sfxPlayer ??= AudioPlayer();
  bool get isSoundEnabled => _isSoundEnabled;

  void toggleSound(bool enabled) {
    _isSoundEnabled = enabled;
  }

  Future<void> playSfx(AudioSfx sfx) async {
    if (!_isSoundEnabled) return;
    try {
      await _player.setAsset('assets/${sfx.assetPath}');
      await _player.play();
    } catch (_) {
      // Fallback êm dịu nếu asset đang cập nhật, không throw crash
    }
  }

  void dispose() {
    _sfxPlayer?.dispose();
    _sfxPlayer = null;
  }
}
