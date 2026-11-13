import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../layout/scale_down_to_fit.dart';
import '../theme/depth.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'progress_ring.dart';

/// Tile for one subject: 3D icon on a tint, title, subtitle and either a
/// progress ring or a "Sắp có" label when the subject is not available yet.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.done,
    this.total,
    this.onTap,
    this.height,
  });

  final Subject subject;
  final String imagePath;
  final String title;
  final String subtitle;
  final int? done;
  final int? total;

  /// When null the subject is not available yet and "Sắp có" is shown.
  final VoidCallback? onTap;

  /// Fixed card height (tablet landscape). The icon, ring and text grow in
  /// proportion; null keeps the compact phone card sized by its content.
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (height != null) {
      return LayoutBuilder(
        builder: (context, c) => _tall(height!, c.maxWidth),
      );
    }
    final trailing = onTap == null
        ? const Text(
            'Sắp có',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          )
        : ProgressRing(
            done: done ?? 0,
            total: total ?? 0,
            color: subject.color,
            size: 44,
          );
    return Pressable(
      onTap: onTap,
      builder: (pressed) => Container(
        decoration: raisedDecoration(
          accent: subject.color,
          tint: subject.tint,
          pressed: pressed,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: subject.tint,
                        borderRadius: BorderRadius.circular(AppRadii.tile),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(imagePath, fit: BoxFit.contain),
                    ),
                    const Spacer(),
                    trailing,
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Taller card for tablets: icon and ring on top, title and subtitle at
  /// the bottom, everything scaled from a 180 x 220 pt design (by the
  /// smaller of the two ratios so narrow cards do not overflow).
  Widget _tall(double height, double width) {
    final k = math.min(height / 180, width / 220);
    final trailing = onTap == null
        ? Text(
            'Sắp có',
            style: TextStyle(
              fontSize: 14 * k,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          )
        : ProgressRing(
            done: done ?? 0,
            total: total ?? 0,
            color: subject.color,
            size: 52 * k,
          );
    return Pressable(
      onTap: onTap,
      builder: (pressed) => Container(
        height: height,
        decoration: raisedDecoration(
          accent: subject.color,
          tint: subject.tint,
          pressed: pressed,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.all(14 * k),
            // Large system text scales the content down instead of
            // overflowing the fixed card height.
            child: ScaleDownToFit(
              fillHeight: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64 * k,
                        height: 64 * k,
                        decoration: BoxDecoration(
                          color: subject.tint,
                          borderRadius: BorderRadius.circular(AppRadii.tile),
                        ),
                        padding: EdgeInsets.all(6 * k),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                      SizedBox(width: 8 * k),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topRight,
                          child: trailing,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 22 * k,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15 * k,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
