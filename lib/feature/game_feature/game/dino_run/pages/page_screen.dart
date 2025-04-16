import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/audio_manager.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/dino_run.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/models/player_data.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/models/settings.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/collision.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/game_over_menu.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/hud.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/logout.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/main_menu.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/pause_menu.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/settings_menu.dart';
import 'package:fun_edu/utils/game_time_manager.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async' as async;


class PageScreen extends StatefulWidget {
  const PageScreen({
    super.key,
  });

  @override
  State<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends State<PageScreen> {
  late DateTime _startTime;
  async.Timer? _timer;
  @override
  void initState() {
    initHive();
     _startTime = DateTime.now();

    // Kiểm tra định kỳ mỗi 1 phút
    _timer = async.Timer?.periodic(const Duration(seconds: 1), (_) async {
      final canPlay = await GameTimeManager("dinoRun").canPlay();
      if (!canPlay) {
        _timer?.cancel();

        // // Lưu thời gian đã chơi tới thời điểm này
        // final played = DateTime.now().difference(_startTime);
        // await GameTimeManager("dinoRun").addPlayTime(played);

        // Hiện thông báo và thoát game
        if (mounted) {
          showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_filled,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Hết giờ chơi!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Bé đã sử dụng hết 15 phút chơi hôm nay.\nHẹn gặp lại bé vào ngày mai nhé!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Xác nhận",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
        }
      }
    });
    super.initState();
  }

  Future<void> initHive() async {
    // For web hive does not need to be initialized.
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    }

    Hive.registerAdapter<PlayerData>(PlayerDataAdapter());
    Hive.registerAdapter<Settings>(SettingsAdapter());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        Flame.device.setPortrait();
        AudioManager.instance.stopBgm();
        return true;
      },
      child: GameWidget<DinoRun>.controlled(
        // This will dislpay a loading bar until [DinoRun] completes
        // its onLoad method.
        loadingBuilder: (conetxt) => const Center(
          child: SizedBox(
            width: 200,
            child: LinearProgressIndicator(),
          ),
        ),
        // Register all the overlays that will be used by this game.
        overlayBuilderMap: {
          MainMenu.id: (_, game) => MainMenu(game),
          CollisionOverlay.id: (_, game) => CollisionOverlay(game),
          PauseMenu.id: (_, game) => PauseMenu(game),
          Hud.id: (_, game) => Hud(game),
          GameOverMenu.id: (_, game) => GameOverMenu(game),
          SettingsMenu.id: (_, game) => SettingsMenu(game),
          LogoutMenu.id: (_, game) => LogoutMenu(game),
        },
        // By default MainMenu overlay will be active.
        initialActiveOverlays: const [MainMenu.id],
        gameFactory: () => DinoRun(
          // Use a fixed resolution camera to avoid manually
          // scaling and handling different screen sizes.
          camera: CameraComponent.withFixedResolution(
            width: 360,
            height: 180,
          ),
        ),
      ),
    );
  }

  // Ví dụ lưu lại khi thoát game
@override
void dispose() {
  final duration = DateTime.now().difference(_startTime);
  GameTimeManager("game_a").addPlayTime(duration);
  super.dispose();
}

}
