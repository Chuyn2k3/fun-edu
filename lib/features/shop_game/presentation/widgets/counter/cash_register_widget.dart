import 'package:flutter/material.dart';

class CashRegisterWidget extends StatelessWidget {
  final int displayCount;

  const CashRegisterWidget({
    super.key,
    required this.displayCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF37474F), // Slate metal
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF263238), width: 3),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: const Color(0xFF81C784), // LCD green
            child: Text(
              '$displayCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'MÁY TÍNH TIỀN',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
