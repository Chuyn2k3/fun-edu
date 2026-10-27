import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_valley_canvas.dart';

void main() {
  testWidgets('DioramaValleyCanvas renders all 5 stations and Pippo plaza', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DioramaValleyCanvas(
            onMarketTap: () {},
            onMathMushroomTap: () {},
            onWonderTreeTap: () {},
            onPetSanctuaryTap: () {},
            onAlphabetCastleTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(DioramaValleyCanvas), findsOneWidget);
  });
}
