import 'package:flutter/material.dart';

import '../../../math/math_question.dart';
import '../../../ui/theme/depth.dart';
import '../../../ui/theme/tokens.dart';
import 'choice_answers.dart';
import 'object_grid.dart';

/// Drag (or tap) a number tile into the dashed slot to match the objects.
class DragNumberMatch extends StatefulWidget {
  const DragNumberMatch({
    super.key,
    required this.q,
    required this.onAnswered,
    this.tileSize = _DragNumberMatchState._size,
    this.arrange,
  });

  final MatchQuestion q;
  final ValueChanged<bool> onAnswered;

  /// Side of the number tiles and of the slot.
  final double tileSize;

  /// When set, the objects and the slot are the question; the number tiles
  /// are stacked as the answers.
  final SplitArrange? arrange;

  @override
  State<DragNumberMatch> createState() => _DragNumberMatchState();
}

class _DragNumberMatchState extends State<DragNumberMatch> {
  static const _size = 80.0;
  bool _done = false;
  bool _reportedWrong = false;
  int? _placed;

  @override
  void didUpdateWidget(DragNumberMatch old) {
    super.didUpdateWidget(old);
    if (old.q != widget.q) {
      _done = false;
      _reportedWrong = false;
      _placed = null;
    }
  }

  void _drop(int v) {
    if (_done) return;
    if (v == widget.q.answer) {
      setState(() {
        _done = true;
        _placed = v;
      });
      widget.onAnswered(true);
    } else if (!_reportedWrong) {
      _reportedWrong = true;
      widget.onAnswered(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrange = widget.arrange;
    if (arrange != null) {
      return arrange(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ObjectGrid(count: widget.q.n),
            const SizedBox(height: 20),
            _slot(),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.q.choices.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _draggable(widget.q.choices[i]),
            ],
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ObjectGrid(count: widget.q.n),
        const SizedBox(height: 20),
        _slot(),
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

  Widget _slot() => DragTarget<int>(
        onWillAcceptWithDetails: (_) => !_done,
        onAcceptWithDetails: (d) => _drop(d.data),
        builder: (context, candidates, _) => SizedBox(
          key: const ValueKey('match-slot'),
          width: widget.tileSize,
          height: widget.tileSize,
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
      );

  Widget _draggable(int v) {
    final tile = _Tile(v, size: widget.tileSize);
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
  const _Tile(this.value, {required this.size});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: raisedDecoration(
        accent: Subject.toan.color,
        tint: Subject.toan.tint,
        radius: AppRadii.tile,
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
