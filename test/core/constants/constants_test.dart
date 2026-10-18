import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/core/constants/audio_paths.dart';

void main() {
  group('Shop Constants Tests', () {
    test('AppShopAssets paths should have correct asset prefixes', () {
      expect(AppShopAssets.shopBackground, contains('assets/shop_game/bg/'));
      expect(AppShopAssets.countertop, contains('assets/shop_game/bg/'));
      expect(AppShopAssets.basket, contains('assets/shop_game/props/'));
      expect(AppShopAssets.redApple, contains('assets/shop_game/items/'));
      expect(AppShopAssets.bearIdleLottie, contains('assets/shop_game/characters/'));
    });

    test('AudioPaths should define required BGM and SFX paths', () {
      expect(AudioPaths.bgmShop, contains('assets/shop_game/audio/'));
      expect(AudioPaths.sfxDragStart, contains('assets/shop_game/audio/'));
      expect(AudioPaths.sfxDropCorrect, contains('assets/shop_game/audio/'));
      expect(AudioPaths.sfxDropWrong, contains('assets/shop_game/audio/'));
    });
  });
}
