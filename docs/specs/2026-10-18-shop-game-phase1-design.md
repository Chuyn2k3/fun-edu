# Design Spec: Tiệm Tạp Hóa Nhí — Phase 1

**Date:** 2026-10-18
**Branch:** `feature/shop-game-phase1`
**Status:** Approved
**Approach:** Incremental Layered Build (Phase 1 of 4)

---

## 1. Overview

Đại cải tạo app `fun_edu` — biến "Tiệm Tạp Hóa Nhí" thành trải nghiệm chính, refactor sang Clean Architecture + thống nhất `flutter_bloc`, giữ nguyên game cũ hoạt động.

**Phase 1 scope:**
- Refactor cấu trúc thư mục sang Clean Architecture
- Thống nhất state management về `flutter_bloc` (Cubit) cho code mới
- Xây dựng `ShopGameScreen` với 6-layer Stack system
- Core drag-drop gameplay: 3 phases (customerEntering → collectingItems → celebrating)
- TTS tiếng Việt + SFX audio
- 3 levels hardcode, 5 loại vật phẩm
- Hive local storage (profile, progress, play logs)
- Lottie animation Bác Gấu (idle/happy)

**Phase 1 KHÔNG bao gồm:**
- ❌ Voice input (speech_to_text) → Phase 2
- ❌ Máy tính tiền interactive (bấm số) → Phase 2
- ❌ Backend API + offline sync → Phase 3
- ❌ Parent Dashboard → Phase 3
- ❌ Monetization (Ads/IAP) → Phase 4
- ❌ COPPA/GDPR-K compliance → Phase 4
- ❌ Multiple shops/characters → Phase 3-4
- ❌ Timer countdown → Phase 2

---

## 2. Architecture

### 2.1 Directory Structure

```
lib/
├── core/
│   ├── constants/                 # AppAssets, AppColors, AudioPaths
│   ├── services/                  # AudioService, TtsService, NavigationService
│   ├── theme/                     # AppThemes (refactored from existing)
│   └── widgets/                   # BouncingButton, HandTutorWidget
│
├── features/
│   ├── shop_game/                 # ★ NEW — Tiệm Tạp Hóa Nhí
│   │   ├── data/
│   │   │   ├── datasources/       # LocalShopDataSource (Hive)
│   │   │   ├── models/            # OrderModel, ItemModel, PlaySessionModel, LevelModel, ChildProfileModel
│   │   │   └── repositories/      # ShopGameRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/          # OrderEntity, ItemEntity, LevelEntity, ChildProfileEntity, PlaySessionEntity
│   │   │   ├── repositories/      # IShopGameRepository
│   │   │   └── usecases/          # GenerateOrderUseCase, RecordPlayLogUseCase
│   │   └── presentation/
│   │       ├── cubit/             # ShopGameCubit, ShopGameState
│   │       ├── screens/           # ShopGameScreen, ShopGameLevelScreen, LevelSelectScreen
│   │       └── widgets/           # 6 layer widgets (see Section 3)
│   │
│   └── legacy/                    # Existing games — moved as-is, NO refactor
│       ├── count_shape/           # from feature/count_shape_game
│       ├── digit/                 # from feature/digit_feature
│       ├── even_odd/              # from feature/even_old_game
│       ├── game/                  # from feature/game_feature
│       ├── math/                  # from feature/math_feature
│       ├── number/                # from feature/number_feature
│       └── operation/             # from feature/operation_feature
│
├── navigation/                    # GoRouter config (refactored from router/)
├── di/                            # GetIt setup (keep + extend)
└── main.dart
```

### 2.2 Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management (new code) | `flutter_bloc` (Cubit + Equatable) | Spec requirement, already in project |
| State management (legacy code) | Keep as-is (mixed) | Avoid breaking working features |
| Legacy migration strategy | Move to `features/legacy/`, fix imports only | Minimal risk, refactor later |
| DI | Keep `GetIt`, extend registrations | Already working, no need to change |
| Local DB | `Hive` (already in project) | Sufficient for Phase 1 offline |
| Screen orientation | Landscape for shop game, Portrait for legacy | Per-screen `SystemChrome` in initState/dispose |
| Animation engine | Flutter native + `flutter_animate` + `lottie` | No Flame needed for Phase 1 UI |
| Drag-drop | Flutter native `Draggable`/`DragTarget` | Simple, sufficient, no external dependency |

---

## 3. UI — 6 Layer Stack System

`ShopGameScreen` uses a fixed-camera first-person POV looking at a wooden checkout counter. Built with a `Stack` of 6 layers to simulate 2.5D depth.

