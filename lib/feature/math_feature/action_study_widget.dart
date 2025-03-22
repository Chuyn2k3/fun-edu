// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fun_edu/feature/math_feature/study_action/study_enum.dart';
// import 'package:fun_edu/helper/pref.dart';
// import 'package:fun_edu/utils/extension.dart';

// class ActionStudyDisplay extends StatefulWidget {
//   const ActionStudyDisplay({super.key});

//   @override
//   State<ActionStudyDisplay> createState() => _ActionStudyDisplayState();
// }

// class _ActionStudyDisplayState extends State<ActionStudyDisplay> {
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       alignment: WrapAlignment.start,
//       crossAxisAlignment: WrapCrossAlignment.center,
//       runAlignment: WrapAlignment.start,
//       runSpacing: 16,
//       children: StudyEnum.values.map((e) {
//         return FractionallySizedBox(
//           alignment: Alignment.center,
//           widthFactor: 1 / 2,
//           child: _actionItem(
//             e,
//             context,
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// Widget _actionItem(
//   StudyEnum action,
//   BuildContext context,
// ) {
//   return InkWell(
//     onTap: action.onTap,
//     child: Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(15),
//         color: Pref.isDarkMode ? Colors.blue.withOpacity(.2) : Colors.white,
//       ),
//       padding: const EdgeInsets.all(12),
//       margin: const EdgeInsets.symmetric(horizontal: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Align(
//             alignment: Alignment.center,
//             child: SizedBox(
//               height: 80,
//               width: 80,
//               child: action.icon,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             action.title,
//             style: TextStyle(
//               color: Theme.of(context).lightTextColor,
//               fontWeight: FontWeight.w900,
//               fontSize: 15,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     ),
//   );
// }
