import '../ui/assets.dart';
import '../ui/theme/tokens.dart';
import 'biology_level.dart';
import 'geography_level.dart';

/// One island of "Đảo Khám phá": its levels, colour and where its level is
/// stored. Screens, providers and cards are shared by every island.
class ExploreIsland {
  const ExploreIsland({
    required this.id,
    required this.prefix,
    required this.name,
    required this.mapTitle,
    required this.subject,
    required this.islandImage,
    required this.levels,
    required this.ready,
  });

  /// Level storage key and route part: `dia-ly`, `sinh-hoc`.
  final String id;

  /// Picture file prefix: `geo`, `bio`.
  final String prefix;

  /// Name in the hall and the parent corner.
  final String name;

  /// Title of the island's level map.
  final String mapTitle;
  final Subject subject;
  final String islandImage;
  final List<GeographyLevel> levels;

  /// Open to kids once its copy is approved and its real pictures are in;
  /// until then the hall shows "Sắp có" and no card counts it.
  final bool ready;
}

const geographyIsland = ExploreIsland(
  id: 'dia-ly',
  prefix: 'geo',
  name: 'Địa lý',
  mapTitle: 'Khám phá Việt Nam',
  subject: Subject.diaLy,
  islandImage: AppImages.islandDiaLy,
  levels: geographyLevels,
  ready: true,
);

/// Every island, in hall order.
final List<ExploreIsland> exploreIslands = [geographyIsland, biologyIsland];

ExploreIsland? exploreIslandById(String id) {
  for (final i in exploreIslands) {
    if (i.id == id) return i;
  }
  return null;
}
