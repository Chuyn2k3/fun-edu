// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fun_edu/feature/math_feature/index.dart';
// import 'package:fun_edu/utils/colorConst.dart';

// class CustomAppBar extends StatelessWidget {
//   const CustomAppBar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       leading: IconButton(
//         icon: const Icon(
//           Icons.calculate_outlined,
//           size: 50,
//           color: Colors.white,
//         ),
//         splashColor: Colors.transparent,
//         highlightColor: Colors.transparent,
//         onPressed: () {
//           if (kIsWeb) {
//             Navigator.pushAndRemoveUntil(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const MathFeature(),
//               ),
//               (route) => false,
//             );
//           }
//         },
//       ),
//       title: const Text(
//         'Mathematics ',
//         style: TextStyle(
//             color: Colors.white,
//             fontSize: 30,
//             fontWeight: FontWeight.w500,
//             letterSpacing: 2),
//       ),
//       backgroundColor: baseColor,
//       elevation: 0,
//     );
//   }
// }
