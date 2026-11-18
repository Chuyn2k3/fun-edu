import 'package:flutter/material.dart';

import '../ui/assets.dart';
import '../ui/theme/tokens.dart';

/// Pure learning snapshot used to compute the kid's learning stickers,
/// attendance calendar and printable certificates. Never reads game tables.
class LearningSnapshot {
  const LearningSnapshot({
    required this.kidName,
    required this.totalStars,
    required this.totalLessons,
    required this.totalLearnedDays,
    required this.learnedDaysThisWeek,
    required this.masteredWriting,
    required this.mathLevelIndex,
    required this.vietnameseLevelIndex,
    required this.englishLevelIndex,
    required this.viewedYear,
    required this.viewedMonth,
    required this.learnedDaysInMonth,
    required this.learnedToday,
  });

  final String kidName;
  final int totalStars;
  final int totalLessons;
  final int totalLearnedDays;
  final int learnedDaysThisWeek;
  final int masteredWriting;
  final int mathLevelIndex;
  final int vietnameseLevelIndex;
  final int englishLevelIndex;
  final int viewedYear;
  final int viewedMonth;
  final Set<int> learnedDaysInMonth;
  final bool learnedToday;

  String get displayKidName {
    final trimmed = kidName.trim();
    return trimmed.isEmpty ? 'Bé' : trimmed;
  }

  /// Friendly Chíp greeting for the Collection header. Never punishes missed
  /// days; gently invites the kid to learn if they haven't learned today yet.
  String get chipGreeting {
    final name = displayKidName;
    if (learnedDaysInMonth.isEmpty && totalLessons == 0) {
      return 'Chào $name! Hoàn thành bài học đầu tiên để mở sticker xinh nhé!';
    }
    if (!learnedToday) {
      return 'Chíp nhớ $name lắm! Hôm nay mình học một bài để dán thêm sao nhé!';
    }
    return 'Tuyệt quá $name ơi! Tháng này mình đã học ${learnedDaysInMonth.length} ngày rồi!';
  }
}

/// One collectible learning sticker unlocked by real learning progress.
class LearningSticker {
  const LearningSticker({
    required this.id,
    required this.title,
    required this.hint,
    required this.praise,
    required this.image,
    required this.accentColor,
    required this.current,
    required this.target,
  });

  final String id;
  final String title;
  final String hint;
  final String praise;
  final String image;
  final Color accentColor;
  final int current;
  final int target;

  bool get unlocked => current >= target;

  int get clampedCurrent => current.clamp(0, target);

  double get progress => target <= 0 ? 1.0 : (clampedCurrent / target);
}

/// One learning certificate carrying the kid's nickname.
class LearningCertificate {
  const LearningCertificate({
    required this.id,
    required this.title,
    required this.requirement,
    required this.citation,
    required this.image,
    required this.accentColor,
    required this.current,
    required this.target,
  });

  final String id;
  final String title;
  final String requirement;
  final String citation;
  final String image;
  final Color accentColor;
  final int current;
  final int target;

  bool get unlocked => current >= target;

  int get clampedCurrent => current.clamp(0, target);

  double get progress => target <= 0 ? 1.0 : (clampedCurrent / target);
}

/// Builds the 12 learning stickers deterministically from [s].
List<LearningSticker> buildLearningStickers(LearningSnapshot s) {
  final name = s.displayKidName;
  final subjectsProgressed = (s.masteredWriting >= 5 ? 1 : 0) +
      (s.mathLevelIndex + 1 >= 2 ? 1 : 0) +
      (s.vietnameseLevelIndex + 1 >= 2 ? 1 : 0) +
      (s.englishLevelIndex + 1 >= 2 ? 1 : 0);

  return [
    LearningSticker(
      id: 'first_lesson',
      title: 'Bước đầu tiên',
      hint: 'Xong 1 bài học',
      praise: 'Hoan hô $name đã hoàn thành bài học đầu tiên cùng Chíp!',
      image: AppImages.chipJoy,
      accentColor: AppColors.accent,
      current: s.totalLessons,
      target: 1,
    ),
    LearningSticker(
      id: 'three_days',
      title: 'Ong chăm chỉ',
      hint: 'Học 3 ngày',
      praise: '$name chăm chỉ như chú ong nhỏ, học đủ 3 ngày rồi!',
      image: AppImages.icFlame,
      accentColor: AppColors.accent,
      current: s.totalLearnedDays,
      target: 3,
    ),
    LearningSticker(
      id: 'seven_days',
      title: 'Tuần lễ rực rỡ',
      hint: 'Học 7 ngày',
      praise: 'Tuyệt vời! $name đã học đủ 7 ngày rực rỡ cùng Chíp!',
      image: AppImages.stickerHugHeart,
      accentColor: Subject.tiengViet.color,
      current: s.totalLearnedDays,
      target: 7,
    ),
    LearningSticker(
      id: 'ten_stars',
      title: 'Hái sao nhỏ',
      hint: 'Tích 10 ngôi sao',
      praise: '$name hái được 10 ngôi sao lấp lánh rồi đấy!',
      image: AppImages.icStar,
      accentColor: CollectionColors.goldBorder,
      current: s.totalStars,
      target: 10,
    ),
    LearningSticker(
      id: 'thirty_stars',
      title: 'Thợ săn sao',
      hint: 'Tích 30 ngôi sao',
      praise: 'Ồ! $name gom được tận 30 ngôi sao học tập luôn!',
      image: AppImages.stickerHugStar,
      accentColor: CollectionColors.goldBorder,
      current: s.totalStars,
      target: 30,
    ),
    LearningSticker(
      id: 'sixty_stars',
      title: 'Vương miện sao',
      hint: 'Tích 60 ngôi sao',
      praise: '$name thật xuất sắc, nhận vương miện 60 ngôi sao nhé!',
      image: AppImages.icCrown,
      accentColor: CollectionColors.goldBorder,
      current: s.totalStars,
      target: 60,
    ),
    LearningSticker(
      id: 'writing_5',
      title: 'Nét bút xinh',
      hint: 'Thuộc 5 nét/chữ',
      praise: 'Bàn tay $name khéo quá, đã thuộc 5 nét chữ rồi!',
      image: AppImages.chipWrite,
      accentColor: Subject.viet.color,
      current: s.masteredWriting,
      target: 5,
    ),
    LearningSticker(
      id: 'writing_20',
      title: 'Họa sĩ chữ',
      hint: 'Thuộc 20 nét/chữ',
      praise: '$name viết đẹp như họa sĩ nhí, thuộc hẳn 20 chữ!',
      image: AppImages.stickerCrayon,
      accentColor: Subject.viet.color,
      current: s.masteredWriting,
      target: 20,
    ),
    LearningSticker(
      id: 'math_lv3',
      title: 'Bé giỏi Toán',
      hint: 'Đạt cấp 3 Toán',
      praise: '$name đếm số và tính toán siêu giỏi luôn!',
      image: AppImages.icToan,
      accentColor: Subject.toan.color,
      current: s.mathLevelIndex + 1,
      target: 3,
    ),
    LearningSticker(
      id: 'vn_lv3',
      title: 'Đọc hay Tiếng Việt',
      hint: 'Đạt cấp 3 Tiếng Việt',
      praise: '$name ghép chữ và đọc Tiếng Việt hay quá đi!',
      image: AppImages.icTiengViet,
      accentColor: Subject.tiengViet.color,
      current: s.vietnameseLevelIndex + 1,
      target: 3,
    ),
    LearningSticker(
      id: 'en_lv3',
      title: 'Hello Tiếng Anh',
      hint: 'Đạt cấp 3 Tiếng Anh',
      praise: 'Good job $name! Bé học Tiếng Anh rất cừ!',
      image: AppImages.icTiengAnh,
      accentColor: Subject.tiengAnh.color,
      current: s.englishLevelIndex + 1,
      target: 3,
    ),
    LearningSticker(
      id: 'all_rounder',
      title: 'Trạng nguyên nhí',
      hint: 'Tiến bộ cả 4 môn',
      praise: '$name giỏi đều cả 4 môn học, xứng danh Trạng nguyên nhí!',
      image: AppImages.stickerGradCap,
      accentColor: AppColors.primary,
      current: subjectsProgressed,
      target: 4,
    ),
  ];
}

