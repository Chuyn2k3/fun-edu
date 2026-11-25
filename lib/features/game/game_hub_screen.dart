import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/data/badges.dart';
import '../../game/data/game_repository.dart';
import '../../explore/explore_flags.dart';
import '../../game/engine/race_question.dart';
import '../../game/travel/trip.dart';
import '../../game/travel/trip_progress.dart';
import '../../game/scene/rocket_sprite.dart';
import '../../online/net/network_status.dart';
import '../../online/online_config.dart';
import '../../parent/parent_gate_route.dart';
import '../../ui/assets.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/floating_nav_bar.dart';
import '../../ui/widgets/nav_rail.dart';
import '../../ui/widgets/pressable.dart';
import '../home/kid_nav.dart';
import 'achievements_card.dart';
import 'friends_row.dart';
import 'game_widgets.dart';
import 'sticker_album_screen.dart';

/// Everything the Góc Chơi hub shows, read from the game repository only
/// (never the learning stars).
class GameHubData {
  const GameHubData({
    required this.stars,
    required this.newItems,
    required this.badges,
    required this.stickers,
    required this.rocket,
    required this.stats,
    this.hasPendingOffer = false,
  });

  final int stars;

  /// Owned rockets/trails not yet seen in the garage.
  final int newItems;
  final int badges;
  final int stickers;
  final String rocket;
  final Map<RaceSubject, GameStats> stats;
  final bool hasPendingOffer;
}

final gameHubProvider = FutureProvider.autoDispose<GameHubData>((ref) async {
  ref.watch(gameDataRevisionProvider);
  final repo = await ref.watch(gameRepositoryProvider.future);
  final badges = await repo.badges();
  final offer = await repo.pendingOffer();
  return GameHubData(
    stars: await repo.totalStars(),
    newItems: (await repo.newGarageItems()).length,
    badges: badges.length,
    stickers: ownedStickers(await repo.owned(), badges).length,
    rocket: (await repo.selected()).rocket,
    stats: {
      for (final s in RaceSubject.values) s: await repo.stats(s),
    },
    hasPendingOffer: offer.isNotEmpty,
  );
});

/// "Góc Chơi" (nav tab "Chơi"): the rocket race hero, the coming-soon
/// friend race cards, the garage, badge cabinet, sticker album and the
/// game's own achievements.
class GameHubScreen extends ConsumerWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameHubProvider).valueOrNull;
    final ff = context.formFactor;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        backgroundColor: GameColors.panelTop,
        body: GameBackdrop(
          child: ff == FormFactor.phone
              ? _PhoneHub(data: data)
              : _TabletHub(
                  data: data, landscape: ff == FormFactor.tabletLandscape),
        ),
      ),
    );
  }
}

void _soon(BuildContext context) {
  showAppToast(context, 'Sắp có', kind: AppToastKind.info);
}

class _PhoneHub extends StatelessWidget {
  const _PhoneHub({required this.data});

