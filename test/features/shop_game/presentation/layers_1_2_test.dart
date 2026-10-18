import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/background_scenery_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart';

void main() {
  testWidgets('BackgroundSceneryLayer and AmbientParticlesLayer render without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BackgroundSceneryLayer(),
              AmbientParticlesLayer(particleCount: 10),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(BackgroundSceneryLayer), findsOneWidget);
    expect(find.byType(AmbientParticlesLayer), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
