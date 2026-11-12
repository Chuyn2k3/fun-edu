import 'package:flutter/material.dart';

import '../../../math/math_question.dart';
import '../../../ui/theme/tokens.dart';
import 'object_grid.dart';

/// Two white cards side by side; tapping a card picks that side.
class CompareGroups extends StatefulWidget {
  const CompareGroups({super.key, required this.q, required this.onAnswered});

  final CompareQuestion q;
  final ValueChanged<bool> onAnswered;

  @override
  State<CompareGroups> createState() => _CompareGroupsState();
}

class _CompareGroupsState extends State<CompareGroups> {
  bool _done = false;
  bool _reportedWrong = false;

  @override
  void didUpdateWidget(CompareGroups old) {
    super.didUpdateWidget(old);
    if (old.q != widget.q) {
      _done = false;
      _reportedWrong = false;
    }
  }

  void _pick(Side s) {
    if (_done) return;
    if (s == widget.q.answer) {
      _done = true;
      widget.onAnswered(true);
    } else if (!_reportedWrong) {
      _reportedWrong = true;
      widget.onAnswered(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _card(Side.left, widget.q.left)),
        const SizedBox(width: 12),
        Expanded(child: _card(Side.right, widget.q.right)),
      ],
    );
  }

  Widget _card(Side side, int count) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(
            color: Subject.toan.color.withOpacity(0.35),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: const [AppShadows.card],
        ),
        child: InkWell(
          key: ValueKey(side == Side.left ? 'compare-left' : 'compare-right'),
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () => _pick(side),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ObjectGrid(count: count, maxPerRow: 3),
          ),
        ),
      ),
    );
  }
}
