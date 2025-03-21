import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/dino_run.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/models/player_data.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/models/settings.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/game_over_menu.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/hud.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/main_menu.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/pause_menu.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/settings_menu.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';

class PageScreen extends StatefulWidget {
  const PageScreen({
    super.key,
  });

  @override
  State<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends State<PageScreen> {
  @override
  void initState() {
    initHive();
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
    return GameWidget<DinoRun>.controlled(
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
        PauseMenu.id: (_, game) => PauseMenu(game),
        Hud.id: (_, game) => Hud(game),
        GameOverMenu.id: (_, game) => GameOverMenu(game),
        SettingsMenu.id: (_, game) => SettingsMenu(game),
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
    );
  }
}
