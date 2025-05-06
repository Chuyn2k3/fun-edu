// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fun_edu/feature/count_shape_game/count_shape_game_screen.dart';
// import 'package:fun_edu/feature/even_old_game/even_odd_game_screen.dart';
// import 'package:fun_edu/feature/even_old_game/widget/game_mode_selector.dart';
// import 'package:fun_edu/feature/provider/game_provider.dart';
// import 'package:fun_edu/utils/base_scaffold.dart';
// import 'package:fun_edu/utils/custom_app_bar.dart';
// import 'package:fun_edu/utils/navigation_service.dart';
// import 'package:provider/provider.dart';

// class CountShapeGameSelectMode extends StatelessWidget {
//   /// {@macro even_old_game_select_mode}
//   const CountShapeGameSelectMode({
//     super.key, // ignore: unused_element
//   });
//   void onSelectMode(String mode) {
//     Navigator.push(
//       getContext,
//       MaterialPageRoute(
//         builder: (context) => ChangeNotifierProvider(
//           create: (_) => GameProvider(),
//           child: CountShapesGameScreen(mode: mode),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//     return BaseScaffold(
//       appBar: CustomAppbar.basic(
//         onTap: () {
//           Navigator.pop(context);
//         },
//         title: 'Đuổi Hình Bắt Số',
//         styleTitle: const TextStyle(
//           color: Colors.pink,
//           fontSize: 18,
//         ),
//       ),
//       body: GameModeSelector(
//         onSelectMode: onSelectMode,
//         practiceDescription: 'Không giới hạn thời gian',
//         challengeDescription: 'Độ khó tăng dần',
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/count_shape_game/count_shape_game_screen.dart';
import 'package:fun_edu/feature/provider/game_provider.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:provider/provider.dart';

class CountShapeGameSelectMode extends StatelessWidget {
  const CountShapeGameSelectMode({super.key});

  void onSelectMode(BuildContext context, String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => GameProvider(),
          child: CountShapesGameScreen(mode: mode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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
                children: [
                  _buildFeatureCard(
                    context: context,
                    title: "Chế Độ Luyện Tập 🧩",
                    description:
                        "Tự do quan sát và đếm hình, không áp lực thời gian!",
                    color: Colors.blueAccent,
                    icon: FontAwesomeIcons.eye,
                    onTap: () => onSelectMode(context, 'practice'),
                  ),
                  _buildFeatureCard(
                    context: context,
                    title: "Chế Độ Thử Thách 🎯",
                    description:
                        "Hình xuất hiện nhanh, bé phải đếm thật chuẩn nhé!",
                    color: Colors.orangeAccent,
                    icon: FontAwesomeIcons.stopwatch,
                    onTap: () => onSelectMode(context, 'challenge'),
                  ),
                ],
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
        colors: [Color(0xFFB2EBF2), Color(0xFFFFF9C4)], // xanh mint -> vàng nhạt
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.teal.withOpacity(0.15),
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
              "Đếm Hình Nhanh",
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
              "Bé muốn chơi theo cách nào nhỉ?\n🧠",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
}


  Widget _buildFeatureCard({
    required BuildContext context,
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
}