### 3.1 Layer Breakdown

```dart
Stack(
  children: [
    BackgroundSceneryLayer(),      // Layer 1 — Pre-rendered 3D background (WebP)
    AmbientParticlesLayer(),       // Layer 2 — Floating sun particles (CustomPainter)
    CustomerCharacterLayer(),      // Layer 3 — Bác Gấu (Lottie) + Blackboard order
    CountertopLayer(),             // Layer 4 — Counter + Basket + Scale + Register + Coins
    FruitShelfDraggableLayer(),    // Layer 5 — Draggable items on shelf
    GameHudOverlay(),              // Layer 6 — HUD + Floating text + Hand Tutor
  ],
)
```

### 3.2 Widget Details

#### Layer 1 — `BackgroundSceneryLayer`
- `Positioned.fill` with `Image.asset` (WebP format)
- Warm wooden shop interior, window showing forest with sunlight
- Single static image, no animation

#### Layer 2 — `AmbientParticlesLayer`
- `CustomPainter` with `Ticker` for animation loop
- 20-30 particles: small golden dots drifting near window area
- Low performance cost, purely decorative

#### Layer 3 — `CustomerCharacterLayer`
- **Bác Gấu:** Lottie animation, positioned right-of-center behind counter
  - Phase 1 states: `idle` (breathing, blinking), `happy` (jumping, clapping)
  - Phase 2+ adds: `talking`, `thinking`
- **Blackboard:** `Positioned` left of Bác Gấu
  - Shows: large number + item icon/name (e.g., "3" + 🍎 "Táo đỏ")
  - Updates when `currentOrder` changes in cubit state

#### Layer 4 — `CountertopLayer`
- **Countertop image:** Wooden surface overlapping Bác Gấu's lower body (depth illusion)
- **`BasketDragTarget`:** `DragTarget<ItemModel>` center of counter
  - Accepts items, shows collected items inside basket
  - Squash & Stretch animation on accept (`flutter_animate`)
- **`SpringScaleWidget`:** Right of basket
  - `AnimatedRotation` needle based on `basketItems.length`
- **`CashRegisterWidget`:** Right of scale
  - Phase 1: Display-only, shows running total count
  - Phase 2: Interactive keypad
- **`CoinJarWidget`:** Far right
  - Shows accumulated coins, animated fill during celebrating phase

#### Layer 5 — `FruitShelfDraggableLayer`
- Positioned at left side of screen (shelf area)
- Each item is `Draggable<ItemModel>`:
  - `feedback`: Item scaled 1.2x with deeper shadow
  - `childWhenDragging`: Semi-transparent ghost at original position
  - `onDragStarted`: Play `sfx_drag_start.mp3`
- Items arranged in shelf rows matching background perspective
- Multiple instances of each type available (e.g., 6 apples on shelf)

#### Layer 6 — `GameHudOverlay`
- **Top Bar (`TopHudBar`):**
  - Left: Back button (green circle)
  - Center-left: Star progress bar (animated fill)
  - Center-right: Wooden sign "Tiệm Tạp Hóa Nhí"
  - Right: Pause button
- **`FloatingCountingText`:** Center screen
  - FadeIn + SlideUp + Scale animation
  - Shows "Một!", "Hai!", "Ba!"... on each correct drop
  - Colorful 3D-style text with stroke
- **`HandTutorWidget`:**
  - Semi-transparent 3D white hand with sparkle trail
  - Auto-shows after 7 seconds of no interaction
  - Loops animation: shelf item → basket
  - Disappears on any touch input

---

## 4. Core Gameplay Loop

### 4.1 Game Phases (Phase 1 — Simplified)

```
loading → customerEntering (5s) → collectingItems → celebrating (3s) → next customer or levelComplete
```

### 4.2 State Machine

```dart
enum GamePhase {
  loading,            // Load level data, init audio
  customerEntering,   // Bác Gấu walks in, TTS reads order
  collectingItems,    // Drag & drop active
  celebrating,        // Confetti, coins fly, star earned
  levelComplete,      // All orders done → summary screen
}

class ShopGameState extends Equatable {
  final GamePhase phase;
  final OrderEntity currentOrder;
  final List<ItemEntity> basketItems;
  final int starCount;
  final int currentOrderIndex;
  final int totalOrders;
  final int errorsCount;
  final bool isHandTutorVisible;
  final String? floatingText;
}
```

### 4.3 Cubit Actions & Transitions

