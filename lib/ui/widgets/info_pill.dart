import 'package:flutter/material.dart';

import '../theme/depth.dart';
import '../theme/tokens.dart';

/// Small rounded chip: a leading widget (icon/emoji) plus a label.
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: raisedDecoration(radius: AppRadii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
