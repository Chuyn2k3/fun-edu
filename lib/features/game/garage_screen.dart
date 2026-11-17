import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/data/game_repository.dart';
import '../../game/data/reward_pool.dart';
import '../../game/scene/flame_painter.dart';
import '../../game/scene/trails.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import 'game_hub_screen.dart';
import 'game_widgets.dart';
import 'item_art.dart';
import 'race_screen.dart' show BigGameButton;
import 'reward_offer_sheet.dart';
import 'rocket_stage.dart';

export 'rocket_stage.dart' show RocketStage, RocketStageState;

const garageRockets = [
  'rocket_orange',
  'rocket_blue',
  'rocket_green',
  'rocket_purple',
];
const garageTrails = [
  'trail_flame',
  'trail_rainbow',
  'trail_sparkle',
  'trail_blue_flame',
];

class GarageData {
  const GarageData({
    required this.owned,
    required this.rocket,
    required this.trail,
    required this.stars,
    required this.offer,
    required this.unseen,
  });

  final Set<String> owned;
  final String rocket;
  final String trail;
  final int stars;

  /// The milestone offer waiting to be picked, or empty.
  final List<String> offer;

  /// Owned rockets/trails not seen in the garage yet.
  final Set<String> unseen;
}

final garageProvider = FutureProvider.autoDispose<GarageData>((ref) async {
  final repo = await ref.watch(gameRepositoryProvider.future);
  final sel = await repo.selected();
  return GarageData(
    owned: await repo.owned(),
    rocket: sel.rocket,
    trail: sel.trail,
    stars: await repo.totalStars(),
    offer: await repo.pendingOffer(),
    unseen: await repo.newGarageItems(),
  );
});

