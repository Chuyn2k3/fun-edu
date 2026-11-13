import 'package:flutter/services.dart';

/// Phones stay portrait (the writing pad is laid out for it); tablets
/// rotate. Returns null while the window has no size yet (on some Android
/// devices the first view metrics arrive after `main` starts).
bool? lockPortraitFor(Size logicalSize) {
  if (logicalSize.isEmpty) return null;
  return logicalSize.shortestSide < 600;
}

/// Applies [lockPortraitFor] once, as soon as a real window size is known.
abstract final class PortraitLock {
  static bool _decided = false;

  /// Whether the decision has been made (tests reset it with [reset]).
  static bool get decided => _decided;

  /// Locks phones to portrait for [logicalSize]; does nothing when the size
  /// is still empty or a decision was already made. Not awaited: nothing
  /// may wait on it.
  static void decide(Size logicalSize) {
    if (_decided) return;
    final lock = lockPortraitFor(logicalSize);
    if (lock == null) return;
    _decided = true;
    if (lock) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  static void reset() => _decided = false;
}
