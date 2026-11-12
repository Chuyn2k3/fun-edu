import 'dart:collection';

import 'glyph.dart';
import 'grader.dart';

/// Tracks one child's attempt at writing a [Glyph] stroke by stroke.
///
/// Call [submit] on every finger lift. A failed stroke never advances
/// [currentIndex]; a stroke that matches a later reference stroke is reported
/// as [StrokeError.wrongOrder].
class GlyphSession {
  GlyphSession(this.glyph, {this.config = const GradeConfig()});

  final Glyph glyph;
  final GradeConfig config;

  final List<StrokeResult> _history = [];
  int _index = 0;

  /// Index of the stroke the child should draw next.
  int get currentIndex => _index;

  bool get isComplete => _index >= glyph.strokes.length;

  /// Every submission result so far, oldest first (unmodifiable view).
  List<StrokeResult> get history => UnmodifiableListView(_history);

  /// Grades [drawn] against the current expected stroke.
  ///
  /// Throws [StateError] when the glyph is already complete.
  StrokeResult submit(Stroke drawn) {
    if (isComplete) throw StateError('Glyph is already complete');
    var result = gradeStroke(drawn, glyph.strokes[_index], config);
    if (result.ok) {
      _index++;
    } else {
      for (var j = _index + 1; j < glyph.strokes.length; j++) {
        final later = gradeStroke(drawn, glyph.strokes[j], config);
        if (later.ok || later.error == StrokeError.wrongDirection) {
          result = StrokeResult(
              ok: false,
              error: StrokeError.wrongOrder,
              deviation: result.deviation);
          break;
        }
      }
    }
    _history.add(result);
    return result;
  }

  /// Starts over from the first stroke and clears [history].
  void reset() {
    _index = 0;
    _history.clear();
  }
}
