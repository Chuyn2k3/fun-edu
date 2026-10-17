# Tiệm Tạp Hóa Nhí (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform `fun_edu` into "Tiệm Tạp Hóa Nhí" (Phase 1) — a 2.5D math roleplay shop game for preschoolers (3-6 yrs) featuring a 6-layer stack counter POV, drag-and-drop item collection, Vietnamese TTS voice interaction, 3 levels with 5 item types, and Hive persistence.

**Architecture:** Clean Architecture with `flutter_bloc` (Cubit + Equatable) for state management. The game screen uses a 6-layer fixed-perspective `Stack` simulating 2.5D depth (Background, Particles, Bear Character & Blackboard, Countertop & Basket, Draggable Shelf, and HUD Overlay). Services for audio and Vietnamese TTS are decoupled behind clean interfaces and registered via `GetIt`.

**Tech Stack:** Flutter 3.24.3, Dart 3.5.3, `flutter_bloc: ^8.1.1`, `equatable: ^2.0.5`, `hive_flutter: ^1.1.0`, `just_audio: ^0.9.39`, `flutter_tts: 3.4.0`, `flutter_animate: ^4.5.2`, `lottie: ^3.1.3`, `confetti: ^0.8.0`, `go_router: ^6.0.9`, `get_it: ^8.0.3`, `uuid: ^4.5.1`.

---

### Task 1: Dependencies Setup

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Update dependencies in `pubspec.yaml`**

Add `just_audio: ^0.9.39`, uncomment `uuid: ^4.5.1`, and add `bloc_test: ^9.1.5` and `mocktail: ^1.0.4` to `dev_dependencies`:

```yaml
  # In dependencies:
  just_audio: ^0.9.39
  uuid: ^4.5.1

  # In dev_dependencies:
  bloc_test: ^9.1.5
  mocktail: ^1.0.4
```

- [ ] **Step 2: Run `flutter pub get`**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter pub get`
Expected: `Process finished with exit code 0`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add just_audio, uuid, bloc_test, and mocktail dependencies"
```

---

### Task 2: Core Constants & Audio Paths

**Files:**
- Create: `lib/core/constants/app_shop_assets.dart`
- Create: `lib/core/constants/audio_paths.dart`
- Test: `test/core/constants/constants_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/constants/constants_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/core/constants/audio_paths.dart';

void main() {
  group('Shop Constants Tests', () {
    test('AppShopAssets paths should have correct asset prefixes', () {
      expect(AppShopAssets.shopBackground, contains('assets/shop_game/bg/'));
      expect(AppShopAssets.countertop, contains('assets/shop_game/bg/'));
      expect(AppShopAssets.basket, contains('assets/shop_game/props/'));
      expect(AppShopAssets.redApple, contains('assets/shop_game/items/'));
      expect(AppShopAssets.bearIdleLottie, contains('assets/shop_game/characters/'));
    });

    test('AudioPaths should define required BGM and SFX paths', () {
      expect(AudioPaths.bgmShop, contains('assets/shop_game/audio/'));
      expect(AudioPaths.sfxDragStart, contains('assets/shop_game/audio/'));
      expect(AudioPaths.sfxDropCorrect, contains('assets/shop_game/audio/'));
      expect(AudioPaths.sfxDropWrong, contains('assets/shop_game/audio/'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/core/constants/constants_test.dart`
