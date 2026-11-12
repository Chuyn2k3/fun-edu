import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stroke/geometry.dart';
import '../../stroke/glyph.dart';

/// Holds the strokes recorded so far in the debug recorder tool.
class RecorderController extends Notifier<List<Stroke>> {
  @override
  List<Stroke> build() => const [];

  void addStroke(Stroke stroke) => state = [...state, stroke];

  void undo() {
    if (state.isEmpty) return;
    state = state.sublist(0, state.length - 1);
  }

  void clear() => state = const [];

  /// Single-line JSON (easy to paste from a phone), 4-decimal coordinates.
  String exportJson(String id, String label) => jsonEncode(
    Glyph(
      id: id,
      label: label,
      strokes: [
        for (final s in state)
          Stroke([
            for (final p in s.points) Point2(_round4(p.x), _round4(p.y)),
          ]),
      ],
    ).toJson(),
  );

  static double _round4(double v) => double.parse(v.toStringAsFixed(4));
}

final recorderProvider = NotifierProvider<RecorderController, List<Stroke>>(
  RecorderController.new,
);
