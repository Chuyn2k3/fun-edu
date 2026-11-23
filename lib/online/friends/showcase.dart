import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../game/data/reward_pool.dart';
import '../../learning/writing_ladder.dart';
import '../../progress/progress_repository.dart';
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

  /// Removes this family's showcase of [kidUuid] (ba mẹ turned it off).
  Future<void> deleteShowcase(String kidUuid) async {
    await _ref.read(sessionProvider.notifier).authorized((token) {
      return _apiClient.delete('/api/v1/showcase/$kidUuid', accessToken: token);
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

/// Game items that count as stickers in the showcase (not rockets or trails).
bool _isSticker(String itemId) =>
    itemId.startsWith('sticker_') || rareStickers.contains(itemId);

/// The showcase card of [kidId], built from this device's data. One builder
/// for the kid's own preview and for what is sent to friends, so both always
/// match. Learning numbers are the [kidId]'s own, not the current kid's.
Future<ShowcaseData?> buildShowcaseData(
  AppDatabase db,
  int kidId, {
  required bool includeLearning,
}) async {
  final repo = KidRepository(db);
  final kid = (await repo.kids()).where((k) => k.id == kidId).firstOrNull;
  if (kid == null) return null;

  final raceNick = (await repo.setting('raceNickname.$kidId'))?.trim();
  final nickname =
      (raceNick != null && raceNick.isNotEmpty) ? raceNick : kid.nickname;

  final profile = await (db.select(db.gameProfile)
        ..where((t) => t.kidId.equals(kidId)))
      .getSingleOrNull();
  final game = GameRepository(db, kidId: kidId);
  final stats = await game.overallStats(kidId);
  final owned = await game.owned();

  ShowcaseLearning? learning;
  if (includeLearning) {
    final progress = ProgressRepository(db, kidId: kidId);
    final glyphStats = await progress.glyphStats();
    learning = ShowcaseLearning(
      glyphs: writingLadder.where((id) => glyphStats[id]?.mastered ?? false).length,
      lessons: await progress.totalLessons(),
      stars: await progress.totalStars(),
    );
  }

  return ShowcaseData(
    nickname: nickname,
    avatar: safeOnlineAvatar(kid.avatar),
    rocket: profile?.selectedRocket ?? 'rocket_orange',
    trail: profile?.selectedTrail ?? 'trail_flame',
    pinned: _decodePinned(await repo.setting(showcasePinnedKey(kidId))),
    races: stats.races,
    wins: stats.wins,
    stickers: owned.where(_isSticker).length,
    learning: learning,
  );
}

List<String> _decodePinned(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return [for (final i in decoded) if (i is String && i.isNotEmpty) i];
    }
  } catch (_) {
    return raw.split(',').where((s) => s.trim().isNotEmpty).toList();
  }
  return const [];
}

/// The current kid's showcase card, as friends will see it.
final ownShowcaseProvider = FutureProvider<ShowcaseData?>((ref) async {
  final kidId = await ref.watch(currentKidIdProvider.future);
  if (kidId == null) return null;
  // Re-read when the pins or the switch change.
  await ref.watch(pinnedShowcaseProvider.future);
  final learningOn = await ref.watch(showcaseLearningProvider.future);
  return buildShowcaseData(ref.watch(databaseProvider), kidId,
      includeLearning: learningOn);
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

  /// Sends [kidId]'s card (the current kid when null). At most one send
  /// every 5 minutes per kid, unless [force] (a parent switch just changed:
  /// friends must see it now).
  Future<bool> request({int? kidId, bool force = false}) async {
    final targetKidId = await _signedInKid(kidId);
    if (targetKidId == null) return false;

    final showcaseOn =
        await _ref.read(kidShowcaseOnProvider(targetKidId).future);
    if (!showcaseOn) return false;

    final now = _ref.read(showcaseClockProvider)();
    final last = _lastSyncTimes[targetKidId];
    if (!force &&
        last != null &&
        now.difference(last) < showcaseSyncCoalesceInterval) {
      return false; // Coalesced
    }

    final learningOn =
        await _ref.read(kidShowcaseLearningProvider(targetKidId).future);
    final db = _ref.read(databaseProvider);
    final data =
        await buildShowcaseData(db, targetKidId, includeLearning: learningOn);
    final kidUuid = await _kidUuid(targetKidId);
    if (data == null || kidUuid == null) return false;

    try {
      await _ref.read(showcaseApiProvider).putShowcase(kidUuid, data.toJson());
      _lastSyncTimes[targetKidId] = now;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes [kidId]'s card from the server (ba mẹ turned the showcase off).
  Future<bool> takeDown(int kidId) async {
    if (await _signedInKid(kidId) == null) return false;
    final kidUuid = await _kidUuid(kidId);
    if (kidUuid == null) return false;
    try {
      await _ref.read(showcaseApiProvider).deleteShowcase(kidUuid);
      _lastSyncTimes.remove(kidId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int?> _signedInKid(int? kidId) async {
    if (!_ref.read(onlineConfigProvider).enabled) return null;
    final session = await _ref.read(sessionProvider.future);
    if (session == null) return null;
    return kidId ?? await _ref.read(currentKidIdProvider.future);
  }

  Future<String?> _kidUuid(int kidId) async {
    final kids = await KidRepository(_ref.read(databaseProvider)).kids();
    final uuid = kids.where((k) => k.id == kidId).firstOrNull?.uuid;
    return (uuid == null || uuid.isEmpty) ? null : uuid;
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
