import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/widgets/session_header.dart';

void main() {
  for (final scale in const [1.0, 1.6, 2.0]) {
    testWidgets('fits a small phone at text x$scale', (t) async {
      t.view.physicalSize = const Size(375, 667);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: [
          homeSummaryProvider.overrideWith((_) async => const HomeSummary(
              totalStars: 1234, learnedDaysThisWeek: 1, masteredWriting: 0)),
        ],
        child: MaterialApp(
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: SessionHeader(
                title: 'Miền Trung', step: 1, totalSteps: 5, onBack: () {}),
          ),
        ),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
      // The back target stays a kid-sized 64.
      final back = t.getSize(find.bySemanticsLabel('Quay lại'));
      expect(back.height, greaterThanOrEqualTo(64));
    });
  }
}
