import 'package:flutter/widgets.dart';

import 'assets.dart';

/// Decodes every bundled image into the image cache so screens do not pop in.
Future<void> precacheAppImages(BuildContext context) async {
  for (final path in AppImages.all) {
    if (!context.mounted) return;
    try {
      await precacheImage(AssetImage(path), context);
    } catch (_) {
      // A missing image must never block the app; the screen shows its own
      // fallback.
    }
  }
}
