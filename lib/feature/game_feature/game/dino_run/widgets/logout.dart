import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/audio_manager.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/dino_run.dart';

// This represents the Logout menu overlay.
class LogoutMenu extends StatelessWidget {
  // An unique identified for this overlay.
  static const id = 'LogoutMenu';

  // Reference to parent game.
  final DinoRun game;

  const LogoutMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.black.withAlpha(100),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  const Text(
                    'Khủng Long thoát hiểm',
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Quay lại chế độ dọc trước khi chuyển màn
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.portraitDown,
                      ]);
                      Flame.device.setPortrait();
                      AudioManager.instance.stopBgm();
                      Navigator.pop(context);
// Chuyển sang màn hình khác
                      // Navigator.pushReplacement(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => const ListGamePage(),
                      //   ),
                      // );
                    },
                    child: const Text(
                      'Thoát',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
