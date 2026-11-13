import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('app khởi động và hiện trang chủ', (tester) async {
    await tester.runAsync(() async {
      final kid = await KidRepository(db)
          .addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
      final levels = LevelRepository(db, kidId: kid);
      await levels.setLevel('viet', 0);
      await levels.setLevel('toan', 0);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bài hôm nay'), findsOneWidget);
  });
}
