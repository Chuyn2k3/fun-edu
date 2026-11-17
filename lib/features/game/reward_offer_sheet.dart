import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/reward_pool.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import 'item_art.dart';

/// Opens the milestone offer: two item cards, the kid picks one. Returns
/// the picked id. The sheet cannot be swiped away (a choice is the point,
/// and the other item simply waits for the next milestone).
Future<String?> showRewardOfferSheet(BuildContext context, List<String> offer) {
  return showModalBottomSheet<String>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RewardOfferSheet(offer: offer),
  );
}

class RewardOfferSheet extends ConsumerStatefulWidget {
  const RewardOfferSheet({super.key, required this.offer});

  final List<String> offer;

  @override
  ConsumerState<RewardOfferSheet> createState() => _RewardOfferSheetState();
}

class _RewardOfferSheetState extends ConsumerState<RewardOfferSheet> {
  static const _line = 'Quà mới! Bé chọn một món nhé!';
  late final Speaker _speaker = ref.read(speakerProvider);

  bool _picked = false;

  @override
  void initState() {
    super.initState();
    _speaker.speak(_line);
  }

  /// The first tap wins; a second (double tap) is ignored, so it can never
  /// pop the page under the sheet.
  void _pick(String id) {
    if (_picked) return;
    _picked = true;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final card = tablet ? 240.0 : 150.0;
    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(20, 22, 20, tablet ? 28 : 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameColors.panelTop, GameColors.panelBottom],
              ),
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: const [
                BoxShadow(
                    color: GameColors.questionCardEdge, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _line,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tablet ? 30 : 24,
                    fontWeight: FontWeight.w900,
                    color: GameColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.offer.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Flexible(
                        child: SizedBox(
                          width: card,
                          child: _OfferCard(
                            id: widget.offer[i],
                            height: card * 1.2,
                            onTap: () => _pick(widget.offer[i]),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Món còn lại sẽ chờ bé ở mốc sau.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tablet ? 20 : 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard(
      {required this.id, required this.height, required this.onTap});

  final String id;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: ValueKey('offer-$id'),
      onTap: onTap,
      semanticsLabel: itemTitle(id),
      builder: (pressed) => Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: raisedDecoration(
          accent: GameColors.keyOrangeEdge,
          tint: GameColors.keyOrangeTop,
          pressed: pressed,
        ),
        child: Column(
          children: [
            Expanded(child: ItemArt(id)),
            const SizedBox(height: 8),
            Text(
              itemTitle(id),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: context.isTablet ? 22 : 17,
                fontWeight: FontWeight.w900,
                color: GameColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
