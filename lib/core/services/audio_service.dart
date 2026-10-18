import 'package:just_audio/just_audio.dart';
import 'package:fun_edu/core/constants/audio_paths.dart';

class AudioService {
  final AudioPlayer _bgmPlayer;
  final AudioPlayer _sfxPlayer;
  bool _isMuted = false;

  AudioService({
    AudioPlayer? bgmPlayer,
    AudioPlayer? sfxPlayer,
  })  : _bgmPlayer = bgmPlayer ?? AudioPlayer(),
        _sfxPlayer = sfxPlayer ?? AudioPlayer();

  bool get isMuted => _isMuted;

  Future<void> init() async {
    await _bgmPlayer.setLoopMode(LoopMode.one);
  }

  Future<void> playBgm(String assetPath) async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.setAsset(assetPath);
      await _bgmPlayer.play();
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> playSfx(String assetPath) async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.setAsset(assetPath);
      await _sfxPlayer.play();
    } catch (_) {}
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.play();
    }
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
