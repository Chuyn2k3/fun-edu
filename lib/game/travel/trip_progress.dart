import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../explore/geography_level.dart';
import '../../profile/kid_repository.dart';
import '../data/game_repository.dart';
import 'trip.dart';

/// Where Chíp is on the trip, for the Góc Chơi cards and the postcard book.
class TripProgress {
  const TripProgress({
    required this.step,
    required this.shown,
    required this.postcards,
    required this.nextStop,
    required this.unseen,
  });

  final int step;

  /// Step up to which this device already showed the postcards.
  final int shown;
  final int postcards;

  /// The next stop to reach; null at the end of the trip.
  final GeoItem? nextStop;

  /// Postcards earned (possibly on another device) not shown here yet.
  final int unseen;
}

String _shownKey(int kidId) => 'tripShown.$kidId';

/// Step up to which this device showed postcards. A device-only setting:
/// it is not in the synced settings list, so each device reveals the
/// postcards it has not shown yet.
Future<int> tripShown(AppDatabase db, int kidId) async =>
    int.tryParse(await KidRepository(db).setting(_shownKey(kidId)) ?? '') ?? 0;

Future<void> markTripShown(AppDatabase db, int kidId, int step) =>
    KidRepository(db).setSetting(_shownKey(kidId), '${tripClamp(step)}');

final tripProgressProvider =
    FutureProvider.autoDispose<TripProgress>((ref) async {
  ref.watch(gameDataRevisionProvider);
  final repo = await ref.watch(gameRepositoryProvider.future);
  final kid = repo.kidId;
  final step = await repo.tripStep();
  final shown =
      kid == null ? step : await tripShown(ref.watch(databaseProvider), kid);
  final postcards = tripPostcards(step);
  return TripProgress(
    step: step,
    shown: shown,
    postcards: postcards,
    nextStop: postcards < tripStops.length ? tripStops[postcards] : null,
    unseen: (postcards - tripPostcards(shown)).clamp(0, tripStops.length).toInt(),
  );
});
