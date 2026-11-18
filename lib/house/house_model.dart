import 'dart:convert';

import 'package:flutter/material.dart';

import '../ui/theme/tokens.dart';

/// Room decoration slots in Nhà Chíp.
enum HouseSlot {
  wall('Tường'),
  rug('Thảm'),
  decor('Góc phòng'),
  buddy('Phụ kiện');

  const HouseSlot(this.label);

  final String label;
}

/// Growth stage of Chíp based on cumulative [ChipHouseState.xp].
class ChipStage {
  const ChipStage({
    required this.level,
    required this.title,
    required this.minXp,
    required this.description,
  });

  final int level;
  final String title;
  final int minXp;
  final String description;
}

const List<ChipStage> chipStages = [
  ChipStage(
    level: 1,
    title: 'Chíp Sơ Sinh',
    minXp: 0,
    description: 'Bé Chíp mới tập nói líu lo',
  ),
  ChipStage(
    level: 2,
    title: 'Chíp Tập Bay',
    minXp: 30,
    description: 'Đôi cánh nhỏ đã cứng cáp hơn',
  ),
  ChipStage(
    level: 3,
    title: 'Chíp Ham Học',
    minXp: 80,
    description: 'Mê đọc chữ và đếm ngôi sao',
  ),
  ChipStage(
    level: 4,
    title: 'Chíp Khám Phá',
    minXp: 150,
    description: 'Dạn dĩ khám phá khắp khu vườn',
  ),
  ChipStage(
    level: 5,
    title: 'Chíp Trạng Nguyên',
    minXp: 250,
    description: 'Thông minh, chăm ngoan cả 4 môn!',
  ),
];

/// Returns the current [ChipStage] for [xp].
ChipStage stageForXp(int xp) {
  var current = chipStages.first;
  for (final s in chipStages) {
    if (xp >= s.minXp) current = s;
  }
  return current;
}

/// Returns the next [ChipStage], or null if already at max stage.
ChipStage? nextStageForXp(int xp) {
  for (final s in chipStages) {
    if (xp < s.minXp) return s;
  }
  return null;
}

/// Fraction (0..1) of progress toward the next growth stage.
double stageProgressForXp(int xp) {
  final current = stageForXp(xp);
  final next = nextStageForXp(xp);
  if (next == null) return 1.0;
  final span = next.minXp - current.minXp;
  if (span <= 0) return 1.0;
  return ((xp - current.minXp) / span).clamp(0.0, 1.0);
}

