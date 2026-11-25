import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the explore island (home card, parent progress card). Off until the
/// owner approves all geography copy and the real pictures replace the
/// placeholders; build with `--dart-define=EXPLORE_ISLAND=true` to try it.
const bool kExploreIslandEnabled =
    bool.fromEnvironment('EXPLORE_ISLAND', defaultValue: false);

/// [kExploreIslandEnabled] as a provider so tests can switch it.
final exploreIslandEnabledProvider =
    Provider<bool>((ref) => kExploreIslandEnabled);
