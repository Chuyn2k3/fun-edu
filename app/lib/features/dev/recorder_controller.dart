import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  String exportJson(String id, String label) =>
      const JsonEncoder.withIndent('  ')
          .convert(Glyph(id: id, label: label, strokes: state).toJson());
}

final recorderProvider = NotifierProvider<RecorderController, List<Stroke>>(
  RecorderController.new,
);
