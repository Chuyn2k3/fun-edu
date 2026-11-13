import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/features/trace/trace_pad.dart';
import 'package:funedu/features/writing/writing_screen.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/stroke/glyph.dart';

Stroke _line(double y, {bool reversed = false}) {
  final pts = [for (var i = 0; i <= 10; i++) Point2(0.1 + 0.08 * i, y)];
  return Stroke(reversed ? pts.reversed.toList() : pts);
}

final _glyph =
    Glyph(id: 'hai-net', label: 'Hai nét', strokes: [_line(0.3), _line(0.7)]);

Future<List<int>> _pump(WidgetTester t, {Size? size, Glyph? glyph}) async {
  if (size != null) {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final completed = <int>[];
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentKidIdProvider.overrideWith((ref) async => 1)
      ],
      child: MaterialApp(
        home: WritingScreen(
          glyph: glyph ?? _glyph,
          step: 1,
          totalSteps: 4,
          onCompleted: completed.add,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return completed;
}

Future<void> _draw(WidgetTester t, Stroke s) async {
  final o = t.getTopLeft(find.byType(TracePad));
  final side = t.getSize(find.byType(TracePad)).width;
  final a = s.points.first;
  final b = s.points.last;
  await t.runAsync(() async {
    await t.dragFrom(
      o + Offset(a.x * side, a.y * side),
      Offset((b.x - a.x) * side, (b.y - a.y) * side),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await t.pump();
}

void main() {
  testWidgets('full flow: ok, reversed, ok, completion fires once', (t) async {
    final completed = await _pump(t);
    expect(find.text('Bé tô nét số 1 nhé!'), findsOneWidget);
    expect(find.text('Viết Hai nét'), findsOneWidget);

    await _draw(t, _line(0.3));
    expect(find.text('Giỏi quá! Giờ tô nét 2 nhé.'), findsOneWidget);

    await _draw(t, _line(0.7, reversed: true));
    expect(find.text('Bé vẽ ngược chiều rồi'), findsOneWidget);

    await _draw(t, _line(0.7));
    expect(find.text('Bé viết Hai nét đẹp lắm!'), findsOneWidget);
    expect(completed, isEmpty);

    // A stroke during the delay is ignored and cannot re-fire completion.
    await _draw(t, _line(0.3));
    // The completion timer is created inside runAsync (real clock), so poll
    // on the real clock too.
    await t.runAsync(() async {
      for (var i = 0; i < 50 && completed.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    });
    expect(completed, [1]);
  });

  testWidgets('Xóa restarts the glyph', (t) async {
    await _pump(t);
    await _draw(t, _line(0.3));
    await t.tap(find.text('Xóa'));
    await t.pump();
    expect(find.text('Bé tô nét số 1 nhé!'), findsOneWidget);
  });

  testWidgets('Xem mẫu does not block drawing', (t) async {
    await _pump(t);
    await t.tap(find.text('Nghe'));
    await t.pump();
    expect(find.byType(SnackBar), findsNothing);
    await t.tap(find.text('Xem mẫu'));
    await t.pump(const Duration(milliseconds: 300));
    await _draw(t, _line(0.3));
    expect(find.text('Giỏi quá! Giờ tô nét 2 nhé.'), findsOneWidget);
    await t.pumpAndSettle();
  });

  testWidgets('long title is not ellipsized at 375x667', (t) async {
    final long = Glyph(
      id: 'x',
      label: 'Nét thẳng đứng',
      strokes: [_line(0.3)],
    );
    await _pump(t, size: const Size(375, 667), glyph: long);
    final render = t.renderObject<RenderParagraph>(
      find.text('Viết Nét thẳng đứng'),
    );
    expect(render.didExceedMaxLines, isFalse);
    expect(find.text("Viết Nét thẳng đứng"), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('action buttons are filled with the card color', (t) async {
    await _pump(t);
    final box = t.widget<Container>(
      find
          .ancestor(of: find.text('Nghe'), matching: find.byType(Container))
          .first,
    );
    final g = (box.decoration! as BoxDecoration).gradient! as LinearGradient;
    expect(g.colors.first, AppColors.card);
  });

  for (final size in const [Size(375, 667), Size(1024, 1366)]) {
    testWidgets('no overflow at $size', (t) async {
      await _pump(t, size: size);
      expect(t.takeException(), isNull);
      expect(find.byType(TracePad), findsOneWidget);
    });
  }

  testWidgets('a wrong stroke replays the model stroke (flash runs)',
      (t) async {
    await _pump(t);
    bool flashing() =>
        t.widgetList<AnimatedBuilder>(find.byType(AnimatedBuilder)).any((b) {
          final a = b.listenable;
          return a is AnimationController && a.isAnimating;
        });
    expect(flashing(), isFalse);
    await _draw(t, _line(0.3, reversed: true));
    expect(find.text('Bé vẽ ngược chiều rồi'), findsOneWidget);
    expect(flashing(), isTrue);
    await t.pumpAndSettle();
  });
}