/// "Xưởng độ tên lửa": the rocket in use on a pedestal with its trail
/// running, tabs "Tên lửa" / "Vệt", owned items to equip, locked items
/// with the cosmic stars to their milestone, and "Bay thử!".
class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  final _stage = GlobalKey<RocketStageState>();
  int _tab = 0;
  bool _flying = false;
  bool _busy = false;

  /// Items shown with "MỚI" during this visit (new when they first showed).
  final Set<String> _fresh = {};

  List<String> get _tabItems => _tab == 0 ? garageRockets : garageTrails;

  /// Remembers which new items were seen and marks the visible tab's new
  /// items as seen, so the hub badge clears.
  Future<void> _markVisibleSeen(GarageData d) async {
    _fresh.addAll(d.unseen);
    final visible = d.unseen.where(_tabItems.contains).toList();
    if (visible.isEmpty) return;
    final repo = await ref.read(gameRepositoryProvider.future);
    await repo.markSeen(visible);
    if (!mounted) return;
    ref.invalidate(gameHubProvider);
    ref.invalidate(garageProvider);
  }

  Future<void> _tapItem(GarageData d, String id) async {
    if (_busy) return;
    final speaker = ref.read(speakerProvider);
    if (d.owned.contains(id)) {
      final isRocket = id.startsWith('rocket_');
      if (id == (isRocket ? d.rocket : d.trail)) {
        speaker.speak(itemTitle(id));
        return;
      }
      _busy = true;
      try {
        final repo = await ref.read(gameRepositoryProvider.future);
        await repo.select(
            rocket: isRocket ? id : null, trail: isRocket ? null : id);
        speaker.speak(itemTitle(id));
      } catch (_) {
        // Could not save: keep what is equipped; nothing to tell the kid.
      } finally {
        _busy = false;
      }
      if (!mounted) return;
      ref.invalidate(garageProvider);
      ref.invalidate(gameHubProvider);
      ref.invalidate(gameSummaryProvider);
      return;
    }
    if (d.offer.contains(id)) {
      _busy = true;
      try {
        final picked = await showRewardOfferSheet(context, d.offer);
        if (picked != null) {
          final repo = await ref.read(gameRepositoryProvider.future);
          await repo.pick(picked);
        }
      } catch (_) {
        // The pick did not save: the offer simply stays waiting.
      } finally {
        _busy = false;
      }
      if (!mounted) return;
      ref.invalidate(garageProvider);
      ref.invalidate(gameHubProvider);
      ref.invalidate(gameSummaryProvider);
      return;
    }
    final left = starsUntilOffered(id, owned: d.owned, stars: d.stars);
    if (left != null) speaker.speak('Còn $left sao vũ trụ nữa nhé!');
  }

  void _setTab(int tab, GarageData? d) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (d != null) _markVisibleSeen(d);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<GarageData>>(garageProvider, (_, next) {
      final d = next.valueOrNull;
      if (d != null && d.unseen.any(_tabItems.contains)) _markVisibleSeen(d);
    });
    final data = ref.watch(garageProvider).valueOrNull;
    final ff = context.formFactor;
    final tablet = ff != FormFactor.phone;
    final pad = tablet ? 32.0 : 16.0;

    final header = GameHeader(
      title: 'Xưởng độ tên lửa',
      onBack: () => context.go('/game'),
      trailing:
          data == null || !tablet ? null : CosmicStarsPill(stars: data.stars),
    );
    final stage = _Stage(
      stageKey: _stage,
      data: data,
      onFlightChanged: (f) {
        if (mounted) setState(() => _flying = f);
      },
    );
    final tabs = _Tabs(
      tab: _tab,
      newRockets: data?.unseen.any(garageRockets.contains) ?? false,
      newTrails: data?.unseen.any(garageTrails.contains) ?? false,
      onTab: (t) => _setTab(t, data),
    );
    final grid = data == null
        ? const SizedBox.shrink()
        : _Grid(
            items: _tabItems,
            data: data,
            fresh: _fresh,
            columns: ff == FormFactor.tabletPortrait ? 4 : 2,
            onTap: (id) => _tapItem(data, id),
          );
    final fly = AnimatedOpacity(
      opacity: _flying ? 0.6 : 1,
      duration: const Duration(milliseconds: 150),
      child: BigGameButton(
        key: const ValueKey('garage-fly'),
        label: 'Bay thử!',
        onTap: _flying ? null : () => _stage.currentState?.takeOff(),
      ),
    );

    final Widget body;
    if (ff == FormFactor.tabletLandscape) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 6, child: stage),
          const SizedBox(width: 32),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabs,
                const SizedBox(height: 24),
                SizedBox(height: 2 * 196 + 22, child: grid),
                const Spacer(),
                fly,
              ],
            ),
          ),
        ],
      );
    } else {
      final tileH = tablet ? 196.0 : 116.0;
      final rows = ff == FormFactor.tabletPortrait ? 1 : 2;
      final gridH = rows * tileH + (rows - 1) * 14;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: stage),
          SizedBox(height: tablet ? 30 : 22),
          tabs,
          SizedBox(height: tablet ? 22 : 16),
          SizedBox(height: gridH, child: grid),
          SizedBox(height: tablet ? 30 : 22),
          fly,
        ],
      );
    }

    return Scaffold(
      backgroundColor: GameColors.panelTop,
      body: GameBackdrop(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                pad, tablet ? 24 : 12, pad, tablet ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                SizedBox(height: tablet ? 24 : 14),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.stageKey,
    required this.data,
    required this.onFlightChanged,
  });

  final GlobalKey<RocketStageState> stageKey;
  final GarageData? data;
  final ValueChanged<bool> onFlightChanged;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final tablet = context.isTablet;
    return Container(
      key: const ValueKey('garage-stage'),
      decoration: spaceCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(
              child: CustomPaint(
                  painter: SpaceSkyPainter(glow: Alignment(0, -0.3))),
            ),
            if (d != null)
              Semantics(
                label: '${itemTitle(d.rocket)}, ${itemTitle(d.trail)}',
                image: true,
                child: RocketStage(
                  key: stageKey,
                  rocket: d.rocket,
                  trail: d.trail,
                  onFlightChanged: onFlightChanged,
                ),
              ),
            if (d != null)
              Positioned(
                left: tablet ? 18 : 12,
                top: tablet ? 18 : 12,
                right: tablet ? 18 : 12,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _NamePill(itemTitle(d.rocket)),
                    _NamePill(itemTitle(d.trail)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NamePill extends StatelessWidget {
  const _NamePill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return ExcludeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: tablet ? 16 : 12, vertical: tablet ? 6 : 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: const [
            BoxShadow(color: GameColors.hudEdge, offset: Offset(0, 4)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: tablet ? 19 : 14,
            fontWeight: FontWeight.w900,
            color: GameColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.tab,
    required this.newRockets,
    required this.newTrails,
    required this.onTab,
  });

  final int tab;
  final bool newRockets;
  final bool newTrails;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    Widget one(int i, String key, String label, bool dot) {
      final on = i == tab;
      return Expanded(
        child: Semantics(
          selected: on,
          child: Pressable(
            key: ValueKey(key),
            onTap: () => onTab(i),
            semanticsLabel: label,
            builder: (pressed) => Container(
              height: gameTarget(context),
              alignment: Alignment.center,
              decoration: on
                  ? raisedKeyDecoration(
                      top: GameColors.goTop,
                      body: GameColors.go,
                      edge: GameColors.goEdge,
                      radius: 20,
                      lip: 6,
                      pressed: pressed,
                    )
                  : whiteChunkyDecoration(pressed: pressed, radius: 20, lip: 6),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: tablet ? 24 : 19,
                        fontWeight: FontWeight.w900,
                        color: on ? GameColors.goInk : GameColors.ink,
                      ),
                    ),
                    if (dot && !on) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: GameColors.go,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        one(0, 'garage-tab-rockets', 'Tên lửa', newRockets),
        SizedBox(width: tablet ? 16 : 12),
        one(1, 'garage-tab-trails', 'Vệt', newTrails),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.items,
    required this.data,
    required this.fresh,
    required this.columns,
    required this.onTap,
  });

  final List<String> items;
  final GarageData data;
  final Set<String> fresh;
  final int columns;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final gap = tablet ? 22.0 : 14.0;
    final rows = (items.length / columns).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: gap),
                  Expanded(child: _tile(items[r * columns + c])),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tile(String id) {
    final owned = data.owned.contains(id);
    final inUse = id == data.rocket || id == data.trail;
    final offered = !owned && data.offer.contains(id);
    final left = owned
        ? null
        : starsUntilOffered(id, owned: data.owned, stars: data.stars);
    return _ItemTile(
      key: ValueKey('garage-item-$id'),
      id: id,
      owned: owned,
      inUse: inUse,
      isNew: owned && !inUse && fresh.contains(id),
      offered: offered,
      starsLeft: left,
      onTap: () => onTap(id),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    super.key,
    required this.id,
    required this.owned,
    required this.inUse,
    required this.isNew,
    required this.offered,
    required this.starsLeft,
    required this.onTap,
  });

  final String id;
  final bool owned;
  final bool inUse;
  final bool isNew;
  final bool offered;
  final int? starsLeft;
  final VoidCallback onTap;

  /// Room kept under the art for the status pill.
  double pillBelow(bool tablet) =>
      inUse || !owned ? (tablet ? 46 : 34) : (tablet ? 22 : 14);

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final title = itemTitle(id);
    final String state;
    if (inUse) {
      state = 'đang dùng';
    } else if (owned) {
      state = isNew ? 'mới, chạm để lắp' : 'chạm để lắp';
    } else if (offered) {
      state = 'quà đang chờ bé chọn';
    } else {
      state = 'còn ${starsLeft ?? 0} sao vũ trụ';
    }
    // Flames are drawn to fill their box: keep them tall and narrow.
    final flame = id == 'trail_flame' || id == 'trail_blue_flame';
    final art = Padding(
      padding: EdgeInsets.fromLTRB(8, tablet ? 14 : 8, 8, pillBelow(tablet)),
      child: Center(
        child: AspectRatio(
          aspectRatio: flame ? 0.6 : 1,
          child: flame ? _FlameArt(id) : ItemArt(id),
        ),
      ),
    );

    final Widget? pill;
    if (inUse) {
      pill = TilePill(
        text: 'Đang dùng',
        icon: Icons.check_rounded,
        color: GameColors.goTop,
        ink: GameColors.goInk,
        edge: GameColors.goEdge,
      );
    } else if (offered) {
      pill = const TilePill(
        text: 'Quà chờ bé!',
        icon: Icons.card_giftcard_rounded,
        color: GameColors.flameMid,
        ink: GameColors.cometInk,
        edge: GameColors.flameOuter,
      );
    } else if (!owned) {
      pill = TilePill(
        text: 'Còn ${starsLeft ?? 0} sao vũ trụ',
        icon: Icons.lock_rounded,
      );
    } else {
      pill = null;
    }

    return Pressable(
      onTap: onTap,
      semanticsLabel: '$title, $state',
      builder: (pressed) => Container(
        decoration: owned || offered
            ? raisedKeyDecoration(
                top: AppColors.card,
                body: offered
                    ? GameColors.panelBottom
                    : GameColors.questionCardTint,
                edge: inUse ? GameColors.goEdge : GameColors.questionCardEdge,
                radius: 22,
                lip: 7,
                pressed: pressed,
              )
            : BoxDecoration(
                color: GameColors.lockedFill,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: GameColors.lockedEdge, offset: Offset(0, 7)),
                ],
              ),
        foregroundDecoration: inUse
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: GameColors.go, width: 3),
              )
            : null,
        child: ExcludeSemantics(
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              owned || offered ? art : LockedLook(child: art),
              if (pill != null)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: tablet ? 12 : 8,
                  child: Center(child: pill),
                ),
              if (isNew)
                const Positioned(
                  top: -10,
                  right: -6,
                  child: TilePill(
                    text: 'MỚI',
                    color: GameColors.goTop,
                    ink: GameColors.goInk,
                    edge: GameColors.goEdge,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A flame trail tile: the race flame (Task 4's [FlameRenderer]) filling
/// its box, still. [ItemArt]'s flame leaves room for a boost and reads
/// too small in a garage tile.
class _FlameArt extends StatelessWidget {
  const _FlameArt(this.id);

  final String id;

  @override
  Widget build(BuildContext context) => Semantics(
        label: itemTitle(id),
        image: true,
        child: CustomPaint(
            painter: _FlameArtPainter(TrailStyle.fromId(id).palette)),
      );
}

class _FlameArtPainter extends CustomPainter {
  const _FlameArtPainter(this.palette);

  final FlamePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    FlameRenderer.paint(
      canvas,
      nozzle: Offset(size.width / 2, size.height * 0.06),
      width: size.width * 0.78,
      length: size.height * 0.8,
      time: 0,
      intensity: 1,
      palette: palette,
    );
  }

  @override
  bool shouldRepaint(_FlameArtPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