  final GameHubData? data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 128),
                children: [
                  _Header(stars: d?.stars),
                  const SizedBox(height: 16),
                  const _GameShelf(heroHeight: 280),
                  const SizedBox(height: 26),
                  const SizedBox(height: 138, child: _SoonRow()),
                  const FriendsRow(bottomGap: 24, topGap: 24),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 100,
                    child: _GarageEntry(data: d),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _BadgesEntry(data: d)),
                        const SizedBox(width: 14),
                        Expanded(child: _StickersEntry(data: d)),
                        const _PostcardsEntry(gap: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AchievementsCard(stats: d?.stats ?? const {}),
                ],
              ),
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
                constraints: const BoxConstraints(maxWidth: 560),
                child: FloatingNavBar(
                  items: kidNavItems,
                  selected: kidNavPlay,
                  onSelect: (i) => onKidNav(context, i, current: kidNavPlay),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabletHub extends StatelessWidget {
  const _TabletHub({required this.data, required this.landscape});

  final GameHubData? data;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final d = data;
    const gap = 24.0;
    final Widget body;
    if (landscape) {
      // Fill the screen height when it is tall enough: the hero and the
      // entry cards take what is left; otherwise fixed sizes and scroll.
      Widget column(bool fill) => Row(
            crossAxisAlignment:
                fill ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    fill
                        ? const Expanded(child: _GameShelf())
                        : const _GameShelf(heroHeight: 470),
                    const SizedBox(height: gap + 8),
                    const SizedBox(height: 176, child: _SoonRow()),
                    const FriendsRow(topGap: gap + 8),
                  ],
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 124, child: _GarageEntry(data: d)),
                    const SizedBox(height: gap),
                    _sized(
                      fill,
                      168,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _BadgesEntry(data: d)),
                          const SizedBox(width: 18),
                          Expanded(child: _StickersEntry(data: d)),
                          const _PostcardsEntry(gap: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: gap),
                    AchievementsCard(stats: d?.stats ?? const {}),
                  ],
                ),
              ),
            ],
          );
      return _frame(
        context,
        (viewport) {
          // Header (≈ 64 + 22) and the scroll padding (24 + 40).
          final room = viewport - 150;
          final text = MediaQuery.textScalerOf(context).scale(1);
          if (room >= 720 && text <= 1.0) {
            return SizedBox(height: room, child: column(true));
          }
          return column(false);
        },
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GameShelf(heroHeight: 420),
          const SizedBox(height: gap + 8),
          const SizedBox(height: 176, child: _SoonRow()),
          const FriendsRow(topGap: gap + 4),
          const SizedBox(height: gap + 4),
          SizedBox(
            height: 196,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _GarageEntry(data: d, tall: true)),
                const SizedBox(width: 18),
                Expanded(child: _BadgesEntry(data: d)),
                const SizedBox(width: 18),
                Expanded(child: _StickersEntry(data: d)),
                const _PostcardsEntry(gap: 18),
              ],
            ),
          ),
          const SizedBox(height: gap + 4),
          AchievementsCard(stats: d?.stats ?? const {}),
        ],
      );
    }
    return _frame(context, (_) => body);
  }

  Widget _sized(bool fill, double height, Widget child) => fill
      ? Expanded(
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height), child: child))
      : SizedBox(height: height, child: child);

  /// Rail on the left, the header and [content] scrolling on the right;
  /// [content] gets the viewport height.
  Widget _frame(BuildContext context, Widget Function(double) content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          right: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: NavRail(
                items: kidNavItems,
                selected: kidNavPlay,
                onSelect: (i) => onKidNav(context, i, current: kidNavPlay),
              ),
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            left: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 24, 32, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(stars: data?.stars),
                    const SizedBox(height: 22),
                    content(c.maxHeight),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stars});

  final int? stars;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Chơi',
            style: TextStyle(
              fontSize: tablet ? 42 : 30,
              fontWeight: FontWeight.w900,
              color: GameColors.ink,
            ),
          ),
        ),
        CosmicStarsPill(key: const ValueKey('hub-stars'), stars: stars ?? 0),
      ],
    );
  }
}

/// The game shelf: the rocket race alone while the explore island is off;
/// with it on, the race card and a wide "Chíp du lịch" card below it (side
/// by side cut the race card's text on tablets). More games join as more
/// cards.
class _GameShelf extends ConsumerWidget {
  const _GameShelf({this.heroHeight});

  /// Height of the race card; null fills the parent (tablet landscape).
  final double? heroHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = heroHeight;
    final race = h == null ? const _RaceHero() : SizedBox(height: h, child: const _RaceHero());
    if (!ref.watch(exploreIslandEnabledProvider)) return race;
    final travelHeight = context.isTablet ? 180.0 : 150.0;
    if (h == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: _RaceHero()),
          const SizedBox(height: 18),
          SizedBox(height: travelHeight, child: const _TravelHero()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        race,
        const SizedBox(height: 14),
        SizedBox(height: travelHeight, child: const _TravelHero()),
      ],
    );
  }
}

