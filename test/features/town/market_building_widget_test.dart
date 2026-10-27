import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/market_building_widget.dart';

void main() {
  testWidgets('MarketBuildingWidget triggers onTap callback and renders title badge', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MarketBuildingWidget(
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tiệm Tạp Hóa Nhí'), findsOneWidget);
    await tester.tap(find.byType(MarketBuildingWidget));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tapped, isTrue);
  });
}
