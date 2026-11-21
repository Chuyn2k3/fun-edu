import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collection/collection_provider.dart';
import '../../game/data/game_repository.dart';
import '../../house/house_repository.dart';
import '../../profile/kid_refresh.dart';
import '../../progress/level_repository.dart';
import '../../screen_time/screen_time_service.dart';

/// After a sync merged data from another device: every screen re-reads it.
void refreshAfterSync(Ref ref) {
  invalidateKidData(ref.invalidate);
  ref.invalidate(vietnameseLevelIndexProvider);
  ref.invalidate(englishLevelIndexProvider);
  ref.invalidate(screenTimeStatusProvider);
  ref.invalidate(collectionSnapshotProvider);
  ref.read(gameDataRevisionProvider.notifier).state++;
  ref.read(houseRevisionProvider.notifier).state++;
}
