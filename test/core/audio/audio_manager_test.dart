import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AudioManager audioManager;

  setUp(() {
    audioManager = AudioManager();
  });

  test('toggleSound switches sound state properly', () {
    expect(audioManager.isSoundEnabled, isTrue);
    audioManager.toggleSound(false);
    expect(audioManager.isSoundEnabled, isFalse);
    audioManager.toggleSound(true);
    expect(audioManager.isSoundEnabled, isTrue);
  });

  test('AudioSfx enum has non-empty asset paths', () {
    for (final sfx in AudioSfx.values) {
      expect(sfx.assetPath, isNotEmpty);
      expect(sfx.assetPath.endsWith('.mp3'), isTrue);
    }
  });
}
