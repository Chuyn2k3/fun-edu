import 'package:flutter/material.dart';

import '../../../math/math_question.dart';
import 'choice_answers.dart';
import 'object_grid.dart';

/// Tap objects to number them 1, 2, 3...; then pick the total below.
class TapCountBoard extends StatefulWidget {
  const TapCountBoard({
    super.key,
    required this.q,
    required this.onAnswered,
    this.answerHeight = 72,
    this.arrange,
  });

  final CountQuestion q;
  final ValueChanged<bool> onAnswered;
  final double answerHeight;
  final SplitArrange? arrange;

  @override
  State<TapCountBoard> createState() => _TapCountBoardState();
}

class _TapCountBoardState extends State<TapCountBoard> {
  final Map<int, int> _numbers = {};

  @override
  void didUpdateWidget(TapCountBoard old) {
    super.didUpdateWidget(old);
    if (old.q != widget.q) _numbers.clear();
  }

  void _tap(int i) {
    if (_numbers.containsKey(i)) return;
    setState(() => _numbers[i] = _numbers.length + 1);
  }

  @override
  Widget build(BuildContext context) {
    final arrange = widget.arrange;
    if (arrange != null) {
      return arrange(
        _grid(),
        ChoiceAnswers(
          choices: widget.q.choices,
          answer: widget.q.answer,
          onAnswered: widget.onAnswered,
          tileHeight: widget.answerHeight,
          vertical: true,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grid(),
        const SizedBox(height: 24),
        ChoiceAnswers(
          choices: widget.q.choices,
          answer: widget.q.answer,
          onAnswered: widget.onAnswered,
          tileHeight: widget.answerHeight,
        ),
      ],
    );
  }

  Widget _grid() => ObjectGrid(
        count: widget.q.n,
        marked: _numbers.keys.toSet(),
        numbers: _numbers,
        onTapObject: _tap,
      );
}
