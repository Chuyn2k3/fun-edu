import 'package:flutter/material.dart';

import 'tokens.dart';

/// Constants for the raised "candy" card style.
abstract final class AppDepth {
  /// Warm brown used for cards that have no subject.
  static const neutral = Color(0xFF8A5A2B);

  /// Bottom tint for cards that have no subject.
  static const neutralTint = Color(0xFFFFF4E6);

  /// Thickness of the coloured bottom lip at rest.
  static const lip = 5.0;

  /// Thickness of the lip while the card is pressed.
  static const pressedLip = 2.0;
}

/// Decoration of a raised card: soft top-to-bottom gradient, a coloured
/// bottom lip and a tinted shadow. [pressed] flattens the lip and tightens
/// the shadow so the card looks pushed in.
BoxDecoration raisedDecoration({
  Color accent = AppDepth.neutral,
  Color? tint,
  double radius = AppRadii.card,
  bool pressed = false,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.card,
        Color.lerp(AppColors.card, tint ?? AppDepth.neutralTint, 0.9)!,
      ],
    ),
    border: Border(
      bottom: BorderSide(
        width: pressed ? AppDepth.pressedLip : AppDepth.lip,
        color: accent.withOpacity(0.28),
      ),
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: accent.withOpacity(0.16),
        blurRadius: pressed ? 12 : 22,
        offset: Offset(0, pressed ? 5 : 12),
      ),
      const BoxShadow(
        color: Color(0x14503C28),
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
    ],
  );
}
