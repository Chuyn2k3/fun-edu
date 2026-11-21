import '../../ui/assets.dart';

enum GameBadge {
  speedKing(
    id: 'speed_king',
    title: 'Vua Thần Tốc',
    howTo: 'Phá kỷ lục về đích của mình 3 lần',
    stickerId: 'sticker_pilot_goggles',
    image: AppImages.badgeSpeedKing,
  ),
  scholar(
    id: 'scholar',
    title: 'Nhà Thông Thái',
    howTo: 'Về đích mà không sai câu nào',
    stickerId: 'sticker_grad_cap',
    image: AppImages.badgeScholar,
  ),
  cometHunter(
    id: 'comet_hunter',
    title: 'Thợ Săn Sao Chổi',
    howTo: 'Trả lời đúng 10 câu sao chổi',
    stickerId: 'sticker_hug_star',
    image: AppImages.badgeCometHunter,
  ),
  neverGiveUp(
    id: 'never_give_up',
    title: 'Không Bỏ Cuộc',
    howTo: 'Đua lại ngay sau khi thua, 3 lần',
    stickerId: 'sticker_fist',
    image: AppImages.badgeNeverGiveUp,
  ),
  chipBuddy(
    id: 'chip_buddy',
    title: 'Bạn Thân Chíp Chíp',
    howTo: 'Thắng Chíp 5 lần',
    stickerId: 'sticker_hug_heart',
    image: AppImages.badgeChipBuddy,
  ),
  mathWhiz(
    id: 'math_whiz',
    title: 'Siêu Toán Học',
    howTo: '50 câu Toán đúng',
    stickerId: 'sticker_abacus',
    image: AppImages.badgeMathWhiz,
  ),
  letterMaster(
    id: 'letter_master',
    title: 'Bậc Thầy Chữ Cái',
    howTo: '50 câu Tiếng Việt đúng',
    stickerId: 'sticker_crayon',
    image: AppImages.badgeLetterMaster,
  ),
  pilot(
    id: 'pilot',
    title: 'Phi Công Chăm Chỉ',
    howTo: 'Đua 20 trận',
    stickerId: 'sticker_wave_rocket',
    image: AppImages.badgePilot,
  ),

  // Online rooms (2B-2). Placeholder art from the existing 3D set until the
  // badge medals are drawn (docs/phase0/asset-list.md).
  friendRacer(
    id: 'friend_racer',
    title: 'Bạn Đua Vui Vẻ',
    howTo: 'Đua với bạn 5 trận',
    stickerId: 'sticker_thumb',
    image: AppImages.badgeFriendRacer,
    online: true,
  ),
  friendChampion(
    id: 'friend_champion',
    title: 'Nhà Vô Địch',
    howTo: 'Về nhất khi đua với bạn 3 lần',
    stickerId: 'sticker_joy',
    image: AppImages.badgeFriendChampion,
    online: true,
  ),
  bigRace(
    id: 'big_race',
    title: 'Cuộc Đua Lớn',
    howTo: 'Đua trong phòng đủ 4 bạn',
    stickerId: 'sticker_surprise',
    image: AppImages.badgeBigRace,
    online: true,
  ),
  cheerleader(
    id: 'cheerleader',
    title: 'Cổ Vũ Nhiệt Tình',
    howTo: 'Gửi 20 sticker cổ vũ cho bạn',
    stickerId: 'sticker_encourage',
    image: AppImages.icStar,
    online: true,
  );

  const GameBadge({
    required this.id,
    required this.title,
    required this.howTo,
    required this.stickerId,
    required this.image,
    this.online = false,
  });

  final String id;
  final String title;
  final String howTo;
  final String stickerId;
  final String image;

  /// Earned only by racing friends in online rooms.
  final bool online;

  static GameBadge? byId(String id) {
    for (final b in values) {
      if (b.id == id) return b;
    }
    return null;
  }
}
