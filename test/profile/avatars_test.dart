import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('kidAvatars has 18 avatars with 12 new animal avatars first', () {
    expect(kidAvatars.length, 18);

    const expectedNewAnimals = [
      AppImages.avatarFox,
      AppImages.avatarPanda,
      AppImages.avatarBunny,
      AppImages.avatarTiger,
      AppImages.avatarCat,
      AppImages.avatarDog,
      AppImages.avatarElephant,
      AppImages.avatarDino,
      AppImages.avatarOwl,
      AppImages.avatarPenguin,
      AppImages.avatarBear,
      AppImages.avatarUnicorn,
    ];

    expect(kidAvatars.take(12).toList(), expectedNewAnimals);

    const expectedOld = [
      AppImages.chipMain,
      AppImages.icStar,
      AppImages.icCrown,
      AppImages.icViet,
      AppImages.icToan,
      AppImages.icTiengAnh,
    ];

    expect(kidAvatars.skip(12).toList(), expectedOld);
  });

  test('every avatar path exists in AssetManifest with 2.0x and 3.0x variants',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();

    for (final path in kidAvatars) {
      expect(bundled, contains(path), reason: 'Missing $path in bundle');
      final slash = path.lastIndexOf('/');
      final dir = path.substring(0, slash);
      final name = path.substring(slash + 1);
      final variants =
          manifest.getAssetVariants(path)!.map((v) => v.key).toSet();
      expect(variants, contains('$dir/2.0x/$name'), reason: 'Missing 2.0x of $path');
      expect(variants, contains('$dir/3.0x/$name'), reason: 'Missing 3.0x of $path');
    }
  });

  test('tease and party sticker helpers produce valid game asset paths',
      () async {
    const teaseIds = [
      'bubble',
      'tongue',
      'byebye',
      'rain',
      'sleepy',
      'turtle',
      'smoke',
    ];

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();

    for (final id in teaseIds) {
      final path = AppImages.stickerTease(id);
      expect(path, 'assets/images/game/sticker-tease-$id.png');
      expect(bundled, contains(path), reason: 'Missing $path in bundle');
      final variants =
          manifest.getAssetVariants(path)!.map((v) => v.key).toSet();
      expect(variants, contains('assets/images/game/2.0x/sticker-tease-$id.png'));
      expect(variants, contains('assets/images/game/3.0x/sticker-tease-$id.png'));
    }

    expect(AppImages.stickerParty, 'assets/images/game/sticker-party.png');
    expect(bundled, contains(AppImages.stickerParty));
  });
}
