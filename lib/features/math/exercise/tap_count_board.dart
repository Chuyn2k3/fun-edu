import 'package:flutter/material.dart';

import '../../../math/math_question.dart';
import 'choice_answers.dart';
import 'object_grid.dart';

/// Tap objects to number them 1, 2, 3...; then pick the total below.
class TapCountBoard extends StatefulWidget {
  const TapCountBoard({super.key, required this.q, required this.onAnswered});

  final CountQuestion q;
  final ValueChanged<bool> onAnswered;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ObjectGrid(
          count: widget.q.n,
          marked: _numbers.keys.toSet(),
          numbers: _numbers,
          onTapObject: _tap,
        ),
        const SizedBox(height: 24),
        ChoiceAnswers(
          choices: widget.q.choices,
          answer: widget.q.answer,
          onAnswered: widget.onAnswered,
        ),
      ],
    );
  }
}
