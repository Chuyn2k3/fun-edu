import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../house/house_model.dart';
import '../../house/house_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/floating_nav_bar.dart';
import '../../ui/widgets/nav_rail.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../voice/speaker.dart';
import '../home/kid_nav.dart';
import 'room_stage.dart';

const _phoneMaxWidth = 560.0;
const _tabletMaxWidth = 1140.0;

enum _HouseTab { feed, decor }

const _petLines = [
  'Hihi, nhột quá đi mất! Chíp thích chơi với bé lắm!',
  'Bé vuốt ve êm quá! Hôm nay mình cùng học thật vui nhé!',
  'Chíp yêu bé nhiều lắm! Cố gắng hái thật nhiều sao nha!',
];

BoxDecoration _primaryButtonDecoration({
  required bool pressed,
  double radius = AppRadii.pill,
}) =>
    BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(radius),
      border: Border(
        bottom: BorderSide(
          width: pressed ? AppDepth.pressedLip : AppDepth.lip,
          color: AppColors.primaryOnTint,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.26),
          blurRadius: pressed ? 8 : 16,
          offset: Offset(0, pressed ? 3 : 8),
        ),
      ],
    );

/// "Nhà Chíp" tab (/house): nurture Chíp with learning stars and decorate
/// Chíp's cozy room with 120fps custom animations, 100% offline.
class HouseScreen extends ConsumerStatefulWidget {
  const HouseScreen({super.key});

