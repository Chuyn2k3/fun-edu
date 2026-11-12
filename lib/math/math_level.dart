/// The kind of exercise a math level uses.
enum MathKind { count, compare, match, add, subtract, addSubtract }

/// One rung of the 9-level math ladder.
class MathLevel {
  const MathLevel({
    required this.id,
    required this.title,
    required this.kind,
    required this.max,
  });

  final String id;
  final String title;
  final MathKind kind;
  final int max;
}

const List<MathLevel> mathLevels = [
  MathLevel(id: 'dem-5', title: 'Đếm đến 5', kind: MathKind.count, max: 5),
  MathLevel(id: 'dem-10', title: 'Đếm đến 10', kind: MathKind.count, max: 10),
  MathLevel(
      id: 'so-sanh-10', title: 'So sánh', kind: MathKind.compare, max: 10),
  MathLevel(id: 'ghep-so-10', title: 'Ghép số', kind: MathKind.match, max: 10),
  MathLevel(id: 'cong-5', title: 'Cộng trong 5', kind: MathKind.add, max: 5),
  MathLevel(id: 'tru-5', title: 'Trừ trong 5', kind: MathKind.subtract, max: 5),
  MathLevel(id: 'cong-10', title: 'Cộng trong 10', kind: MathKind.add, max: 10),
  MathLevel(
      id: 'tru-10', title: 'Trừ trong 10', kind: MathKind.subtract, max: 10),
  MathLevel(
    id: 'cong-tru-20',
    title: 'Cộng trừ trong 20',
    kind: MathKind.addSubtract,
    max: 20,
  ),
];