| Action | Trigger | State Change | Side Effects |
|--------|---------|-------------|--------------|
| `startGame(levelId)` | Screen init | `loading` → `customerEntering` | Load level data from Hive, init audio |
| `onCustomerEntered()` | After TTS + 5s | `customerEntering` → `collectingItems` | Enable drag interaction, start idle timer (7s for hand tutor) |
| `addItemToBasket(item)` | Correct drag-drop | Update `basketItems`, `floatingText` | TTS count number, reset idle timer |
| `rejectItem(item)` | Wrong item type | No phase change | Bounce animation, TTS "Ồ, bác cần X kìa!", increment `errorsCount` |
| `completeOrder()` | `basketItems.length == order.quantity` | `collectingItems` → `celebrating` | Confetti, coins, +star |
| `nextCustomer()` | After 3s celebrating | `celebrating` → `customerEntering` | Clear basket, load next order |
| `completeLevel()` | Last order celebrated | `celebrating` → `levelComplete` | Save progress to Hive, show summary |
| `showHandTutor()` | 7s no interaction | Set `isHandTutorVisible = true` | Show hand animation |
| `hideHandTutor()` | Any touch | Set `isHandTutorVisible = false` | Hide hand |

### 4.4 Star Scoring (per order)

| Errors | Stars |
|--------|-------|
| 0 | ⭐⭐⭐ |
| 1-2 | ⭐⭐ |
| 3+ | ⭐ |

Level star = average of all order stars (rounded down).

---

## 5. Audio System

### 5.1 Architecture

```
AudioService
├── BgmPlayer (just_audio) — looping background music
├── SfxPlayer (just_audio) — one-shot sound effects
└── TtsService (flutter_tts) — Vietnamese voice synthesis
```

### 5.2 TTS Configuration

```dart
class TtsService {
  Future<void> init() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.45);   // Slow for young children
    await _tts.setPitch(1.2);          // Higher pitch, friendly
  }

  Future<void> speakAndWait(String text);  // Blocks until TTS completes
  Future<void> speak(String text);          // Fire-and-forget
}
```

### 5.3 TTS Scripts

| Phase | Script Template |
|-------|----------------|
| Customer entering | "Chào bé {name}! Lấy giúp bác {quantity} quả {itemName} nhé!" |
| Counting (each drop) | "Một!", "Hai!", "Ba!", "Bốn!", "Năm!" |
| Wrong item | "Ồ, bác cần {itemName} kìa!" |
| Order complete | "Giỏi lắm! Cảm ơn bé nhé!" |
| Level complete | "Tuyệt vời! Bé đã hoàn thành xuất sắc!" |

### 5.4 SFX Files Required

| File | Trigger | Duration |
|------|---------|----------|
| `bgm_shop.mp3` | Loop throughout game | ~60s loop |
| `sfx_drag_start.mp3` | `onDragStarted` | ~0.3s |
| `sfx_drop_correct.mp3` | Correct item dropped in basket | ~0.5s |
| `sfx_drop_wrong.mp3` | Wrong item rejected | ~0.5s |
| `sfx_basket_bounce.mp3` | Basket squash animation | ~0.3s |
| `sfx_star_collect.mp3` | Star added to progress | ~0.5s |
| `sfx_coin_drop.mp3` | Coins fly to jar | ~0.8s |
| `sfx_confetti.mp3` | Confetti burst | ~1s |
| `sfx_level_complete.mp3` | Level summary shown | ~2s |

Source: Royalty-free sound libraries (freesound.org, mixkit.co).

---

## 6. Data Layer

### 6.1 Data Models

```dart
class ItemModel {
  final String id;            // 'red_apple_1'
  final ItemType type;        // enum: redApple, banana, pumpkin, orange, watermelon
  final String nameVi;        // 'Táo đỏ'
  final String assetPath;     // 'assets/shop_game/items/red_apple.webp'
  final int shelfPosition;
}

class OrderModel {
  final String id;
  final ItemType requiredItem;
  final int requiredQuantity;  // 1-5
  final int difficulty;        // 1-3
}

class LevelModel {
  final String id;
  final String shopName;
  final List<OrderModel> orders;
  final int starsToUnlock;
}

class PlaySessionModel {
  final String id;
  final String levelId;
  final String orderId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int errorsCount;
  final int starsEarned;
  final bool completed;
}

class ChildProfileModel {
  final String id;
  final String name;
  final int age;
  final int totalStars;
  final int totalCoins;
  final Map<String, int> levelStars;  // {'level_1': 3}
  final DateTime createdAt;
}
```

