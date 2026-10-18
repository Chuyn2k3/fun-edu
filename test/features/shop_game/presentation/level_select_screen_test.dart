import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/screens/level_select_screen.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/dialogs/level_summary_dialog.dart';

class MockShopGameRepository extends Mock implements IShopGameRepository {}

void main() {
  late MockShopGameRepository mockRepo;

  final testProfile = ChildProfileEntity(
    id: 'c1',
    name: 'Bé Na',
    age: 4,
    totalStars: 10,
    totalCoins: 25,
    levelStars: const {'level_1': 3, 'level_2': 2},
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRepo = MockShopGameRepository();
    when(() => mockRepo.getChildProfile()).thenAnswer((_) async => testProfile);
  });

  testWidgets('LevelSummaryDialog renders stars and action buttons', (tester) async {
    bool replayTapped = false;
    bool nextTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelSummaryDialog(
            levelNumber: 1,
            starsEarned: 3,
            coinsEarned: 15,
            onReplay: () => replayTapped = true,
            onNext: () => nextTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Hoàn thành Màn 1!'), findsOneWidget);
    expect(find.text('+15 🪙'), findsOneWidget);
    expect(find.text('Chơi lại'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.tap(find.text('Chơi lại'));
    expect(replayTapped, isTrue);

    await tester.tap(find.text('Tiếp tục'));
    expect(nextTapped, isTrue);
  });

  testWidgets('LevelSelectScreen displays 3 levels with unlock status and child profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelSelectScreen(repository: mockRepo),
      ),
    );

    // Settle async loading
    await tester.pumpAndSettle();

    expect(find.text('Bé Na'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // Stars
    expect(find.text('Tiệm Trái Cây'), findsOneWidget);
    expect(find.text('Chợ Rau Củ'), findsOneWidget);
    expect(find.text('Siêu Thị Mini'), findsOneWidget);

    // Level 3 requires 20 stars, profile has 10 -> shows locked indicator
    expect(find.textContaining('Cần 20 ⭐'), findsOneWidget);
  });
}