/// "Chíp du lịch" on the shelf: postcards so far and the next stop.
class _TravelHero extends ConsumerWidget {
  const _TravelHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(tripProgressProvider).valueOrNull;
    final tablet = context.isTablet;
    final next = p?.nextStop;
    return Pressable(
      key: const ValueKey('hub-travel'),
      onTap: () => context.go('/game/travel'),
      semanticsLabel: 'Chíp du lịch',
      builder: (pressed) => Container(
        padding: EdgeInsets.all(tablet ? 18 : 14),
        decoration: raisedDecoration(
          accent: Subject.diaLy.color,
          tint: Subject.diaLy.tint,
          radius: 32,
          pressed: pressed,
        ),
        child: LayoutBuilder(builder: (context, c) {
          final art = Image.asset(
            next?.image ?? AppImages.islandDiaLy,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chíp du lịch',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tablet ? 30 : 24,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${p?.postcards ?? 0}/${tripStops.length} bưu thiếp',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tablet ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: Subject.diaLy.color,
                ),
              ),
              if (next != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Trạm tới: ${next.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tablet ? 17 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          );
          return Row(
            children: [
              Image.asset(AppImages.chipJoy,
                  width: c.maxHeight * 0.8, height: c.maxHeight * 0.8),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: text,
                ),
              ),
              // Narrow phones keep the room for the words.
              if (c.maxWidth >= 420)
                SizedBox(
                    width: c.maxHeight * 0.7,
                    height: c.maxHeight * 0.7,
                    child: art),
            ],
          );
        }),
      ),
    );
  }
}

/// "Sổ tem" beside the badges and stickers while the explore island is on.
class _PostcardsEntry extends ConsumerWidget {
  const _PostcardsEntry({required this.gap});

  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(exploreIslandEnabledProvider)) return const SizedBox.shrink();
    final p = ref.watch(tripProgressProvider).valueOrNull;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: gap),
        child: _EntryCard(
          key: const ValueKey('hub-postcards'),
          image: AppImages.islandDiaLy,
          title: 'Sổ tem',
          subtitle: '${p?.postcards ?? 0}/${tripStops.length}',
          tall: true,
          count: p?.unseen ?? 0,
          countKey: const ValueKey('hub-postcards-new'),
          onTap: () => context.go('/game/postcards'),
        ),
      ),
    );
  }
}

