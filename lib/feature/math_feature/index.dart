// import 'package:flutter/material.dart';
// import 'package:fun_edu/feature/math_feature/action_study_widget.dart';
// import 'package:fun_edu/feature/math_feature/banner.dart';
// import 'package:fun_edu/feature/math_feature/customWidget/math_learn_card.dart';
// import 'package:fun_edu/feature/math_feature/home_type.dart';
// import 'package:fun_edu/helper/pref.dart';
// import 'package:fun_edu/utils/base_scaffold.dart';
// import 'package:fun_edu/utils/custom_app_bar.dart';
// import 'package:fun_edu/utils/extension.dart';
// import 'package:get/get.dart';

// class MathFeature extends StatelessWidget {
//   const MathFeature({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//  var mq = MediaQuery.sizeOf(context);
//     return
//     BaseScaffold(
//       appBar: CustomAppbar.basic(
//         title: "Toán học",
//         styleTitle: TextStyle(color: Theme.of(context).lightTextColor),
//         onTap: () => Navigator.pop(context),
//       ),
//       body: ListView(
//         padding: EdgeInsets.symmetric(
//             horizontal: mq.width * .04, vertical: mq.height * .015),
//         children: MathLearnType.values.map((e) => MathLearnCard(mathLearnType: e)).toList(),
//       ),
//     )
//     ;
//   }
// }
