import 'package:flutter/widgets.dart';

import 'assets.dart';

/// Images in the order they are decoded: the splash logo first (the splash
/// is on screen while the rest load), then every screen image.
const precacheOrder = [AppImages.logo, ...AppImages.all];

/// Decodes every bundled image into the image cache so screens do not pop in.
Future<void> precacheAppImages(BuildContext context) async {
  for (final path in precacheOrder) {
    if (!context.mounted) return;
    try {
      await precacheImage(AssetImage(path), context);
    } catch (_) {
      // A missing image must never block the app; the screen shows its own
      // fallback.
    }
  }
}
