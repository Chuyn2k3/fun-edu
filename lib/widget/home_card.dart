import 'package:flutter/material.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/model/home_type.dart';

class HomeCard extends StatelessWidget {
  final HomeType homeType;

  const HomeCard({super.key, required this.homeType});

  @override
  Widget build(BuildContext context) {
    Color titleColor = _getContrastingTextColor(homeType.color);
    Color descColor = titleColor.withOpacity(0.8);
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: homeType.onTap,
      child: Container(
        // width: size.height * 0.15,
        height: size.height * 0.18,
        decoration: BoxDecoration(
          color: homeType.color,
          boxShadow: [
            BoxShadow(
              blurRadius: 0,
              color: homeType.colorB,
              offset: const Offset(4, 4),
              spreadRadius: 0,
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -15,
              bottom: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.asset(
                          "assets/images/${homeType.image}", // Sử dụng đường dẫn đến ảnh trong assets
                          height: 48, // Chiều cao của ảnh
                          width: 48, // Chiều rộng của ảnh (tuỳ chọn, nếu cần)
                          // Áp dụng màu sắc nếu cần (có thể sử dụng để tô màu cho ảnh)
                        ),
                      ),
                      Expanded(
                        child: Text(
                          textAlign: TextAlign.end,
                          homeType.title,
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: 'LilitaOne',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorBase
                                .primaryText, // Màu tự động đổi để nổi bật
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      homeType.desc,
                      textAlign: TextAlign.start,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'LilitaOne',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: descColor, // Màu mô tả nhẹ hơn tiêu đề
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 4,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: homeType.colorB,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hàm xác định màu chữ tương phản để tiêu đề dễ đọc
  Color _getContrastingTextColor(Color background) {
    double luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
