// import 'package:flutter/material.dart';
// import 'package:fun_edu/feature/math_feature/index.dart';
// import 'package:fun_edu/feature/math_feature/screen/ask_operator.dart';
// import 'package:fun_edu/feature/math_feature/watch_video/video_learn_math_screen.dart';
// import 'package:get/get.dart';

// enum MathLearnType { watchVideo, quiz }

// extension MyMathLearnType on MathLearnType {
//   //title
//   String get title => switch (this) {
//         MathLearnType.watchVideo => 'XEM VIDEO',
//         MathLearnType.quiz => 'LUYỆN PHÉP TÍNH',
//       };

//   //lottie
//   String get image => switch (this) {
//         MathLearnType.watchVideo => 'video_player.png',
//         MathLearnType.quiz => 'quiz.png',
//       };

//   String get desc => switch (this) {
//         MathLearnType.watchVideo => 'Học các chữ số từ 0 đến 9',
//         MathLearnType.quiz => 'Luyện tập các phép toán cộng trừ',
//       };

//   //for alignment
//   bool get leftAlign => switch (this) {
//         MathLearnType.watchVideo => true,
//         MathLearnType.quiz => false,
//       };

//   //for padding
//   EdgeInsets get padding => switch (this) {
//         MathLearnType.watchVideo => EdgeInsets.all(16),
//         MathLearnType.quiz => EdgeInsets.all(16),
//       };

//   //for navigation
//   VoidCallback get onTap {
//     return switch (this) {
//       MathLearnType.watchVideo => () =>
//           Get.to(() => const VideoLearnMathScreen()),
//       MathLearnType.quiz => () => Get.to(() => const AskOperator(isQuiz: true)),
//       //Get.snackbar("Thông báo", "Tính năng chưa hỗ trợ"),
//     };
//   }
// }
