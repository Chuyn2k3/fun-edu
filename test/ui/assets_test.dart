import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/precache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every AppImages asset is bundled, PNGs with 2.0x and 3.0x variants',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();
    for (final path in AppImages.all) {
      expect(bundled, contains(path), reason: path);
      if (path.endsWith('.png')) {
        final slash = path.lastIndexOf('/');
        final dir = path.substring(0, slash);
        final name = path.substring(slash + 1);
        final variants =
            manifest.getAssetVariants(path)!.map((v) => v.key).toSet();
        expect(variants, contains('$dir/2.0x/$name'), reason: path);
        expect(variants, contains('$dir/3.0x/$name'), reason: path);
      }
    }
  });

  test('game art PNGs have an alpha channel', () async {
    final game = AppImages.all.where((p) => p.startsWith('assets/images/game/'));
    expect(game.length, 46);
    for (final path in game) {
      final bytes = (await rootBundle.load(path)).buffer.asUint8List();
      // PNG IHDR colour type is byte 25: 6 = RGBA, 4 = grey+alpha.
      expect([4, 6], contains(bytes[25]), reason: path);
    }
  });

  test('the splash logo is precached first, then every screen image', () {
    expect(precacheOrder.first, AppImages.logo);
    expect(precacheOrder.skip(1), AppImages.all);
  });
}
