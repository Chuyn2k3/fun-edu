import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum FormFactor { phone, tabletPortrait, tabletLandscape }

/// Phone when the shortest side is under 600 (also covers split view);
/// otherwise tablet, by orientation.
FormFactor formFactorOf(Size windowSize) {
  if (math.min(windowSize.width, windowSize.height) < 600) {
    return FormFactor.phone;
  }
  return windowSize.width > windowSize.height
      ? FormFactor.tabletLandscape
      : FormFactor.tabletPortrait;
}

extension FormFactorX on BuildContext {
  FormFactor get formFactor => formFactorOf(MediaQuery.sizeOf(this));
  bool get isTablet => formFactor != FormFactor.phone;
}

/// Sizes used by the tablet layouts.
abstract final class TabletSizes {
  static const kidTarget = 80.0;
  static const textScale = 1.2;
  static const railWidth = 104.0;
  static const messageMaxWidth = 640.0;
}
