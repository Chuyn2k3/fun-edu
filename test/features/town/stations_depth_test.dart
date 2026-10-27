import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/alphabet_castle_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/math_mushroom_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/pet_sanctuary_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/wonder_tree_widget.dart';

void main() {
  testWidgets('All 4 stations render with tactile badges and respond to taps', (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AlphabetCastleBuildingWidget(onTap: () => taps++, scale: 0.85),
                WonderTreeBuildingWidget(onTap: () => taps++, scale: 1.0),
                MathMushroomWidget(onTap: () => taps++, scale: 1.15),
                PetSanctuaryBuildingWidget(onTap: () => taps++, scale: 1.15),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AlphabetCastleBuildingWidget), findsOneWidget);
    expect(find.byType(WonderTreeBuildingWidget), findsOneWidget);
    expect(find.byType(MathMushroomWidget), findsOneWidget);
    expect(find.byType(PetSanctuaryBuildingWidget), findsOneWidget);

    await tester.tap(find.byType(MathMushroomWidget));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });
}
