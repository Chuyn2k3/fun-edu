import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/kid_repository.dart';
import '../progress/progress_repository.dart';
import 'house_model.dart';

/// Clock used by Nhà Chíp (overridable in tests).
final houseClockProvider = Provider<Clock>((_) => DateTime.now);

/// Bump this after saving Nhà Chíp state so UI refreshes immediately.
final houseRevisionProvider = StateProvider<int>((_) => 0);

/// Reads and persists [ChipHouseState] per kid in `AppSettings`.
class ChipHouseRepository {
  ChipHouseRepository(this._kids);

  final KidRepository _kids;

  static String keyForKid(int kidId) => 'chipHouse.$kidId';

  Future<ChipHouseState> load(int? kidId) async {
    if (kidId == null) return const ChipHouseState();
    final raw = await _kids.setting(keyForKid(kidId));
    return ChipHouseState.decode(raw);
  }

  Future<void> save(int? kidId, ChipHouseState state) async {
    if (kidId == null) return;
    await _kids.setSetting(keyForKid(kidId), state.encode());
  }
}

final chipHouseRepositoryProvider = Provider<ChipHouseRepository>(
  (ref) => ChipHouseRepository(ref.watch(kidRepositoryProvider)),
);

/// Combined read model for Nhà Chíp: current kid nickname, total learning
/// stars, and persisted [ChipHouseState].
class ChipHouseData {
  const ChipHouseData({
    required this.kidId,
    required this.kidName,
    required this.totalLearningStars,
    required this.state,
  });

  final int? kidId;
  final String kidName;
  final int totalLearningStars;
  final ChipHouseState state;

  String get displayKidName {
    final t = kidName.trim();
    return t.isEmpty ? 'Bé' : t;
  }

  int get availableStars => state.availableStars(totalLearningStars);
}

final chipHouseDataProvider =
    FutureProvider.autoDispose<ChipHouseData>((ref) async {
  ref.watch(houseRevisionProvider);
  final kidId = await ref.watch(currentKidIdProvider.future);
  final kids = await ref.watch(kidsProvider.future);
  final summary = await ref.watch(homeSummaryProvider.future);
  final repo = ref.watch(chipHouseRepositoryProvider);
  final state = await repo.load(kidId);
  final kid = kids.where((k) => k.id == kidId).firstOrNull;
  return ChipHouseData(
    kidId: kidId,
    kidName: kid?.nickname ?? 'Bé',
    totalLearningStars: summary.totalStars,
    state: state,
  );
});
