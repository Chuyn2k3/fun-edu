import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/badges.dart';
import '../../game/scene/rocket_sprite.dart';
import '../../online/friends/showcase.dart';
import '../../profile/kid_repository.dart';
import '../../ui/assets.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import 'showcase_editor.dart';

/// Screen displaying a kid's showcase (Tủ khoe): avatar, rocket, 3 pinned
/// items, stats, and 3 reaction buttons.
class ShowcaseScreen extends ConsumerStatefulWidget {
  const ShowcaseScreen({
    super.key,
    this.familyId,
    this.kidUuid,
    this.initialData,
    this.isOwn = false,
  });

  final String? familyId;
  final String? kidUuid;
  final ShowcaseData? initialData;
  final bool isOwn;

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen> {
  ShowcaseData? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    if (_data == null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(ShowcaseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      setState(() {
        _data = widget.initialData;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (widget.isOwn) {
      final own = await ref.read(ownShowcaseProvider.future);
      if (mounted) {
        setState(() {
          _data = own;
          _loading = false;
        });
      }
      return;
    }

    final familyId = widget.familyId;
    final kidUuid = widget.kidUuid;
    if (familyId == null || kidUuid == null) {
      setState(() {
        _loading = false;
        _error = 'Tủ khoe đang đóng';
      });
      return;
    }

    try {
      final res = await ref.read(showcaseApiProvider).getShowcase(familyId, kidUuid);
      if (mounted) {
        setState(() {
          if (res == null) {
            _error = 'Tủ khoe đang đóng';
          } else {
            _data = res;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Tủ khoe đang đóng';
          _loading = false;
        });
      }
    }
  }

  Future<void> _react(String kind) async {
    final d = _data;
    final familyId = widget.familyId;
    final kidUuid = widget.kidUuid;
    if (d == null || familyId == null || kidUuid == null) return;
    if (d.mine.contains(kind)) return; // already reacted

    // Optimistic update
    final newReactions = Map<String, int>.from(d.reactions);
    newReactions[kind] = (newReactions[kind] ?? 0) + 1;
    final newMine = Set<String>.from(d.mine)..add(kind);

    setState(() {
      _data = d.copyWith(
        reactions: newReactions,
        mine: newMine,
      );
    });

    try {
      await ref.read(showcaseApiProvider).react(familyId, kidUuid, kind);
    } catch (_) {
      // Revert if failed
      if (mounted) {
        setState(() => _data = d);
        showAppToast(context, 'Chưa gửi được cảm xúc, thử lại nhé', kind: AppToastKind.warning);
      }
    }
  }

  Widget _buildPinnedImage(String id, double size) {
    if (id.startsWith('sticker_')) {
      final asset = AppImages.stickers[id];
      if (asset != null) {
        return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
      }
    }
    final badge = GameBadge.byId(id);
    if (badge != null) {
      return Image.asset(badge.image, width: size, height: size, fit: BoxFit.contain);
    }
    return Icon(Icons.star_rounded, size: size * 0.7, color: GameColors.starWarm);
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final isOwn = widget.isOwn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isOwn ? 'Tủ khoe của con' : 'Tủ khoe của bạn',
          style: TextStyle(
            fontSize: tablet ? 24 : 19,
            fontWeight: FontWeight.w900,
            color: GameColors.ink,
          ),
        ),
        leading: BackButton(
          color: GameColors.ink,
          onPressed: () => Navigator.maybeOf(context)?.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(AppImages.chipSleep, height: 110),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: tablet ? 22 : 18,
                              fontWeight: FontWeight.w900,
                              color: GameColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bạn chưa mở Tủ khoe hoặc hai nhà chưa là bạn của nhau.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: tablet ? 16 : 14,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _data == null
                    ? const SizedBox.shrink()
                    : _buildContent(_data!, tablet, isOwn),
      ),
    );
  }

  Widget _buildContent(ShowcaseData d, bool tablet, bool isOwn) {
    final avatarSize = tablet ? 104.0 : 86.0;
    final avatar = safeOnlineAvatar(d.avatar);
    final rocket = RocketSprite.forItem(d.rocket);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 32 : 16,
        vertical: tablet ? 20 : 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tablet ? 680 : 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kid Card
              Container(
                padding: EdgeInsets.all(tablet ? 24 : 16),
                decoration: raisedDecoration(tint: GameColors.cockpitBg),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: GameColors.starWarm, width: 3),
                          ),
                          child: ClipOval(
                            child: Image.asset(avatar, fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          bottom: -6,
                          child: Image.asset(
                            rocket.asset,
                            width: tablet ? 48 : 38,
                            height: tablet ? 48 : 38,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      d.nickname,
                      style: TextStyle(
                        fontSize: tablet ? 26 : 21,
                        fontWeight: FontWeight.w900,
                        color: GameColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 3 pinned slots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < maxShowcasePinned; i++)
                          _buildPinnedSlot(i, d.pinned, tablet),
                      ],
                    ),
                    if (isOwn) ...[
                      const SizedBox(height: 14),
                      Pressable(
                        key: const ValueKey('edit-showcase-button'),
                        semanticsLabel: 'Đổi ô khoe',
                        onTap: () async {
                          final kidId = await ref.read(currentKidIdProvider.future);
                          if (kidId != null && mounted) {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShowcaseEditor(
                                  kidId: kidId,
                                  initialPinned: d.pinned,
                                ),
                              ),
                            );
                            _load();
                          }
                        },
                        builder: (pressed) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: raisedDecoration(
                            tint: GameColors.starWarm,
                            pressed: pressed,
                          ),
                          child: Text(
                            'Đổi 3 ô khoe',
                            style: TextStyle(
                              fontSize: tablet ? 16 : 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats
              Container(
                padding: EdgeInsets.all(tablet ? 20 : 14),
                decoration: raisedDecoration(tint: AppColors.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Thành tích đua',
                      style: TextStyle(
                        fontSize: tablet ? 19 : 16,
                        fontWeight: FontWeight.w900,
                        color: GameColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatTile('${d.races}', 'Trận đua', tablet),
                        _buildStatTile('${d.wins}', 'Về nhất', tablet),
                        _buildStatTile('${d.stickers}', 'Huy hiệu', tablet),
                      ],
                    ),
                    if (d.learning != null) ...[
                      const Divider(height: 24),
                      Text(
                        'Tiến độ học tập',
                        style: TextStyle(
                          fontSize: tablet ? 19 : 16,
                          fontWeight: FontWeight.w900,
                          color: GameColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatTile('✏️ ${d.learning!.glyphs}', 'Chữ thuộc', tablet),
                          _buildStatTile('📘 ${d.learning!.lessons}', 'Bài xong', tablet),
                          _buildStatTile('⭐ ${d.learning!.stars}', 'Ngôi sao', tablet),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Reactions
              Container(
                padding: EdgeInsets.all(tablet ? 20 : 14),
                decoration: raisedDecoration(tint: AppColors.card),
                child: Column(
                  children: [
                    Text(
                      isOwn ? 'Cảm xúc từ bạn bè' : 'Thả cảm xúc cho bạn',
                      style: TextStyle(
                        fontSize: tablet ? 19 : 16,
                        fontWeight: FontWeight.w900,
                        color: GameColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildReactionButton('clap', '👏', d.reactions['clap'] ?? 0, d.mine.contains('clap'), tablet, isOwn),
                        _buildReactionButton('heart', '❤️', d.reactions['heart'] ?? 0, d.mine.contains('heart'), tablet, isOwn),
                        _buildReactionButton('star', '⭐', d.reactions['star'] ?? 0, d.mine.contains('star'), tablet, isOwn),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedSlot(int index, List<String> pinned, bool tablet) {
    final size = tablet ? 88.0 : 70.0;
    final hasItem = index < pinned.length;
    final id = hasItem ? pinned[index] : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(
          color: hasItem ? GameColors.starWarm : AppColors.card.withOpacity(0.6),
          width: 2.5,
        ),
      ),
      alignment: Alignment.center,
      child: id != null
          ? _buildPinnedImage(id, size * 0.75)
          : Icon(
              Icons.star_border_rounded,
              size: tablet ? 32 : 24,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
    );
  }

  Widget _buildStatTile(String value, String label, bool tablet) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: tablet ? 24 : 19,
                fontWeight: FontWeight.w900,
                color: GameColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: tablet ? 15 : 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(
    String kind,
    String icon,
    int count,
    bool lit,
    bool tablet,
    bool isOwn,
  ) {
    final size = tablet ? 80.0 : 64.0;
    return Pressable(
      key: ValueKey('reaction-$kind'),
      semanticsLabel: 'Thả $kind',
      onTap: isOwn ? null : () => _react(kind),
      builder: (pressed) => Container(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: raisedDecoration(
          tint: lit ? GameColors.starWarm : (pressed ? GameColors.cockpitBg : AppColors.card),
          pressed: pressed,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: tablet ? 28 : 22)),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: tablet ? 16 : 13,
                fontWeight: FontWeight.w900,
                color: lit ? AppColors.text : GameColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
