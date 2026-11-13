import 'package:flutter/material.dart';

import '../layout/form_factor.dart';
import '../theme/depth.dart';

/// Scale of the Chip image on tablet message screens (vs its phone size).
const tabletChipScale = 1.4;

/// Wraps a message screen's content in one centred raised card on tablets
/// (max width [TabletSizes.messageMaxWidth]); returns [child] untouched on
/// phones.
class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (!context.isTablet) return child;
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: TabletSizes.messageMaxWidth),
        child: Container(
          key: const ValueKey('message-card'),
          padding: padding,
          decoration: raisedDecoration(),
          child: child,
        ),
      ),
    );
  }
}
