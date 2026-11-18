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

  // Free-flight deep space backdrop, nebulae and warp streaks.
  static const spaceTop = Color(0xFF130D36);
  static const spaceMid = Color(0xFF24185E);
  static const spaceBottom = Color(0xFF1A1044);
  static const nebulaViolet = Color(0xFF6C4CE0);
  static const nebulaMagenta = Color(0xFFB854D6);
  static const nebulaCyan = Color(0xFF3E92CC);
  static const streakLight = Color(0xFFD8E6FF);

  // Mini vertical progress bar along right edge.
  static const progressTrack = Color(0xFF2E2268);
  static const progressBorder = Color(0xFF8A78D6);
  static const progressKid = Color(0xFFFF8A34);
  static const progressChip = Color(0xFFFFFFFF);
  static const progressChipRing = Color(0xFFFF7043);
  static const stallSmoke = Color(0xFF48425E);

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

  // Overtake banner.
  static const overtakeBannerTop = Color(0xFFFF8F00);
  static const overtakeBannerBottom = Color(0xFFFF6D00);

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

/// Colors for printable A4 Vietnamese ô li worksheets (both live preview and
/// PDF export). Designed to print cleanly on both color and monochrome ink.
abstract final class WorksheetColors {
  static const paper = Color(0xFFFFFFFF);
  static const gridLight = Color(0xFFC7DDF5);
  static const gridHeavy = Color(0xFF7DA8D6);
  static const cellBorder = Color(0xFFA7C6E8);
  static const contextLetter = Color(0xFFD6DBE6);
  static const modelInk = Color(0xFF24264D);
  static const traceInk = Color(0xFFAEB6C8);
  static const accent = Color(0xFFE05E14);
  static const startDot = Color(0xFFE05E14);
  static const startDotMuted = Color(0xFF9AA3B8);
  static const headerSubtitle = Color(0xFF5D617D);
  static const rewardStarStroke = Color(0xFFD1A43B);
}

/// Swatch colors shown in English Colors lessons (high visibility on cream/white).
abstract final class EnglishSwatchColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const yellow = Color(0xFFFBC02D);
  static const green = Color(0xFF2E9E5B);
  static const orange = Color(0xFFFB8C00);
  static const purple = Color(0xFF8E24AA);
  static const pink = Color(0xFFEC407A);
  static const black = Color(0xFF212121);
  static const white = Color(0xFFFFFFFF);
  static const brown = Color(0xFF795548);
}

/// Colors for the learning Collection tab (Sưu tập): stickers, attendance
/// calendar, and kid certificates. All text/ink pairs meet >= 4.5:1 contrast.
abstract final class CollectionColors {
  static const goldFill = Color(0xFFFFF4CC);
  static const goldHalo = Color(0xFFFFDF73);
  static const goldBorder = Color(0xFFE0A82E);
  static const goldInk = Color(0xFF7A4B00);

  static const certPaper = Color(0xFFFFFBF0);
  static const certFrameOuter = Color(0xFFD69A24);
  static const certFrameInner = Color(0xFFF0C75E);

  static const calendarStampFill = Color(0xFFFFF1C7);
  static const calendarTodayFill = Color(0xFFFFEEE2);

  static const lockedSurface = Color(0xFFF3EFE8);
  static const lockedBorder = Color(0xFFE0D7C8);
  static const lockedInk = Color(0xFF565E7D);
  static const progressTrack = Color(0xFFE8E0D2);
}

/// Colors for Nhà Chíp (cozy room painter, themes, rugs, decor, treat badges).
/// All foreground/background text pairs meet >= 4.5:1 contrast.
abstract final class HouseColors {
  // Room wall & window themes
  static const sunnyWallTop = Color(0xFFFFF4E0);
  static const sunnyWallBottom = Color(0xFFFFE4BE);
  static const sunnySky = Color(0xFF9AD8FF);
  static const sunnySun = Color(0xFFFFD84D);

  static const forestWallTop = Color(0xFFE6F7EA);
  static const forestWallBottom = Color(0xFFC9EBD2);
  static const forestSky = Color(0xFFA7E8C2);
  static const forestLeaf = Color(0xFF2E9E5B);

  static const oceanWallTop = Color(0xFFE4F2FF);
  static const oceanWallBottom = Color(0xFFC4E1FF);
  static const oceanSky = Color(0xFF7CC8FF);
  static const oceanWave = Color(0xFF2563EB);

  static const starryWallTop = Color(0xFF3A2F7A);
  static const starryWallBottom = Color(0xFF5A4BA3);
  static const starrySky = Color(0xFF1D174B);
  static const starryMoon = Color(0xFFFFEC99);

  // Room architecture (wood floor, window frame, baseboard)
  static const woodFloorTop = Color(0xFFECC69B);
  static const woodFloorBottom = Color(0xFFD8A878);
  static const woodPlankLine = Color(0xFFC49262);
  static const baseboard = Color(0xFFF6E7D4);
  static const windowFrame = Color(0xFF9A663B);
  static const windowSill = Color(0xFFB57C4C);

  // Rugs
  static const rugCream = Color(0xFFFFF8EC);
  static const rugCreamEdge = Color(0xFFE8C8A0);
  static const rugRainbow1 = Color(0xFFFF9A9A);
  static const rugRainbow2 = Color(0xFFFFD27D);
  static const rugRainbow3 = Color(0xFF8EE59B);
  static const rugRainbow4 = Color(0xFF89C4FF);
  static const rugCloud = Color(0xFFEAF5FF);
  static const rugCloudEdge = Color(0xFFAAD2FA);
  static const rugStar = Color(0xFFFFF0B8);
  static const rugStarEdge = Color(0xFFE0A82E);

  // Decor props
  static const shelfWood = Color(0xFFA76F40);
  static const bookRed = Color(0xFFE5534B);
  static const bookBlue = Color(0xFF3B82F6);
  static const bookGreen = Color(0xFF22A06B);
  static const bookYellow = Color(0xFFF5B727);
  static const potClay = Color(0xFFD97343);
  static const plantDark = Color(0xFF1E7E45);
  static const plantLight = Color(0xFF4CC37A);
  static const lampGlow = Color(0xFFFFE58F);
  static const lampStand = Color(0xFF6B5B95);
  static const globeWater = Color(0xFF4DA6FF);
  static const globeLand = Color(0xFF47B86E);

  // Treats & status chips
  static const equippedFill = Color(0xFFE3F7EC);
  static const equippedInk = Color(0xFF0E6B42);
  static const treatAcorn = Color(0xFFB3682B);
  static const treatApple = Color(0xFFD9382E);
  static const treatHoney = Color(0xFFD98A16);
  static const treatCake = Color(0xFF8B46D9);
  static const xpBarFill = Color(0xFF2E9E5B);
  static const xpBarTrack = Color(0xFFE7E2D8);
}
