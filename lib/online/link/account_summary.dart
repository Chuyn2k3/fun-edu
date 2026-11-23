import '../sync/sync_store.dart';

/// Summary of an account or device data state, used to detect whether data exists
/// and compare local guest progress with remote account progress.
class AccountSummary {
  const AccountSummary({
    required this.hasData,
    this.kids = const [],
  });

  final bool hasData;
  final List<KidSummary> kids;

  factory AccountSummary.fromJson(Map<String, dynamic> json) {
    return AccountSummary(
      hasData: json['hasData'] as bool? ?? false,
      kids: (json['kids'] as List<dynamic>? ?? [])
          .map((e) => KidSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, Object?> toJson() => {
        'hasData': hasData,
        'kids': kids.map((k) => k.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountSummary &&
          runtimeType == other.runtimeType &&
          hasData == other.hasData &&
          _listEquals(kids, other.kids);

  @override
  int get hashCode => Object.hash(hasData, Object.hashAll(kids));

  @override
  String toString() => 'AccountSummary(hasData: $hasData, kids: $kids)';
}

class KidSummary {
  const KidSummary({
    required this.nickname,
    required this.avatar,
    this.stars = 0,
    this.glyphs = 0,
    this.pages = 0,
    this.items = 0,
    this.badges = 0,
  });

  final String nickname;
  final String avatar;
  final int stars;
  final int glyphs;
  final int pages;
  final int items;
  final int badges;

  factory KidSummary.fromJson(Map<String, dynamic> json) {
    return KidSummary(
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? 'chip',
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      glyphs: (json['glyphs'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      items: (json['items'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
        'nickname': nickname,
        'avatar': avatar,
        'stars': stars,
        'glyphs': glyphs,
        'pages': pages,
        'items': items,
        'badges': badges,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KidSummary &&
          runtimeType == other.runtimeType &&
          nickname == other.nickname &&
          avatar == other.avatar &&
          stars == other.stars &&
          glyphs == other.glyphs &&
          pages == other.pages &&
          items == other.items &&
          badges == other.badges;

  @override
  int get hashCode => Object.hash(
        nickname,
        avatar,
        stars,
        glyphs,
        pages,
        items,
        badges,
      );

  @override
  String toString() =>
      'KidSummary(nickname: $nickname, avatar: $avatar, stars: $stars, glyphs: $glyphs, pages: $pages, items: $items, badges: $badges)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _toMs(Object? val) {
  if (val is num) return val.toInt();
  if (val is String) {
    final dt = DateTime.tryParse(val);
    if (dt != null) return dt.millisecondsSinceEpoch;
    return int.tryParse(val) ?? 0;
  }
  return 0;
}

/// Computes a list of [KidSummary] from sync records (as returned by `exportAll`).
List<KidSummary> summarizeRecords(Map<String, Map<String, Object?>?> records) {
  final kidUuids = <String>[];
  final kidNicknames = <String, String>{};
  final kidAvatars = <String, String>{};
  final kidCreatedAts = <String, int>{};

  // 1. Identify all active kids
  for (final entry in records.entries) {
    final key = entry.key;
    final payload = entry.value;
    if (payload == null) continue;
    if (key.startsWith('kid:')) {
      final parts = key.split(':');
      if (parts.length >= 2) {
        final ku = parts[1];
        kidUuids.add(ku);
        kidNicknames[ku] = payload['nickname'] as String? ?? '';
        kidAvatars[ku] = payload['avatar'] as String? ?? 'chip';
        kidCreatedAts[ku] = _toMs(payload['createdAt']);
      }
    }
  }

  // Sort by createdAt asc, then key asc, max 4
  kidUuids.sort((a, b) {
    final c = (kidCreatedAts[a] ?? 0).compareTo(kidCreatedAts[b] ?? 0);
    return c != 0 ? c : a.compareTo(b);
  });
  final topKids = kidUuids.take(4).toList();

  final stars = <String, int>{};
  final glyphs = <String, int>{};
  final pages = <String, int>{};
  final items = <String, int>{};
  final badges = <String, int>{};

  for (final ku in topKids) {
    stars[ku] = 0;
    glyphs[ku] = 0;
    pages[ku] = 0;
    items[ku] = 0;
    badges[ku] = 0;
  }

  for (final entry in records.entries) {
    final key = entry.key;
    final payload = entry.value;
    if (payload == null) continue;
    final parts = key.split(':');
    if (parts.length < 3) continue;
    final kind = parts[0];
    final ku = parts[1];
    if (!topKids.contains(ku)) continue;

    switch (kind) {
      case 'lesson':
        final s = (payload['stars'] as num?)?.toInt() ?? 0;
        stars[ku] = (stars[ku] ?? 0) + s;
      case 'glyph':
        glyphs[ku] = (glyphs[ku] ?? 0) + 1;
      case 'page':
        pages[ku] = (pages[ku] ?? 0) + 1;
      case 'item':
        items[ku] = (items[ku] ?? 0) + 1;
      case 'badge':
        badges[ku] = (badges[ku] ?? 0) + 1;
    }
  }

  return [
    for (final ku in topKids)
      KidSummary(
        nickname: kidNicknames[ku] ?? '',
        avatar: kidAvatars[ku] ?? 'chip',
        stars: stars[ku] ?? 0,
        glyphs: glyphs[ku] ?? 0,
        pages: pages[ku] ?? 0,
        items: items[ku] ?? 0,
        badges: badges[ku] ?? 0,
      ),
  ];
}

Future<List<KidSummary>> localSummary(SyncStore store) async {
  final records = await store.exportAll();
  return summarizeRecords(records);
}
