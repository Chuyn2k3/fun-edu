import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/pages/dino_run_screen.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';

class DinoPage extends StatelessWidget {
  const DinoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PortalMasterLayout(body: DinoRunScreen()),
    );
  }
}