/// One treat the kid can feed Chíp.
class HouseTreat {
  const HouseTreat({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reaction,
    required this.costStars,
    required this.xpGain,
    required this.icon,
    required this.color,
    this.isDailyFree = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String reaction;
  final int costStars;
  final int xpGain;
  final IconData icon;
  final Color color;
  final bool isDailyFree;
}

const List<HouseTreat> houseTreats = [
  HouseTreat(
    id: 'acorn_free',
    title: 'Hạt dẻ giòn',
    subtitle: 'Miễn phí mỗi ngày',
    reaction: 'Ngon quá, giòn rụm luôn! Cảm ơn bé!',
    costStars: 0,
    xpGain: 10,
    icon: Icons.eco_rounded,
    color: HouseColors.treatAcorn,
    isDailyFree: true,
  ),
  HouseTreat(
    id: 'apple',
    title: 'Táo đỏ ngọt',
    subtitle: 'Giòn ngọt đầy sức khỏe',
    reaction: 'Táo đỏ ngọt lịm, Chíp khỏe re rồi!',
    costStars: 2,
    xpGain: 15,
    icon: Icons.apple_rounded,
    color: HouseColors.treatApple,
  ),
  HouseTreat(
    id: 'honey_cake',
    title: 'Bánh mật ong',
    subtitle: 'Thơm lừng ấm áp',
    reaction: 'Chà, bánh mật ong thơm phức quá đi!',
    costStars: 4,
    xpGain: 30,
    icon: Icons.bakery_dining_rounded,
    color: HouseColors.treatHoney,
  ),
  HouseTreat(
    id: 'star_cake',
    title: 'Bánh kem sao',
    subtitle: 'Tiệc ngọt đặc biệt',
    reaction: 'Oa! Tiệc bánh kem ngôi sao tuyệt vời nhất!',
    costStars: 6,
    xpGain: 50,
    icon: Icons.cake_rounded,
    color: HouseColors.treatCake,
  ),
];

/// One room decoration item.
class HouseItem {
  const HouseItem({
    required this.id,
    required this.slot,
    required this.title,
    required this.costStars,
    required this.swatch,
    required this.icon,
  });

  final String id;
  final HouseSlot slot;
  final String title;
  final int costStars;
  final Color swatch;
  final IconData icon;
}

const List<HouseItem> houseCatalog = [
  // Wall themes
  HouseItem(
    id: 'wall_sunny',
    slot: HouseSlot.wall,
    title: 'Phòng nắng ấm',
    costStars: 0,
    swatch: HouseColors.sunnyWallBottom,
    icon: Icons.wb_sunny_rounded,
  ),
  HouseItem(
    id: 'wall_forest',
    slot: HouseSlot.wall,
    title: 'Nhà trên cây',
    costStars: 8,
    swatch: HouseColors.forestWallBottom,
    icon: Icons.park_rounded,
  ),
  HouseItem(
    id: 'wall_ocean',
    slot: HouseSlot.wall,
    title: 'Phòng biển xanh',
    costStars: 12,
    swatch: HouseColors.oceanWallBottom,
    icon: Icons.waves_rounded,
  ),
  HouseItem(
    id: 'wall_starry',
    slot: HouseSlot.wall,
    title: 'Bầu trời sao',
    costStars: 16,
    swatch: HouseColors.starryWallBottom,
    icon: Icons.nights_stay_rounded,
  ),

  // Rugs
  HouseItem(
    id: 'rug_cream',
    slot: HouseSlot.rug,
    title: 'Thảm tròn kem',
    costStars: 0,
    swatch: HouseColors.rugCreamEdge,
    icon: Icons.circle_outlined,
  ),
  HouseItem(
    id: 'rug_rainbow',
    slot: HouseSlot.rug,
    title: 'Thảm cầu vồng',
    costStars: 6,
    swatch: HouseColors.rugRainbow1,
    icon: Icons.looks_rounded,
  ),
  HouseItem(
    id: 'rug_cloud',
    slot: HouseSlot.rug,
    title: 'Thảm đám mây',
    costStars: 10,
    swatch: HouseColors.rugCloudEdge,
    icon: Icons.cloud_rounded,
  ),
  HouseItem(
    id: 'rug_star',
    slot: HouseSlot.rug,
    title: 'Thảm ngôi sao',
    costStars: 14,
    swatch: HouseColors.rugStarEdge,
    icon: Icons.star_rounded,
  ),

  // Corner decor
  HouseItem(
    id: 'decor_shelf',
    slot: HouseSlot.decor,
    title: 'Kệ sách nhỏ',
    costStars: 0,
    swatch: HouseColors.shelfWood,
    icon: Icons.menu_book_rounded,
  ),
  HouseItem(
    id: 'decor_plant',
    slot: HouseSlot.decor,
    title: 'Chậu cây xanh',
    costStars: 5,
    swatch: HouseColors.plantLight,
    icon: Icons.local_florist_rounded,
  ),
  HouseItem(
    id: 'decor_lamp',
    slot: HouseSlot.decor,
    title: 'Đèn mặt trăng',
    costStars: 9,
    swatch: HouseColors.lampStand,
    icon: Icons.lightbulb_rounded,
  ),
  HouseItem(
    id: 'decor_globe',
    slot: HouseSlot.decor,
    title: 'Quả địa cầu',
    costStars: 12,
    swatch: HouseColors.globeWater,
    icon: Icons.public_rounded,
  ),

  // Buddy / accessories
  HouseItem(
    id: 'buddy_none',
    slot: HouseSlot.buddy,
    title: 'Chíp tự nhiên',
    costStars: 0,
    swatch: AppColors.accent,
    icon: Icons.pets_rounded,
  ),
  HouseItem(
    id: 'buddy_pillow',
    slot: HouseSlot.buddy,
    title: 'Gối ngôi sao',
    costStars: 8,
    swatch: CollectionColors.goldBorder,
    icon: Icons.auto_awesome_rounded,
  ),
  HouseItem(
    id: 'buddy_crown',
    slot: HouseSlot.buddy,
    title: 'Vương miện nhỏ',
    costStars: 10,
    swatch: HouseColors.treatHoney,
    icon: Icons.workspace_premium_rounded,
  ),
  HouseItem(
    id: 'buddy_crayon',
    slot: HouseSlot.buddy,
    title: 'Bút sáp vui vẻ',
    costStars: 12,
    swatch: AppColors.accent,
    icon: Icons.brush_rounded,
  ),
];

const Set<String> defaultOwnedHouseItems = {
  'wall_sunny',
  'rug_cream',
  'decor_shelf',
  'buddy_none',
};

const Map<HouseSlot, String> defaultEquippedHouseItems = {
  HouseSlot.wall: 'wall_sunny',
  HouseSlot.rug: 'rug_cream',
  HouseSlot.decor: 'decor_shelf',
  HouseSlot.buddy: 'buddy_none',
};

List<HouseItem> houseItemsForSlot(HouseSlot slot) =>
    houseCatalog.where((i) => i.slot == slot).toList(growable: false);

String dayKeyOf(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Persistent per-kid state for Nhà Chíp.
class ChipHouseState {
  const ChipHouseState({
    this.xp = 0,
    this.spentStars = 0,
    this.ownedIds = defaultOwnedHouseItems,
    this.equipped = defaultEquippedHouseItems,
    this.lastFreeTreatDay,
  });

  final int xp;
  final int spentStars;
  final Set<String> ownedIds;
  final Map<HouseSlot, String> equipped;
  final String? lastFreeTreatDay;

  ChipStage get stage => stageForXp(xp);
  ChipStage? get nextStage => nextStageForXp(xp);
  double get stageProgress => stageProgressForXp(xp);

  String equippedId(HouseSlot slot) =>
      equipped[slot] ?? defaultEquippedHouseItems[slot]!;

  bool isOwned(String itemId) =>
      defaultOwnedHouseItems.contains(itemId) || ownedIds.contains(itemId);

  bool canClaimFreeTreat(DateTime now) => lastFreeTreatDay != dayKeyOf(now);

  int availableStars(int totalLearningStars) {
    final left = totalLearningStars - spentStars;
    return left < 0 ? 0 : left;
  }

  ChipHouseState copyWith({
    int? xp,
    int? spentStars,
    Set<String>? ownedIds,
    Map<HouseSlot, String>? equipped,
    String? lastFreeTreatDay,
  }) =>
      ChipHouseState(
        xp: xp ?? this.xp,
        spentStars: spentStars ?? this.spentStars,
        ownedIds: ownedIds ?? this.ownedIds,
        equipped: equipped ?? this.equipped,
        lastFreeTreatDay: lastFreeTreatDay ?? this.lastFreeTreatDay,
      );

  Map<String, Object?> toJson() => {
        'xp': xp,
        'spentStars': spentStars,
        'ownedIds': ownedIds.toList(),
        'equipped': {
          for (final e in equipped.entries) e.key.name: e.value,
        },
        if (lastFreeTreatDay != null) 'lastFreeTreatDay': lastFreeTreatDay,
      };

  String encode() => jsonEncode(toJson());

  static ChipHouseState decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ChipHouseState();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final xp = (map['xp'] as num?)?.toInt() ?? 0;
      final spent = (map['spentStars'] as num?)?.toInt() ?? 0;
      final ownedRaw = map['ownedIds'];
      final owned = <String>{
        ...defaultOwnedHouseItems,
        if (ownedRaw is List)
          for (final item in ownedRaw)
            if (item is String) item,
      };
      final eqMap = Map<HouseSlot, String>.from(defaultEquippedHouseItems);
      final eqRaw = map['equipped'];
      if (eqRaw is Map) {
        for (final slot in HouseSlot.values) {
          final v = eqRaw[slot.name];
          if (v is String && owned.contains(v)) {
            eqMap[slot] = v;
          }
        }
      }
      final lastFree = map['lastFreeTreatDay'] as String?;
      return ChipHouseState(
        xp: xp < 0 ? 0 : xp,
        spentStars: spent < 0 ? 0 : spent,
        ownedIds: owned,
        equipped: eqMap,
        lastFreeTreatDay: lastFree,
      );
    } catch (_) {
      return const ChipHouseState();
    }
  }
}

/// Outcome of feeding Chíp.
class FeedResult {
  const FeedResult({
    required this.ok,
    required this.state,
    required this.leveledUp,
    required this.message,
  });

