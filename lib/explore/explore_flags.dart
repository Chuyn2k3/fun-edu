import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'explore_island.dart';

/// Shows the explore island (home card, parent progress card). Off until the
/// owner approves all geography copy and the real pictures replace the
/// placeholders; build with `--dart-define=EXPLORE_ISLAND=true` to try it.
const bool kExploreIslandEnabled =
    bool.fromEnvironment('EXPLORE_ISLAND', defaultValue: false);

/// [kExploreIslandEnabled] as a provider so tests can switch it.
final exploreIslandEnabledProvider =
    Provider<bool>((ref) => kExploreIslandEnabled);

/// The islands in hall order; tests swap in their own.
final exploreIslandsProvider =
    Provider<List<ExploreIsland>>((ref) => exploreIslands);

/// Whether an island is open to kids (its `ready` flag); tests override.
final exploreReadyProvider = Provider.family<bool, String>((ref, id) {
  for (final i in ref.watch(exploreIslandsProvider)) {
    if (i.id == id) return i.ready;
  }
  return false;
});
