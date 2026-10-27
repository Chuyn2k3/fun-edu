import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/town/presentation/widgets/interactive_pippo_character.dart';

void main() {
  testWidgets('InteractivePippoCharacter shows overhead bubble on tap and auto-dismisses', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: InteractivePippoCharacter()),
        ),
      ),
    );

    // Initially bubble should not be visible
    expect(find.textContaining('Chào bạn nhỏ!'), findsNothing);

    // Tap Pippo mascot
    await tester.tap(find.byType(InteractivePippoCharacter));
    await tester.pump();

    // Now bubble should be visible
    expect(find.textContaining('Chào bạn nhỏ!'), findsOneWidget);

    // After 3.5 seconds it auto-dismisses
    await tester.pump(const Duration(milliseconds: 3500));
    expect(find.textContaining('Chào bạn nhỏ!'), findsNothing);
  });
}
