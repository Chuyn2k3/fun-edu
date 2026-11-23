import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/badges.dart';
import '../../game/data/game_repository.dart';
import '../../game/data/reward_pool.dart';
import '../../online/friends/showcase.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';

/// Fetches owned badges for the editor.
final ownedBadgesProvider =
    FutureProvider.autoDispose<Set<GameBadge>>((ref) async {
  final repo = await ref.watch(gameRepositoryProvider.future);
  return repo.badges();
});

/// Editor allowing a kid to pin up to 3 owned stickers or badges to their showcase.
class ShowcaseEditor extends ConsumerStatefulWidget {
  const ShowcaseEditor({super.key, required this.kidId, required this.initialPinned});

  final int kidId;
  final List<String> initialPinned;

  @override
  ConsumerState<ShowcaseEditor> createState() => _ShowcaseEditorState();
}

class _ShowcaseEditorState extends ConsumerState<ShowcaseEditor> {
  late final List<String> _pinned = List<String>.from(widget.initialPinned);
  bool _saving = false;

  void _toggle(String id) {
    setState(() {
      if (_pinned.contains(id)) {
        _pinned.remove(id);
      } else if (_pinned.length < maxShowcasePinned) {
        _pinned.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await savePinnedShowcaseItems(ref, widget.kidId, _pinned);
    if (mounted) Navigator.maybeOf(context)?.pop();
  }

  Widget _buildItemImage(String id, double size) {
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

  String _itemTitle(String id) {
    if (id.startsWith('sticker_')) {
      return itemTitle(id).replaceFirst('Sticker ', '');
    }
    final badge = GameBadge.byId(id);
    if (badge != null) return badge.title;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final btnH = tablet ? 80.0 : 64.0;
    final slotSize = tablet ? 96.0 : 76.0;

    final ownedBadgesAsync = ref.watch(ownedBadgesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chọn 3 món khoe với bạn',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3 pinned preview slots at top
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(tablet ? 16 : 12),
              decoration: raisedDecoration(tint: GameColors.cockpitBg),
              child: Column(
                children: [
                  Text(
                    'Đã chọn ${_pinned.length}/$maxShowcasePinned món',
                    style: TextStyle(
                      fontSize: tablet ? 18 : 15,
                      fontWeight: FontWeight.w800,
                      color: GameColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < maxShowcasePinned; i++)
                        _buildPinnedSlot(i, slotSize, tablet),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Kho huy hiệu & sticker của bé:',
                style: TextStyle(
                  fontSize: tablet ? 18 : 15,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Owned items grid
            Expanded(
              child: ownedBadgesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Chưa tải được kho đồ')),
                data: (badges) {
                  final ownedIds = <String>[
                    for (final b in badges) b.id,
                  ];
                  // Also include gift stickers
                  for (final id in rewardPool) {
                    if (id.startsWith('sticker_')) ownedIds.add(id);
                  }

                  if (ownedIds.isEmpty) {
                    return Center(
                      child: Text(
                        'Bé chưa có món nào để khoe. Hãy đua thật vui để mở khóa nhé!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: tablet ? 18 : 15,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: tablet ? 5 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: ownedIds.length,
                    itemBuilder: (context, idx) {
                      final id = ownedIds[idx];
                      final isPinned = _pinned.contains(id);
                      final title = _itemTitle(id);
                      return Pressable(
                        key: ValueKey('showcase-item-$id'),
                        semanticsLabel: title,
                        onTap: () => _toggle(id),
                        builder: (pressed) => Container(
                          padding: const EdgeInsets.all(8),
                          decoration: raisedDecoration(
                            tint: isPinned ? GameColors.starWarm : AppColors.card,
                            pressed: pressed,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildItemImage(id, tablet ? 56 : 44),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: tablet ? 13 : 11,
                                  fontWeight: FontWeight.w800,
                                  color: GameColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Bottom Save Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: btnH,
                child: Pressable(
                  key: const ValueKey('showcase-save-button'),
                  semanticsLabel: 'Lưu Tủ khoe',
                  onTap: _saving ? null : _save,
                  builder: (pressed) => Container(
                    height: btnH,
                    decoration: raisedDecoration(
                      accent: AppColors.accent,
                      pressed: pressed,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _saving ? 'Đang lưu…' : 'Lưu Tủ khoe',
                      style: TextStyle(
                        fontSize: tablet ? 24 : 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.card,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedSlot(int index, double size, bool tablet) {
    final hasItem = index < _pinned.length;
    final id = hasItem ? _pinned[index] : null;

    if (id == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppRadii.tile),
          border: Border.all(color: AppColors.card.withOpacity(0.6), width: 2),
        ),
        child: Icon(Icons.add_rounded, size: tablet ? 36 : 28, color: AppColors.card),
      );
    }

    return Pressable(
      key: ValueKey('pinned-slot-$index'),
      semanticsLabel: 'Bỏ chọn món khoe',
      onTap: () => _toggle(id),
      builder: (pressed) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(6),
        decoration: raisedDecoration(
          tint: AppColors.card,
          pressed: pressed,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildItemImage(id, size * 0.7),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger,
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
