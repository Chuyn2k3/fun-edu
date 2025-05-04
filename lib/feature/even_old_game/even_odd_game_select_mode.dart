import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/feature/even_old_game/even_odd_game_screen.dart';
import 'package:fun_edu/feature/even_old_game/widget/game_mode_selector.dart';
import 'package:fun_edu/feature/provider/game_provider.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:provider/provider.dart';

class EvenOddGameSelectMode extends StatelessWidget {
  /// {@macro even_old_game_select_mode}
  const EvenOddGameSelectMode({
    super.key, // ignore: unused_element
  });
  void onSelectMode(String mode) {
    Navigator.push(
      getContext,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => GameProvider(),
          child: EvenOddGameScreen(mode: mode),
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
      appBar: CustomAppbar.basic(
        onTap: () {
          Navigator.pop(context);
        },
        title: 'Phân Biệt Số Chẵn, Lẻ',
        styleTitle: const TextStyle(
          color: Colors.pink,
          fontSize: 18,
        ),
      ),
      body: GameModeSelector(
        onSelectMode: onSelectMode,
        practiceDescription: 'Không giới hạn thời gian',
        challengeDescription: 'Độ khó tăng dần',
      ),
    );
  }
}
