import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/screens/town_screen.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_valley_canvas.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_world_hud.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_bottom_dock.dart';

void main() {
  testWidgets('TownScreen mounts DioramaValleyCanvas with Edge HUD and Bottom Dock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TownScreen(),
      ),
    );

    expect(find.byType(DioramaValleyCanvas), findsOneWidget);
    expect(find.byType(GameWorldHud), findsOneWidget);
    expect(find.byType(GameBottomDock), findsOneWidget);
  });
}
