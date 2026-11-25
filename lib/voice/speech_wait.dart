import 'dart:async';

/// Waits for Chíp to finish a line before a screen moves on, so the next
/// line never stops this one mid-sentence. [done] completes once the speech
/// has ended and at least `atLeast` has passed, and never later than
/// `atMost`. A voice that fails or is switched off only costs `atLeast`.
/// [cancel] drops the wait: [done] then never completes.
class SpeechWait {
  SpeechWait(
    Future<void> speech, {
    required Duration atLeast,
    Duration atMost = const Duration(seconds: 8),
  }) {
    speech.then((_) {}, onError: (_) {}).whenComplete(() {
      _spoken = true;
      _check();
    });
    _min = Timer(atLeast, () {
      _waited = true;
      _check();
    });
    _cap = Timer(atMost, _finish);
  }

  final _done = Completer<void>();
  late final Timer _min;
  late final Timer _cap;
  bool _spoken = false;
  bool _waited = false;
  bool _cancelled = false;

  Future<void> get done => _done.future;

  void _check() {
    if (_spoken && _waited) _finish();
  }

  void _finish() {
    _min.cancel();
    _cap.cancel();
    if (!_cancelled && !_done.isCompleted) _done.complete();
  }

  void cancel() {
    _cancelled = true;
    _min.cancel();
    _cap.cancel();
  }
}

/// [SpeechWait.done] for one-off waits.
Future<void> afterSpeech(
  Future<void> speech, {
  required Duration atLeast,
  Duration atMost = const Duration(seconds: 8),
}) =>
    SpeechWait(speech, atLeast: atLeast, atMost: atMost).done;
