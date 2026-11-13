import 'package:flutter/material.dart';

import '../../../ui/theme/depth.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/theme/tokens.dart';

/// Three big answer buttons. Reports `true` on the correct pick and `false`
/// on the first wrong pick only; wrong buttons dim and disable, the rest stay
/// tappable. Locks after the correct pick.
class ChoiceAnswers extends StatefulWidget {
  const ChoiceAnswers({
    super.key,
    required this.choices,
    required this.answer,
    required this.onAnswered,
  });

  final List<int> choices;
  final int answer;
  final ValueChanged<bool> onAnswered;

  @override
  State<ChoiceAnswers> createState() => _ChoiceAnswersState();
}

class _ChoiceAnswersState extends State<ChoiceAnswers> {
  final Set<int> _wrong = {};
  bool _reportedWrong = false;
  bool _done = false;

  @override
  void didUpdateWidget(ChoiceAnswers old) {
    super.didUpdateWidget(old);
    if (old.answer != widget.answer ||
        !_sameList(old.choices, widget.choices)) {
      _wrong.clear();
      _reportedWrong = false;
      _done = false;
    }
  }

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _pick(int v) {
    if (_done || _wrong.contains(v)) return;
    if (v == widget.answer) {
      setState(() => _done = true);
      widget.onAnswered(true);
    } else {
      setState(() => _wrong.add(v));
      if (!_reportedWrong) {
        _reportedWrong = true;
        widget.onAnswered(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < widget.choices.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _button(widget.choices[i])),
        ],
      ],
    );
  }

  Widget _button(int v) {
    final correct = _done && v == widget.answer;
    final wrong = _wrong.contains(v);
    final enabled = !_done && !wrong;
    return Opacity(
      opacity: wrong ? 0.4 : 1,
      child: Pressable(
        onTap: enabled ? () => _pick(v) : null,
        builder: (pressed) {
          final raised = raisedDecoration(
            accent: Subject.toan.color,
            tint: Subject.toan.tint,
            radius: AppRadii.tile,
            pressed: pressed,
          );
          return Container(
            height: 72,
            alignment: Alignment.center,
            decoration: correct
                ? BoxDecoration(
                    color: AppColors.primary,
                    border: raised.border,
                    borderRadius: raised.borderRadius,
                    boxShadow: raised.boxShadow,
                  )
                : raised,
            child: Text(
              '$v',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: correct ? AppColors.card : AppColors.text,
              ),
            ),
          );
        },
      ),
    );
  }
}
