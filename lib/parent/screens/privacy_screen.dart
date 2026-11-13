import 'package:flutter/material.dart';

import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';

/// Placeholder; the real privacy policy replaces this body in a later task.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách quyền riêng tư')),
      body: const DottedBackground(
        child: Center(
          child: Text(
            'Đang cập nhật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
