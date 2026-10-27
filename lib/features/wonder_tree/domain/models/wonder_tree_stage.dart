enum WonderTreeStage {
  seed,       // 0-1 ngày
  seedling,   // 2-3 ngày
  blooming,   // 4 ngày
  goldenFruit // 5 ngày (Quả chín rụng rương quà)
}

extension WonderTreeStageExt on WonderTreeStage {
  static WonderTreeStage fromStreak(int streak) {
    if (streak <= 0) return WonderTreeStage.seed;
    final mod = streak % 5;
    if (mod == 0) return WonderTreeStage.goldenFruit;
    if (mod == 1) return WonderTreeStage.seed;
    if (mod <= 3) return WonderTreeStage.seedling;
    return WonderTreeStage.blooming;
  }
}
