import 'package:flutter/material.dart';

import '../theme/tokens.dart';
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
  });

  final Subject subject;
  final String imagePath;
  final String title;
  final String subtitle;
  final int? done;
  final int? total;

  /// When null the subject is not available yet and "Sắp có" is shown.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x17503C28),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
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
}
