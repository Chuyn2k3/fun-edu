/// One step of today's lesson: a glyph to write or a math session.
sealed class LessonItem {
  const LessonItem();
}

class WritingItem extends LessonItem {
  const WritingItem(this.glyphId);

  final String glyphId;

  @override
  bool operator ==(Object other) =>
      other is WritingItem && other.glyphId == glyphId;

  @override
  int get hashCode => Object.hash('writing', glyphId);

  @override
  String toString() => 'WritingItem($glyphId)';
}

class MathItem extends LessonItem {
  const MathItem(this.levelIndex);

  final int levelIndex;

  @override
  bool operator ==(Object other) =>
      other is MathItem && other.levelIndex == levelIndex;

  @override
  int get hashCode => Object.hash('math', levelIndex);

  @override
  String toString() => 'MathItem($levelIndex)';
}
