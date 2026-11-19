import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import 'space_track.dart' show paintImageFitted;

/// A rocket picture and where its nozzle is. [aspect] (height / width) comes
/// from the art itself so layout does not wait for the image to load.
@immutable
class RocketSprite {
  const RocketSprite._(
    this.asset,
    this.aspect,
    this.nozzle, {
    this.windowCenter = const Offset(0.50, 0.50),
    this.windowRadius = 0.115,
    this.hasWindow = true,
  });

  final String asset;
  final double aspect;

  /// Nozzle height as a fraction of the image height from the top: the
  /// flame starts here, behind the fins.
  final double nozzle;

  /// Normalized porthole window center (x, y) relative to rocket rect.
  final Offset windowCenter;

  /// Porthole window radius as a fraction of rocket width.
  final double windowRadius;

  /// Whether this rocket has a porthole window showing the pilot avatar.
  final bool hasWindow;

  static const orange = RocketSprite._(
    AppImages.rocketOrange,
    171 / 96,
    0.80,
    windowCenter: Offset(0.50, 0.515),
    windowRadius: 0.115,
  );
  static const blue = RocketSprite._(
    AppImages.rocketBlue,
    147 / 96,
    0.81,
    windowCenter: Offset(0.50, 0.517),
    windowRadius: 0.115,
  );
  static const green = RocketSprite._(
    AppImages.rocketGreen,
    136 / 96,
    0.81,
    windowCenter: Offset(0.50, 0.257),
    windowRadius: 0.115,
  );
  static const purple = RocketSprite._(
    AppImages.rocketPurple,
    144 / 96,
    0.81,
    windowCenter: Offset(0.50, 0.542),
    windowRadius: 0.115,
  );

  /// Chíp's white rocket with Chíp already sculpted inside the cockpit.
  static const chip = RocketSprite._(
    AppImages.rocketChip,
    148 / 96,
    0.82,
    hasWindow: false,
  );

  /// Garage item id → sprite; unknown ids fall back to the orange starter.
  static RocketSprite forItem(String id) => switch (id) {
        'rocket_blue' => blue,
        'rocket_green' => green,
        'rocket_purple' => purple,
        _ => orange,
      };

  static final Paint _windowInnerPaint = Paint()
    ..color = GameColors.windowBezelDark;
  static final Paint _windowBezelPaint = Paint()
    ..color = GameColors.windowBezel
    ..style = PaintingStyle.stroke;

  /// Draws [image] in [rect] (aspect kept).
  static void paintImage(Canvas canvas, ui.Image image, Rect rect) =>
      paintImageFitted(canvas, image, rect);

  /// Draws rocket body and, if [sprite.hasWindow] and [avatarImage] is provided,
  /// clips the kid avatar inside the porthole window with a metallic bezel.
  static void paintRocket(
    Canvas canvas, {
    required RocketSprite sprite,
    required ui.Image? rocketImage,
    required ui.Image? avatarImage,
    required Rect rect,
  }) {
    if (rocketImage != null) {
      paintImageFitted(canvas, rocketImage, rect);
    }
    if (sprite.hasWindow && avatarImage != null) {
      final winX = rect.left + rect.width * sprite.windowCenter.dx;
      final winY = rect.top + rect.height * sprite.windowCenter.dy;
      final winR = rect.width * sprite.windowRadius;

      // Dark porthole backing
      canvas.drawCircle(Offset(winX, winY), winR, _windowInnerPaint);

      // Clipped avatar
      canvas.save();
      final clipPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(winX, winY), radius: winR));
      canvas.clipPath(clipPath);
      paintImageFitted(
        canvas,
        avatarImage,
        Rect.fromCircle(center: Offset(winX, winY), radius: winR),
      );
      canvas.restore();

      // Metallic bezel ring
      _windowBezelPaint.strokeWidth = math.max(1.2, rect.width * 0.022);
      canvas.drawCircle(Offset(winX, winY), winR, _windowBezelPaint);
    }
  }
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
