import 'package:flutter/material.dart';
import 'package:fun_edu/helper/pref.dart';

import '../utils/colorConst.dart';

class MainScreenCard extends StatelessWidget {
  const MainScreenCard({
    super.key,
    required TextEditingController ques,
    required this.icon,
    required this.label,
    required this.max,
    this.maxValue = 999999,
    required this.hint,
  }) : _ques = ques;

  final TextEditingController _ques;
  final IconData icon;
  final String label;
  final String hint;
  final int max;
  final int maxValue;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width > 700 ? 500 : double.infinity,
      child: TextFormField(
        maxLength: max,
        controller: _ques,
        keyboardType: TextInputType.number,
        validator: (val) {
          if (val!.isEmpty) {
            return 'Vui lòng nhập giá trị';
          } else if (int.parse(val) < 2) {
            return 'Giá trị phải lớn hơn hoặc bằng 2';
          } else if (int.parse(val) > maxValue) {
            return 'Giá trị tối đa là $maxValue';
          }
          return null;
        },
        style: TextStyle(
            color: Pref.isDarkMode ? Colors.grey : Colors.black, fontSize: 20),
        decoration: InputDecoration(
          errorStyle: const TextStyle(color: redColorLight),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: redColorLight),
            borderRadius: BorderRadius.circular(16),
          ),
          labelText: label,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: baseColorLight, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          focusColor: baseColorLight,
          prefixIcon: Icon(icon),
          hintStyle: const TextStyle(color: Colors.grey),
          hintText: hint,
          contentPadding: const EdgeInsets.all(15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
