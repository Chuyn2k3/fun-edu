import 'package:flutter/material.dart';

/// What is sent before the first sign-in (Nghị định 13/2023: consent first).
class OnlineConsentDialog extends StatelessWidget {
  const OnlineConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lưu dữ liệu của bé lên máy chủ?'),
      content: const SingleChildScrollView(
        child: Text(
          'Khi đăng nhập, ứng dụng sẽ lưu lên máy chủ của FunEdu:\n'
          '• Tên gọi ở nhà, ảnh đại diện và tuổi của bé\n'
          '• Tiến độ học, sao, cấp độ, kết quả trò chơi\n'
          '• Phần thưởng và cài đặt giờ chơi ba mẹ đặt\n'
          '• Trang vở đẹp nhất của mỗi chữ; các lần tập khác chỉ ở trên máy\n\n'
          'Không chia sẻ với ai, không quảng cáo. '
          'Ba mẹ có thể xóa tài khoản online bất cứ lúc nào.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Để sau'),
        ),
        TextButton(
          key: const ValueKey('consent-online'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Đồng ý'),
        ),
      ],
    );
  }
}

Future<bool> showOnlineConsentDialog(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    builder: (_) => const OnlineConsentDialog(),
  );
  return agreed == true;
}
