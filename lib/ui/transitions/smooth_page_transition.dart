import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Page for a kid sub-screen.
///
/// On iOS this is the system [CupertinoPage], so the edge swipe back keeps
/// working. Elsewhere it is a gentle 160 ms fade plus a subtle 0.97 -> 1.0
/// scale instead of the heavier platform slide.
Page<T> buildSmoothTransitionPage<T>({
  required Widget child,
  required LocalKey key,
  Duration duration = const Duration(milliseconds: 160),
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<T>(key: key, child: child);
  }
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final scale = Tween<double>(begin: 0.97, end: 1.0).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}
