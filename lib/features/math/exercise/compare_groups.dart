import 'package:flutter/material.dart';

import '../../../math/math_question.dart';
import '../../../ui/theme/depth.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/theme/tokens.dart';
import 'choice_answers.dart';
import 'object_grid.dart';

/// Two white cards side by side; tapping a card picks that side.
class CompareGroups extends StatefulWidget {
  const CompareGroups({
    super.key,
    required this.q,
    required this.onAnswered,
    this.arrange,
  });

  final CompareQuestion q;
  final ValueChanged<bool> onAnswered;

  /// When set, the two groups are the answers, stacked; the question part
  /// is empty (the screen shows the prompt).
  final SplitArrange? arrange;

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
    final arrange = widget.arrange;
    if (arrange != null) {
      return arrange(
        const SizedBox.shrink(),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _card(Side.left, widget.q.left),
            const SizedBox(height: 16),
            _card(Side.right, widget.q.right),
          ],
        ),
      );
    }
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
    return Pressable(
      key: ValueKey(side == Side.left ? 'compare-left' : 'compare-right'),
      onTap: () => _pick(side),
      builder: (pressed) => Container(
        decoration: raisedDecoration(
          accent: Subject.toan.color,
          tint: Subject.toan.tint,
          pressed: pressed,
        ),
        padding: const EdgeInsets.all(12),
        child: ObjectGrid(count: count, maxPerRow: 3),
      ),
    );
  }
}
