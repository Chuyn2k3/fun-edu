import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/trace/trace_pad.dart';
import 'package:funedu/features/trace/trace_screen.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:material_ui/material_ui.dart';

class _FakeRepo implements GlyphRepository {
  @override
  Future<List<String>> listIds() async => ['net-ngang'];

  @override
  Future<Glyph> load(String id) async => Glyph(
        id: id,
        label: 'Nét ngang',
        strokes: [
          Stroke([
            for (var i = 0; i <= 10; i++) Point2(0.1 + 0.08 * i, 0.5),
          ]),
        ],
      );
}

Future<AppDatabase> _pump(WidgetTester t) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        glyphRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
      child: const MaterialApp(home: TraceScreen('net-ngang')),
    ),
  );
  await t.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('tracing the guide completes the glyph', (t) async {
    final db = await _pump(t);
    final o = t.getTopLeft(find.byType(TracePad));
    final s = t.getSize(find.byType(TracePad)).width;
    await t.runAsync(() async {
      await t.dragFrom(o + Offset(s * 0.1, s * 0.5), Offset(s * 0.8, 0));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pumpAndSettle();
    expect(find.text('Giỏi quá!'), findsOneWidget);
    expect(find.text('Làm lại'), findsOneWidget);
    expect(await t.runAsync(() => db.summary('net-ngang')), (total: 1, ok: 1));
    await t.tap(find.text('Làm lại'));
    await t.pumpAndSettle();
    expect(find.text('Giỏi quá!'), findsNothing);
  });

  testWidgets('reverse stroke shows direction message', (t) async {
    final db = await _pump(t);
    final o = t.getTopLeft(find.byType(TracePad));
    final s = t.getSize(find.byType(TracePad)).width;
    await t.runAsync(() async {
      await t.dragFrom(o + Offset(s * 0.9, s * 0.5), Offset(-s * 0.8, 0));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pumpAndSettle();
    expect(find.text('Bé vẽ ngược chiều rồi'), findsOneWidget);
    expect(find.text('Giỏi quá!'), findsNothing);
    expect(await t.runAsync(() => db.summary('net-ngang')), (total: 1, ok: 0));
  });

  testWidgets('second finger during a drag submits only one stroke', (t) async {
    final db = await _pump(t);
    final o = t.getTopLeft(find.byType(TracePad));
    final s = t.getSize(find.byType(TracePad)).width;
    final g1 = await t.startGesture(o + Offset(s * 0.1, s * 0.5));
    await g1.moveBy(Offset(s * 0.3, 0));
    final g2 = await t.startGesture(o + Offset(s * 0.5, s * 0.9));
    await g2.moveBy(Offset(s * 0.1, 0));
    await g2.up();
    await g1.moveBy(Offset(s * 0.5, 0));
    await g1.up();
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pumpAndSettle();
    expect(await t.runAsync(() => db.summary('net-ngang')), (total: 1, ok: 1));
  });
}