  final bool ok;
  final ChipHouseState state;
  final bool leveledUp;
  final String message;
}

/// Pure transition for feeding [treat] to Chíp.
FeedResult applyFeed({
  required ChipHouseState current,
  required HouseTreat treat,
  required int totalLearningStars,
  required DateTime now,
}) {
  if (treat.isDailyFree && !current.canClaimFreeTreat(now)) {
    return FeedResult(
      ok: false,
      state: current,
      leveledUp: false,
      message: 'Hôm nay Chíp ăn hạt dẻ rồi, ngày mai lại có nhé!',
    );
  }
  final avail = current.availableStars(totalLearningStars);
  if (treat.costStars > avail) {
    final need = treat.costStars - avail;
    return FeedResult(
      ok: false,
      state: current,
      leveledUp: false,
      message: 'Cần thêm $need sao nữa. Mình học thêm 1 bài để hái sao nhé!',
    );
  }

  final oldLevel = current.stage.level;
  final nextState = current.copyWith(
    xp: current.xp + treat.xpGain,
    spentStars: current.spentStars + treat.costStars,
    lastFreeTreatDay:
        treat.isDailyFree ? dayKeyOf(now) : current.lastFreeTreatDay,
  );
  final leveledUp = nextState.stage.level > oldLevel;
  final msg = leveledUp
      ? 'Hoan hô! Chíp vừa lớn lên Cấp ${nextState.stage.level} — ${nextState.stage.title}!'
      : treat.reaction;
  return FeedResult(
    ok: true,
    state: nextState,
    leveledUp: leveledUp,
    message: msg,
  );
}

/// Outcome of buying or equipping a room decoration item.
class DecorResult {
  const DecorResult({
    required this.ok,
    required this.purchased,
    required this.state,
    required this.message,
  });

