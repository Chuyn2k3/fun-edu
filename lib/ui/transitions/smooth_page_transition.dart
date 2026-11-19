import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds a gentle, buttery-smooth page transition (160ms Fade + subtle Scale 0.97 -> 1.0)
/// styled like modern arcade and tactile mobile apps, replacing the heavy OS slide transitions
/// that cause dropped frames and visual hitching.
CustomTransitionPage<T> buildSmoothTransitionPage<T>({
  required Widget child,
  required LocalKey key,
  Duration duration = const Duration(milliseconds: 160),
}) {
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
