import 'package:flutter/material.dart';
import 'package:fun_edu/utils/colorConst.dart';

class QuizButtonIcon extends StatelessWidget {
  const QuizButtonIcon({
    required this.option,
    super.key,
  });
  final String option;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          border: Border.all(color: baseColor, width: 2),
          borderRadius: BorderRadius.circular(30)),
      width: MediaQuery.of(context).size.width > 550
          ? 200
          : MediaQuery.of(context).size.width / 4,
      height: MediaQuery.of(context).size.width > 550
          ? 50
          : MediaQuery.of(context).size.width / 7,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: baseColorLight, // Bạn có thể thay đổi màu sắc khi lựa chọn
            fontSize: 25,
            fontWeight:
                FontWeight.bold, // Thêm hiệu ứng chuyển trọng lượng font chữ
          ),
          child: Text(option),
        ),
      ),
    );
  }
}
