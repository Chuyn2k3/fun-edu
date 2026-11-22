/// The kind of exercise a math level uses.
enum MathKind {
  count,
  compare,
  match,
  add,
  subtract,
  addSubtract,

  /// Tens bundles and single sticks up to 99.
  tensOnes,

  /// Reading an analogue clock: o'clock and half past.
  clock,

  /// Adding Vietnamese banknotes (in nghìn đồng).
  money,
}

/// One rung of the math ladder (9 basic levels, then 3 advanced ones).
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
  // Advanced (Toán nâng cao).
  MathLevel(id: 'so-100', title: 'Số đến 100', kind: MathKind.tensOnes, max: 99),
  MathLevel(id: 'dong-ho', title: 'Xem đồng hồ', kind: MathKind.clock, max: 12),
  MathLevel(id: 'tien', title: 'Tiền Việt Nam', kind: MathKind.money, max: 20),
];
