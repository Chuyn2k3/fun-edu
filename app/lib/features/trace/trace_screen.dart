import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_database.dart';
import '../../stroke/glyph.dart';
import '../../stroke/glyph_repository.dart';
import '../../stroke/glyph_session.dart';
import '../../stroke/grader.dart';
import 'trace_pad.dart';

const String _okMessage = 'Đúng rồi!';

String _errorMessage(StrokeError error) => switch (error) {
  StrokeError.tooShort => 'Vẽ dài thêm chút nữa nhé',
  StrokeError.wrongDirection => 'Bé vẽ ngược chiều rồi',
  StrokeError.offPath => 'Đi theo đường chấm nhé',
  StrokeError.wrongOrder => 'Nét này vẽ sau nhé',
};

/// Screen where a child traces a glyph; every graded stroke is logged.
class TraceScreen extends ConsumerWidget {
  const TraceScreen(this.glyphId, {super.key});

  final String glyphId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glyph = ref.watch(glyphProvider(glyphId));
    return Scaffold(
      appBar: AppBar(title: Text(glyph.value?.label ?? '')),
      body: SafeArea(
        child: glyph.when(
          data: (g) => _TraceBody(g),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Không mở được chữ này')),
        ),
      ),
    );
  }
}

class _TraceBody extends ConsumerStatefulWidget {
  const _TraceBody(this.glyph);

  final Glyph glyph;

  @override
  ConsumerState<_TraceBody> createState() => _TraceBodyState();
}

class _TraceBodyState extends ConsumerState<_TraceBody> {
  late final GlyphSession _session = GlyphSession(widget.glyph);
  final List<Stroke> _inked = [];
  String? _message;
  int _attempts = 0;

  void _onStrokeEnd(Stroke drawn) {
    if (_session.isComplete) return;
    final index = _session.currentIndex;
    final result = _session.submit(drawn);
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      ref
          .read(databaseProvider)
          .logAttempt(
            glyphId: widget.glyph.id,
            strokeIndex: index,
            ok: result.ok,
            error: result.error?.name,
            deviation: result.deviation,
            drawn: drawn,
          )
          .catchError((Object e, StackTrace st) {
        debugPrint('logAttempt failed: $e\n$st');
            messenger.showSnackBar(
              const SnackBar(content: Text('Không lưu được kết quả')),
            );
          }),
    );
    setState(() {
      _attempts++;
      if (result.ok) {
        _inked.add(drawn);
        _message = _okMessage;
      } else {
        _message = _errorMessage(result.error!);
      }
    });
  }

  void _reset() {
    _session.reset();
    setState(() {
      _inked.clear();
      _message = null;
      _attempts = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = _session.isComplete;
    final textStyle = Theme.of(context).textTheme.headlineSmall;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: TracePad(
                  onStrokeEnd: _onStrokeEnd,
                  guide: widget.glyph.strokes,
                  inked: List.of(_inked),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(complete ? 'Giỏi quá!' : (_message ?? ''), style: textStyle),
          Text(
            _attempts == 0 ? '' : 'Lần thử: $_attempts',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: complete
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 64),
                    ),
                    onPressed: _reset,
                    child: const Text('Làm lại'),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
