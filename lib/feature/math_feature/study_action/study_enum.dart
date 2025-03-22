// import 'package:flutter/material.dart';
// import 'package:fun_edu/feature/math_feature/screen/ask_operator.dart';
// import 'package:fun_edu/utils/navigation_service.dart';
// import 'package:lottie/lottie.dart';

// enum StudyEnum {
//   practice,
//   genPDF,
//   chatAI,
//   drap,
//   paint,
// }

// extension ExtStudyEnum on StudyEnum {
//   String get title {
//     switch (this) {
//       case StudyEnum.genPDF:
//         return "Tạo file PDF";
//       case StudyEnum.chatAI:
//         return "Giải toán với AI";
//       case StudyEnum.drap:
//         return "Ghép khối";
//       case StudyEnum.practice:
//         return "Bài quiz";
//       case StudyEnum.paint:
//         return "Trò chơi";
//     }
//   }

//   Widget get icon {
//     switch (this) {
//       case StudyEnum.genPDF:
//         return Lottie.asset("assets/lottie/genPDFv2.json");
//       case StudyEnum.chatAI:
//         return Lottie.asset("assets/lottie/ai_ask_me.json");
//       case StudyEnum.drap:
//         return Lottie.asset("assets/lottie/math_drag.json");
//       case StudyEnum.practice:
//         return Lottie.asset("assets/lottie/math_pratice.json");
//       case StudyEnum.paint:
//         return Lottie.asset("assets/lottie/math_paint.json");
//     }
//   }

//   Function()? get onTap {
//     switch (this) {
//       case StudyEnum.genPDF:
//       return () => Navigator.push(
//               getContext,
//               MaterialPageRoute(builder: (context) => const AskOperator(isQuiz: false)),
//             );
//       case StudyEnum.chatAI:
//       case StudyEnum.drap:
//       case StudyEnum.practice:
//       return () => Navigator.push(
//               getContext,
//               MaterialPageRoute(builder: (context) => const AskOperator(isQuiz: true)),
//             );
//       case StudyEnum.paint:
//         return () => Navigator.push(
//               getContext,
//               MaterialPageRoute(builder: (context) => const AskOperator(isQuiz: false)),
//             );
//     }
//   }
// }
