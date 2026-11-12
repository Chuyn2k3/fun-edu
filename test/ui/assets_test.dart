import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every AppImages asset is bundled, PNGs with 2.0x and 3.0x variants',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();
    for (final path in AppImages.all) {
      expect(bundled, contains(path), reason: path);
      if (path.endsWith('.png')) {
        final name = path.substring('assets/images/'.length);
        final variants =
            manifest.getAssetVariants(path)!.map((v) => v.key).toSet();
        expect(variants, contains('assets/images/2.0x/$name'), reason: path);
        expect(variants, contains('assets/images/3.0x/$name'), reason: path);
      }
    }
  });
}
