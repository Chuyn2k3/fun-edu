import 'package:flutter/material.dart';

import '../theme/depth.dart';

/// White card with large radius and a soft, wide shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: raisedDecoration(),
      child: child,
    );
  }
}