  @override
  ConsumerState<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends ConsumerState<HouseScreen> {
  _HouseTab _tab = _HouseTab.feed;
  HouseSlot _slot = HouseSlot.wall;
  String? _reactionText;
  HouseFxEvent? _fxEvent;
  int _fxSeq = 0;
  int _petIndex = 0;

  void _triggerFx({required String speech, required HouseFxEvent event}) {
    setState(() {
      _reactionText = speech;
      _fxEvent = event;
    });
    unawaited(ref.read(speakerProvider).speak(speech));
  }

  void _onPetChip(ChipHouseData data) {
    final line = _petLines[_petIndex % _petLines.length]
        .replaceAll('bé', data.displayKidName);
    _petIndex++;
    _triggerFx(
      speech: line,
      event: HouseFxEvent(
        seq: ++_fxSeq,
        kind: HouseFxKind.pet,
        badge: 'Vui quá!',
      ),
    );
  }

  Future<void> _onFeed(ChipHouseData data, HouseTreat treat) async {
    // Placeholder shown while loading (or on a read error): nothing to
    // spend or save yet, so stay quiet instead of saying "not enough stars".
    if (data.kidId == null) return;
    final now = ref.read(houseClockProvider)();
    final res = applyFeed(
      current: data.state,
      treat: treat,
      totalLearningStars: data.totalLearningStars,
      now: now,
    );
    if (!res.ok) {
      setState(() => _reactionText = res.message);
      unawaited(ref.read(speakerProvider).speak(res.message));
      return;
    }
    await ref.read(chipHouseRepositoryProvider).save(data.kidId, res.state);
    ref.read(houseRevisionProvider.notifier).state++;
    _triggerFx(
      speech: res.message,
      event: HouseFxEvent(
        seq: ++_fxSeq,
        kind: res.leveledUp ? HouseFxKind.levelUp : HouseFxKind.feed,
        treatColor: treat.color,
        treatIcon: treat.icon,
        badge: res.leveledUp
            ? 'Lên cấp ${res.state.stage.level}!'
            : '+${treat.xpGain} XP',
      ),
    );
  }

  Future<void> _onDecorTap(ChipHouseData data, HouseItem item) async {
    // Placeholder shown while loading (or on a read error): nothing to
    // spend or save yet, so stay quiet instead of saying "not enough stars".
    if (data.kidId == null) return;
    if (data.state.equippedId(item.slot) == item.id) {
      _triggerFx(
        speech: '${item.title} đang trang trí trong phòng rồi nè!',
        event: HouseFxEvent(
          seq: ++_fxSeq,
          kind: HouseFxKind.decor,
          decorSlot: item.slot,
          decorColor: item.swatch,
          badge: 'Đang dùng!',
        ),
      );
      return;
    }
    final res = applyBuyOrEquip(
      current: data.state,
      item: item,
      totalLearningStars: data.totalLearningStars,
    );
    if (!res.ok) {
      setState(() => _reactionText = res.message);
      unawaited(ref.read(speakerProvider).speak(res.message));
      return;
    }
    await ref.read(chipHouseRepositoryProvider).save(data.kidId, res.state);
    ref.read(houseRevisionProvider.notifier).state++;
    _triggerFx(
      speech: res.message,
      event: HouseFxEvent(
        seq: ++_fxSeq,
        kind: HouseFxKind.decor,
        decorSlot: item.slot,
        decorColor: item.swatch,
        badge: res.purchased ? 'Mở mới!' : 'Đã lắp!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(chipHouseDataProvider);
    final ff = context.formFactor;
    final tablet = ff != FormFactor.phone;
    final landscape = ff == FormFactor.tabletLandscape;
    final now = ref.watch(houseClockProvider)();

    final sky = Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 240,
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppImages.bgSky,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withOpacity(0),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget buildBody(ChipHouseData data) {
      final greeting = _reactionText ??
          'Chào ${data.displayKidName}! Chạm vào Chíp để chơi, hoặc cho Chíp ăn nhé!';

      final stageColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoomStage(
            state: data.state,
            fxEvent: _fxEvent,
            onPetChip: () => _onPetChip(data),
            tablet: tablet,
          ),
          SizedBox(height: tablet ? 16 : 12),
          _GrowthAndBubbleCard(
            state: data.state,
            bubbleText: greeting,
            tablet: tablet,
          ),
        ],
      );

      final controlsColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSwitcher(
            selected: _tab,
            tablet: tablet,
            onSelect: (t) => setState(() => _tab = t),
          ),
          SizedBox(height: tablet ? 16 : 12),
          if (_tab == _HouseTab.feed)
            _TreatGrid(
              data: data,
              now: now,
              tablet: tablet,
              onFeed: (t) => _onFeed(data, t),
            )
          else ...[
            _SlotFilterRow(
              selected: _slot,
              tablet: tablet,
              onSelect: (s) => setState(() => _slot = s),
            ),
            SizedBox(height: tablet ? 14 : 10),
            _DecorGrid(
              data: data,
              slot: _slot,
              tablet: tablet,
              onTap: (item) => _onDecorTap(data, item),
            ),
          ],
        ],
      );

      final scrollBody = SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tablet ? 8 : 16,
          tablet ? 20 : 12,
          tablet ? 28 : 16,
          tablet ? 36 : 124,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HouseHeader(
              availableStars: data.availableStars,
              totalStars: data.totalLearningStars,
              tablet: tablet,
            ),
            SizedBox(height: tablet ? 18 : 14),
            if (landscape)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 52, child: stageColumn),
                  const SizedBox(width: 24),
                  Expanded(flex: 48, child: controlsColumn),
                ],
              )
            else ...[
              stageColumn,
              SizedBox(height: tablet ? 18 : 14),
              controlsColumn,
            ],
          ],
        ),
      );

      if (!tablet) {
        return Stack(
          children: [
            sky,
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _phoneMaxWidth),
                  child: scrollBody,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _phoneMaxWidth),
                    child: FloatingNavBar(
                      items: kidNavItems,
                      selected: kidNavHouse,
                      onSelect: (i) =>
                          onKidNav(context, i, current: kidNavHouse),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          sky,
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                right: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: NavRail(
                      items: kidNavItems,
                      selected: kidNavHouse,
                      onSelect: (i) =>
                          onKidNav(context, i, current: kidNavHouse),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  left: false,
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _tabletMaxWidth),
                      child: scrollBody,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final data = dataAsync.valueOrNull ??
        const ChipHouseData(
          kidId: null,
          kidName: 'Bé',
          totalLearningStars: 0,
          state: ChipHouseState(),
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        body: DottedBackground(
          child: buildBody(data),
        ),
      ),
    );
  }
}

class _HouseHeader extends StatelessWidget {
  const _HouseHeader({
    required this.availableStars,
    required this.totalStars,
    required this.tablet,
  });

