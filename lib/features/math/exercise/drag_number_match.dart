import 'package:flutter/material.dart';

import '../../../math/math_question.dart';
import '../../../ui/theme/tokens.dart';
import 'object_grid.dart';

/// Drag (or tap) a number tile into the dashed slot to match the objects.
class DragNumberMatch extends StatefulWidget {
  const DragNumberMatch({super.key, required this.q, required this.onAnswered});

  final MatchQuestion q;
  final ValueChanged<bool> onAnswered;

  @override
  State<DragNumberMatch> createState() => _DragNumberMatchState();
}

class _DragNumberMatchState extends State<DragNumberMatch> {
  static const _size = 80.0;
  bool _done = false;
  int? _placed;

  @override
  void didUpdateWidget(DragNumberMatch old) {
    super.didUpdateWidget(old);
    if (old.q != widget.q) {
      _done = false;
      _placed = null;
    }
  }

  void _drop(int v) {
    if (_done) return;
    final ok = v == widget.q.answer;
    setState(() {
      _done = true;
      if (ok) _placed = v;
    });
    widget.onAnswered(ok);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ObjectGrid(count: widget.q.n),
        const SizedBox(height: 20),
        DragTarget<int>(
          onWillAcceptWithDetails: (_) => !_done,
          onAcceptWithDetails: (d) => _drop(d.data),
          builder: (context, candidates, _) => SizedBox(
            key: const ValueKey('match-slot'),
            width: _size,
            height: _size,
            child: CustomPaint(
              painter: _DashedPainter(highlight: candidates.isNotEmpty),
              child: Center(
                child: _placed == null
                    ? null
                    : Text(
                        '$_placed',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.q.choices.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _draggable(widget.q.choices[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _draggable(int v) {
    final tile = _Tile(v);
    return GestureDetector(
      key: ValueKey('match-tile-$v'),
      onTap: () => _drop(v),
      child: _done
          ? Opacity(opacity: v == _placed ? 0.4 : 1, child: tile)
          : Draggable<int>(
              data: v,
              feedback: Material(type: MaterialType.transparency, child: tile),
              childWhenDragging: Opacity(opacity: 0.3, child: tile),
              child: tile,
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.value);
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _DragNumberMatchState._size,
      height: _DragNumberMatchState._size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        boxShadow: const [AppShadows.card],
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.highlight});
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = highlight ? AppColors.accent : AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AppRadii.tile),
      ));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.highlight != highlight;
}
