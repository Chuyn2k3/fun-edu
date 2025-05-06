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

import 'package:flutter/material.dart';
import 'package:fun_edu/feature/math_feature/action_study_widget.dart';
import 'package:fun_edu/feature/math_feature/customWidget/math_learn_card.dart';
import 'package:fun_edu/feature/math_feature/home_type.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MathFeature extends StatelessWidget {
  const MathFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(context),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                children: MathLearnType.values.map((e) {
                  return _buildFeatureCard(
                    title: e.title,
                    description: e.desc,
                    color: _getColorByType(e),
                    icon: _getIconByType(e),
                    onTap: e.onTap,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBA68C8), Color(0xFFF48FB1)], // tím -> hồng pastel
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                "Toán Học 🎈",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Bé muốn học theo cách nào nhỉ?\n🤩",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA68C8), // tím pastel
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: FaIcon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorByType(MathLearnType type) {
    switch (type) {
      case MathLearnType.spaceGame:
        return Colors.deepPurple;
      case MathLearnType.quiz:
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconByType(MathLearnType type) {
    switch (type) {
      case MathLearnType.spaceGame:
        return FontAwesomeIcons.spaceShuttle;
      case MathLearnType.quiz:
        return FontAwesomeIcons.plusMinus;
      default:
        return FontAwesomeIcons.plusMinus;
    }
  }
}
