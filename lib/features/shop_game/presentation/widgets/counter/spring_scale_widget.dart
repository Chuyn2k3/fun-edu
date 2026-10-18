import 'dart:math';
import 'package:flutter/material.dart';

class SpringScaleWidget extends StatelessWidget {
  final int itemCount;

  const SpringScaleWidget({
    super.key,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    // Needle turns according to number of items
    final angle = min(itemCount * 0.4, pi);

    return Container(
      width: 80,
      height: 100,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F), // Vintage red scale body
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedRotation(
                turns: angle / (2 * pi),
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 2,
                  height: 24,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount kg',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
