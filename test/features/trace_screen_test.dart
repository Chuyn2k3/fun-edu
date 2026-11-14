import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/features/trace/trace_pad.dart';
import 'package:funedu/features/trace/trace_screen.dart';
import 'package:funedu/features/writing/ruled_paper.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:flutter/material.dart';

class _FakeRepo implements GlyphRepository {
  @override
  Future<List<String>> listIds() async => ['net-ngang'];

  @override
  Future<Glyph> load(String id) async => Glyph(
    id: id,
    label: 'Nét ngang',
    strokes: [
      Stroke([for (var i = 0; i <= 10; i++) Point2(0.1 + 0.08 * i, 0.5)]),
    ],
  );
}

class _AssetRepo implements GlyphRepository {
  @override
  Future<List<String>> listIds() async => ['chu-b'];

  @override
  Future<Glyph> load(String id) async => Glyph.fromJson(
      jsonDecode(File('assets/glyphs/$id.json').readAsStringSync())
          as Map<String, dynamic>);
}

class _FailingDb extends AppDatabase {
  _FailingDb() : super(NativeDatabase.memory());

  @override
  Future<void> logAttempt({
    required int kidId,
    required String glyphId,
    required int strokeIndex,
    required bool ok,
    required String? error,
    required double deviation,
    Stroke? drawn,
  }) async => throw StateError('disk full');
}

Future<AppDatabase> _pump(WidgetTester t, {AppDatabase? database}) async {
  final db = database ?? AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentKidIdProvider.overrideWith((ref) async => 1),
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
    expect(await t.runAsync(() => db.summary(1, 'net-ngang')), (total: 1, ok: 1));
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
    expect(await t.runAsync(() => db.summary(1, 'net-ngang')), (total: 1, ok: 0));
    expect(find.text('Lần thử: 1'), findsOneWidget);
    final rows = (await t.runAsync(() => db.attemptsFor(1, 'net-ngang')))!;
    expect(rows, hasLength(1));
    expect(rows.single.glyphId, 'net-ngang');
    expect(rows.single.strokeIndex, 0);
    expect(rows.single.ok, isFalse);
    expect(rows.single.error, 'wrongDirection');
    final pts = jsonDecode(rows.single.points!) as List;
    expect(pts.length, greaterThan(2));
    expect((pts.first as List).length, 2);
    expect(((pts.first as List)[0] as num).toDouble(), closeTo(0.9, 0.05));
    expect(((pts.last as List)[0] as num).toDouble(), closeTo(0.1, 0.05));
  });

  testWidgets('repeated identical error still bumps the attempt counter', (
    t,
  ) async {
    await _pump(t);
    final o = t.getTopLeft(find.byType(TracePad));
    final s = t.getSize(find.byType(TracePad)).width;
    for (var i = 1; i <= 2; i++) {
      await t.runAsync(() async {
        await t.dragFrom(o + Offset(s * 0.9, s * 0.5), Offset(-s * 0.8, 0));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await t.pumpAndSettle();
      expect(find.text('Lần thử: $i'), findsOneWidget);
    }
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
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pumpAndSettle();
    expect(await t.runAsync(() => db.summary(1, 'net-ngang')), (total: 1, ok: 1));
  });

  testWidgets('a failing log write is surfaced to the adult', (t) async {
    await _pump(t, database: _FailingDb());
    final o = t.getTopLeft(find.byType(TracePad));
    final s = t.getSize(find.byType(TracePad)).width;
    await t.runAsync(() async {
      await t.dragFrom(o + Offset(s * 0.1, s * 0.5), Offset(s * 0.8, 0));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pumpAndSettle();
    expect(find.text('Không lưu được kết quả'), findsOneWidget);
  });
  testWidgets('a letter is traced in its window on o li paper', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = _AssetRepo();
    final glyph = await repo.load('chu-b');
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentKidIdProvider.overrideWith((ref) async => 1),
          glyphRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: TraceScreen('chu-b')),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Chữ b'), findsOneWidget);
    final win = glyph.inWindow();
    expect(t.widget<TracePad>(find.byType(TracePad)).guide, win.strokes);
    expect(t.widget<RuledPaper>(find.byType(RuledPaper)).ruling, win.ruling);
  });
}
