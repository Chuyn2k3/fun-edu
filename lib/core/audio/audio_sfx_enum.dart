enum AudioSfx {
  click,
  correctTing,
  wrongSoft,
  waterSplash,
  eggCrack,
  levelVictory,
}

extension AudioSfxPath on AudioSfx {
  String get assetPath => switch (this) {
        AudioSfx.click => 'audio/click.mp3',
        AudioSfx.correctTing => 'audio/correct.mp3',
        AudioSfx.wrongSoft => 'audio/wrong.mp3',
        AudioSfx.waterSplash => 'audio/water_splash.mp3',
        AudioSfx.eggCrack => 'audio/egg_crack.mp3',
        AudioSfx.levelVictory => 'audio/victory.mp3',
      };
}
