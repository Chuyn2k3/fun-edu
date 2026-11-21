import 'package:flutter/material.dart';

import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';

const _sections = <(String, List<String>)>[
  (
    'Chúng tôi thu thập gì',
    [
      'Ứng dụng chỉ lưu những thông tin cần để bé học:',
      '• Tên gọi ở nhà của bé (không cần tên thật).',
      '• Ảnh đại diện chọn từ bộ ảnh có sẵn trong ứng dụng.',
      '• Tuổi của bé.',
      '• Tiến độ học: bài đã làm, sao, cấp độ, kết quả tập viết.',
      '• Thời gian bé dùng ứng dụng mỗi ngày.',
      '• Tên các phần thưởng do ba mẹ tự đặt.',
      '• Các nét bé viết (tọa độ từng nét), giữ lại để cải thiện việc chấm '
          'bài tập viết. Các nét này chỉ lưu trên máy này.',
    ],
  ),
  (
    'Dữ liệu lưu ở đâu',
    [
      'Mặc định toàn bộ dữ liệu chỉ nằm trên máy này và ứng dụng không gửi '
          'gì lên mạng.',
      'Nếu ba mẹ đăng nhập "Tài khoản gia đình" (Google hoặc Apple) trong Góc '
          'ba mẹ, ứng dụng lưu lên máy chủ của FunEdu: tên gọi ở nhà, ảnh đại '
          'diện, tuổi, tiến độ học và trò chơi, phần thưởng và cài đặt giờ '
          'chơi — để dùng chung trên nhiều máy. Từ tài khoản Google/Apple, '
          'chúng tôi chỉ giữ mã định danh và email của ba mẹ. Các nét bé viết '
          'không bao giờ rời khỏi máy.',
      'Ba mẹ có thể đăng xuất hoặc xóa tài khoản online bất cứ lúc nào; xóa '
          'tài khoản sẽ xóa vĩnh viễn mọi dữ liệu của gia đình trên máy chủ.',
    ],
  ),
  (
    'Chúng tôi không làm gì',
    [
      '• Không chia sẻ dữ liệu của bé với bên thứ ba.',
      '• Không quảng cáo.',
      '• Không dùng SDK theo dõi hay phân tích hành vi.',
    ],
  ),
  (
    'Quyền của ba mẹ',
    [
      'Ba mẹ có thể xem tiến bộ của bé, sửa hoặc xóa hồ sơ từng bé, và xóa '
          'toàn bộ dữ liệu bất cứ lúc nào trong Góc ba mẹ (mục Tiến bộ, Hồ '
          'sơ và Cài đặt).',
    ],
  ),
  (
    'Căn cứ pháp lý',
    [
      'Chúng tôi xử lý dữ liệu theo Nghị định 13/2023/NĐ-CP về bảo vệ dữ '
          'liệu cá nhân. Dữ liệu của trẻ em chỉ được tạo khi ba mẹ đồng ý.',
    ],
  ),
  (
    'Liên hệ',
    [
      'Mọi thắc mắc hoặc yêu cầu về dữ liệu, xin liên hệ: phamdoan060801@gmail.com',
    ],
  ),
];

/// The Vietnamese privacy policy, reachable from Góc ba mẹ > Cài đặt.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách quyền riêng tư')),
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (title, lines) in _sections) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            line,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
