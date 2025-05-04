import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/app_colors.dart';

class GameModeSelector extends StatelessWidget {
  final Function(String) onSelectMode;
  final String practiceDescription;
  final String challengeDescription;

  const GameModeSelector({
    Key? key,
    required this.onSelectMode,
    required this.practiceDescription,
    required this.challengeDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'Chọn Chế Độ Chơi',
            style: TextStyle(fontSize: 24, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildModeCard(
            context: context,
            title: 'Luyện Tập',
            description: practiceDescription,
            icon: Icons.school_rounded,
            color: AppColors.evenColor,
            onTap: () => onSelectMode('practice'),
          ),
          const SizedBox(height: 20),
          _buildModeCard(
            context: context,
            title: 'Thử Thách',
            description: challengeDescription,
            icon: Icons.emoji_events_rounded,
            color: AppColors.accent,
            onTap: () => onSelectMode('challenge'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 22,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
