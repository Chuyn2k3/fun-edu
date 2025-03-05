import 'package:flutter/material.dart';

class WhiteRoundedCornersCard extends Card {
  final EdgeInsets? padding;

  const WhiteRoundedCornersCard({
    super.key,
    required super.child,
    this.padding,
    super.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.all(16),
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding:
            padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
