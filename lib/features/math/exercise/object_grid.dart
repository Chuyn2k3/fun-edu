import 'package:flutter/material.dart';

import '../../../ui/assets.dart';
import '../../../ui/theme/tokens.dart';

/// A grid of [count] pictures, at most [maxPerRow] per row, cells >= 56.
class ObjectGrid extends StatelessWidget {
  const ObjectGrid({
    super.key,
    required this.count,
    this.image = AppImages.icStar,
    this.marked = const {},
    this.faded = const {},
    this.numbers = const {},
    this.onTapObject,
    this.maxPerRow = 5,
  });

  final int count;
  final String image;

  /// Indices drawn with a soft highlight.
  final Set<int> marked;

  /// Indices drawn dimmed (for example the objects taken away in a subtraction).
  final Set<int> faded;

  /// Order number badges to draw on top of objects, keyed by index.
  final Map<int, int> numbers;
  final ValueChanged<int>? onTapObject;
  final int maxPerRow;

  static const _minCell = 56.0;
  static const _maxCell = 72.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth.isFinite ? c.maxWidth : _maxCell * maxPerRow;
      final fit = ((width + _gap) / (_minCell + _gap)).floor();
      final perRow = fit.clamp(1, maxPerRow);
      final cell =
          ((width - _gap * (perRow - 1)) / perRow).clamp(_minCell, _maxCell);
      final rows = <Widget>[];
      for (var start = 0; start < count; start += perRow) {
        final end = start + perRow < count ? start + perRow : count;
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = start; i < end; i++) ...[
              if (i > start) const SizedBox(width: _gap),
              _cell(i, cell),
            ],
          ],
        ));
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: _gap),
            rows[r],
          ],
        ],
      );
    });
  }

  Widget _cell(int i, double size) {
    final badge = numbers[i];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapObject == null ? null : () => onTapObject!(i),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (marked.contains(i))
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.dot,
                  shape: BoxShape.circle,
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Opacity(
                  opacity: faded.contains(i) ? 0.3 : 1,
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
              ),
            ),
            if (badge != null)
              Container(
                key: const ValueKey('count-badge'),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.text,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.card,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