  final bool ok;
  final bool purchased;
  final ChipHouseState state;
  final String message;
}

/// Pure transition for equipping an owned item or buying & equipping a new one.
DecorResult applyBuyOrEquip({
  required ChipHouseState current,
  required HouseItem item,
  required int totalLearningStars,
}) {
  if (current.isOwned(item.id)) {
    final nextEquipped = Map<HouseSlot, String>.from(current.equipped)
      ..[item.slot] = item.id;
    return DecorResult(
      ok: true,
      purchased: false,
      state: current.copyWith(equipped: nextEquipped),
      message: 'Đã trang trí ${item.title} rồi nè!',
    );
  }
  final avail = current.availableStars(totalLearningStars);
  if (item.costStars > avail) {
    final need = item.costStars - avail;
    return DecorResult(
      ok: false,
      purchased: false,
      state: current,
      message: 'Cần thêm $need sao nữa để mở ${item.title} nhé!',
    );
  }
  final nextOwned = Set<String>.from(current.ownedIds)..add(item.id);
  final nextEquipped = Map<HouseSlot, String>.from(current.equipped)
    ..[item.slot] = item.id;
  return DecorResult(
    ok: true,
    purchased: true,
    state: current.copyWith(
      spentStars: current.spentStars + item.costStars,
      ownedIds: nextOwned,
      equipped: nextEquipped,
    ),
    message: 'Oa! Phòng của Chíp có ${item.title} đẹp quá!',
  );
}