### 6.2 Hive Boxes

| Box Name | Type | Purpose |
|----------|------|---------|
| `child_profile` | `ChildProfileModel` | Single child profile |
| `level_progress` | `Map<String, int>` | Stars earned per level |
| `play_sessions` | `List<PlaySessionModel>` | Play log (future sync queue) |
| `app_settings` | `Map<String, dynamic>` | Volume, TTS speed, etc. |

### 6.3 Repository Interface

```dart
abstract class IShopGameRepository {
  Future<ChildProfileEntity> getChildProfile();
  Future<void> saveChildProfile(ChildProfileEntity profile);
  Future<LevelEntity> getLevel(String levelId);
  Future<List<LevelEntity>> getAvailableLevels();
  Future<void> recordPlaySession(PlaySessionEntity session);
  Future<int> getTotalStars();
}
```

Implementation (`ShopGameRepositoryImpl`) reads/writes Hive only in Phase 1. Interface is designed for Phase 3 backend sync addition without changing consumers.

### 6.4 Level Content (Hardcoded Phase 1)

**Level 1 — Tiệm Trái Cây** (⭐ Easy, unlock: 0 stars)
| Order | Item | Quantity |
|-------|------|----------|
| 1 | Táo đỏ | 2 |
| 2 | Chuối | 1 |
| 3 | Cam | 2 |
| 4 | Táo đỏ | 3 |
| 5 | Chuối | 3 |

**Level 2 — Chợ Rau Củ** (⭐⭐ Medium, unlock: 8 stars)
| Order | Item | Quantity |
|-------|------|----------|
| 1 | Bí ngô | 2 |
| 2 | Cam | 3 |
| 3 | Dưa hấu | 2 |
| 4 | Táo đỏ | 4 |
| 5 | Bí ngô | 3 |

**Level 3 — Siêu Thị Mini** (⭐⭐⭐ Hard, unlock: 20 stars)
| Order | Item | Quantity |
|-------|------|----------|
| 1 | Cam | 3 |
| 2 | Dưa hấu | 2 |
| 3 | Chuối | 4 |
| 4 | Bí ngô | 3 |
| 5 | Táo đỏ | 5 |
| 6 | Dưa hấu | 3 |

Items available: redApple (🍎), banana (🍌), pumpkin (🎃), orange (🍊), watermelon (🍉).

---

## 7. Animation Inventory

| Widget | Effect | Package | Trigger |
|--------|--------|---------|---------|
| Bác Gấu | `idle` ↔ `happy` | `lottie` | Phase change |
| Draggable item (drag) | Scale 1.0→1.2, deeper shadow | `flutter_animate` | `onDragStarted` |
| Draggable item (reject) | SlideBack + shake | `flutter_animate` | Wrong item dropped |
| Basket on accept | Squash & Stretch | `flutter_animate` | `onAcceptWithDetails` |
| Spring Scale needle | Rotation by angle | `AnimatedRotation` | `basketItems.length` change |
| Floating count text | FadeIn + SlideUp + Scale | `flutter_animate` | Each correct drop |
| Star progress bar | Animated width fill | `AnimatedContainer` | `starCount` change |
| Coins → Jar | Curved path flight | `flutter_animate` | Celebrating phase |
| Confetti | Burst from top-center | `confetti` | Celebrating phase |
| Hand Tutor | Loop: shelf → basket path | `flutter_animate` | After 7s idle |
| Ambient particles | Random drift loop | `CustomPainter` + `Ticker` | Always running |

---

## 8. Navigation

### 8.1 New Routes

```dart
GoRoute(
  path: '/shop-game',
  name: 'shopGame',
  builder: (context, state) => const LevelSelectScreen(),
  routes: [
    GoRoute(
      path: 'level/:levelId',
      name: 'shopGameLevel',
      builder: (context, state) => ShopGameScreen(
        levelId: state.pathParameters['levelId']!,
      ),
    ),
  ],
),
```

### 8.2 Orientation Handling

```dart
// ShopGameScreen — lock landscape
@override
void initState() {
  super.initState();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

@override
void dispose() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  super.dispose();
}
```

### 8.3 Entry Point

Add a prominent card/button on the existing Home Screen (`home_screen.dart`) that navigates to `/shop-game`. This should be the most visually prominent element — the new flagship feature.

---

## 9. Error Handling

