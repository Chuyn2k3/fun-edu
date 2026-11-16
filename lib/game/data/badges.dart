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
    howTo: 'Một trận đúng cả 10 câu ngay lần đầu',
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
  );

  const GameBadge({
    required this.id,
    required this.title,
    required this.howTo,
    required this.stickerId,
    required this.image,
  });

  final String id;
  final String title;
  final String howTo;
  final String stickerId;
  final String image;

  static GameBadge? byId(String id) {
    for (final b in values) {
      if (b.id == id) return b;
    }
    return null;
  }
}
