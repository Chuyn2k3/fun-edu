import 'package:flutter/material.dart';

/// Brand palette (spec 8.2a).
abstract final class AppColors {
  static const primary = Color(0xFFC8460F);
  /// [primary] darkened for small text on a tinted raised card (the
  /// gradient end of a subject tint), where [primary] is just under 4.5:1.
  static const primaryOnTint = Color(0xFFB43E0D);
  static const accent = Color(0xFFE8590C);
  static const background = Color(0xFFFBF5EC);
  static const dot = Color(0xFFEADFCF);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF22284A);
  static const textMuted = Color(0xFF5B6385);
}

enum Subject {
  viet(Color(0xFFE8590C), Color(0xFFFFF0E4)),
  tiengViet(Color(0xFF7C3AED), Color(0xFFF3EDFF)),
  toan(Color(0xFF2563EB), Color(0xFFE8F1FF)),
  tiengAnh(Color(0xFF0F8A5F), Color(0xFFE5F7EF));

  const Subject(this.color, this.tint);

  /// Strong subject color (rings, icons).
  final Color color;

  /// Soft background tint for the subject.
  final Color tint;
}

abstract final class AppRadii {
  static const card = 28.0;
  static const tile = 18.0;
  static const pill = 999.0;
}

/// Rocket race scene palette (phase 2B-1, "Bản 7"). Only the race scene uses
/// these; kid-facing UI around it keeps [AppColors].
abstract final class GameColors {
  // Sky gradient, top to bottom.
  static const skyTop = Color(0xFF2A2766);
  static const skyUpper = Color(0xFF4B3C93);
  static const skyLower = Color(0xFF8E6BC2);
  static const skyHorizon = Color(0xFFF2A9B8);
  static const star = Color(0xFFFFFFFF);
  static const starWarm = Color(0xFFFFF6C7);

  /// White sprite mask for the smoke/sparkle atlas; each particle tints it.
  static const spriteMask = Color(0xFFFFFFFF);

  // 2.5D track slab.
  static const track = Color(0xFF7B66C9);
  static const trackFar = Color(0xFF6A56B8);
  static const trackRim = Color(0xFF5B4AA8);
  static const trackSide = Color(0xFF43358A);
  static const trackTie = Color(0xFF9784DA);
  static const laneLine = Color(0xFFB9A9F0);
  static const rocketShadow = Color(0xFF2E2470);
  static const planetHalo = Color(0xFFFFE27A);

  // Flame (classic orange).
  static const flameCore = Color(0xFFFFFDF2);
  static const flameMid = Color(0xFFFFE27A);
  static const flameOuterHot = Color(0xFFFFF7D1);
  static const flameOuter = Color(0xFFFFD24A);
  static const flameOuterMid = Color(0xFFFF7A1A);
  static const flameOuterEnd = Color(0xFFE8380C);
  static const flameGlow = Color(0xFFFFB547);
  static const smoke = Color(0xFFF6EEFF);

  // Blue flame trail.
  static const blueCore = Color(0xFFF4FBFF);
  static const blueMid = Color(0xFFA8ECFF);
  static const blueOuterHot = Color(0xFFE2F7FF);
  static const blueOuter = Color(0xFF6FD3FF);
  static const blueOuterMid = Color(0xFF2E8BFF);
  static const blueOuterEnd = Color(0xFF3A3DDB);
  static const blueGlow = Color(0xFF7CC8FF);
  static const blueSmoke = Color(0xFFE6F0FF);

  // Rainbow smoke puffs (pastel, readable on the purple track).
  static const rainbow = [
    Color(0xFFFF9A9A),
    Color(0xFFFFC46B),
    Color(0xFFFFF07A),
    Color(0xFF8EE59B),
    Color(0xFF7CC8FF),
    Color(0xFFB69CFF),
  ];

  // Sparkle trail stars.
  static const sparkles = [
    Color(0xFFFFF6C7),
    Color(0xFFFFFFFF),
    Color(0xFFFFD24A),
    Color(0xFFFFB3D9),
  ];

  // Clouds drawn in code (2.5D: light top, lilac-pink underside).
  static const cloudTop = Color(0xFFFFF7F9);
  static const cloudLight = Color(0xFFFFF0F3);
  static const cloudShade = Color(0xFFF5CFDA);
  static const cloudFar = Color(0xFFC9B3EE);
  static const cloudFarShade = Color(0xFFA990DE);

  // Comet streak.
  static const cometHead = Color(0xFFFFFBE8);
  static const cometTail = Color(0xFFFFB547);

  // Race screen, around the scene ("Bản 7"): warm cream question area.
  static const panelTop = Color(0xFFFFF4E4);
  static const panelBottom = Color(0xFFFFEBD2);
  static const questionCardTint = Color(0xFFFFF8F0);
  static const questionCardEdge = Color(0xFFEED8BD);
  static const listenFill = Color(0xFFFFE3C8);
  static const listenEdge = Color(0xFFF1BE92);
  static const listenInk = Color(0xFF9A3412);
  static const hudEdge = Color(0xFFD9CCEB);
  static const hudShadow = Color(0x4D140A3C);
  static const cometInk = Color(0xFF7A4A00);
  static const ink = Color(0xFF24264D);
  static const correctRing = Color(0xFF2F9E6B);

  // Answer keys: light top, body, bottom edge, text (all text >= 4.5:1).
  static const keyOrangeTop = Color(0xFFFFD2A6);
  static const keyOrange = Color(0xFFFFB77A);
  static const keyOrangeEdge = Color(0xFFD9803E);
  static const keyOrangeInk = Color(0xFF5A2208);
  static const keyBlueTop = Color(0xFFC9DDFF);
  static const keyBlue = Color(0xFF9EC0FA);
  static const keyBlueEdge = Color(0xFF5E86D1);
  static const keyBlueInk = Color(0xFF16306E);
  static const keyGreenTop = Color(0xFFC7F0DA);
  static const keyGreen = Color(0xFF93DDB7);
  static const keyGreenEdge = Color(0xFF4DAA7D);
  static const keyGreenInk = Color(0xFF0C4A31);

  // Big orange "Đua lại!" key.
  static const goTop = Color(0xFFFFA45C);
  static const go = Color(0xFFF97316);
  static const goEdge = Color(0xFFB44A0A);
  static const goInk = Color(0xFF3B1404);

  // Góc Chơi hub, garage, cabinet and album ("Bản 7").
  /// Soft violet highlight in the space hero and the garage stage.
  static const skyGlow = Color(0xFF6B56C2);
  /// Thick bottom edge under the space hero and the garage stage.
  static const stageEdge = Color(0xFF2E2670);
  /// Subtitle on the space hero (>= 4.5:1 on [skyUpper]).
  static const heroSubtitle = Color(0xFFFFE2C4);
  /// Locked garage tile, badge or sticker: lilac fill, edge and label ink.
  static const lockedFill = Color(0xFFECE7FA);
  static const lockedEdge = Color(0xFFCFC6EE);
  static const lockedInk = Color(0xFF4A4F75);
  /// Silhouette of a sticker not owned yet.
  static const silhouette = Color(0xFFB9AEDB);

  // Fireworks sparks.
  static const fireworks = [
    Color(0xFFFFD24A),
    Color(0xFFFF8FB1),
    Color(0xFF7CC8FF),
    Color(0xFF8EE59B),
    Color(0xFFFFFFFF),
    Color(0xFFFFA45C),
  ];
}