| Scenario | Handling |
|----------|----------|
| TTS engine not available / no vi-VN | Fallback: show text bubble above Bác Gấu's head |
| Asset load failure | Show colored placeholder box + log error |
| Hive data corruption | Reset profile to defaults, show friendly message |
| Drag outside any DragTarget | Animate item back to shelf position |
| User exits mid-game (back/home) | Auto-save current progress, resume on return |
| Screen rotation conflict | `WillPopScope` + restore orientation before pop |

---

## 10. Testing Strategy

| Layer | Test Type | What to Test |
|-------|-----------|-------------|
| `ShopGameCubit` | Unit | Phase transitions, basket add/reject logic, star scoring, order completion |
| `ShopGameRepositoryImpl` | Unit | Hive read/write, model↔entity mapping |
| `GenerateOrderUseCase` | Unit | Returns correct orders for each level |
| `RecordPlayLogUseCase` | Unit | Correctly saves PlaySessionModel to Hive |
| `TtsService` | Unit (mock) | Correct language/rate/pitch config, speak called with right text |
| `AudioService` | Unit (mock) | Correct SFX played at right triggers |
| `ShopGameScreen` | Widget | DragTarget accepts correct items, rejects wrong items, phase UI changes |
| `BasketDragTarget` | Widget | Visual feedback on hover/accept/reject |
| Legacy features | Smoke | Existing games still launch and function after file move |

---

## 11. Asset Requirements

### 11.1 Images (WebP format, landscape 16:9)

| Asset | Description | File |
|-------|-------------|------|
| Shop background | Warm wooden interior, window with forest | `assets/shop_game/bg/shop_background.webp` |
| Countertop | Wooden counter surface | `assets/shop_game/bg/countertop.webp` |
| Blackboard | Chalk-style blackboard frame | `assets/shop_game/bg/blackboard.webp` |
| Basket | Wicker basket (empty) | `assets/shop_game/props/basket.webp` |
| Spring scale | Red spring scale with needle | `assets/shop_game/props/scale.webp` |
| Cash register | Retro-style register | `assets/shop_game/props/cash_register.webp` |
| Coin jar | Glass jar with gold coins | `assets/shop_game/props/coin_jar.webp` |
| Red apple | 🍎 item sprite | `assets/shop_game/items/red_apple.webp` |
| Banana | 🍌 item sprite | `assets/shop_game/items/banana.webp` |
| Pumpkin | 🎃 item sprite | `assets/shop_game/items/pumpkin.webp` |
| Orange | 🍊 item sprite | `assets/shop_game/items/orange.webp` |
| Watermelon | 🍉 item sprite | `assets/shop_game/items/watermelon.webp` |
| Gold coin | Single coin sprite | `assets/shop_game/items/gold_coin.webp` |
| Star (filled) | Gold star | `assets/shop_game/hud/star_filled.webp` |
| Star (empty) | Grey star outline | `assets/shop_game/hud/star_empty.webp` |
| Hand tutor | White semi-transparent hand | `assets/shop_game/hud/hand_tutor.webp` |

### 11.2 Lottie Animations

| Asset | States | File |
|-------|--------|------|
| Bác Gấu | idle, happy | `assets/shop_game/characters/bear_idle.json`, `bear_happy.json` |

### 11.3 Audio (MP3)

See Section 5.4 for full list. Directory: `assets/shop_game/audio/`.

---

## 12. Dependencies Changes

### Add to `pubspec.yaml`:
```yaml
# Already present, keep:
flutter_bloc: ^8.1.1
equatable: ^2.0.5
hive_flutter: ^1.1.0
flutter_animate: ^4.5.2
lottie: ^3.1.3
confetti: ^0.8.0
flutter_tts: 3.4.0
go_router: ^6.0.9
get_it: ^8.0.3

# Add:
just_audio: ^0.9.39       # BGM + SFX playback
uuid: ^4.5.1              # Generate unique IDs for play sessions
```

### Remove from new code path (legacy keeps them):
No packages removed in Phase 1 — legacy code still uses `riverpod`, `get`, `provider`, etc. Removal happens in future phases as legacy features are migrated.

---

## 13. Phase Roadmap (Future Reference)

| Phase | Focus | Key Additions |
|-------|-------|---------------|
| **Phase 1** (this spec) | Core MVP | Clean Arch, drag-drop game, TTS, 3 levels |
| **Phase 2** | Rich interaction | Voice input, cash register keypad, timer, adaptive difficulty, more levels |
| **Phase 3** | Connected | Backend API, offline sync, Parent Dashboard, VIP shops, more characters |
| **Phase 4** | Revenue | Rewarded Ads, IAP, COPPA/GDPR-K, polish, 10+ levels |