/// The big "Đua tên lửa" card: space sky, planet, comet, Chíp in its
/// rocket and the "Đua với Chíp" key (opens the subject picker).
class _RaceHero extends StatelessWidget {
  const _RaceHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      // Composition of the 358×280 mockup, scaled by height; wide cards
      // push the text column right so it sits beside the rocket.
      final s = math.min(h / 280, w / 358);
      final textLeft = math.max(146 * s, w * 0.40);
      final tablet = context.isTablet;
      final keyH = math.max(gameTarget(context), 60 * s);
      return Container(
        decoration: spaceCardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: SpaceSkyPainter()),
              ),
              Positioned(
                right: -26 * s,
                top: -10 * s,
                width: 170 * s,
                child: Image.asset(AppImages.planet, fit: BoxFit.contain),
              ),
              Positioned(
                left: textLeft - 14 * s,
                top: 18 * s,
                width: 72 * s,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scale(-1.0, 1.0)
                    ..rotateZ(8 * math.pi / 180),
                  child: Image.asset(AppImages.comet, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                left: math.max(18 * s, textLeft - 162 * s),
                top: math.max(50 * s, (h - 208 * s) / 2),
                height: 208 * s,
                child: Transform.rotate(
                  angle: 10 * math.pi / 180,
                  child: Semantics(
                    label: 'Chíp Chíp lái tên lửa',
                    image: true,
                    child:
                        Image.asset(AppImages.rocketChip, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                left: textLeft,
                right: 12 * s,
                bottom: 22 * s,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Đua tên lửa',
                      style: TextStyle(
                        fontSize: 30 * s,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: AppColors.card,
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      'Trả lời đúng, bay vút lên!',
                      style: TextStyle(
                        fontSize: (15 * s).clamp(15, 26),
                        fontWeight: FontWeight.w800,
                        color: GameColors.heroSubtitle,
                      ),
                    ),
                    SizedBox(height: 14 * s),
                    Pressable(
                      key: const ValueKey('hub-race'),
                      onTap: () => context.go('/game/pick'),
                      semanticsLabel: 'Đua với Chíp',
                      builder: (pressed) => Container(
                        height: keyH,
                        padding: EdgeInsets.symmetric(horizontal: 14 * s),
                        decoration: raisedKeyDecoration(
                          top: GameColors.goTop,
                          body: GameColors.go,
                          edge: GameColors.goEdge,
                          radius: 22 * s,
                          lip: 7,
                          pressed: pressed,
                        ),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  size: (28 * s).clamp(28, 48),
                                  color: GameColors.goInk),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Đua với Chíp',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize:
                                        tablet ? (20 * s).clamp(24, 34) : 18,
                                    fontWeight: FontWeight.w900,
                                    color: GameColors.goInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// "Mời bạn đua" and "Nhập mã": online rooms (2B-2), opened through the
/// parent gate. A build without a server says "Sắp có".
class _SoonRow extends ConsumerWidget {
  const _SoonRow();

  Future<void> _open(BuildContext context, WidgetRef ref, String mode) async {
    if (!ref.read(onlineConfigProvider).enabled) {
      _soon(context);
      return;
    }
    final net = ref.read(networkStatusProvider);
    if (net == NetState.offline) {
      await showAppDialog<void>(
        context,
        title: 'Cần có mạng để đua với bạn nhé',
        primaryLabel: 'Được rồi',
        audience: AppAudience.kid,
        image: AppImages.chipEncourage,
      );
      return;
    }
    if (net == NetState.serverUnreachable) {
      await showAppDialog<void>(
        context,
        title: 'Chưa kết nối được với trạm vũ trụ',
        message: 'Máy chủ đang bận hoặc chưa bật, bạn thử lại sau nhé!',
        primaryLabel: 'Được rồi',
        audience: AppAudience.kid,
        image: AppImages.chipEncourage,
      );
      return;
    }
    if (await showParentGate(context) && context.mounted) {
      context.push('/game/room?mode=$mode');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineConfigProvider).enabled;
    final tablet = context.isTablet;
    final label = TextStyle(
      fontSize: tablet ? 24 : 18,
      fontWeight: FontWeight.w900,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Pressable(
            onTap: () => _open(context, ref, 'create'),
            semanticsLabel: online ? 'Mời bạn đua' : 'Mời bạn đua, sắp có',
            builder: (pressed) => Container(
              decoration: raisedKeyDecoration(
                top: GameColors.keyBlueTop,
                body: GameColors.keyBlue,
                edge: GameColors.keyBlueEdge,
                lip: 9,
                pressed: pressed,
              ),
              child: LayoutBuilder(builder: (context, c) {
                final s = c.maxHeight / 138;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      Positioned(
                        left: c.maxWidth * 0.5 - 70 * s,
                        top: 10 * s,
                        height: 78 * s,
                        child: Transform.rotate(
                          angle: -12 * math.pi / 180,
                          child: Image.asset(AppImages.rocketBlue),
                        ),
                      ),
                      Positioned(
                        left: c.maxWidth * 0.5 + 18 * s,
                        top: 14 * s,
                        height: 72 * s,
                        child: Transform.rotate(
                          angle: 12 * math.pi / 180,
                          child: Image.asset(AppImages.rocketGreen),
                        ),
                      ),
                      Positioned(
                        left: 4,
                        right: 4,
                        bottom: 14 * s,
                        child: ExcludeSemantics(
                          child: Text('Mời bạn đua',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style:
                                  label.copyWith(color: GameColors.keyBlueInk)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(width: tablet ? 20 : 14),
        Expanded(
          child: Pressable(
            onTap: () => _open(context, ref, 'join'),
            semanticsLabel: online ? 'Nhập mã' : 'Nhập mã, sắp có',
            builder: (pressed) => Container(
              decoration: raisedKeyDecoration(
                top: GameColors.keyGreenTop,
                body: GameColors.keyGreen,
                edge: GameColors.keyGreenEdge,
                lip: 9,
                pressed: pressed,
              ),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final d in const ['4', '8', '2'])
                          Container(
                            width: tablet ? 42 : 30,
                            height: tablet ? 54 : 40,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                    color: GameColors.keyGreen,
                                    offset: Offset(0, 4)),
                              ],
                            ),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: tablet ? 28 : 20,
                                fontWeight: FontWeight.w900,
                                color: GameColors.keyGreenInk,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: tablet ? 16 : 12),
                    Text('Nhập mã',
                        maxLines: 1,
                        style: label.copyWith(color: GameColors.keyGreenInk)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A white chunky entry card: picture, title, subtitle and an optional
/// orange count. [tall] puts the picture above the text.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.count = 0,
    this.countKey,
    this.tall = false,
    this.tilt = 0,
  });

  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int count;
  final Key? countKey;
  final bool tall;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final titleStyle = TextStyle(
      fontSize: tablet ? 22 : 17,
      height: 1.1,
      fontWeight: FontWeight.w900,
      color: GameColors.ink,
    );
    final subStyle = TextStyle(
      fontSize: tablet ? 16 : 13,
      fontWeight: FontWeight.w800,
      color: AppColors.textMuted,
    );
    final picture = Transform.rotate(
      angle: tilt,
      child: Image.asset(image, fit: BoxFit.contain),
    );
    final badge = count > 0
        ? Container(
            constraints: BoxConstraints(minWidth: tablet ? 38 : 30),
            height: tablet ? 38 : 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameColors.goTop, GameColors.go],
              ),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: const [
                BoxShadow(color: GameColors.goEdge, offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              '$count',
              key: countKey,
              style: TextStyle(
                fontSize: tablet ? 19 : 15,
                fontWeight: FontWeight.w900,
                color: GameColors.goInk,
              ),
            ),
          )
        : null;
    return Pressable(
      onTap: onTap,
      semanticsLabel: '$title. $subtitle',
      builder: (pressed) => Container(
        decoration: whiteChunkyDecoration(pressed: pressed),
        padding: tall
            ? EdgeInsets.fromLTRB(12, tablet ? 16 : 12, 12, tablet ? 14 : 12)
            : EdgeInsets.fromLTRB(12, 8, tablet ? 18 : 14, 8),
        child: ExcludeSemantics(
          child: tall
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Column(
                        children: [
                          Expanded(child: picture),
                          SizedBox(height: tablet ? 10 : 6),
                          // Narrow tall cards shrink the title, never cut it.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: titleStyle),
                          ),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subStyle),
                        ],
                      ),
                    ),
                    if (badge != null)
                      Positioned(top: -4, right: -2, child: badge),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: tablet ? 104 : 78,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: picture,
                      ),
                    ),
                    SizedBox(width: tablet ? 14 : 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle),
                          const SizedBox(height: 3),
                          Text(subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: subStyle),
                        ],
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge,
                    ],
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: tablet ? 36 : 28,
                        color: GameColors.keyOrangeEdge),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GarageEntry extends StatelessWidget {
  const _GarageEntry({required this.data, this.tall = false});

  final GameHubData? data;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final n = data?.newItems ?? 0;
    final hasPendingOffer = data?.hasPendingOffer ?? false;
    final subtitle = hasPendingOffer
        ? 'Quà chờ bé!'
        : (n > 0 ? 'Có $n món mới chờ lắp!' : 'Chọn tên lửa và vệt khói');
    return _EntryCard(
      key: const ValueKey('hub-garage'),
      image: RocketSprite.forItem(data?.rocket ?? 'rocket_orange').asset,
      tilt: 0.35,
      title: 'Xưởng độ tên lửa',
      subtitle: subtitle,
      count: n,
      countKey: const ValueKey('hub-garage-new'),
      tall: tall,
      onTap: () => context.go('/game/garage'),
    );
  }
}

class _BadgesEntry extends StatelessWidget {
  const _BadgesEntry({required this.data});

  final GameHubData? data;

  @override
  Widget build(BuildContext context) {
    return _EntryCard(
      key: const ValueKey('hub-badges'),
      image: AppImages.badgeChipBuddy,
      title: 'Tủ huy hiệu',
      subtitle: '${data?.badges ?? 0}/${GameBadge.values.length} huy hiệu',
      tall: true,
      onTap: () => context.go('/game/badges'),
    );
  }
}

class _StickersEntry extends StatelessWidget {
  const _StickersEntry({required this.data});

  final GameHubData? data;

  @override
  Widget build(BuildContext context) {
    return _EntryCard(
      key: const ValueKey('hub-stickers'),
      image: AppImages.chipJoy,
      title: 'Album sticker',
      subtitle: '${data?.stickers ?? 0}/${stickerCatalogue.length} sticker',
      tall: true,
      onTap: () => context.go('/game/stickers'),
    );
  }
}
