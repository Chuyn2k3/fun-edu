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
}