Expected: FAIL with compilation error (classes not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/core/constants/app_shop_assets.dart`:
```dart
class AppShopAssets {
  AppShopAssets._();

  static const String baseBg = 'assets/shop_game/bg/';
  static const String baseProps = 'assets/shop_game/props/';
  static const String baseItems = 'assets/shop_game/items/';
  static const String baseHud = 'assets/shop_game/hud/';
  static const String baseChars = 'assets/shop_game/characters/';

  // Backgrounds & Surfaces
  static const String shopBackground = '${baseBg}shop_background.webp';
  static const String countertop = '${baseBg}countertop.webp';
  static const String blackboard = '${baseBg}blackboard.webp';

  // Props
  static const String basket = '${baseProps}basket.webp';
  static const String scale = '${baseProps}scale.webp';
  static const String cashRegister = '${baseProps}cash_register.webp';
  static const String coinJar = '${baseProps}coin_jar.webp';

  // Items
  static const String redApple = '${baseItems}red_apple.webp';
  static const String banana = '${baseItems}banana.webp';
  static const String pumpkin = '${baseItems}pumpkin.webp';
  static const String orange = '${baseItems}orange.webp';
  static const String watermelon = '${baseItems}watermelon.webp';
  static const String goldCoin = '${baseItems}gold_coin.webp';

  // HUD
  static const String starFilled = '${baseHud}star_filled.webp';
  static const String starEmpty = '${baseHud}star_empty.webp';
  static const String handTutor = '${baseHud}hand_tutor.webp';

  // Lottie Characters
  static const String bearIdleLottie = '${baseChars}bear_idle.json';
  static const String bearHappyLottie = '${baseChars}bear_happy.json';
}
```

Create `lib/core/constants/audio_paths.dart`:
```dart
class AudioPaths {
  AudioPaths._();

  static const String baseAudio = 'assets/shop_game/audio/';

  static const String bgmShop = '${baseAudio}bgm_shop.mp3';
  static const String sfxDragStart = '${baseAudio}sfx_drag_start.mp3';
  static const String sfxDropCorrect = '${baseAudio}sfx_drop_correct.mp3';
  static const String sfxDropWrong = '${baseAudio}sfx_drop_wrong.mp3';
  static const String sfxBasketBounce = '${baseAudio}sfx_basket_bounce.mp3';
  static const String sfxStarCollect = '${baseAudio}sfx_star_collect.mp3';
  static const String sfxCoinDrop = '${baseAudio}sfx_coin_drop.mp3';
  static const String sfxConfetti = '${baseAudio}sfx_confetti.mp3';
  static const String sfxLevelComplete = '${baseAudio}sfx_level_complete.mp3';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/core/constants/constants_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/ test/core/constants/
git commit -m "feat(shop_game): add core assets and audio constants"
```

---

### Task 3: Domain Layer — Entities & Enums

**Files:**
- Create: `lib/features/shop_game/domain/entities/item_entity.dart`
- Create: `lib/features/shop_game/domain/entities/order_entity.dart`
- Create: `lib/features/shop_game/domain/entities/level_entity.dart`
- Create: `lib/features/shop_game/domain/entities/child_profile_entity.dart`
- Create: `lib/features/shop_game/domain/entities/play_session_entity.dart`
- Test: `test/features/shop_game/domain/entities_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/domain/entities_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

void main() {
  group('Domain Entities Tests', () {
    test('ItemEntity equality and props', () {
      final item1 = ItemEntity(
        id: 'red_apple_1',
        type: ItemType.redApple,
        nameVi: 'Táo đỏ',
        assetPath: 'assets/shop_game/items/red_apple.webp',
        shelfPosition: 0,
      );
      final item2 = ItemEntity(
        id: 'red_apple_1',
        type: ItemType.redApple,
        nameVi: 'Táo đỏ',
        assetPath: 'assets/shop_game/items/red_apple.webp',
        shelfPosition: 0,
      );
      expect(item1, equals(item2));
    });

    test('OrderEntity completion logic check', () {
      final order = OrderEntity(
        id: 'order_1',
        requiredItem: ItemType.redApple,
        requiredQuantity: 3,
        difficulty: 1,
      );
      expect(order.requiredQuantity, 3);
      expect(order.requiredItem, ItemType.redApple);
    });

    test('ChildProfileEntity copyWith', () {
      final profile = ChildProfileEntity(
        id: 'child_1',
        name: 'Bé Na',
        age: 5,
        totalStars: 10,
        totalCoins: 50,
        levelStars: const {'level_1': 3},
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = profile.copyWith(totalStars: 13, totalCoins: 60);
      expect(updated.totalStars, 13);
      expect(updated.totalCoins, 60);
      expect(updated.name, 'Bé Na');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/domain/entities_test.dart`
Expected: FAIL (files missing)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/domain/entities/item_entity.dart`:
```dart
import 'package:equatable/equatable.dart';

enum ItemType {
  redApple,
  banana,
  pumpkin,
  orange,
  watermelon,
}

extension ItemTypeExtension on ItemType {
  String get vietnameseName {
    switch (this) {
      case ItemType.redApple:
        return 'Táo đỏ';
      case ItemType.banana:
        return 'Chuối';
      case ItemType.pumpkin:
        return 'Bí ngô';
      case ItemType.orange:
        return 'Cam';
      case ItemType.watermelon:
        return 'Dưa hấu';
    }
  }

  String get emoji {
    switch (this) {
      case ItemType.redApple:
        return '🍎';
      case ItemType.banana:
        return '🍌';
      case ItemType.pumpkin:
        return '🎃';
      case ItemType.orange:
        return '🍊';
      case ItemType.watermelon:
        return '🍉';
    }
  }
}

class ItemEntity extends Equatable {
  final String id;
  final ItemType type;
  final String nameVi;
  final String assetPath;
  final int shelfPosition;

  const ItemEntity({
    required this.id,
    required this.type,
    required this.nameVi,
    required this.assetPath,
    required this.shelfPosition,
  });

  @override
  List<Object?> get props => [id, type, nameVi, assetPath, shelfPosition];
}
```

Create `lib/features/shop_game/domain/entities/order_entity.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final ItemType requiredItem;
  final int requiredQuantity;
  final int difficulty;

  const OrderEntity({
    required this.id,
    required this.requiredItem,
    required this.requiredQuantity,
    this.difficulty = 1,
  });

  @override
  List<Object?> get props => [id, requiredItem, requiredQuantity, difficulty];
}
```

Create `lib/features/shop_game/domain/entities/level_entity.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

class LevelEntity extends Equatable {
  final String id;
  final String shopName;
  final List<OrderEntity> orders;
  final int starsToUnlock;

  const LevelEntity({
    required this.id,
    required this.shopName,
    required this.orders,
    required this.starsToUnlock,
  });

  @override
  List<Object?> get props => [id, shopName, orders, starsToUnlock];
}
```

Create `lib/features/shop_game/domain/entities/child_profile_entity.dart`:
```dart
import 'package:equatable/equatable.dart';

class ChildProfileEntity extends Equatable {
  final String id;
  final String name;
  final int age;
  final int totalStars;
  final int totalCoins;
  final Map<String, int> levelStars;
  final DateTime createdAt;

  const ChildProfileEntity({
    required this.id,
    required this.name,
    required this.age,
    required this.totalStars,
    required this.totalCoins,
    required this.levelStars,
    required this.createdAt,
  });

  ChildProfileEntity copyWith({
    String? id,
    String? name,
    int? age,
    int? totalStars,
    int? totalCoins,
    Map<String, int>? levelStars,
    DateTime? createdAt,
  }) {
    return ChildProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      totalStars: totalStars ?? this.totalStars,
      totalCoins: totalCoins ?? this.totalCoins,
      levelStars: levelStars ?? this.levelStars,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        totalStars,
        totalCoins,
        levelStars,
        createdAt,
      ];
}
```

Create `lib/features/shop_game/domain/entities/play_session_entity.dart`:
```dart
import 'package:equatable/equatable.dart';

class PlaySessionEntity extends Equatable {
  final String id;
  final String levelId;
  final String orderId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int errorsCount;
  final int starsEarned;
  final bool completed;

  const PlaySessionEntity({
    required this.id,
    required this.levelId,
    required this.orderId,
    required this.startedAt,
    this.completedAt,
    required this.errorsCount,
    required this.starsEarned,
    required this.completed,
  });

  @override
  List<Object?> get props => [
        id,
        levelId,
        orderId,
        startedAt,
        completedAt,
        errorsCount,
        starsEarned,
        completed,
      ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/domain/entities_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/domain/entities/ test/features/shop_game/domain/
git commit -m "feat(shop_game): add domain entities and enums"
```

---

### Task 4: Domain Layer — Repository Interface & UseCases

**Files:**
- Create: `lib/features/shop_game/domain/repositories/i_shop_game_repository.dart`
- Create: `lib/features/shop_game/domain/usecases/generate_order_usecase.dart`
- Create: `lib/features/shop_game/domain/usecases/record_play_log_usecase.dart`
- Test: `test/features/shop_game/domain/usecases_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/domain/usecases_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/generate_order_usecase.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/record_play_log_usecase.dart';

class MockShopGameRepository extends Mock implements IShopGameRepository {}

void main() {
  late MockShopGameRepository mockRepo;
  late GenerateOrderUseCase generateOrderUseCase;
  late RecordPlayLogUseCase recordPlayLogUseCase;

  setUpAll(() {
    registerFallbackValue(PlaySessionEntity(
      id: 'mock_session',
      levelId: 'level_1',
      orderId: 'order_1',
      startedAt: DateTime.now(),
      errorsCount: 0,
      starsEarned: 3,
      completed: true,
    ));
  });

  setUp(() {
    mockRepo = MockShopGameRepository();
    generateOrderUseCase = GenerateOrderUseCase(mockRepo);
    recordPlayLogUseCase = RecordPlayLogUseCase(mockRepo);
  });

  group('UseCases Tests', () {
    test('GenerateOrderUseCase returns order list for given level', () async {
      final mockLevel = LevelEntity(
        id: 'level_1',
        shopName: 'Tiệm Trái Cây',
        starsToUnlock: 0,
        orders: const [
          OrderEntity(id: 'o1', requiredItem: ItemType.redApple, requiredQuantity: 2),
          OrderEntity(id: 'o2', requiredItem: ItemType.banana, requiredQuantity: 1),
        ],
      );

      when(() => mockRepo.getLevel('level_1')).thenAnswer((_) async => mockLevel);

      final orders = await generateOrderUseCase('level_1');
      expect(orders.length, 2);
      expect(orders.first.requiredItem, ItemType.redApple);
      verify(() => mockRepo.getLevel('level_1')).called(1);
    });

    test('RecordPlayLogUseCase calls repository recordPlaySession', () async {
      final session = PlaySessionEntity(
        id: 's1',
        levelId: 'level_1',
        orderId: 'o1',
        startedAt: DateTime.now(),
        errorsCount: 1,
        starsEarned: 2,
        completed: true,
      );

      when(() => mockRepo.recordPlaySession(any())).thenAnswer((_) async => {});

      await recordPlayLogUseCase(session);
      verify(() => mockRepo.recordPlaySession(session)).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/domain/usecases_test.dart`
Expected: FAIL (files missing)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/domain/repositories/i_shop_game_repository.dart`:
```dart
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

abstract class IShopGameRepository {
  Future<ChildProfileEntity> getChildProfile();
  Future<void> saveChildProfile(ChildProfileEntity profile);
  Future<LevelEntity> getLevel(String levelId);
  Future<List<LevelEntity>> getAvailableLevels();
  Future<void> recordPlaySession(PlaySessionEntity session);
  Future<int> getTotalStars();
  Future<void> updateLevelStars(String levelId, int stars);
}
```

Create `lib/features/shop_game/domain/usecases/generate_order_usecase.dart`:
```dart
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';

class GenerateOrderUseCase {
  final IShopGameRepository _repository;

  const GenerateOrderUseCase(this._repository);

  Future<List<OrderEntity>> call(String levelId) async {
    final level = await _repository.getLevel(levelId);
    return level.orders;
  }
}
```

Create `lib/features/shop_game/domain/usecases/record_play_log_usecase.dart`:
```dart
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';

class RecordPlayLogUseCase {
  final IShopGameRepository _repository;

  const RecordPlayLogUseCase(this._repository);

  Future<void> call(PlaySessionEntity session) async {
    await _repository.recordPlaySession(session);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/domain/usecases_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/domain/ test/features/shop_game/domain/
git commit -m "feat(shop_game): add domain repository interface and usecases"
```

---

### Task 5: Data Layer — Models & Mapping

**Files:**
- Create: `lib/features/shop_game/data/models/item_model.dart`
- Create: `lib/features/shop_game/data/models/order_model.dart`
- Create: `lib/features/shop_game/data/models/level_model.dart`
- Create: `lib/features/shop_game/data/models/child_profile_model.dart`
- Create: `lib/features/shop_game/data/models/play_session_model.dart`
- Test: `test/features/shop_game/data/models_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/data/models_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/data/models/item_model.dart';
import 'package:fun_edu/features/shop_game/data/models/order_model.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

void main() {
  group('Data Models Tests', () {
    test('ItemModel toEntity and fromEntity round-trip', () {
      final entity = ItemEntity(
        id: 'apple_1',
        type: ItemType.redApple,
        nameVi: 'Táo đỏ',
        assetPath: 'assets/shop_game/items/red_apple.webp',
        shelfPosition: 0,
      );

      final model = ItemModel.fromEntity(entity);
      expect(model.id, 'apple_1');
      expect(model.toEntity(), equals(entity));
    });

    test('ChildProfileModel JSON / Map serialization', () {
      final model = ChildProfileModel(
        id: 'child_1',
        name: 'Bé Bắp',
        age: 4,
        totalStars: 5,
        totalCoins: 20,
        levelStars: {'level_1': 3},
        createdAt: DateTime(2026, 1, 1).toIso8601String(),
      );

      final map = model.toMap();
      final restored = ChildProfileModel.fromMap(map);
      expect(restored.name, 'Bé Bắp');
      expect(restored.totalStars, 5);
      expect(restored.levelStars['level_1'], 3);
    });

    test('PlaySessionModel JSON / Map serialization', () {
      final model = PlaySessionModel(
        id: 'sess_1',
        levelId: 'level_1',
        orderId: 'order_1',
        startedAt: DateTime(2026, 1, 1, 10, 0).toIso8601String(),
        completedAt: DateTime(2026, 1, 1, 10, 2).toIso8601String(),
        errorsCount: 1,
        starsEarned: 2,
        completed: true,
      );

      final map = model.toMap();
      final restored = PlaySessionModel.fromMap(map);
      expect(restored.id, 'sess_1');
      expect(restored.errorsCount, 1);
      expect(restored.completed, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/models_test.dart`
Expected: FAIL (models not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/data/models/item_model.dart`:
```dart
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class ItemModel {
  final String id;
  final ItemType type;
  final String nameVi;
  final String assetPath;
  final int shelfPosition;

  const ItemModel({
    required this.id,
    required this.type,
    required this.nameVi,
    required this.assetPath,
    required this.shelfPosition,
  });

  ItemEntity toEntity() => ItemEntity(
        id: id,
        type: type,
        nameVi: nameVi,
        assetPath: assetPath,
        shelfPosition: shelfPosition,
      );

  factory ItemModel.fromEntity(ItemEntity entity) => ItemModel(
        id: entity.id,
        type: entity.type,
        nameVi: entity.nameVi,
        assetPath: entity.assetPath,
        shelfPosition: entity.shelfPosition,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'nameVi': nameVi,
        'assetPath': assetPath,
        'shelfPosition': shelfPosition,
      };

  factory ItemModel.fromMap(Map<String, dynamic> map) => ItemModel(
        id: map['id'] as String,
        type: ItemType.values.firstWhere((e) => e.name == map['type']),
        nameVi: map['nameVi'] as String,
        assetPath: map['assetPath'] as String,
        shelfPosition: map['shelfPosition'] as int,
      );
}
```

Create `lib/features/shop_game/data/models/order_model.dart`:
```dart
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

class OrderModel {
  final String id;
  final ItemType requiredItem;
  final int requiredQuantity;
  final int difficulty;

  const OrderModel({
    required this.id,
    required this.requiredItem,
    required this.requiredQuantity,
    this.difficulty = 1,
  });

  OrderEntity toEntity() => OrderEntity(
        id: id,
        requiredItem: requiredItem,
        requiredQuantity: requiredQuantity,
        difficulty: difficulty,
      );

  factory OrderModel.fromEntity(OrderEntity entity) => OrderModel(
        id: entity.id,
        requiredItem: entity.requiredItem,
        requiredQuantity: entity.requiredQuantity,
        difficulty: entity.difficulty,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'requiredItem': requiredItem.name,
        'requiredQuantity': requiredQuantity,
        'difficulty': difficulty,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] as String,
        requiredItem: ItemType.values.firstWhere((e) => e.name == map['requiredItem']),
        requiredQuantity: map['requiredQuantity'] as int,
        difficulty: map['difficulty'] as int? ?? 1,
      );
}
```

Create `lib/features/shop_game/data/models/level_model.dart`:
```dart
import 'package:fun_edu/features/shop_game/data/models/order_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';

class LevelModel {
  final String id;
  final String shopName;
  final List<OrderModel> orders;
  final int starsToUnlock;

  const LevelModel({
    required this.id,
    required this.shopName,
    required this.orders,
    required this.starsToUnlock,
  });

  LevelEntity toEntity() => LevelEntity(
        id: id,
        shopName: shopName,
        orders: orders.map((o) => o.toEntity()).toList(),
        starsToUnlock: starsToUnlock,
      );

  factory LevelModel.fromEntity(LevelEntity entity) => LevelModel(
        id: entity.id,
        shopName: entity.shopName,
        orders: entity.orders.map((o) => OrderModel.fromEntity(o)).toList(),
        starsToUnlock: entity.starsToUnlock,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'shopName': shopName,
        'orders': orders.map((o) => o.toMap()).toList(),
        'starsToUnlock': starsToUnlock,
      };

  factory LevelModel.fromMap(Map<String, dynamic> map) => LevelModel(
        id: map['id'] as String,
        shopName: map['shopName'] as String,
        orders: (map['orders'] as List<dynamic>)
            .map((o) => OrderModel.fromMap(Map<String, dynamic>.from(o as Map)))
            .toList(),
        starsToUnlock: map['starsToUnlock'] as int,
      );
}
```

Create `lib/features/shop_game/data/models/child_profile_model.dart`:
```dart
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';

class ChildProfileModel {
  final String id;
  final String name;
  final int age;
  final int totalStars;
  final int totalCoins;
  final Map<String, int> levelStars;
  final String createdAt;

  const ChildProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.totalStars,
    required this.totalCoins,
    required this.levelStars,
    required this.createdAt,
  });

  ChildProfileEntity toEntity() => ChildProfileEntity(
        id: id,
        name: name,
        age: age,
        totalStars: totalStars,
        totalCoins: totalCoins,
        levelStars: Map<String, int>.from(levelStars),
        createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      );

  factory ChildProfileModel.fromEntity(ChildProfileEntity entity) => ChildProfileModel(
        id: entity.id,
        name: entity.name,
        age: entity.age,
        totalStars: entity.totalStars,
        totalCoins: entity.totalCoins,
        levelStars: Map<String, int>.from(entity.levelStars),
        createdAt: entity.createdAt.toIso8601String(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'totalStars': totalStars,
        'totalCoins': totalCoins,
        'levelStars': levelStars,
        'createdAt': createdAt,
      };

  factory ChildProfileModel.fromMap(Map<String, dynamic> map) => ChildProfileModel(
        id: map['id'] as String,
        name: map['name'] as String,
        age: map['age'] as int,
        totalStars: map['totalStars'] as int? ?? 0,
        totalCoins: map['totalCoins'] as int? ?? 0,
        levelStars: Map<String, int>.from(map['levelStars'] as Map? ?? {}),
        createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
}
```

Create `lib/features/shop_game/data/models/play_session_model.dart`:
```dart
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

class PlaySessionModel {
  final String id;
  final String levelId;
  final String orderId;
  final String startedAt;
  final String? completedAt;
  final int errorsCount;
  final int starsEarned;
  final bool completed;

  const PlaySessionModel({
    required this.id,
    required this.levelId,
    required this.orderId,
    required this.startedAt,
    this.completedAt,
    required this.errorsCount,
    required this.starsEarned,
    required this.completed,
  });

  PlaySessionEntity toEntity() => PlaySessionEntity(
        id: id,
        levelId: levelId,
        orderId: orderId,
        startedAt: DateTime.tryParse(startedAt) ?? DateTime.now(),
        completedAt: completedAt != null ? DateTime.tryParse(completedAt!) : null,
        errorsCount: errorsCount,
        starsEarned: starsEarned,
        completed: completed,
      );

  factory PlaySessionModel.fromEntity(PlaySessionEntity entity) => PlaySessionModel(
        id: entity.id,
        levelId: entity.levelId,
        orderId: entity.orderId,
        startedAt: entity.startedAt.toIso8601String(),
        completedAt: entity.completedAt?.toIso8601String(),
        errorsCount: entity.errorsCount,
        starsEarned: entity.starsEarned,
        completed: entity.completed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'levelId': levelId,
        'orderId': orderId,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'errorsCount': errorsCount,
        'starsEarned': starsEarned,
        'completed': completed,
      };

  factory PlaySessionModel.fromMap(Map<String, dynamic> map) => PlaySessionModel(
        id: map['id'] as String,
        levelId: map['levelId'] as String,
        orderId: map['orderId'] as String,
        startedAt: map['startedAt'] as String,
        completedAt: map['completedAt'] as String?,
        errorsCount: map['errorsCount'] as int,
        starsEarned: map['starsEarned'] as int,
        completed: map['completed'] as bool,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/models_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/data/models/ test/features/shop_game/data/
git commit -m "feat(shop_game): add data models and entity mappers"
```

---

### Task 6: Data Layer — Hardcoded Level & Shelf Items Data

**Files:**
- Create: `lib/features/shop_game/data/datasources/shop_game_levels_data.dart`
- Test: `test/features/shop_game/data/levels_data_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/data/levels_data_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

void main() {
  group('ShopGameLevelsData Tests', () {
    test('provides 3 distinct levels with correct order counts and items', () {
      final levels = ShopGameLevelsData.levels;
      expect(levels.length, 3);

      // Level 1: Tiệm Trái Cây
      final level1 = levels.firstWhere((l) => l.id == 'level_1');
      expect(level1.starsToUnlock, 0);
      expect(level1.orders.length, 5);
      expect(level1.orders[0].requiredItem, ItemType.redApple);
      expect(level1.orders[0].requiredQuantity, 2);

      // Level 2: Chợ Rau Củ
      final level2 = levels.firstWhere((l) => l.id == 'level_2');
      expect(level2.starsToUnlock, 8);
      expect(level2.orders.length, 5);

      // Level 3: Siêu Thị Mini
      final level3 = levels.firstWhere((l) => l.id == 'level_3');
      expect(level3.starsToUnlock, 20);
      expect(level3.orders.length, 6);
    });

    test('shelfItems provides all 5 item types with multiple shelf slots', () {
      final items = ShopGameLevelsData.shelfItems;
      expect(items.length, greaterThanOrEqualTo(5));
      final types = items.map((e) => e.type).toSet();
      expect(types.contains(ItemType.redApple), isTrue);
      expect(types.contains(ItemType.banana), isTrue);
      expect(types.contains(ItemType.pumpkin), isTrue);
      expect(types.contains(ItemType.orange), isTrue);
      expect(types.contains(ItemType.watermelon), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/levels_data_test.dart`
Expected: FAIL (file missing)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/data/datasources/shop_game_levels_data.dart`:
```dart
import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/features/shop_game/data/models/item_model.dart';
import 'package:fun_edu/features/shop_game/data/models/level_model.dart';
import 'package:fun_edu/features/shop_game/data/models/order_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class ShopGameLevelsData {
  ShopGameLevelsData._();

  static const List<ItemModel> shelfItems = [
    ItemModel(
      id: 'red_apple',
      type: ItemType.redApple,
      nameVi: 'Táo đỏ',
      assetPath: AppShopAssets.redApple,
      shelfPosition: 0,
    ),
    ItemModel(
      id: 'banana',
      type: ItemType.banana,
      nameVi: 'Chuối',
      assetPath: AppShopAssets.banana,
      shelfPosition: 1,
    ),
    ItemModel(
      id: 'orange',
      type: ItemType.orange,
      nameVi: 'Cam',
      assetPath: AppShopAssets.orange,
      shelfPosition: 2,
    ),
    ItemModel(
      id: 'pumpkin',
      type: ItemType.pumpkin,
      nameVi: 'Bí ngô',
      assetPath: AppShopAssets.pumpkin,
      shelfPosition: 3,
    ),
    ItemModel(
      id: 'watermelon',
      type: ItemType.watermelon,
      nameVi: 'Dưa hấu',
      assetPath: AppShopAssets.watermelon,
      shelfPosition: 4,
    ),
  ];

  static const List<LevelModel> levels = [
    // Level 1: Tiệm Trái Cây (⭐ Dễ, mở khóa: 0 sao)
    LevelModel(
      id: 'level_1',
      shopName: 'Tiệm Trái Cây',
      starsToUnlock: 0,
      orders: [
        OrderModel(id: 'l1_o1', requiredItem: ItemType.redApple, requiredQuantity: 2, difficulty: 1),
        OrderModel(id: 'l1_o2', requiredItem: ItemType.banana, requiredQuantity: 1, difficulty: 1),
        OrderModel(id: 'l1_o3', requiredItem: ItemType.orange, requiredQuantity: 2, difficulty: 1),
        OrderModel(id: 'l1_o4', requiredItem: ItemType.redApple, requiredQuantity: 3, difficulty: 1),
        OrderModel(id: 'l1_o5', requiredItem: ItemType.banana, requiredQuantity: 3, difficulty: 1),
      ],
    ),
    // Level 2: Chợ Rau Củ (⭐⭐ Vừa, mở khóa: 8 sao)
    LevelModel(
      id: 'level_2',
      shopName: 'Chợ Rau Củ',
      starsToUnlock: 8,
      orders: [
        OrderModel(id: 'l2_o1', requiredItem: ItemType.pumpkin, requiredQuantity: 2, difficulty: 2),
        OrderModel(id: 'l2_o2', requiredItem: ItemType.orange, requiredQuantity: 3, difficulty: 2),
        OrderModel(id: 'l2_o3', requiredItem: ItemType.watermelon, requiredQuantity: 2, difficulty: 2),
        OrderModel(id: 'l2_o4', requiredItem: ItemType.redApple, requiredQuantity: 4, difficulty: 2),
        OrderModel(id: 'l2_o5', requiredItem: ItemType.pumpkin, requiredQuantity: 3, difficulty: 2),
      ],
    ),
    // Level 3: Siêu Thị Mini (⭐⭐⭐ Thử thách, mở khóa: 20 sao)
    LevelModel(
      id: 'level_3',
      shopName: 'Siêu Thị Mini',
      starsToUnlock: 20,
      orders: [
        OrderModel(id: 'l3_o1', requiredItem: ItemType.orange, requiredQuantity: 3, difficulty: 3),
        OrderModel(id: 'l3_o2', requiredItem: ItemType.watermelon, requiredQuantity: 2, difficulty: 3),
        OrderModel(id: 'l3_o3', requiredItem: ItemType.banana, requiredQuantity: 4, difficulty: 3),
        OrderModel(id: 'l3_o4', requiredItem: ItemType.pumpkin, requiredQuantity: 3, difficulty: 3),
        OrderModel(id: 'l3_o5', requiredItem: ItemType.redApple, requiredQuantity: 5, difficulty: 3),
        OrderModel(id: 'l3_o6', requiredItem: ItemType.watermelon, requiredQuantity: 3, difficulty: 3),
      ],
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/levels_data_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/data/datasources/ test/features/shop_game/data/
git commit -m "feat(shop_game): add hardcoded 3 levels and shelf items content"
```

---

### Task 7: Data Layer — Local DataSource & Hive Storage

**Files:**
- Create: `lib/features/shop_game/data/datasources/local_shop_datasource.dart`
- Test: `test/features/shop_game/data/local_shop_datasource_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/data/local_shop_datasource_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';

void main() {
  late Directory tempDir;
  late LocalShopDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    dataSource = LocalShopDataSource();
    await dataSource.init();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalShopDataSource Tests', () {
    test('returns default profile when none exists and allows saving', () async {
      final profile = await dataSource.getChildProfile();
      expect(profile.name, isNotEmpty);
      expect(profile.totalStars, 0);

      final updated = ChildProfileModel(
        id: profile.id,
        name: 'Bé Tít',
        age: 5,
        totalStars: 10,
        totalCoins: 30,
        levelStars: const {'level_1': 3},
        createdAt: profile.createdAt,
      );
      await dataSource.saveChildProfile(updated);

      final reloaded = await dataSource.getChildProfile();
      expect(reloaded.name, 'Bé Tít');
      expect(reloaded.totalStars, 10);
      expect(reloaded.levelStars['level_1'], 3);
    });

    test('records and retrieves play session logs', () async {
      final session = PlaySessionModel(
        id: 'sess_123',
        levelId: 'level_1',
        orderId: 'l1_o1',
        startedAt: DateTime.now().toIso8601String(),
        errorsCount: 0,
        starsEarned: 3,
        completed: true,
      );

      await dataSource.recordPlaySession(session);
      final logs = await dataSource.getPlaySessions();
      expect(logs.length, 1);
      expect(logs.first.id, 'sess_123');
    });

    test('updates and returns level stars progress', () async {
      await dataSource.saveLevelStars('level_1', 3);
      final stars = await dataSource.getLevelStars('level_1');
      expect(stars, 3);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/local_shop_datasource_test.dart`
Expected: FAIL (class not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/data/datasources/local_shop_datasource.dart`:
```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';

class LocalShopDataSource {
  static const String profileBoxName = 'child_profile';
  static const String levelProgressBoxName = 'level_progress';
  static const String playSessionsBoxName = 'play_sessions';
  static const String appSettingsBoxName = 'app_settings';

  Box? _profileBox;
  Box? _progressBox;
  Box? _sessionsBox;
  Box? _settingsBox;

  Future<void> init() async {
    _profileBox = await Hive.openBox(profileBoxName);
    _progressBox = await Hive.openBox(levelProgressBoxName);
    _sessionsBox = await Hive.openBox(playSessionsBoxName);
    _settingsBox = await Hive.openBox(appSettingsBoxName);
  }

  Future<ChildProfileModel> getChildProfile() async {
    final raw = _profileBox?.get('current_child');
    if (raw == null) {
      final defaultProfile = ChildProfileModel(
        id: const Uuid().v4(),
        name: 'Bé',
        age: 4,
        totalStars: 0,
        totalCoins: 0,
        levelStars: const {},
        createdAt: DateTime.now().toIso8601String(),
      );
      await saveChildProfile(defaultProfile);
      return defaultProfile;
    }
    return ChildProfileModel.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> saveChildProfile(ChildProfileModel profile) async {
    await _profileBox?.put('current_child', profile.toMap());
  }

  Future<void> recordPlaySession(PlaySessionModel session) async {
    final list = _sessionsBox?.get('logs', defaultValue: <dynamic>[]) as List<dynamic>;
    final mutableList = List<dynamic>.from(list)..add(session.toMap());
    await _sessionsBox?.put('logs', mutableList);
  }

  Future<List<PlaySessionModel>> getPlaySessions() async {
    final list = _sessionsBox?.get('logs', defaultValue: <dynamic>[]) as List<dynamic>;
    return list
        .map((e) => PlaySessionModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveLevelStars(String levelId, int stars) async {
    await _progressBox?.put(levelId, stars);

    // Sync total stars into child profile
    final current = await getChildProfile();
    final updatedStarsMap = Map<String, int>.from(current.levelStars);
    final prevStars = updatedStarsMap[levelId] ?? 0;
    if (stars > prevStars) {
      updatedStarsMap[levelId] = stars;
      final newTotal = updatedStarsMap.values.fold<int>(0, (sum, v) => sum + v);
      await saveChildProfile(
        ChildProfileModel(
          id: current.id,
          name: current.name,
          age: current.age,
          totalStars: newTotal,
          totalCoins: current.totalCoins + (stars - prevStars) * 5,
          levelStars: updatedStarsMap,
          createdAt: current.createdAt,
        ),
      );
    }
  }

  Future<int> getLevelStars(String levelId) async {
    return (_progressBox?.get(levelId, defaultValue: 0) as int?) ?? 0;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/local_shop_datasource_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/data/datasources/local_shop_datasource.dart test/features/shop_game/data/local_shop_datasource_test.dart
git commit -m "feat(shop_game): add Hive local shop datasource"
```

---

### Task 8: Data Layer — Repository Implementation

**Files:**
- Create: `lib/features/shop_game/data/repositories/shop_game_repository_impl.dart`
- Test: `test/features/shop_game/data/shop_game_repository_impl_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/data/shop_game_repository_impl_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';
import 'package:fun_edu/features/shop_game/data/repositories/shop_game_repository_impl.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

class MockLocalShopDataSource extends Mock implements LocalShopDataSource {}

void main() {
  late MockLocalShopDataSource mockDataSource;
  late ShopGameRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(ChildProfileModel(
      id: 'id',
      name: 'name',
      age: 4,
      totalStars: 0,
      totalCoins: 0,
      levelStars: const {},
      createdAt: DateTime.now().toIso8601String(),
    ));
    registerFallbackValue(PlaySessionModel(
      id: 'id',
      levelId: 'level_1',
      orderId: 'o1',
      startedAt: DateTime.now().toIso8601String(),
      errorsCount: 0,
      starsEarned: 3,
      completed: true,
    ));
  });

  setUp(() {
    mockDataSource = MockLocalShopDataSource();
    repository = ShopGameRepositoryImpl(mockDataSource);
  });

  group('ShopGameRepositoryImpl Tests', () {
    test('getChildProfile converts Model to Entity', () async {
      final model = ChildProfileModel(
        id: 'c1',
        name: 'Bé Miu',
        age: 5,
        totalStars: 9,
        totalCoins: 45,
        levelStars: const {'level_1': 3},
        createdAt: DateTime(2026, 1, 1).toIso8601String(),
      );
      when(() => mockDataSource.getChildProfile()).thenAnswer((_) async => model);

      final profile = await repository.getChildProfile();
      expect(profile.name, 'Bé Miu');
      expect(profile.totalStars, 9);
    });

    test('getLevel returns level from hardcoded data', () async {
      final level = await repository.getLevel('level_1');
      expect(level.id, 'level_1');
      expect(level.orders.length, 5);
    });

    test('getAvailableLevels returns all 3 levels', () async {
      final levels = await repository.getAvailableLevels();
      expect(levels.length, 3);
    });

    test('recordPlaySession delegates to datasource', () async {
      when(() => mockDataSource.recordPlaySession(any())).thenAnswer((_) async => {});

      final session = PlaySessionEntity(
        id: 's1',
        levelId: 'level_1',
        orderId: 'o1',
        startedAt: DateTime.now(),
        errorsCount: 0,
        starsEarned: 3,
        completed: true,
      );

      await repository.recordPlaySession(session);
      verify(() => mockDataSource.recordPlaySession(any())).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/shop_game_repository_impl_test.dart`
Expected: FAIL (class not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/data/repositories/shop_game_repository_impl.dart`:
```dart
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';

class ShopGameRepositoryImpl implements IShopGameRepository {
  final LocalShopDataSource _localDataSource;

  ShopGameRepositoryImpl(this._localDataSource);

  @override
  Future<ChildProfileEntity> getChildProfile() async {
    final model = await _localDataSource.getChildProfile();
    return model.toEntity();
  }

  @override
  Future<void> saveChildProfile(ChildProfileEntity profile) async {
    final model = ChildProfileModel.fromEntity(profile);
    await _localDataSource.saveChildProfile(model);
  }

  @override
  Future<LevelEntity> getLevel(String levelId) async {
    final levelModel = ShopGameLevelsData.levels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => ShopGameLevelsData.levels.first,
    );
    return levelModel.toEntity();
  }

  @override
  Future<List<LevelEntity>> getAvailableLevels() async {
    return ShopGameLevelsData.levels.map((l) => l.toEntity()).toList();
  }

  @override
  Future<void> recordPlaySession(PlaySessionEntity session) async {
    final model = PlaySessionModel.fromEntity(session);
    await _localDataSource.recordPlaySession(model);
  }

  @override
  Future<int> getTotalStars() async {
    final profile = await getChildProfile();
    return profile.totalStars;
  }

  @override
  Future<void> updateLevelStars(String levelId, int stars) async {
    await _localDataSource.saveLevelStars(levelId, stars);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/data/shop_game_repository_impl_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/data/repositories/ test/features/shop_game/data/
git commit -m "feat(shop_game): implement ShopGameRepositoryImpl"
```

---

### Task 9: Core Services — Audio & TTS

**Files:**
- Create: `lib/core/services/tts_service.dart`
- Create: `lib/core/services/audio_service.dart`
- Test: `test/core/services/tts_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/services/tts_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

void main() {
  group('TtsScriptBuilder Tests', () {
    test('buildCustomerOrderSpeech formats correctly', () {
      final speech = TtsScriptBuilder.buildCustomerOrderSpeech('Bé Na', 3, ItemType.redApple);
      expect(speech, 'Chào bé Bé Na! Lấy giúp bác 3 quả Táo đỏ nhé!');
    });

    test('buildCountingSpeech returns Vietnamese numeral words', () {
      expect(TtsScriptBuilder.buildCountingSpeech(1), 'Một!');
      expect(TtsScriptBuilder.buildCountingSpeech(2), 'Hai!');
      expect(TtsScriptBuilder.buildCountingSpeech(3), 'Ba!');
      expect(TtsScriptBuilder.buildCountingSpeech(4), 'Bốn!');
      expect(TtsScriptBuilder.buildCountingSpeech(5), 'Năm!');
    });

    test('buildWrongItemSpeech formats correctly', () {
      final speech = TtsScriptBuilder.buildWrongItemSpeech(ItemType.banana);
      expect(speech, 'Ồ, bác cần Chuối kìa!');
    });

    test('buildOrderCompleteSpeech returns friendly compliment', () {
      expect(TtsScriptBuilder.buildOrderCompleteSpeech(), 'Giỏi lắm! Cảm ơn bé nhé!');
    });

    test('buildLevelCompleteSpeech returns celebration phrase', () {
      expect(TtsScriptBuilder.buildLevelCompleteSpeech(), 'Tuyệt vời! Bé đã hoàn thành xuất sắc!');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/core/services/tts_service_test.dart`
Expected: FAIL (class not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/core/services/tts_service.dart`:
```dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class TtsScriptBuilder {
  TtsScriptBuilder._();

  static String buildCustomerOrderSpeech(String childName, int quantity, ItemType itemType) {
    return 'Chào bé $childName! Lấy giúp bác $quantity quả ${itemType.vietnameseName} nhé!';
  }

  static String buildCountingSpeech(int count) {
    switch (count) {
      case 1:
        return 'Một!';
      case 2:
        return 'Hai!';
      case 3:
        return 'Ba!';
      case 4:
        return 'Bốn!';
      case 5:
        return 'Năm!';
      default:
        return '$count!';
    }
  }

  static String buildWrongItemSpeech(ItemType neededType) {
    return 'Ồ, bác cần ${neededType.vietnameseName} kìa!';
  }

  static String buildOrderCompleteSpeech() {
    return 'Giỏi lắm! Cảm ơn bé nhé!';
  }

  static String buildLevelCompleteSpeech() {
    return 'Tuyệt vời! Bé đã hoàn thành xuất sắc!';
  }
}

class TtsService {
  final FlutterTts _tts;
  bool _isInitialized = false;

  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('vi-VN');
      await _tts.setSpeechRate(0.45); // Slow for young children
      await _tts.setPitch(1.2);       // Friendly high tone
      await _tts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (_) {
      // Fallback handled in UI
    }
  }

  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
```

Create `lib/core/services/audio_service.dart`:
```dart
import 'package:just_audio/just_audio.dart';
import 'package:fun_edu/core/constants/audio_paths.dart';

class AudioService {
  final AudioPlayer _bgmPlayer;
  final AudioPlayer _sfxPlayer;
  bool _isMuted = false;

  AudioService({
    AudioPlayer? bgmPlayer,
    AudioPlayer? sfxPlayer,
  })  : _bgmPlayer = bgmPlayer ?? AudioPlayer(),
        _sfxPlayer = sfxPlayer ?? AudioPlayer();

  bool get isMuted => _isMuted;

  Future<void> init() async {
    await _bgmPlayer.setLoopMode(LoopMode.one);
  }

  Future<void> playBgm(String assetPath) async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.setAsset(assetPath);
      await _bgmPlayer.play();
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> playSfx(String assetPath) async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.setAsset(assetPath);
      await _sfxPlayer.play();
    } catch (_) {}
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.play();
    }
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/core/services/tts_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/tts_service.dart lib/core/services/audio_service.dart test/core/services/tts_service_test.dart
git commit -m "feat(shop_game): implement TtsService with Vietnamese scripts and AudioService"
```

---

### Task 10: Dependency Injection Setup

**Files:**
- Modify: `lib/di/locator.dart`
- Test: `test/di/locator_shop_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/di/locator_shop_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:get_it/get_it.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/generate_order_usecase.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/record_play_log_usecase.dart';
import 'package:fun_edu/di/locator.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_di_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('setupShopGameLocator registers all shop game services and use cases', () async {
    await setupShopGameLocator();

    expect(GetIt.instance.isRegistered<LocalShopDataSource>(), isTrue);
    expect(GetIt.instance.isRegistered<IShopGameRepository>(), isTrue);
    expect(GetIt.instance.isRegistered<GenerateOrderUseCase>(), isTrue);
    expect(GetIt.instance.isRegistered<RecordPlayLogUseCase>(), isTrue);
    expect(GetIt.instance.isRegistered<TtsService>(), isTrue);
    expect(GetIt.instance.isRegistered<AudioService>(), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/di/locator_shop_test.dart`
Expected: FAIL (`setupShopGameLocator` not defined)

- [ ] **Step 3: Write minimal implementation**

Add `setupShopGameLocator` to `lib/di/locator.dart`:
```dart
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/repositories/shop_game_repository_impl.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/generate_order_usecase.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/record_play_log_usecase.dart';

Future<void> setupShopGameLocator() async {
  final localDataSource = LocalShopDataSource();
  await localDataSource.init();
  serviceLocator.registerLazySingleton<LocalShopDataSource>(() => localDataSource);

  serviceLocator.registerLazySingleton<IShopGameRepository>(
      () => ShopGameRepositoryImpl(serviceLocator<LocalShopDataSource>()));

  serviceLocator.registerFactory<GenerateOrderUseCase>(
      () => GenerateOrderUseCase(serviceLocator<IShopGameRepository>()));
  serviceLocator.registerFactory<RecordPlayLogUseCase>(
      () => RecordPlayLogUseCase(serviceLocator<IShopGameRepository>()));

  serviceLocator.registerLazySingleton<TtsService>(() => TtsService());
  serviceLocator.registerLazySingleton<AudioService>(() => AudioService());
}
```
And call `await setupShopGameLocator();` inside `setupLocator()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/di/locator_shop_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/di/locator.dart test/di/locator_shop_test.dart
git commit -m "feat(shop_game): register shop game dependencies in serviceLocator"
```

---

### Task 11: Presentation Layer — ShopGameState & ShopGameCubit

**Files:**
- Create: `lib/features/shop_game/presentation/cubit/shop_game_state.dart`
- Create: `lib/features/shop_game/presentation/cubit/shop_game_cubit.dart`
- Test: `test/features/shop_game/presentation/shop_game_cubit_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/shop_game_cubit_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_cubit.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';

class MockShopGameRepository extends Mock implements IShopGameRepository {}
class MockTtsService extends Mock implements TtsService {}
class MockAudioService extends Mock implements AudioService {}

void main() {
  late MockShopGameRepository mockRepo;
  late MockTtsService mockTts;
  late MockAudioService mockAudio;

  final testOrders = [
    const OrderEntity(id: 'o1', requiredItem: ItemType.redApple, requiredQuantity: 2),
    const OrderEntity(id: 'o2', requiredItem: ItemType.banana, requiredQuantity: 1),
  ];

  final testLevel = LevelEntity(
    id: 'level_1',
    shopName: 'Tiệm Trái Cây',
    starsToUnlock: 0,
    orders: testOrders,
  );

  final testProfile = ChildProfileEntity(
    id: 'c1',
    name: 'Bé Na',
    age: 4,
    totalStars: 0,
    totalCoins: 0,
    levelStars: const {},
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(PlaySessionEntity(
      id: 'sess',
      levelId: 'level_1',
      orderId: 'o1',
      startedAt: DateTime.now(),
      errorsCount: 0,
      starsEarned: 3,
      completed: true,
    ));
  });

  setUp(() {
    mockRepo = MockShopGameRepository();
    mockTts = MockTtsService();
    mockAudio = MockAudioService();

    when(() => mockRepo.getLevel('level_1')).thenAnswer((_) async => testLevel);
    when(() => mockRepo.getChildProfile()).thenAnswer((_) async => testProfile);
    when(() => mockRepo.recordPlaySession(any())).thenAnswer((_) async => {});
    when(() => mockRepo.updateLevelStars(any(), any())).thenAnswer((_) async => {});
    when(() => mockTts.init()).thenAnswer((_) async => {});
    when(() => mockTts.speak(any())).thenAnswer((_) async => {});
    when(() => mockAudio.playBgm(any())).thenAnswer((_) async => {});
    when(() => mockAudio.playSfx(any())).thenAnswer((_) async => {});
  });

  group('ShopGameCubit Tests', () {
    test('initial state is loading', () {
      final cubit = ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      );
      expect(cubit.state.phase, GamePhase.loading);
      cubit.close();
    });

    blocTest<ShopGameCubit, ShopGameState>(
      'startGame loads level and transitions to customerEntering',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      act: (cubit) => cubit.startGame('level_1'),
      expect: () => [
        isA<ShopGameState>()
            .having((s) => s.phase, 'phase', GamePhase.customerEntering)
            .having((s) => s.currentOrder.id, 'order id', 'o1')
            .having((s) => s.childName, 'child name', 'Bé Na'),
      ],
    );

    blocTest<ShopGameCubit, ShopGameState>(
      'onCustomerEntered transitions to collectingItems',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      seed: () => ShopGameState.initial().copyWith(
        phase: GamePhase.customerEntering,
        currentOrder: testOrders.first,
        totalOrders: 2,
      ),
      act: (cubit) => cubit.onCustomerEntered(),
      expect: () => [
        isA<ShopGameState>().having((s) => s.phase, 'phase', GamePhase.collectingItems),
      ],
    );

    blocTest<ShopGameCubit, ShopGameState>(
      'addItemToBasket adds correct item, updates floatingText, and triggers celebrating on match',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      seed: () => ShopGameState.initial().copyWith(
        phase: GamePhase.collectingItems,
        currentOrder: testOrders.first, // requiredQuantity: 2, redApple
        totalOrders: 2,
      ),
      act: (cubit) async {
        const apple = ItemEntity(
          id: 'apple_1',
          type: ItemType.redApple,
          nameVi: 'Táo đỏ',
          assetPath: '',
          shelfPosition: 0,
        );
        cubit.addItemToBasket(apple);
        cubit.addItemToBasket(apple);
      },
      expect: () => [
        isA<ShopGameState>()
            .having((s) => s.basketItems.length, 'basket count 1', 1)
            .having((s) => s.floatingText, 'floating text', 'Một!'),
        isA<ShopGameState>()
            .having((s) => s.basketItems.length, 'basket count 2', 2)
            .having((s) => s.floatingText, 'floating text', 'Hai!')
            .having((s) => s.phase, 'celebrating', GamePhase.celebrating),
      ],
    );

    blocTest<ShopGameCubit, ShopGameState>(
      'rejectItem increments errorsCount without changing phase',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      seed: () => ShopGameState.initial().copyWith(
        phase: GamePhase.collectingItems,
        currentOrder: testOrders.first,
        errorsCount: 0,
      ),
      act: (cubit) => cubit.rejectItem(const ItemEntity(
        id: 'b1',
        type: ItemType.banana,
        nameVi: 'Chuối',
        assetPath: '',
        shelfPosition: 1,
      )),
      expect: () => [
        isA<ShopGameState>().having((s) => s.errorsCount, 'errorsCount', 1),
      ],
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/shop_game_cubit_test.dart`
Expected: FAIL (cubit and state not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/cubit/shop_game_state.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

enum GamePhase {
  loading,
  customerEntering,
  collectingItems,
  celebrating,
  levelComplete,
}

class ShopGameState extends Equatable {
  final GamePhase phase;
  final String levelId;
  final String childName;
  final List<OrderEntity> orders;
  final OrderEntity currentOrder;
  final List<ItemEntity> basketItems;
  final int currentOrderIndex;
  final int totalOrders;
  final int starCount;
  final int errorsCount;
  final bool isHandTutorVisible;
  final String? floatingText;
  final List<int> orderStarsHistory;

  const ShopGameState({
    required this.phase,
    required this.levelId,
    required this.childName,
    required this.orders,
    required this.currentOrder,
    required this.basketItems,
    required this.currentOrderIndex,
    required this.totalOrders,
    required this.starCount,
    required this.errorsCount,
    required this.isHandTutorVisible,
    this.floatingText,
    required this.orderStarsHistory,
  });

  factory ShopGameState.initial() => const ShopGameState(
        phase: GamePhase.loading,
        levelId: '',
        childName: 'Bé',
        orders: [],
        currentOrder: OrderEntity(id: '', requiredItem: ItemType.redApple, requiredQuantity: 1),
        basketItems: [],
        currentOrderIndex: 0,
        totalOrders: 0,
        starCount: 0,
        errorsCount: 0,
        isHandTutorVisible: false,
        floatingText: null,
        orderStarsHistory: [],
      );

  ShopGameState copyWith({
    GamePhase? phase,
    String? levelId,
    String? childName,
    List<OrderEntity>? orders,
    OrderEntity? currentOrder,
    List<ItemEntity>? basketItems,
    int? currentOrderIndex,
    int? totalOrders,
    int? starCount,
    int? errorsCount,
    bool? isHandTutorVisible,
    String? floatingText,
    List<int>? orderStarsHistory,
  }) {
    return ShopGameState(
      phase: phase ?? this.phase,
      levelId: levelId ?? this.levelId,
      childName: childName ?? this.childName,
      orders: orders ?? this.orders,
      currentOrder: currentOrder ?? this.currentOrder,
      basketItems: basketItems ?? this.basketItems,
      currentOrderIndex: currentOrderIndex ?? this.currentOrderIndex,
      totalOrders: totalOrders ?? this.totalOrders,
      starCount: starCount ?? this.starCount,
      errorsCount: errorsCount ?? this.errorsCount,
      isHandTutorVisible: isHandTutorVisible ?? this.isHandTutorVisible,
      floatingText: floatingText,
      orderStarsHistory: orderStarsHistory ?? this.orderStarsHistory,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        levelId,
        childName,
        orders,
        currentOrder,
        basketItems,
        currentOrderIndex,
        totalOrders,
        starCount,
        errorsCount,
        isHandTutorVisible,
        floatingText,
        orderStarsHistory,
      ];
}
```

Create `lib/features/shop_game/presentation/cubit/shop_game_cubit.dart`:
```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:fun_edu/core/constants/audio_paths.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';

class ShopGameCubit extends Cubit<ShopGameState> {
  final IShopGameRepository _repository;
  final TtsService _ttsService;
  final AudioService _audioService;

  DateTime? _orderStartTime;
  Timer? _idleTimer;

  ShopGameCubit({
    required IShopGameRepository repository,
    required TtsService ttsService,
    required AudioService audioService,
  })  : _repository = repository,
        _ttsService = ttsService,
        _audioService = audioService,
        super(ShopGameState.initial());

  Future<void> startGame(String levelId) async {
    emit(state.copyWith(phase: GamePhase.loading));
    await _ttsService.init();
    await _audioService.init();
    await _audioService.playBgm(AudioPaths.bgmShop);

    final level = await _repository.getLevel(levelId);
    final profile = await _repository.getChildProfile();

    final firstOrder = level.orders.isNotEmpty
        ? level.orders.first
        : const OrderEntity(id: 'o_def', requiredItem: ItemType.redApple, requiredQuantity: 1);

    _orderStartTime = DateTime.now();

    emit(state.copyWith(
      phase: GamePhase.customerEntering,
      levelId: levelId,
      childName: profile.name,
      orders: level.orders,
      currentOrder: firstOrder,
      currentOrderIndex: 0,
      totalOrders: level.orders.length,
      basketItems: const [],
      starCount: 0,
      errorsCount: 0,
      isHandTutorVisible: false,
      orderStarsHistory: const [],
    ));

    // Speak initial order
    final speech = TtsScriptBuilder.buildCustomerOrderSpeech(
      profile.name,
      firstOrder.requiredQuantity,
      firstOrder.requiredItem,
    );
    await _ttsService.speak(speech);
  }

  void onCustomerEntered() {
    emit(state.copyWith(phase: GamePhase.collectingItems));
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 7), () {
      if (state.phase == GamePhase.collectingItems) {
        emit(state.copyWith(isHandTutorVisible: true));
      }
    });
  }

  void hideHandTutor() {
    if (state.isHandTutorVisible) {
      emit(state.copyWith(isHandTutorVisible: false));
    }
    _startIdleTimer();
  }

  void addItemToBasket(ItemEntity item) {
    hideHandTutor();

    if (item.type != state.currentOrder.requiredItem) {
      rejectItem(item);
      return;
    }

    final newBasket = List<ItemEntity>.from(state.basketItems)..add(item);
    final count = newBasket.length;
    final countWord = TtsScriptBuilder.buildCountingSpeech(count);

    _audioService.playSfx(AudioPaths.sfxDropCorrect);
    _audioService.playSfx(AudioPaths.sfxBasketBounce);
    _ttsService.speak(countWord);

    if (count >= state.currentOrder.requiredQuantity) {
      // Completed this order!
      _handleOrderCompleted(newBasket, countWord);
    } else {
      emit(state.copyWith(
        basketItems: newBasket,
        floatingText: countWord,
      ));
    }
  }

  void rejectItem(ItemEntity item) {
    hideHandTutor();
    final newErrors = state.errorsCount + 1;
    _audioService.playSfx(AudioPaths.sfxDropWrong);
    final wrongSpeech = TtsScriptBuilder.buildWrongItemSpeech(state.currentOrder.requiredItem);
    _ttsService.speak(wrongSpeech);

    emit(state.copyWith(errorsCount: newErrors));
  }

  Future<void> _handleOrderCompleted(List<ItemEntity> newBasket, String countWord) async {
    _idleTimer?.cancel();

    // Calculate stars for this order:
    // 0 errors -> 3 stars, 1-2 errors -> 2 stars, 3+ -> 1 star
    final int earnedStars;
    if (state.errorsCount == 0) {
      earnedStars = 3;
    } else if (state.errorsCount <= 2) {
      earnedStars = 2;
    } else {
      earnedStars = 1;
    }

    final newHistory = List<int>.from(state.orderStarsHistory)..add(earnedStars);

    // Save play session log
    final session = PlaySessionEntity(
      id: const Uuid().v4(),
      levelId: state.levelId,
      orderId: state.currentOrder.id,
      startedAt: _orderStartTime ?? DateTime.now(),
      completedAt: DateTime.now(),
      errorsCount: state.errorsCount,
      starsEarned: earnedStars,
      completed: true,
    );
    await _repository.recordPlaySession(session);

    _audioService.playSfx(AudioPaths.sfxConfetti);
    _audioService.playSfx(AudioPaths.sfxStarCollect);
    _audioService.playSfx(AudioPaths.sfxCoinDrop);

    emit(state.copyWith(
      phase: GamePhase.celebrating,
      basketItems: newBasket,
      floatingText: countWord,
      starCount: state.starCount + earnedStars,
      orderStarsHistory: newHistory,
    ));

    await _ttsService.speak(TtsScriptBuilder.buildOrderCompleteSpeech());
  }

  Future<void> nextCustomerOrFinish() async {
    final nextIndex = state.currentOrderIndex + 1;
    if (nextIndex >= state.totalOrders) {
      // Level Completed!
      await _handleLevelCompleted();
    } else {
      final nextOrder = state.orders[nextIndex];
      _orderStartTime = DateTime.now();
      emit(state.copyWith(
        phase: GamePhase.customerEntering,
        currentOrder: nextOrder,
        currentOrderIndex: nextIndex,
        basketItems: const [],
        errorsCount: 0,
        floatingText: null,
      ));

      final speech = TtsScriptBuilder.buildCustomerOrderSpeech(
        state.childName,
        nextOrder.requiredQuantity,
        nextOrder.requiredItem,
      );
      await _ttsService.speak(speech);
    }
  }

  Future<void> _handleLevelCompleted() async {
    _idleTimer?.cancel();
    final totalOrderStars = state.orderStarsHistory.fold<int>(0, (sum, s) => sum + s);
    final avgStars = (state.orderStarsHistory.isNotEmpty)
        ? (totalOrderStars / state.orderStarsHistory.length).round()
        : 3;

    await _repository.updateLevelStars(state.levelId, avgStars);
    _audioService.playSfx(AudioPaths.sfxLevelComplete);
    await _ttsService.speak(TtsScriptBuilder.buildLevelCompleteSpeech());

    emit(state.copyWith(
      phase: GamePhase.levelComplete,
      floatingText: null,
    ));
  }

  @override
  Future<void> close() {
    _idleTimer?.cancel();
    _audioService.stopBgm();
    _ttsService.stop();
    return super.close();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/shop_game_cubit_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/presentation/cubit/ test/features/shop_game/presentation/
git commit -m "feat(shop_game): implement ShopGameCubit and ShopGameState"
```

---

### Task 12: UI Layer 1 & 2 — BackgroundSceneryLayer & AmbientParticlesLayer

**Files:**
- Create: `lib/features/shop_game/presentation/widgets/layers/background_scenery_layer.dart`
- Create: `lib/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart`
- Test: `test/features/shop_game/presentation/layers_1_2_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/layers_1_2_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/background_scenery_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart';

void main() {
  testWidgets('BackgroundSceneryLayer and AmbientParticlesLayer render without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BackgroundSceneryLayer(),
              AmbientParticlesLayer(particleCount: 10),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(BackgroundSceneryLayer), findsOneWidget);
    expect(find.byType(AmbientParticlesLayer), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layers_1_2_test.dart`
Expected: FAIL (widgets not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/widgets/layers/background_scenery_layer.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';

class BackgroundSceneryLayer extends StatelessWidget {
  const BackgroundSceneryLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        AppShopAssets.shopBackground,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Warm wooden interior fallback painter if asset is missing
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEEDBB2), // Warm sunlight from window
                  Color(0xFF8B5A2B), // Deep oak wood
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart`:
```dart
import 'dart:math';
import 'package:flutter/material.dart';

class AmbientParticlesLayer extends StatefulWidget {
  final int particleCount;

  const AmbientParticlesLayer({
    super.key,
    this.particleCount = 25,
  });

  @override
  State<AmbientParticlesLayer> createState() => _AmbientParticlesLayerState();
}

class _AmbientParticlesLayerState extends State<AmbientParticlesLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 2,
        speed: _random.nextDouble() * 0.15 + 0.05,
        opacity: _random.nextDouble() * 0.4 + 0.2,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(_particles, _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final currentY = (p.y - (animationValue * p.speed)) % 1.0;
      final currentX = (p.x + sin(animationValue * 2 * pi + p.speed) * 0.02) % 1.0;

      paint.color = Colors.amberAccent.withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layers_1_2_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/presentation/widgets/layers/ test/features/shop_game/presentation/layers_1_2_test.dart
git commit -m "feat(shop_game): add BackgroundSceneryLayer and AmbientParticlesLayer"
```

---

### Task 13: UI Layer 3 — CustomerCharacterLayer & Blackboard

**Files:**
- Create: `lib/features/shop_game/presentation/widgets/layers/customer_character_layer.dart`
- Create: `lib/features/shop_game/presentation/widgets/customer/blackboard_order_widget.dart`
- Create: `lib/features/shop_game/presentation/widgets/customer/bear_character_widget.dart`
- Test: `test/features/shop_game/presentation/layer_3_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/layer_3_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/customer_character_layer.dart';

void main() {
  testWidgets('CustomerCharacterLayer displays blackboard order correctly', (tester) async {
    const order = OrderEntity(
      id: 'o1',
      requiredItem: ItemType.redApple,
      requiredQuantity: 3,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CustomerCharacterLayer(
                phase: GamePhase.collectingItems,
                currentOrder: order,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('🍎 Táo đỏ'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_3_test.dart`
Expected: FAIL (widgets not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/widgets/customer/blackboard_order_widget.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

class BlackboardOrderWidget extends StatelessWidget {
  final OrderEntity order;

  const BlackboardOrderWidget({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B), // Blackboard slate
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 6), // Wooden frame
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            offset: Offset(2, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${order.requiredQuantity}',
            style: const TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '${order.requiredItem.emoji} ${order.requiredItem.vietnameseName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD54F), // Chalk yellow
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/customer/bear_character_widget.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';

class BearCharacterWidget extends StatelessWidget {
  final GamePhase phase;

  const BearCharacterWidget({
    super.key,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final isHappy = phase == GamePhase.celebrating || phase == GamePhase.levelComplete;
    final lottieAsset = isHappy ? AppShopAssets.bearHappyLottie : AppShopAssets.bearIdleLottie;

    return Lottie.asset(
      lottieAsset,
      width: 220,
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback vector friendly bear face
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF795548),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5D4037), width: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isHappy ? '🐻 🎉' : '🐻',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bác Gấu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/layers/customer_character_layer.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/customer/bear_character_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/customer/blackboard_order_widget.dart';

class CustomerCharacterLayer extends StatelessWidget {
  final GamePhase phase;
  final OrderEntity currentOrder;

  const CustomerCharacterLayer({
    super.key,
    required this.phase,
    required this.currentOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BlackboardOrderWidget(order: currentOrder),
          const SizedBox(width: 24),
          BearCharacterWidget(phase: phase),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_3_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/presentation/widgets/customer/ lib/features/shop_game/presentation/widgets/layers/customer_character_layer.dart test/features/shop_game/presentation/layer_3_test.dart
git commit -m "feat(shop_game): add Layer 3 CustomerCharacterLayer with Bác Gấu and Blackboard"
```

---

### Task 14: UI Layer 4 — CountertopLayer (Basket, Scale, Register, Coin Jar)

**Files:**
- Create: `lib/features/shop_game/presentation/widgets/counter/basket_drag_target.dart`
- Create: `lib/features/shop_game/presentation/widgets/counter/spring_scale_widget.dart`
- Create: `lib/features/shop_game/presentation/widgets/counter/cash_register_widget.dart`
- Create: `lib/features/shop_game/presentation/widgets/counter/coin_jar_widget.dart`
- Create: `lib/features/shop_game/presentation/widgets/layers/countertop_layer.dart`
- Test: `test/features/shop_game/presentation/layer_4_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/layer_4_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/basket_drag_target.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/countertop_layer.dart';

void main() {
  testWidgets('BasketDragTarget accepts item on drop callback', (tester) async {
    ItemEntity? droppedItem;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountertopLayer(
            basketItems: const [],
            onItemDropped: (item) => droppedItem = item,
          ),
        ),
      ),
    );

    expect(find.byType(CountertopLayer), findsOneWidget);
    expect(find.byType(BasketDragTarget), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_4_test.dart`
Expected: FAIL (widgets not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/widgets/counter/basket_drag_target.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class BasketDragTarget extends StatefulWidget {
  final List<ItemEntity> items;
  final ValueChanged<ItemEntity> onItemDropped;

  const BasketDragTarget({
    super.key,
    required this.items,
    required this.onItemDropped,
  });

  @override
  State<BasketDragTarget> createState() => _BasketDragTargetState();
}

class _BasketDragTargetState extends State<BasketDragTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ItemEntity>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (data) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onItemDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedScale(
          scale: _isHovering ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 240,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFC48E56), // Wicker basket color
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
              border: Border.all(
                color: _isHovering ? Colors.amberAccent : const Color(0xFF8B5A2B),
                width: _isHovering ? 5 : 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 8),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Basket rim handle
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA06A3B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Collected items inside basket
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: widget.items.map((it) {
                    return Text(
                      it.type.emoji,
                      style: const TextStyle(fontSize: 28),
                    )
                        .animate()
                        .scale(duration: 200.ms, curve: Curves.easeOutBack);
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/counter/spring_scale_widget.dart`:
```dart
import 'dart:math';
import 'package:flutter/material.dart';

class SpringScaleWidget extends StatelessWidget {
  final int itemCount;

  const SpringScaleWidget({
    super.key,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    // Needle turns according to number of items
    final angle = min(itemCount * 0.4, pi);

    return Container(
      width: 80,
      height: 100,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F), // Vintage red scale body
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedRotation(
                turns: angle / (2 * pi),
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 2,
                  height: 24,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount kg',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/counter/cash_register_widget.dart`:
```dart
import 'package:flutter/material.dart';

class CashRegisterWidget extends StatelessWidget {
  final int displayCount;

  const CashRegisterWidget({
    super.key,
    required this.displayCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF37474F), // Slate metal
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF263238), width: 3),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: const Color(0xFF81C784), // LCD green
            child: Text(
              '$displayCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'MÁY TÍNH TIỀN',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/counter/coin_jar_widget.dart`:
```dart
import 'package:flutter/material.dart';

class CoinJarWidget extends StatelessWidget {
  final int coins;

  const CoinJarWidget({
    super.key,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/layers/countertop_layer.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/basket_drag_target.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/cash_register_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/coin_jar_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/spring_scale_widget.dart';

class CountertopLayer extends StatelessWidget {
  final List<ItemEntity> basketItems;
  final ValueChanged<ItemEntity> onItemDropped;
  final int totalCoins;

  const CountertopLayer({
    super.key,
    required this.basketItems,
    required this.onItemDropped,
    this.totalCoins = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 160,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Wooden countertop surface
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: Color(0xFF8D5B28), // Oak wood counter
              border: Border(
                top: BorderSide(color: Color(0xFFB87E43), width: 8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  offset: Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          // Countertop Props Row
          Positioned(
            bottom: 20,
            left: 200,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BasketDragTarget(
                  items: basketItems,
                  onItemDropped: onItemDropped,
                ),
                SpringScaleWidget(itemCount: basketItems.length),
                CashRegisterWidget(displayCount: basketItems.length),
                CoinJarWidget(coins: totalCoins),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_4_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/presentation/widgets/counter/ lib/features/shop_game/presentation/widgets/layers/countertop_layer.dart test/features/shop_game/presentation/layer_4_test.dart
git commit -m "feat(shop_game): add Layer 4 CountertopLayer with Basket, Scale, Register, Coin Jar"
```

---

### Task 15: UI Layer 5 — FruitShelfDraggableLayer

**Files:**
- Create: `lib/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart`
- Create: `lib/features/shop_game/presentation/widgets/shelf/draggable_fruit_item.dart`
- Test: `test/features/shop_game/presentation/layer_5_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/layer_5_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/shelf/draggable_fruit_item.dart';

void main() {
  testWidgets('FruitShelfDraggableLayer displays Draggable items for shelf', (tester) async {
    final items = ShopGameLevelsData.shelfItems.map((m) => m.toEntity()).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FruitShelfDraggableLayer(items: items),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FruitShelfDraggableLayer), findsOneWidget);
    expect(find.byType(DraggableFruitItem), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_5_test.dart`
Expected: FAIL (widgets not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/widgets/shelf/draggable_fruit_item.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class DraggableFruitItem extends StatelessWidget {
  final ItemEntity item;
  final VoidCallback? onDragStarted;

  const DraggableFruitItem({
    super.key,
    required this.item,
    this.onDragStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<ItemEntity>(
      data: item,
      onDragStarted: onDragStarted,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.3,
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: _ItemVisual(item: item),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _ItemVisual(item: item),
      ),
      child: _ItemVisual(item: item),
    );
  }
}

class _ItemVisual extends StatelessWidget {
  final ItemEntity item;

  const _ItemVisual({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: Text(
        item.type.emoji,
        style: const TextStyle(fontSize: 44),
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/shelf/draggable_fruit_item.dart';

class FruitShelfDraggableLayer extends StatelessWidget {
  final List<ItemEntity> items;
  final VoidCallback? onDragStarted;

  const FruitShelfDraggableLayer({
    super.key,
    required this.items,
    this.onDragStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      top: 60,
      bottom: 40,
      width: 140,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6D4C41).withOpacity(0.9), // Wooden shelf background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4E342E), width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(4, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(color: Color(0xFF4E342E), thickness: 3),
          itemBuilder: (context, index) {
            return Center(
              child: DraggableFruitItem(
                item: items[index],
                onDragStarted: onDragStarted,
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_5_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/presentation/widgets/shelf/ lib/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart test/features/shop_game/presentation/layer_5_test.dart
git commit -m "feat(shop_game): add Layer 5 FruitShelfDraggableLayer and DraggableFruitItem"
```

---

### Task 16: UI Layer 6 — GameHudOverlay, FloatingCountingText & HandTutorWidget

**Files:**
- Create: `lib/features/shop_game/presentation/widgets/hud/top_hud_bar.dart`
- Create: `lib/features/shop_game/presentation/widgets/hud/floating_counting_text.dart`
- Create: `lib/core/widgets/hand_tutor_widget.dart`
- Create: `lib/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart`
- Test: `test/features/shop_game/presentation/layer_6_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/layer_6_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/top_hud_bar.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/floating_counting_text.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart';

void main() {
  testWidgets('GameHudOverlay renders top bar and floating text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GameHudOverlay(
                currentOrderIndex: 0,
                totalOrders: 5,
                starCount: 3,
                floatingText: 'Một!',
                isHandTutorVisible: true,
                onBackPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TopHudBar), findsOneWidget);
    expect(find.text('Một!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_6_test.dart`
Expected: FAIL (widgets not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/widgets/hud/top_hud_bar.dart`:
```dart
import 'package:flutter/material.dart';

class TopHudBar extends StatelessWidget {
  final int currentOrderIndex;
  final int totalOrders;
  final int starCount;
  final VoidCallback onBackPressed;
  final VoidCallback? onPausePressed;

  const TopHudBar({
    super.key,
    required this.currentOrderIndex,
    required this.totalOrders,
    required this.starCount,
    required this.onBackPressed,
    this.onPausePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Circular Back Button
          IconButton(
            onPressed: onBackPressed,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          // Star progress display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '$starCount',
                  style: const TextStyle(
                    fontFamily: 'LilitaOne',
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Shop Title Plaque
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8D5B28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB87E43), width: 3),
            ),
            child: const Text(
              'Tiệm Tạp Hóa Nhí',
              style: TextStyle(
                fontFamily: 'LilitaOne',
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          const Spacer(),
          // Customer Progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Khách: ${currentOrderIndex + 1}/$totalOrders',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/hud/floating_counting_text.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FloatingCountingText extends StatelessWidget {
  final String text;

  const FloatingCountingText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'LilitaOne',
          fontSize: 80,
          fontWeight: FontWeight.bold,
          color: Colors.amberAccent,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.6),
              offset: const Offset(4, 6),
              blurRadius: 8,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 300.ms)
          .moveY(begin: 0, end: -40, duration: 600.ms)
          .fadeOut(delay: 500.ms, duration: 300.ms),
    );
  }
}
```

Create `lib/core/widgets/hand_tutor_widget.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HandTutorWidget extends StatelessWidget {
  const HandTutorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 100,
      bottom: 120,
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10),
            ],
          ),
          child: const Text('👉', style: TextStyle(fontSize: 48)),
        )
            .animate(onPlay: (c) => c.repeat())
            .moveX(begin: 0, end: 200, duration: 1200.ms, curve: Curves.easeInOut)
            .fadeIn(duration: 300.ms)
            .fadeOut(delay: 900.ms, duration: 300.ms),
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:fun_edu/core/widgets/hand_tutor_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/floating_counting_text.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/top_hud_bar.dart';

class GameHudOverlay extends StatelessWidget {
  final int currentOrderIndex;
  final int totalOrders;
  final int starCount;
  final String? floatingText;
  final bool isHandTutorVisible;
  final VoidCallback onBackPressed;

  const GameHudOverlay({
    super.key,
    required this.currentOrderIndex,
    required this.totalOrders,
    required this.starCount,
    this.floatingText,
    required this.isHandTutorVisible,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TopHudBar(
          currentOrderIndex: currentOrderIndex,
          totalOrders: totalOrders,
          starCount: starCount,
          onBackPressed: onBackPressed,
        ),
        if (floatingText != null) FloatingCountingText(text: floatingText!),
        if (isHandTutorVisible) const HandTutorWidget(),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/layer_6_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/hand_tutor_widget.dart lib/features/shop_game/presentation/widgets/hud/ lib/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart test/features/shop_game/presentation/layer_6_test.dart
git commit -m "feat(shop_game): add Layer 6 GameHudOverlay, TopHudBar, FloatingCountingText, and HandTutorWidget"
```

---

### Task 17: Presentation Layer — ShopGameScreen & Landscape Lock

**Files:**
- Create: `lib/features/shop_game/presentation/screens/shop_game_screen.dart`
- Test: `test/features/shop_game/presentation/shop_game_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/shop_game_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/screens/shop_game_screen.dart';

class MockShopGameRepository extends Mock implements IShopGameRepository {}
class MockTtsService extends Mock implements TtsService {}
class MockAudioService extends Mock implements AudioService {}

void main() {
  late MockShopGameRepository mockRepo;
  late MockTtsService mockTts;
  late MockAudioService mockAudio;

  setUp(() {
    mockRepo = MockShopGameRepository();
    mockTts = MockTtsService();
    mockAudio = MockAudioService();

    when(() => mockRepo.getLevel('level_1')).thenAnswer(
      (_) async => const LevelEntity(
        id: 'level_1',
        shopName: 'Tiệm Trái Cây',
        starsToUnlock: 0,
        orders: [
          OrderEntity(id: 'o1', requiredItem: ItemType.redApple, requiredQuantity: 2),
        ],
      ),
    );
    when(() => mockRepo.getChildProfile()).thenAnswer(
      (_) async => ChildProfileEntity(
        id: 'c1',
        name: 'Bé Na',
        age: 4,
        totalStars: 0,
        totalCoins: 0,
        levelStars: const {},
        createdAt: DateTime.now(),
      ),
    );
    when(() => mockTts.init()).thenAnswer((_) async => {});
    when(() => mockTts.speak(any())).thenAnswer((_) async => {});
    when(() => mockAudio.init()).thenAnswer((_) async => {});
    when(() => mockAudio.playBgm(any())).thenAnswer((_) async => {});
    when(() => mockAudio.playSfx(any())).thenAnswer((_) async => {});
    when(() => mockAudio.stopBgm()).thenAnswer((_) async => {});
    when(() => mockTts.stop()).thenAnswer((_) async => {});

    GetIt.instance.registerSingleton<IShopGameRepository>(mockRepo);
    GetIt.instance.registerSingleton<TtsService>(mockTts);
    GetIt.instance.registerSingleton<AudioService>(mockAudio);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('ShopGameScreen renders and initializes game loop', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShopGameScreen(levelId: 'level_1'),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ShopGameScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/shop_game_screen_test.dart`
Expected: FAIL (screen not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/screens/shop_game_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_cubit.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/background_scenery_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/countertop_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/customer_character_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart';

class ShopGameScreen extends StatefulWidget {
  final String levelId;

  const ShopGameScreen({
    super.key,
    required this.levelId,
  });

  @override
  State<ShopGameScreen> createState() => _ShopGameScreenState();
}

class _ShopGameScreenState extends State<ShopGameScreen> {
  late final ShopGameCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Lock landscape mode for Shop Game
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _cubit = ShopGameCubit(
      repository: GetIt.instance<IShopGameRepository>(),
      ttsService: GetIt.instance<TtsService>(),
      audioService: GetIt.instance<AudioService>(),
    )..startGame(widget.levelId);
  }

  @override
  void dispose() {
    // Restore portrait mode for rest of app
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelfEntities = ShopGameLevelsData.shelfItems.map((m) => m.toEntity()).toList();

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: BlocConsumer<ShopGameCubit, ShopGameState>(
          listener: (context, state) {
            if (state.phase == GamePhase.celebrating) {
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  _cubit.nextCustomerOrFinish();
                }
              });
            } else if (state.phase == GamePhase.customerEntering) {
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted && _cubit.state.phase == GamePhase.customerEntering) {
                  _cubit.onCustomerEntered();
                }
              });
            }
          },
          builder: (context, state) {
            if (state.phase == GamePhase.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return GestureDetector(
              onTapDown: (_) => _cubit.hideHandTutor(),
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  // Layer 1: Background Scenery
                  const BackgroundSceneryLayer(),

                  // Layer 2: Ambient Particles
                  const AmbientParticlesLayer(),

                  // Layer 3: Customer Character (Bác Gấu) + Blackboard
                  CustomerCharacterLayer(
                    phase: state.phase,
                    currentOrder: state.currentOrder,
                  ),

                  // Layer 4: Countertop + Basket + Scale + Register + Jar
                  CountertopLayer(
                    basketItems: state.basketItems,
                    onItemDropped: (item) => _cubit.addItemToBasket(item),
                  ),

                  // Layer 5: Fruit Shelf with Draggable items
                  FruitShelfDraggableLayer(
                    items: shelfEntities,
                    onDragStarted: () => _cubit.hideHandTutor(),
                  ),

                  // Layer 6: Game HUD Overlay
                  GameHudOverlay(
                    currentOrderIndex: state.currentOrderIndex,
                    totalOrders: state.totalOrders,
                    starCount: state.starCount,
                    floatingText: state.floatingText,
                    isHandTutorVisible: state.isHandTutorVisible,
                    onBackPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/shop_game_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/presentation/screens/shop_game_screen.dart test/features/shop_game/presentation/shop_game_screen_test.dart
git commit -m "feat(shop_game): add ShopGameScreen 6-layer stack and landscape orientation control"
```

---

### Task 18: Presentation Layer — LevelSummaryDialog & LevelSelectScreen

**Files:**
- Create: `lib/features/shop_game/presentation/widgets/dialogs/level_summary_dialog.dart`
- Create: `lib/features/shop_game/presentation/screens/level_select_screen.dart`
- Test: `test/features/shop_game/presentation/level_select_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/shop_game/presentation/level_select_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/screens/level_select_screen.dart';

class MockShopGameRepository extends Mock implements IShopGameRepository {}

void main() {
  late MockShopGameRepository mockRepo;

  setUp(() {
    mockRepo = MockShopGameRepository();
    when(() => mockRepo.getChildProfile()).thenAnswer(
      (_) async => ChildProfileEntity(
        id: 'c1',
        name: 'Bé Na',
        age: 5,
        totalStars: 10,
        totalCoins: 30,
        levelStars: const {'level_1': 3},
        createdAt: DateTime.now(),
      ),
    );
    GetIt.instance.registerSingleton<IShopGameRepository>(mockRepo);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('LevelSelectScreen renders 3 shop game levels and star count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Tiệm Trái Cây'), findsOneWidget);
    expect(find.text('Chợ Rau Củ'), findsOneWidget);
    expect(find.text('Siêu Thị Mini'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/level_select_screen_test.dart`
Expected: FAIL (screen not found)

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/shop_game/presentation/widgets/dialogs/level_summary_dialog.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class LevelSummaryDialog extends StatefulWidget {
  final int starsEarned;
  final VoidCallback onContinue;

  const LevelSummaryDialog({
    super.key,
    required this.starsEarned,
    required this.onContinue,
  });

  @override
  State<LevelSummaryDialog> createState() => _LevelSummaryDialogState();
}

class _LevelSummaryDialogState extends State<LevelSummaryDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HOÀN THÀNH!',
                  style: TextStyle(
                    fontFamily: 'LilitaOne',
                    fontSize: 28,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        index < widget.starsEarned ? '⭐' : '⚪',
                        style: const TextStyle(fontSize: 40),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: widget.onContinue,
                  child: const Text(
                    'TIẾP TỤC',
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/shop_game/presentation/screens/level_select_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  ChildProfileEntity? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final repo = GetIt.instance<IShopGameRepository>();
    final p = await repo.getChildProfile();
    setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final levels = ShopGameLevelsData.levels;
    final totalStars = _profile?.totalStars ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('Chọn Cửa Hàng'),
        backgroundColor: const Color(0xFF8D5B28),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  '$totalStars',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isUnlocked = totalStars >= level.starsToUnlock;
          final earnedStars = _profile?.levelStars[level.id] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFFFE082) : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? '🏪' : '🔒',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              title: Text(
                level.shopName,
                style: const TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 20,
                  color: Color(0xFF4E342E),
                ),
              ),
              subtitle: Text(
                isUnlocked ? 'Số thử thách: ${level.orders.length}' : 'Cần ${level.starsToUnlock} ⭐ để mở',
                style: TextStyle(
                  color: isUnlocked ? Colors.black54 : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: isUnlocked
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (starIdx) {
                        return Text(
                          starIdx < earnedStars ? '⭐' : '⚪',
                          style: const TextStyle(fontSize: 18),
                        );
                      }),
                    )
                  : null,
              onTap: isUnlocked
                  ? () => context.push('/shop-game/level/${level.id}')
                  : null,
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/features/shop_game/presentation/level_select_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/shop_game/presentation/widgets/dialogs/ lib/features/shop_game/presentation/screens/level_select_screen.dart test/features/shop_game/presentation/level_select_screen_test.dart
git commit -m "feat(shop_game): add LevelSummaryDialog and LevelSelectScreen"
```

---

### Task 19: Navigation & Home Screen Flagship Integration

**Files:**
- Modify: `lib/router/go_router_name_enum.dart`
- Modify: `lib/router/app_router.dart`
- Modify: `lib/screen/home_screen.dart`
- Test: `test/navigation/shop_game_routing_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/navigation/shop_game_routing_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';

void main() {
  test('GoRouterName defines shopGame and shopGameLevel routes', () {
    expect(GoRouterName.shopGame.routeName, 'shopGame');
    expect(GoRouterName.shopGame.routePath, '/shop-game');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/navigation/shop_game_routing_test.dart`
Expected: FAIL (`shopGame` enum value not found)

- [ ] **Step 3: Write minimal implementation**

In `lib/router/go_router_name_enum.dart`, add:
```dart
  shopGame,
  shopGameLevel,
```
and under extension:
```dart
      case GoRouterName.shopGame:
        return '/shop-game';
      case GoRouterName.shopGameLevel:
        return 'level/:levelId';
```

In `lib/router/app_router.dart`, add routes:
```dart
      GoRoute(
        path: GoRouterName.shopGame.routePath,
        name: GoRouterName.shopGame.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: LevelSelectScreen()),
        routes: [
          GoRoute(
            path: 'level/:levelId',
            name: GoRouterName.shopGameLevel.routeName,
            pageBuilder: (context, state) {
              final levelId = state.pathParameters['levelId'] ?? 'level_1';
              return MaterialPage<void>(
                child: ShopGameScreen(levelId: levelId),
              );
            },
          ),
        ],
      ),
```

In `lib/screen/home_screen.dart`, add the Flagship banner for "Tiệm Tạp Hóa Nhí" right above `Expanded(child: RefreshIndicator(...))`:
```dart
                    // Flagship Banner for Tiệm Tạp Hóa Nhí
                    GestureDetector(
                      onTap: () => context.pushNamed(GoRouterName.shopGame.routeName),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.orangeAccent,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text('🏪', style: TextStyle(fontSize: 44)),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tiệm Tạp Hóa Nhí',
                                    style: TextStyle(
                                      fontFamily: 'LilitaOne',
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Học toán cùng Bác Gấu vui nhộn!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'CHƠI NGAY',
                                style: TextStyle(
                                  fontFamily: 'LilitaOne',
                                  color: Color(0xFFFF5722),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/navigation/shop_game_routing_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/router/ lib/screen/home_screen.dart test/navigation/shop_game_routing_test.dart
git commit -m "feat(shop_game): add GoRouter routes and Home Screen flagship banner"
```

---

### Task 20: Full Verification & Sanity Check

**Files:**
- Test: All tests across the project

- [ ] **Step 1: Run all unit and widget tests**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter test test/core/ test/features/ test/di/ test/navigation/`
Expected: ALL PASS with 0 failures

- [ ] **Step 2: Run `flutter analyze`**

Run: `export PATH=~/development/flutter/bin:$PATH && flutter analyze`
Expected: `No issues found!` (or 0 errors)

- [ ] **Step 3: Commit and wrap up Phase 1**

```bash
git status
git add -A
git commit -m "chore: verify full test suite and clean analysis for Shop Game Phase 1"
```

---
