import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_screen.dart';

void main() {
  testWidgets(
      'AnswerDesk renders a solid placeholder instead of SizedBox.shrink when questions are loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          raceControllerProvider.overrideWith(
            () => _FakeLoadingRaceController(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AnswerDesk(
              onKey: (_) {},
              onListen: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify: AnswerDesk has non-zero height and does not collapse to 0
    final deskFinder = find.byType(AnswerDesk);
    expect(deskFinder, findsOneWidget);
    final size = tester.getSize(deskFinder);
    expect(size.height, greaterThan(120));

    // Verify readiness text is shown
    expect(find.text('Sẵn sàng xuất phát!'), findsOneWidget);
  });
}

class _FakeLoadingRaceController extends RaceController {
  @override
  RaceState build() {
    return const RaceState(
      phase: RacePhase.loading,
      questions: [],
    );
  }
}
