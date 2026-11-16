import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../ui/assets.dart';
import 'space_track.dart' show paintImageFitted;

/// A rocket picture and where its nozzle is. [aspect] (height / width) comes
/// from the art itself so layout does not wait for the image to load.
@immutable
class RocketSprite {
  const RocketSprite._(this.asset, this.aspect, this.nozzle);

  final String asset;
  final double aspect;

  /// Nozzle height as a fraction of the image height from the top: the
  /// flame starts here, behind the fins.
  final double nozzle;

  static const orange = RocketSprite._(AppImages.rocketOrange, 171 / 96, 0.80);
  static const blue = RocketSprite._(AppImages.rocketBlue, 147 / 96, 0.81);
  static const green = RocketSprite._(AppImages.rocketGreen, 136 / 96, 0.81);
  static const purple = RocketSprite._(AppImages.rocketPurple, 144 / 96, 0.81);

  /// Chíp's white rocket (never a garage item).
  static const chip = RocketSprite._(AppImages.rocketChip, 148 / 96, 0.82);

  /// Garage item id → sprite; unknown ids fall back to the orange starter.
  static RocketSprite forItem(String id) => switch (id) {
        'rocket_blue' => blue,
        'rocket_green' => green,
        'rocket_purple' => purple,
        _ => orange,
      };

  /// Draws [image] in [rect] (aspect kept).
  static void paintImage(Canvas canvas, ui.Image image, Rect rect) =>
      paintImageFitted(canvas, image, rect);
}

/// Resolves asset images to `ui.Image`s for painters, one notifier per
/// asset (null until decoded). Owned by the scene; disposes what it decoded.
class SceneImages {
  final Map<String, ValueNotifier<ui.Image?>> _images = {};
  final Map<String, ImageStream> _streams = {};
  final Map<String, ImageStreamListener> _listeners = {};
  ImageConfiguration? _config;

  ValueNotifier<ui.Image?> operator [](String asset) =>
      _images.putIfAbsent(asset, () => ValueNotifier<ui.Image?>(null));

  /// (Re)resolves [assets] for the current [config] (device pixel ratio).
  void resolve(ImageConfiguration config, Iterable<String> assets) {
    final changed = config != _config;
    _config = config;
    for (final asset in assets) {
      if (!changed && _streams.containsKey(asset)) continue;
      final stream = AssetImage(asset).resolve(config);
      final old = _streams[asset];
      if (old != null && old.key == stream.key) continue;
      if (old != null) old.removeListener(_listeners[asset]!);
      final listener = ImageStreamListener((info, _) {
        final n = this[asset];
        n.value?.dispose();
        n.value = info.image;
      });
      _streams[asset] = stream;
      _listeners[asset] = listener;
      stream.addListener(listener);
    }
  }

  void dispose() {
    _streams.forEach((asset, s) => s.removeListener(_listeners[asset]!));
    for (final n in _images.values) {
      n.value?.dispose();
      n.dispose();
    }
  }
}
