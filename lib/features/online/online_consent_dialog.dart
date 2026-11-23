import 'package:flutter/material.dart';

import '../../ui/feedback/feedback.dart';

/// Displays the parental consent dialog before first online sign-in (Nghị định 13/2023).
Future<bool> showOnlineConsentDialog(BuildContext context) async {
  final agreed = await showAppDialog<bool>(
    context,
    title: 'Lưu dữ liệu của bé lên máy chủ?',
    message: 'Khi đăng nhập, ứng dụng sẽ lưu lên máy chủ của FunEdu:\n'
        '• Tên gọi ở nhà, ảnh đại diện và tuổi của bé\n'
        '• Tiến độ học, sao, cấp độ, kết quả trò chơi\n'
        '• Phần thưởng và cài đặt giờ chơi ba mẹ đặt\n'
        '• Trang vở đẹp nhất của mỗi chữ; các lần tập khác chỉ ở trên máy\n'
        '• Tủ khoe của bé (nếu ba mẹ bật) và kết nối bạn đua qua mã do ba mẹ '
        'tạo hoặc nhập (không chữ tự do)\n\n'
        'Không chia sẻ với ai, không quảng cáo. '
        'Ba mẹ có thể xóa tài khoản online bất cứ lúc nào.',
    primaryLabel: 'Đồng ý',
    primaryKey: const ValueKey('consent-online'),
    secondaryLabel: 'Để sau',
    audience: AppAudience.parent,
  );
  return agreed == true;
}