  final int availableStars;
  final int totalStars;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Nhà của Chíp',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tablet ? 30 : 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label:
              'Còn $availableStars ngôi sao để chăm Chíp, tổng đã học $totalStars sao',
          excludeSemantics: true,
          child: Container(
            key: const ValueKey('house-available-stars'),
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 18 : 14,
              vertical: tablet ? 10 : 8,
            ),
            decoration: raisedDecoration(radius: AppRadii.pill),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.icStar,
                  width: tablet ? 26 : 22,
                  height: tablet ? 26 : 22,
                ),
                const SizedBox(width: 6),
                Text(
                  '$availableStars sao',
                  style: TextStyle(
                    fontSize: tablet ? 19 : 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GrowthAndBubbleCard extends StatelessWidget {
  const _GrowthAndBubbleCard({
    required this.state,
    required this.bubbleText,
    required this.tablet,
  });

  final ChipHouseState state;
  final String bubbleText;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final stage = state.stage;
    final next = state.nextStage;
    final xpLabel = next == null
        ? 'Cấp tối đa · ${state.xp} XP'
        : '${state.xp}/${next.minXp} XP';

    return Container(
      padding: EdgeInsets.all(tablet ? 18 : 14),
      decoration: raisedDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpeechBubble(text: bubbleText),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cấp ${stage.level}: ${stage.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tablet ? 18 : 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                xpLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: state.stageProgress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 11,
                backgroundColor: HouseColors.xpBarTrack,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(HouseColors.xpBarFill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.selected,
    required this.tablet,
    required this.onSelect,
  });

  final _HouseTab selected;
  final bool tablet;
  final ValueChanged<_HouseTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeTabButton(
            key: const ValueKey('house-tab-feed'),
            label: 'Cho Chíp ăn',
            icon: Icons.restaurant_rounded,
            active: selected == _HouseTab.feed,
            tablet: tablet,
            onTap: () => onSelect(_HouseTab.feed),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeTabButton(
            key: const ValueKey('house-tab-decor'),
            label: 'Trang trí nhà',
            icon: Icons.chair_rounded,
            active: selected == _HouseTab.decor,
            tablet: tablet,
            onTap: () => onSelect(_HouseTab.decor),
          ),
        ),
      ],
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.tablet,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : AppColors.text;
    return Pressable(
      onTap: onTap,
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: tablet ? 74 : 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: active
            ? _primaryButtonDecoration(pressed: pressed, radius: AppRadii.tile)
            : raisedDecoration(pressed: pressed, radius: AppRadii.tile),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: tablet ? 24 : 20, color: fg),
            const SizedBox(width: 7),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: tablet ? 19 : 16,
                    fontWeight: FontWeight.w900,
                    color: fg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-pass 2-column grid (avoids shrinkWrap double layout at 120fps).
class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({
    required this.children,
    required this.spacing,
    required this.itemHeight,
  });

  final List<Widget> children;
  final double spacing;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: spacing));
      rows.add(
        SizedBox(
          height: itemHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _TreatGrid extends StatelessWidget {
  const _TreatGrid({
    required this.data,
    required this.now,
    required this.tablet,
    required this.onFeed,
  });

  final ChipHouseData data;
  final DateTime now;
  final bool tablet;
  final ValueChanged<HouseTreat> onFeed;

  @override
  Widget build(BuildContext context) {
    return _TwoColumnGrid(
      spacing: tablet ? 16 : 12,
      itemHeight: tablet ? 196 : 180,
      children: [
        for (final treat in houseTreats) _buildTile(treat),
      ],
    );
  }

  Widget _buildTile(HouseTreat treat) {
    final freeClaimed = treat.isDailyFree && !data.state.canClaimFreeTreat(now);
    final canAfford = !freeClaimed && data.availableStars >= treat.costStars;
    final badgeLabel = freeClaimed
        ? 'Đã ăn hôm nay'
        : (treat.isDailyFree ? 'Miễn phí' : '${treat.costStars} sao');

    return Semantics(
      button: true,
      label: '${treat.title}, cộng ${treat.xpGain} điểm, $badgeLabel',
      excludeSemantics: true,
      child: Pressable(
        onTap: () => onFeed(treat),
        builder: (pressed) => Container(
          key: ValueKey('house-treat-${treat.id}'),
          padding: const EdgeInsets.all(14),
          decoration: freeClaimed
              ? BoxDecoration(
                  color: CollectionColors.lockedSurface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: CollectionColors.lockedBorder,
                    width: 1.5,
                  ),
                )
              : raisedDecoration(
                  accent: treat.color,
                  pressed: pressed,
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: tablet ? 56 : 48,
                height: tablet ? 56 : 48,
                decoration: BoxDecoration(
                  color: treat.color.withOpacity(freeClaimed ? 0.12 : 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  treat.icon,
                  size: tablet ? 32 : 28,
                  color:
                      freeClaimed ? CollectionColors.lockedInk : treat.color,
                ),
              ),
              Column(
                children: [
                  Text(
                    treat.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: tablet ? 18 : 16,
                      fontWeight: FontWeight.w900,
                      color: freeClaimed
                          ? CollectionColors.lockedInk
                          : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${treat.xpGain} XP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: freeClaimed
                          ? CollectionColors.lockedInk
                          : HouseColors.xpBarFill,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: freeClaimed
                      ? CollectionColors.progressTrack
                      : (canAfford
                          ? CollectionColors.goldFill
                          : CollectionColors.lockedSurface),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    badgeLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: freeClaimed
                          ? CollectionColors.lockedInk
                          : (canAfford
                              ? CollectionColors.goldInk
                              : AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotFilterRow extends StatelessWidget {
  const _SlotFilterRow({
    required this.selected,
    required this.tablet,
    required this.onSelect,
  });

  final HouseSlot selected;
  final bool tablet;
  final ValueChanged<HouseSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < HouseSlot.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _SlotChip(
              key: ValueKey('house-slot-${HouseSlot.values[i].name}'),
              label: HouseSlot.values[i].label,
              active: selected == HouseSlot.values[i],
              tablet: tablet,
              onTap: () => onSelect(HouseSlot.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    super.key,
    required this.label,
    required this.active,
    required this.tablet,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: tablet ? 56 : 48),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        alignment: Alignment.center,
        decoration: active
            ? _primaryButtonDecoration(pressed: pressed, radius: AppRadii.pill)
            : raisedDecoration(pressed: pressed, radius: AppRadii.pill),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: tablet ? 15 : 13,
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorGrid extends StatelessWidget {
  const _DecorGrid({
    required this.data,
    required this.slot,
    required this.tablet,
    required this.onTap,
  });

  final ChipHouseData data;
  final HouseSlot slot;
  final bool tablet;
  final ValueChanged<HouseItem> onTap;

  @override
  Widget build(BuildContext context) {
    final items = houseItemsForSlot(slot);
    final equippedId = data.state.equippedId(slot);

    return _TwoColumnGrid(
      spacing: tablet ? 16 : 12,
      itemHeight: tablet ? 186 : 172,
      children: [
        for (final item in items) _buildTile(item, equippedId == item.id),
      ],
    );
  }

  Widget _buildTile(HouseItem item, bool equipped) {
    final owned = data.state.isOwned(item.id);
    final statusLabel = equipped
        ? 'Đang dùng'
        : (owned ? 'Chọn dùng' : 'Mở · ${item.costStars} sao');

    return Semantics(
      button: true,
      label: '${item.title}, $statusLabel',
      excludeSemantics: true,
      child: Pressable(
        onTap: () => onTap(item),
        builder: (pressed) => Container(
          key: ValueKey('house-item-${item.id}'),
          padding: const EdgeInsets.all(14),
          decoration: equipped
              ? BoxDecoration(
                  color: HouseColors.equippedFill,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: HouseColors.equippedInk,
                    width: 2.5,
                  ),
                )
              : (owned
                  ? raisedDecoration(accent: item.swatch, pressed: pressed)
                  : BoxDecoration(
                      color: CollectionColors.lockedSurface,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(
                        color: CollectionColors.lockedBorder,
                        width: 1.5,
                      ),
                    )),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: tablet ? 54 : 46,
                height: tablet ? 54 : 46,
                decoration: BoxDecoration(
                  color: item.swatch.withOpacity(owned ? 0.35 : 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.swatch.withOpacity(0.7),
                    width: 2,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: tablet ? 30 : 26,
                  color: owned ? AppColors.text : CollectionColors.lockedInk,
                ),
              ),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tablet ? 17 : 15,
                  fontWeight: FontWeight.w900,
                  color: owned ? AppColors.text : CollectionColors.lockedInk,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: equipped
                      ? HouseColors.equippedInk
                      : (owned
                          ? AppColors.background
                          : CollectionColors.goldFill),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: equipped
                          ? Colors.white
                          : (owned
                              ? AppColors.text
                              : CollectionColors.goldInk),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
