/// The pedagogical exercise kind for each rung of the Vietnamese ladder.
enum VietnameseKind {
  vowel,
  consonant,
  tone,
  syllableBuild,
  digraph,
  openRhyme,
  closedRhyme,
  wordRead,
  phraseFill,
}

/// One rung of the 9-level Vietnamese ladder (Tiếng Việt 1 progression).
class VietnameseLevel {
  const VietnameseLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String id;
  final String title;
  final String subtitle;
  final VietnameseKind kind;
}

const List<VietnameseLevel> vietnameseLevels = [
  VietnameseLevel(
    id: 'nguyen-am',
    title: 'Nguyên âm',
    subtitle: 'a, ă, â, e, ê, i, o, ô, ơ, u, ư, y',
    kind: VietnameseKind.vowel,
  ),
  VietnameseLevel(
    id: 'phu-am-don',
    title: 'Phụ âm đơn',
    subtitle: 'b, c, d, đ, g, h, k, l, m, n…',
    kind: VietnameseKind.consonant,
  ),
  VietnameseLevel(
    id: 'dau-thanh',
    title: 'Dấu thanh',
    subtitle: 'huyền, sắc, hỏi, ngã, nặng',
    kind: VietnameseKind.tone,
  ),
  VietnameseLevel(
    id: 'ghep-tieng',
    title: 'Ghép tiếng',
    subtitle: 'b + a → ba, c + ô → cô',
    kind: VietnameseKind.syllableBuild,
  ),
  VietnameseLevel(
    id: 'phu-am-ghep',
    title: 'Phụ âm ghép',
    subtitle: 'ch, gh, kh, ng, nh, ph, th, tr',
    kind: VietnameseKind.digraph,
  ),
  VietnameseLevel(
    id: 'van-xuoi',
    title: 'Vần xuôi',
    subtitle: 'ai, ao, au, âu, ay, oi, ôi, ui…',
    kind: VietnameseKind.openRhyme,
  ),
  VietnameseLevel(
    id: 'van-am-cuoi',
    title: 'Vần có âm cuối',
    subtitle: 'an, ân, en, in, on, am, ang, ong…',
    kind: VietnameseKind.closedRhyme,
  ),
  VietnameseLevel(
    id: 'doc-tu',
    title: 'Đọc từ quen',
    subtitle: 'con mèo, quả cam, ngôi sao…',
    kind: VietnameseKind.wordRead,
  ),
  VietnameseLevel(
    id: 'hoan-thien-cum',
    title: 'Điền cụm từ',
    subtitle: 'bé đi học, chim hót hay…',
    kind: VietnameseKind.phraseFill,
  ),
];
