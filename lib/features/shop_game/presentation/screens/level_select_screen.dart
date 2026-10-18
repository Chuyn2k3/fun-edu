import 'package:flutter/material.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/screens/shop_game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final IShopGameRepository? repository;

  const LevelSelectScreen({
    super.key,
    this.repository,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late final IShopGameRepository _repo;
  ChildProfileEntity? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? locator<IShopGameRepository>();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _repo.getChildProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8E7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
      );
    }

    final profile = _profile!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7043),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  // Child Profile Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🐻', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stars & Coins
                  Row(
                    children: [
                      _buildPill(
                        icon: '⭐',
                        count: '${profile.totalStars}',
                        borderColor: Colors.amber,
                        textColor: const Color(0xFFE65100),
                      ),
                      const SizedBox(width: 8),
                      _buildPill(
                        icon: '🪙',
                        count: '${profile.totalCoins}',
                        borderColor: const Color(0xFFFFB300),
                        textColor: const Color(0xFFE65100),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Title
            const Text(
              'CHỌN CỬA HÀNG',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5D4037),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Level Cards List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: ShopGameLevelsData.levels.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final level = ShopGameLevelsData.levels[index];
                  final isUnlocked = profile.totalStars >= level.starsToUnlock;
                  final earnedStars = profile.levelStars[level.id] ?? 0;

                  return _buildLevelCard(
                    context: context,
                    levelNumber: index + 1,
                    shopName: level.shopName,
                    starsToUnlock: level.starsToUnlock,
                    isUnlocked: isUnlocked,
                    earnedStars: earnedStars,
                    onTap: () {
                      if (isUnlocked) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShopGameScreen(levelId: level.id),
                          ),
                        ).then((_) => _loadProfile());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Bé cần tích lũy thêm ${level.starsToUnlock - profile.totalStars} ⭐ để mở khóa nhé!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: const Color(0xFFFF7043),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required String icon,
    required String count,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 3),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required int levelNumber,
    required String shopName,
    required int starsToUnlock,
    required bool isUnlocked,
    required int earnedStars,
    required VoidCallback onTap,
  }) {
    final icons = ['🍎', '🎃', '🍉'];
    final icon = icons[(levelNumber - 1) % icons.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? const Color(0xFF8D6E63) : Colors.grey.shade400,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Shop Icon Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked ? const Color(0xFFFFF3E0) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnlocked ? const Color(0xFFFFB74D) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Shop Name & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MÀN $levelNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isUnlocked ? const Color(0xFFFF7043) : Colors.grey,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shopName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? const Color(0xFF4E342E) : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isUnlocked)
                    Row(
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            i < earnedStars ? '⭐' : '☆',
                            style: TextStyle(
                              fontSize: 18,
                              color: i < earnedStars ? Colors.amber : Colors.grey.shade400,
                            ),
                          ),
                        );
                      }),
                    )
                  else
                    Text(
                      '🔒 Cần $starsToUnlock ⭐ để mở',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                ],
              ),
            ),
            // Action arrow or lock icon
            Icon(
              isUnlocked ? Icons.play_circle_fill_rounded : Icons.lock_rounded,
              size: 36,
              color: isUnlocked ? const Color(0xFF66BB6A) : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
