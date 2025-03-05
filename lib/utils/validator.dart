// import 'package:flutter_app/utils/extension.dart';

// class Validator {
//   static String? validatePassword(
//       {required String password, required String name, int minLength = 4}) {
//     if (password.isEmpty) {
//       return '$name không để trống';
//     }
//     if (password.length < minLength) {
//       return "Mật khẩu dài tối thiểu 4 ký tự";
//     }
//     return null;
//   }

//   static String? validateNumber(String value) {
//     if (value.isEmpty) {
//       return "Vui lòng nhập số";
//     } else if (!RegExp(r'^-?[0-9]+$').hasMatch(value)) {
//       return "Vui lòng nhập số hợp lệ";
//     } else {
//       return null;
//     }
//   }

//   static String? validateDouble(String value) {
//     if (value.isEmpty) {
//       return "Vui lòng nhập số";
//     }
//     final n = double.tryParse(value);
//     if (n == null) {
//       return "Vui lòng nhập số hợp lệ";
//     }
//     return null;
//   }

//   static String? validateString({required String str, required String name}) {
//     if (str.isEmpty) {
//       return "$name không để trống";
//     }
//     return null;
//   }

//   static String? validateEmail({required String str}) {
//     if (str.isValidEmail()) {
//       return null;
//     }
//     if (str.isEmpty) {
//       return "Vui lòng Email";
//     }
//     return "Email không hợp lệ";
//   }

//   static String? validatePhoneNumber(String value) {
//     Pattern pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
//     RegExp regex = RegExp(pattern.toString());
//     if (!regex.hasMatch(value)) {
//       return "Nhập số điện thoại hợp lệ";
//     } else {
//       return null;
//     }
//   }

//   static String? checkEmpty(dynamic str) {
//     if (str.isEmpty) {
//       return '_';
//     }
//     return str.toString();
//   }
// }
