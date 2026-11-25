import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../explore/geography_level.dart';
import '../../game/data/game_repository.dart';
import '../../game/travel/trip.dart';
import '../../game/travel/trip_progress.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import 'travel_screen.dart' show TripNameTile;

/// "Sổ tem": every postcard of Chíp's trip, grouped like the geography
/// island. Postcards earned on another device are revealed here first.
class PostcardBookScreen extends ConsumerStatefulWidget {
  const PostcardBookScreen({super.key});

  @override
  ConsumerState<PostcardBookScreen> createState() => _PostcardBookState();
}

class _PostcardBookState extends ConsumerState<PostcardBookScreen> {
  /// Postcards still to reveal on this device, in trip order.
  List<GeoItem>? _reveal;
  GeoItem? _big;
  bool _revealChecked = false;
  int _revealUpTo = 0;

  late final Speaker _speaker;

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
  }

  @override
  void dispose() {
    _speaker.stop();
    super.dispose();
  }

  void _checkReveal(TripProgress p) {
    if (_revealChecked) return;
    _revealChecked = true;
    final stops = tripNewStops(p.shown, p.step);
    if (stops.isEmpty) return;
    // Mark only what this reveal shows, even if a sync moves Chíp meanwhile.
    _revealUpTo = p.step;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _reveal = stops);
      _read(stops.first);
    });
  }

  void _read(GeoItem s) => _speaker.speak('${s.speech}. ${s.fact}');

  Future<void> _nextReveal(int step) async {
    final list = _reveal;
    if (list == null) return;
    if (list.length > 1) {
      setState(() => _reveal = list.sublist(1));
      _read(list[1]);
      return;
    }
    setState(() => _reveal = null);
    // Read before the awaits: the kid may leave while the mark is written.
    final db = ref.read(databaseProvider);
    final revision = ref.read(gameDataRevisionProvider.notifier);
    final kid = (await ref.read(gameRepositoryProvider.future)).kidId;
    if (kid != null) {
      await markTripShown(db, kid, step);
      revision.state++;
    }
  }

  void _tap(GeoItem s, bool earned) {
    if (!earned) {
      _speaker.speak('Chíp chưa tới đây, mình đi tiếp nhé!');
      return;
    }
    setState(() => _big = s);
    _read(s);
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final progress = ref.watch(tripProgressProvider).valueOrNull;
    if (progress != null) _checkReveal(progress);
    final earned = progress?.postcards ?? 0;
    final cols = tablet ? 5 : 3;

    final groups = <Widget>[];
    var index = 0;
    for (final level in geographyLevels.skip(3)) {
      groups.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(
          level.title,
          style: TextStyle(
            fontSize: tablet ? 24 : 20,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ));
      final tiles = <Widget>[];
      for (final s in level.items) {
        final has = index < earned;
        tiles.add(_PostcardTile(
          key: ValueKey('postcard-${s.id}'),
          stop: s,
          earned: has,
          onTap: () => _tap(s, has),
        ));
        index++;
      }
      groups.add(GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
        children: tiles,
      ));
    }

    final size = tablet ? TabletSizes.kidTarget : 64.0;
    final header = Row(
      children: [
        Pressable(
          onTap: () => context.canPop() ? context.pop() : context.go('/game'),
          semanticsLabel: 'Quay lại',
          builder: (pressed) => Container(
            width: size,
            height: size,
            decoration: raisedDecoration(radius: size / 2, pressed: pressed),
            child: Icon(Icons.chevron_left_rounded,
                size: tablet ? 44 : 36, color: AppColors.text),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Sổ tem',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
        ),
        Text(
          '$earned/${tripStops.length}',
          style: TextStyle(
            fontSize: tablet ? 24 : 20,
            fontWeight: FontWeight.w900,
            color: Subject.diaLy.color,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );

    final reveal = _reveal;
    final big = _big;
    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tablet ? 1000 : 560),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, tablet ? 32 : 24),
                  children: [header, ...groups],
                ),
              ),
            ),
            if (reveal != null && progress != null)
              _Overlay(
                key: const ValueKey('postcard-reveal'),
                stop: reveal.first,
                title: 'Bưu thiếp mới!',
                buttonKey: const ValueKey('postcard-reveal-next'),
                button: reveal.length > 1 ? 'Xem tiếp' : 'Dán vào sổ',
                tablet: tablet,
                onButton: () => _nextReveal(_revealUpTo),
              )
            else if (big != null)
              _Overlay(
                key: const ValueKey('postcard-big'),
                stop: big,
                title: null,
                buttonKey: const ValueKey('postcard-big-close'),
                button: 'Đóng',
                tablet: tablet,
                onButton: () => setState(() => _big = null),
              ),
          ],
        ),
      ),
    );
    return tablet ? TabletTextScale(child: scaffold) : scaffold;
  }
}

class _PostcardTile extends StatelessWidget {
  const _PostcardTile({
    super.key,
    required this.stop,
    required this.earned,
    required this.onTap,
  });

  final GeoItem stop;
  final bool earned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticsLabel: earned ? stop.name : 'Bưu thiếp chưa có',
      builder: (pressed) => Container(
        padding: const EdgeInsets.all(8),
        decoration: raisedDecoration(
          radius: AppRadii.tile,
          accent: earned ? Subject.diaLy.color : AppColors.dot,
          tint: earned ? Subject.diaLy.tint : AppDepth.neutralTint,
          pressed: pressed,
        ),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => earned
                    ? Image.asset(
                        stop.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            TripNameTile(stop.name, size: c.biggest.shortestSide),
                      )
                    : Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: c.biggest.shortestSide * 0.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            if (earned)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stop.name,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    super.key,
    required this.stop,
    required this.title,
    required this.buttonKey,
    required this.button,
    required this.tablet,
    required this.onButton,
  });

  final GeoItem stop;
  final String? title;
  final Key buttonKey;
  final String button;
  final bool tablet;
  final VoidCallback onButton;

  @override
  Widget build(BuildContext context) {
    final art = tablet ? 260.0 : 180.0;
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.text.withOpacity(0.35),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tablet ? 520 : 360),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: EdgeInsets.all(tablet ? 28 : 20),
              decoration: raisedDecoration(radius: AppRadii.card),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: tablet ? 22 : 18,
                          fontWeight: FontWeight.w800,
                          color: Subject.diaLy.color,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Center(
                      child: Image.asset(
                        stop.image,
                        width: art,
                        height: art,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            TripNameTile(stop.name, size: art),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      stop.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: tablet ? 30 : 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stop.fact,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: tablet ? 20 : 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Pressable(
                      key: buttonKey,
                      onTap: onButton,
                      semanticsLabel: button,
                      builder: (pressed) => Container(
                        constraints: BoxConstraints(
                            minHeight: tablet ? TabletSizes.kidTarget : 64),
                        alignment: Alignment.center,
                        decoration: raisedDecoration(
                          radius: AppRadii.pill,
                          accent: AppColors.primary,
                          tint: AppColors.primary,
                          pressed: pressed,
                        ),
                        child: Text(
                          button,
                          style: TextStyle(
                            fontSize: tablet ? 24 : 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.card,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
