import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/floating_counting_text.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/top_hud_bar.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart';

void main() {
  testWidgets('TopHudBar displays level, coins and handles exit', (tester) async {
    bool exitTapped = false;
    bool soundToggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopHudBar(
            levelNumber: 1,
            totalCoins: 15,
            isMuted: false,
            onExitPressed: () => exitTapped = true,
            onSoundToggled: () => soundToggled = true,
          ),
        ),
      ),
    );

    expect(find.text('Màn 1'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(exitTapped, isTrue);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    expect(soundToggled, isTrue);
  });

  testWidgets('FloatingCountingText displays counting text and animates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FloatingCountingText(text: '+1 Táo!'),
        ),
      ),
    );

    expect(find.text('+1 Táo!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('GameHudOverlay renders top bar and shows celebration banner on celebrating phase', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GameHudOverlay(
                phase: GamePhase.celebrating,
                levelNumber: 1,
                totalCoins: 10,
                isMuted: false,
                onExitPressed: () {},
                onSoundToggled: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TopHudBar), findsOneWidget);
    expect(find.text('XUẤT SẮC!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
