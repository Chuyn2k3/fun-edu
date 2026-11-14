import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/features/trace/trace_pad.dart';
import 'package:funedu/features/writing/ruled_paper.dart';
import 'package:funedu/features/writing/writing_screen.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/voice/speaker.dart';

import '../voice/fake_speaker.dart';

Stroke _line(double y, {bool reversed = false}) {
  final pts = [for (var i = 0; i <= 10; i++) Point2(0.1 + 0.08 * i, y)];
  return Stroke(reversed ? pts.reversed.toList() : pts);
}

final _glyph =
    Glyph(id: 'hai-net', label: 'Hai nét', strokes: [_line(0.3), _line(0.7)]);

/// A bundled glyph read straight from the asset file.
Glyph _asset(String id) => Glyph.fromJson(
    jsonDecode(File('assets/glyphs/$id.json').readAsStringSync())
        as Map<String, dynamic>);

class _FileRepo implements GlyphRepository {
  @override
  Future<List<String>> listIds() async => [];

  @override
  Future<Glyph> load(String id) async => _asset(id);
}

Future<List<int>> _pump(WidgetTester t,
    {Size? size, Glyph? glyph, FakeSpeaker? speaker}) async {
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
        currentKidIdProvider.overrideWith((ref) async => 1),
        glyphRepositoryProvider.overrideWithValue(_FileRepo()),
        if (speaker != null) speakerProvider.overrideWithValue(speaker),
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

/// Draws [s] point by point (window coordinates of the pad).
Future<void> _trace(WidgetTester t, Stroke s) async {
  final o = t.getTopLeft(find.byType(TracePad));
  final side = t.getSize(find.byType(TracePad)).width;
  Offset at(Point2 p) => o + Offset(p.x * side, p.y * side);
  await t.runAsync(() async {
    final g = await t.startGesture(at(s.points.first));
    for (final p in s.points.skip(1)) {
      await g.moveTo(at(p));
    }
    await g.up();
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

  for (final size in const [Size(1133, 744), Size(744, 1133), Size(960, 600)]) {
    testWidgets('tablet: no overflow at $size', (t) async {
      await _pump(t, size: size);
      expect(t.takeException(), isNull);
      final pad = t.getRect(find.byType(TracePad));
      expect(pad.width, pad.height);
    });
  }

  Rect buttonRect(WidgetTester t, String label) => t.getRect(find
      .ancestor(of: find.text(label), matching: find.byType(Container))
      .first);

  testWidgets('tablet landscape: pad left, Chip card and stacked buttons right',
      (t) async {
    await _pump(t, size: const Size(1366, 1024));
    final pad = t.getRect(find.byType(TracePad));
    expect(pad.width, pad.height);
    expect(pad.height, greaterThan(800));
    final card = t.getRect(find.byKey(const ValueKey('writing-chip-card')));
    expect(pad.right, lessThan(card.left));
    final chip = t.getRect(find.byKey(const ValueKey('writing-chip-image')));
    expect(chip.height, greaterThanOrEqualTo(220));
    final rects = [
      for (final l in ['Xem mẫu', 'Nghe', 'Xóa']) buttonRect(t, l)
    ];
    for (final r in rects) {
      expect(r.height, greaterThanOrEqualTo(80));
      expect(r.left, greaterThan(pad.right));
      expect((r.left - rects.first.left).abs(), lessThanOrEqualTo(1));
    }
    expect(rects[1].top, greaterThan(rects[0].bottom));
    expect(rects[2].top, greaterThan(rects[1].bottom));
    expect(rects[0].top, greaterThan(card.bottom));
    expect(find.text('Nét 1/2'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('tablet portrait: buttons in one row below the pad', (t) async {
    await _pump(t, size: const Size(1024, 1366));
    final pad = t.getRect(find.byType(TracePad));
    expect(pad.width, pad.height);
    expect(pad.width, 1024 - 96);
    final rects = [
      for (final l in ['Xem mẫu', 'Nghe', 'Xóa']) buttonRect(t, l)
    ];
    for (final r in rects) {
      expect(r.top, greaterThan(pad.bottom));
      expect((r.top - rects.first.top).abs(), lessThanOrEqualTo(1));
      expect(r.height, greaterThanOrEqualTo(80));
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('rotating mid-stroke discards the stroke without errors',
      (t) async {
    final completed = await _pump(t, size: const Size(1366, 1024));
    final o = t.getTopLeft(find.byType(TracePad));
    final side = t.getSize(find.byType(TracePad)).width;
    final g = await t.startGesture(o + Offset(0.1 * side, 0.3 * side));
    await g.moveBy(Offset(0.2 * side, 0));
    await t.pump();
    t.view.physicalSize = const Size(1024, 1366);
    await t.pump();
    await g.moveBy(Offset(0.2 * side, 0));
    await g.up();
    await t.pump();
    expect(t.takeException(), isNull);
    final pad = t.getRect(find.byType(TracePad));
    expect(pad.width, pad.height);
    expect(find.text('Bé tô nét số 1 nhé!'), findsOneWidget);
    expect(find.text('Giỏi quá! Giờ tô nét 2 nhé.'), findsNothing);
    expect(completed, isEmpty);
    await t.pumpAndSettle();
  });

  testWidgets('switching tablet <-> phone (split view) does not re-speak',
      (t) async {
    t.view.physicalSize = const Size(1366, 1024);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fake = FakeSpeaker();
    await t.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        speakerProvider.overrideWithValue(fake),
        currentKidIdProvider.overrideWith((ref) async => 1),
      ],
      child: MaterialApp(
        home: WritingScreen(
          glyph: _glyph,
          step: 1,
          totalSteps: 4,
          onCompleted: (_) {},
        ),
      ),
    ));
    await t.pumpAndSettle();
    final first = List.of(fake.spoken);
    expect(first, isNotEmpty);
    for (final size in const [
      Size(500, 1366),
      Size(1366, 1024),
      Size(1024, 1366),
      Size(500, 1366),
    ]) {
      t.view.physicalSize = size;
      await t.pumpAndSettle();
    }
    expect(fake.spoken, first);
    expect(t.takeException(), isNull);
  });
  group('letters on o li', () {
    testWidgets('chu-b: windowed guide and ruling; tracing finishes it',
        (t) async {
      final glyph = _asset('chu-b');
      final win = glyph.inWindow();
      final completed = await _pump(t, glyph: glyph);
      final pad = t.widget<TracePad>(find.byType(TracePad));
      expect(pad.guide, win.strokes);
      final paper = t.widget<RuledPaper>(find.byType(RuledPaper));
      expect(paper.ruling, win.ruling);
      expect(find.text('Viết Chữ b'), findsOneWidget);
      for (final s in win.strokes) {
        await _trace(t, s);
      }
      expect(find.textContaining('đẹp lắm'), findsOneWidget);
      await t.runAsync(() async {
        for (var i = 0; i < 50 && completed.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      expect(completed, [0]);
    });

    testWidgets('chu-i: the dot stroke can be traced and the hint survives',
        (t) async {
      final win = _asset('chu-i').inWindow();
      expect(win.strokes.last.points, hasLength(1));
      final completed = await _pump(t, glyph: _asset('chu-i'));
      await _trace(t, win.strokes.first);
      await t.tap(find.text('Xem mẫu'));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      await t.pumpAndSettle();
      final p = win.strokes.last.points.single;
      final o = t.getTopLeft(find.byType(TracePad));
      final side = t.getSize(find.byType(TracePad)).width;
      await t.runAsync(() async {
        await t.tapAt(o + Offset(p.x * side, p.y * side));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await t.pump();
      expect(find.textContaining('đẹp lắm'), findsOneWidget);
      await t.runAsync(() async {
        for (var i = 0; i < 50 && completed.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      expect(completed, [0]);
    });

    testWidgets('dau-sac: faint chu-a under the guide, never graded',
        (t) async {
      final mark = _asset('dau-sac');
      await _pump(t, glyph: mark);
      final layer = find.byKey(const ValueKey('glyph-context'));
      expect(layer, findsOneWidget);
      // The faint letter sits below the pad (earlier in the same Stack).
      final stack = t.widget<Stack>(find
          .ancestor(of: find.byType(TracePad), matching: find.byType(Stack))
          .first);
      int indexOf(Finder f) => stack.children.indexWhere((c) => find
          .descendant(of: find.byWidget(c), matching: f)
          .evaluate()
          .isNotEmpty);
      expect(indexOf(layer), lessThan(indexOf(find.byType(TracePad))));
      expect(indexOf(layer), greaterThan(indexOf(find.byType(RuledPaper))));
      // Its strokes are chu-a's, placed in dau-sac's window.
      final a = _asset('chu-a');
      final expected = Glyph(
              id: a.id, label: a.label, strokes: a.strokes, ruling: mark.ruling)
          .inWindow()
          .strokes;
      expect(t.widget<FaintLetter>(layer).strokes, expected);
      expect(t.widget<TracePad>(find.byType(TracePad)).guide,
          mark.inWindow().strokes);
      // Drawing the letter itself does not advance the mark.
      await _trace(t, expected.first);
      expect(find.textContaining('đẹp lắm'), findsNothing);
      expect(find.textContaining('Giỏi quá'), findsNothing);
      await t.pumpAndSettle();
    });

    testWidgets('speaks the name the teacher says; title keeps the label',
        (t) async {
      final fake = FakeSpeaker();
      final glyph = _asset('chu-b');
      await _pump(t, glyph: glyph, speaker: fake);
      expect(find.text('Viết Chữ b'), findsOneWidget);
      expect(fake.spoken.single, contains('chữ bờ'));
      expect(fake.spoken.single, isNot(contains('Chữ b ')));
      for (final s in glyph.inWindow().strokes) {
        await _trace(t, s);
      }
      expect(fake.spoken.last, 'Bé viết chữ bờ đẹp lắm!');
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1500)));
    });

    testWidgets('old glyph so-2: plain paper, raw strokes, old prompt',
        (t) async {
      final glyph = _asset('so-2');
      final fake = FakeSpeaker();
      await _pump(t, glyph: glyph, speaker: fake);
      expect(t.widget<RuledPaper>(find.byType(RuledPaper)).ruling, isNull);
      expect(t.widget<TracePad>(find.byType(TracePad)).guide, glyph.strokes);
      expect(find.byKey(const ValueKey('glyph-context')), findsNothing);
      expect(fake.spoken.single, 'Bé tô nét số 1 nhé!');
    });

    testWidgets('iPad rotation mid-stroke on chu-g drops the half stroke',
        (t) async {
      final glyph = _asset('chu-g');
      final win = glyph.inWindow();
      final completed = await _pump(t, size: const Size(1366, 1024), glyph: glyph);
      Rect pad() => t.getRect(find.byType(TracePad));
      final before = pad();
      final pts = win.strokes.first.points;
      Offset at(Point2 p, Rect r) =>
          r.topLeft + Offset(p.x * r.width, p.y * r.height);
      final g = await t.startGesture(at(pts.first, before));
      for (final p in pts.take(pts.length ~/ 2)) {
        await g.moveTo(at(p, before));
      }
      await t.pump();
      t.view.physicalSize = const Size(1024, 1366);
      await t.pump();
      final after = pad();
      for (final p in pts.skip(pts.length ~/ 2)) {
        await g.moveTo(at(p, after));
      }
      await g.up();
      await t.pump();
      expect(t.takeException(), isNull);
      expect(after.width, isNot(before.width));
      expect(t.getRect(find.byType(RuledPaper)).size, after.size);
      expect(find.textContaining('Giỏi quá'), findsNothing);
      expect(completed, isEmpty);
      await t.pumpAndSettle();
    });
  });
}
