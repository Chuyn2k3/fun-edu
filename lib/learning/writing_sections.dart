/// The four groups of the writing ladder, in teaching order.
enum WritingSection {
  strokes('Nét cơ bản'),
  digits('Chữ số'),
  letters('Chữ cái'),
  marks('Dấu thanh');

  const WritingSection(this.title);

  final String title;
}

/// Section of a glyph id, decided by its prefix (`net-`, `so-`, `chu-`,
/// `dau-`). Unknown ids fall into [WritingSection.strokes].
WritingSection sectionOf(String glyphId) {
  if (glyphId.startsWith('so-')) return WritingSection.digits;
  if (glyphId.startsWith('chu-')) return WritingSection.letters;
  if (glyphId.startsWith('dau-')) return WritingSection.marks;
  return WritingSection.strokes;
}

/// Splits [ids] by section, keeping their order; empty sections are omitted.
Map<WritingSection, List<String>> groupLadder(List<String> ids) {
  final out = <WritingSection, List<String>>{};
  for (final s in WritingSection.values) {
    final list = [
      for (final id in ids)
        if (sectionOf(id) == s) id,
    ];
    if (list.isNotEmpty) out[s] = list;
  }
  return out;
}
