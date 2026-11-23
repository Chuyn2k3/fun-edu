import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collection/collection_provider.dart';
import '../../game/data/game_repository.dart';
import '../../profile/avatars.dart';
import '../../profile/kid_repository.dart';
import '../api_client.dart';
import '../auth/session_controller.dart';
import '../online_config.dart';

/// Pinned item in kid's showcase (sticker or badge).
const int maxShowcasePinned = 3;

/// Coalescing interval: max 1 PUT / 5 minutes per kid.
const Duration showcaseSyncCoalesceInterval = Duration(minutes: 5);

/// Per-kid key for pinned showcase items (comma-separated list of item IDs).
String showcasePinnedKey(int kidId) => 'showcasePinned.$kidId';

/// Learning progress included in Tủ khoe when enabled by parent.
class ShowcaseLearning {
  const ShowcaseLearning({
    required this.glyphs,
    required this.lessons,
    required this.stars,
  });

  final int glyphs;
  final int lessons;
  final int stars;

  factory ShowcaseLearning.fromJson(Map<String, dynamic> json) {
    return ShowcaseLearning(
      glyphs: (json['glyphs'] as num?)?.toInt() ?? 0,
      lessons: (json['lessons'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'glyphs': glyphs,
        'lessons': lessons,
        'stars': stars,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowcaseLearning &&
          runtimeType == other.runtimeType &&
          glyphs == other.glyphs &&
          lessons == other.lessons &&
          stars == other.stars;

  @override
  int get hashCode => Object.hash(glyphs, lessons, stars);
}

/// The showcase card payload for a kid.
class ShowcaseData {
  const ShowcaseData({
    required this.nickname,
    required this.avatar,
    required this.rocket,
    required this.trail,
    this.pinned = const [],
    this.races = 0,
    this.wins = 0,
    this.stickers = 0,
    this.learning,
    this.reactions = const {'clap': 0, 'heart': 0, 'star': 0},
    this.mine = const {},
  });

  final String nickname;
  final String avatar;
  final String rocket;
  final String trail;
  final List<String> pinned;
  final int races;
  final int wins;
  final int stickers;
  final ShowcaseLearning? learning;
  final Map<String, int> reactions;
  final Set<String> mine;

  factory ShowcaseData.fromJson(Map<String, dynamic> json) {
    final pinnedRaw = json['pinned'];
    final pinned = <String>[];
    if (pinnedRaw is List) {
      for (final item in pinnedRaw) {
        if (item is String && item.isNotEmpty && pinned.length < maxShowcasePinned) {
          pinned.add(item);
        }
      }
    }

    final reactionsRaw = json['reactions'];
    final reactions = <String, int>{'clap': 0, 'heart': 0, 'star': 0};
    if (reactionsRaw is Map) {
      for (final k in ['clap', 'heart', 'star']) {
        final count = reactionsRaw[k];
        if (count is num) reactions[k] = count.toInt();
      }
    }

    final mineRaw = json['mine'];
    final mine = <String>{};
    if (mineRaw is List) {
      for (final item in mineRaw) {
        if (item is String) mine.add(item);
      }
    }

    final learningRaw = json['learning'];
    final learning = learningRaw is Map<String, dynamic>
        ? ShowcaseLearning.fromJson(learningRaw)
        : (learningRaw is Map
            ? ShowcaseLearning.fromJson(Map<String, dynamic>.from(learningRaw))
            : null);

    return ShowcaseData(
      nickname: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? (json['nickname'] as String).trim()
          : 'Bạn đua',
      avatar: (json['avatar'] as String?) ?? kidAvatars[1],
      rocket: (json['rocket'] as String?) ?? 'rocket_orange',
      trail: (json['trail'] as String?) ?? 'flame',
      pinned: pinned,
      races: (json['races'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      stickers: (json['stickers'] as num?)?.toInt() ?? 0,
      learning: learning,
      reactions: reactions,
      mine: mine,
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'avatar': avatar,
        'rocket': rocket,
        'trail': trail,
        'pinned': pinned,
        'races': races,
        'wins': wins,
        'stickers': stickers,
        if (learning != null) 'learning': learning!.toJson(),
      };

  ShowcaseData copyWith({
    String? nickname,
    String? avatar,
    String? rocket,
    String? trail,
    List<String>? pinned,
    int? races,
    int? wins,
    int? stickers,
    ShowcaseLearning? learning,
    Map<String, int>? reactions,
    Set<String>? mine,
  }) {
    return ShowcaseData(
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      rocket: rocket ?? this.rocket,
      trail: trail ?? this.trail,
      pinned: pinned ?? this.pinned,
      races: races ?? this.races,
      wins: wins ?? this.wins,
      stickers: stickers ?? this.stickers,
      learning: learning ?? this.learning,
      reactions: reactions ?? this.reactions,
      mine: mine ?? this.mine,
    );
  }
}

/// Client for showcase REST endpoints.
class ShowcaseApi {
  ShowcaseApi(this._apiClient, this._ref);

  final ApiClient _apiClient;
  final Ref _ref;

  Future<void> putShowcase(String kidUuid, Map<String, dynamic> payload) async {
    await _ref.read(sessionProvider.notifier).authorized((token) {
      return _apiClient.put(
        '/api/v1/showcase/$kidUuid',
        payload,
        accessToken: token,
      );
    });
  }

  Future<ShowcaseData?> getShowcase(String familyId, String kidUuid) async {
    final res = await _ref.read(sessionProvider.notifier).authorized((token) {
      return _apiClient.get(
        '/api/v1/showcase/$familyId/$kidUuid',
        accessToken: token,
      );
    });
    if (res == null) return null;
    return ShowcaseData.fromJson(res);
  }

  Future<void> react(String familyId, String kidUuid, String kind) async {
    await _ref.read(sessionProvider.notifier).authorized((token) {
      return _apiClient.post(
        '/api/v1/showcase/$familyId/$kidUuid/react',
        {'kind': kind},
        accessToken: token,
      );
    });
  }
}

final showcaseApiProvider = Provider<ShowcaseApi>((ref) {
  return ShowcaseApi(ref.watch(apiClientProvider), ref);
});

/// Fetches pinned item IDs for [kidId] from preferences.
final kidPinnedShowcaseProvider = FutureProvider.family<List<String>, int>((ref, kidId) async {
  final raw = await ref.watch(kidRepositoryProvider).setting(showcasePinnedKey(kidId));
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return [
        for (final item in decoded)
          if (item is String && item.isNotEmpty) item
      ];
    }
  } catch (_) {
    return raw.split(',').where((s) => s.trim().isNotEmpty).toList();
  }
  return const [];
});

/// Pinned item IDs for the current selected kid.
final pinnedShowcaseProvider = FutureProvider<List<String>>((ref) async {
  final kidId = await ref.watch(currentKidIdProvider.future);
  if (kidId == null) return const [];
  return ref.watch(kidPinnedShowcaseProvider(kidId).future);
});

/// Builds the local [ShowcaseData] for the current kid from device databases.
final ownShowcaseProvider = FutureProvider<ShowcaseData?>((ref) async {
  final kidId = await ref.watch(currentKidIdProvider.future);
  if (kidId == null) return null;

  final repo = ref.watch(kidRepositoryProvider);
  final kids = await repo.kids();
  final kid = kids.where((k) => k.id == kidId).firstOrNull;
  if (kid == null) return null;

  final raceNick = await repo.setting('raceNickname.$kidId');
  final nickname = (raceNick?.trim().isNotEmpty == true)
      ? raceNick!.trim()
      : kid.nickname;

  final rocket = await repo.setting('rocket.$kidId') ?? 'rocket_orange';
  final trail = await repo.setting('trail.$kidId') ?? 'flame';
  final pinned = await ref.watch(pinnedShowcaseProvider.future);

  final gameRepo = await ref.watch(gameRepositoryProvider.future);
  final stats = await gameRepo.overallStats();
  final ownedBadges = await gameRepo.badges();
  final ownedItems = await gameRepo.newGarageItems(); // fallback items

  // Calculate learning stats
  final learningOn = await ref.watch(showcaseLearningProvider.future);
  ShowcaseLearning? learning;
  if (learningOn) {
    try {
      final snap = await ref.watch(collectionSnapshotProvider.future);
      learning = ShowcaseLearning(
        glyphs: snap.masteredWriting,
        lessons: snap.totalLessons,
        stars: snap.totalStars,
      );
    } catch (_) {}
  }

  return ShowcaseData(
    nickname: nickname,
    avatar: safeOnlineAvatar(kid.avatar),
    rocket: rocket,
    trail: trail,
    pinned: pinned,
    races: stats.races,
    wins: stats.wins,
    stickers: ownedBadges.length + ownedItems.length,
    learning: learning,
  );
});

/// Clock provider for coalescing sync.
final showcaseClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Synchronizes kid's showcase to server (coalesced, max 1 PUT / 5 min / kid).
class ShowcaseSync {
  ShowcaseSync(this._ref);

  final Ref _ref;
  final Map<int, DateTime> _lastSyncTimes = {};

  @visibleForTesting
  void clearLastSyncTimes() => _lastSyncTimes.clear();

  Future<bool> request({int? kidId}) async {
    final online = _ref.read(onlineConfigProvider).enabled;
    if (!online) return false;
    final session = await _ref.read(sessionProvider.future);
    if (session == null) return false;

    final targetKidId = kidId ?? await _ref.read(currentKidIdProvider.future);
    if (targetKidId == null) return false;

    final showcaseOn =
        await _ref.read(kidShowcaseOnProvider(targetKidId).future);
    if (!showcaseOn) return false;

    final now = _ref.read(showcaseClockProvider)();
    final last = _lastSyncTimes[targetKidId];
    if (last != null && now.difference(last) < showcaseSyncCoalesceInterval) {
      return false; // Coalesced
    }

    final repo = _ref.read(kidRepositoryProvider);
    final kids = await repo.kids();
    final kid = kids.where((k) => k.id == targetKidId).firstOrNull;
    if (kid == null) return false;

    final raceNick = await repo.setting('raceNickname.$targetKidId');
    final nickname = (raceNick?.trim().isNotEmpty == true)
        ? raceNick!.trim()
        : kid.nickname;

    final rocket =
        await repo.setting('rocket.$targetKidId') ?? 'rocket_orange';
    final trail = await repo.setting('trail.$targetKidId') ?? 'flame';
    final pinned =
        await _ref.read(kidPinnedShowcaseProvider(targetKidId).future);

    final gameRepo = await _ref.read(gameRepositoryProvider.future);
    final stats = await gameRepo.overallStats(targetKidId);
    final ownedBadges = await gameRepo.badges(targetKidId);

    final learningOn =
        await _ref.read(kidShowcaseLearningProvider(targetKidId).future);
    ShowcaseLearning? learning;
    if (learningOn) {
      try {
        final snap = await _ref.read(collectionSnapshotProvider.future);
        learning = ShowcaseLearning(
          glyphs: snap.masteredWriting,
          lessons: snap.totalLessons,
          stars: snap.totalStars,
        );
      } catch (_) {}
    }

    final kidUuid = kid.uuid;
    if (kidUuid == null || kidUuid.isEmpty) return false;

    final payload = ShowcaseData(
      nickname: nickname,
      avatar: safeOnlineAvatar(kid.avatar),
      rocket: rocket,
      trail: trail,
      pinned: pinned,
      races: stats.races,
      wins: stats.wins,
      stickers: ownedBadges.length,
      learning: learning,
    ).toJson();

    try {
      await _ref.read(showcaseApiProvider).putShowcase(kidUuid, payload);
      _lastSyncTimes[targetKidId] = now;
      return true;
    } catch (_) {
      return false;
    }
  }
}

final showcaseSyncProvider = Provider<ShowcaseSync>((ref) {
  return ShowcaseSync(ref);
});

/// Safe avatar selection falling back to kidAvatars.
String safeOnlineAvatar(String avatar) {
  return kidAvatars.contains(avatar) ? avatar : kidAvatars[1];
}

/// Sets pinned items for [kidId] (up to [maxShowcasePinned]).
Future<void> savePinnedShowcaseItems(
  WidgetRef ref,
  int kidId,
  List<String> items,
) async {
  final pinned = items.take(maxShowcasePinned).toList();
  await ref.read(kidRepositoryProvider).setSetting(
        showcasePinnedKey(kidId),
        jsonEncode(pinned),
      );
  ref.invalidate(kidPinnedShowcaseProvider(kidId));
  ref.invalidate(pinnedShowcaseProvider);
  ref.invalidate(ownShowcaseProvider);
  await ref.read(showcaseSyncProvider).request(kidId: kidId);
}
