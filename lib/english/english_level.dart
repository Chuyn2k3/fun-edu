/// Exercise category for each rung of the 9-level English ladder.
enum EnglishKind {
  lettersAM,
  lettersNZ,
  numbers,
  colors,
  animals,
  foodFruit,
  phonics,
  familyBody,
  greetings,
}

/// One rung of the 9-level English ladder (ages 3–7 beginner progression).
class EnglishLevel {
  const EnglishLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String id;
  final String title;
  final String subtitle;
  final EnglishKind kind;
}

const List<EnglishLevel> englishLevels = [
  EnglishLevel(
    id: 'letters-a-m',
    title: 'Chữ cái A – M',
    subtitle: 'Aa, Bb, Cc… Mm',
    kind: EnglishKind.lettersAM,
  ),
  EnglishLevel(
    id: 'letters-n-z',
    title: 'Chữ cái N – Z',
    subtitle: 'Nn, Oo, Pp… Zz',
    kind: EnglishKind.lettersNZ,
  ),
  EnglishLevel(
    id: 'numbers-1-10',
    title: 'Số đếm 1 – 10',
    subtitle: 'one, two, three… ten',
    kind: EnglishKind.numbers,
  ),
  EnglishLevel(
    id: 'colors',
    title: 'Màu sắc',
    subtitle: 'red, blue, yellow, green…',
    kind: EnglishKind.colors,
  ),
  EnglishLevel(
    id: 'animals',
    title: 'Con vật',
    subtitle: 'cat, dog, bird, fish…',
    kind: EnglishKind.animals,
  ),
  EnglishLevel(
    id: 'food-fruit',
    title: 'Trái cây & Đồ ăn',
    subtitle: 'apple, banana, milk, cake…',
    kind: EnglishKind.foodFruit,
  ),
  EnglishLevel(
    id: 'phonics',
    title: 'Âm đầu Phonics',
    subtitle: 'a-pple, b-all, c-at, s-un…',
    kind: EnglishKind.phonics,
  ),
  EnglishLevel(
    id: 'family-body',
    title: 'Gia đình & Cơ thể',
    subtitle: 'mom, dad, eye, hand…',
    kind: EnglishKind.familyBody,
  ),
  EnglishLevel(
    id: 'greetings',
    title: 'Câu chào ngắn',
    subtitle: 'Good morning, Thank you…',
    kind: EnglishKind.greetings,
  ),
];