/// Builds the 6 learning certificates deterministically from [s].
List<LearningCertificate> buildLearningCertificates(LearningSnapshot s) {
  final name = s.displayKidName;
  return [
    LearningCertificate(
      id: 'cert_diligent',
      title: 'Bé Chăm Học',
      requirement: 'Hoàn thành 3 bài học',
      citation:
          'Ghi nhận bé $name đã chăm chỉ hoàn thành đều đặn các bài học cùng Chíp Chíp!',
      image: AppImages.icFlame,
      accentColor: AppColors.accent,
      current: s.totalLessons,
      target: 3,
    ),
    LearningCertificate(
      id: 'cert_writing',
      title: 'Bàn Tay Khéo Léo',
      requirement: 'Thuộc 10 nét/chữ Tập viết',
      citation:
          'Tuyên dương bé $name rèn nét chữ cẩn thận và thuộc nhiều chữ cái đẹp!',
      image: AppImages.icViet,
      accentColor: Subject.viet.color,
      current: s.masteredWriting,
      target: 10,
    ),
    LearningCertificate(
      id: 'cert_math',
      title: 'Sao Toán Học',
      requirement: 'Đạt cấp 3 môn Toán',
      citation:
          'Chúc mừng bé $name thông minh, nhanh nhẹn vượt qua các thử thách Toán học!',
      image: AppImages.icToan,
      accentColor: Subject.toan.color,
      current: s.mathLevelIndex + 1,
      target: 3,
    ),
    LearningCertificate(
      id: 'cert_vietnamese',
      title: 'Đọc Giỏi Tiếng Việt',
      requirement: 'Đạt cấp 3 môn Tiếng Việt',
      citation:
          'Khen ngợi bé $name nhận mặt chữ, ghép âm vần Tiếng Việt thật xuất sắc!',
      image: AppImages.icTiengViet,
      accentColor: Subject.tiengViet.color,
      current: s.vietnameseLevelIndex + 1,
      target: 3,
    ),
    LearningCertificate(
      id: 'cert_english',
      title: 'Bé Giỏi Tiếng Anh',
      requirement: 'Đạt cấp 3 môn Tiếng Anh',
      citation:
          'Chúc mừng bé $name tự tin nghe nói và ghi nhớ từ vựng Tiếng Anh thật giỏi!',
      image: AppImages.icTiengAnh,
      accentColor: Subject.tiengAnh.color,
      current: s.englishLevelIndex + 1,
      target: 3,
    ),
    LearningCertificate(
      id: 'cert_star',
      title: 'Ngôi Sao Chíp Chíp',
      requirement: 'Tích đủ 50 ngôi sao học tập',
      citation:
          'Vinh danh bé $name đạt cột mốc 50 ngôi sao rực rỡ trên hành trình khám phá tri thức!',
      image: AppImages.icCrown,
      accentColor: CollectionColors.goldBorder,
      current: s.totalStars,
      target: 50,
    ),
  ];
}

/// Number of calendar days in [year]/[month] (1..12).
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Weekday of the 1st of [year]/[month]: 1 = Monday .. 7 = Sunday.
int firstWeekdayOfMonth(int year, int month) => DateTime(year, month, 1).weekday;
