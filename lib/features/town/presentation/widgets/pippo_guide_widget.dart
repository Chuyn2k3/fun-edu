import 'package:flutter/material.dart';

class PippoGuideWidget extends StatelessWidget {
  final String greeting;
  final VoidCallback? onTap;

  const PippoGuideWidget({
    super.key,
    this.greeting = 'Chào bé! Hôm nay chúng mình cùng khám phá nhé!',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.amber.shade300,
            child: const Icon(Icons.face_retouching_natural, color: Colors.deepOrange, size: 36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                greeting,
                style: const TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
