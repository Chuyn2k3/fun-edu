import '../../ui/layout/form_factor.dart';

/// Widest the tablet map grid grows; keeps tiles from stretching on 13".
const tabletMapMaxWidth = 1120.0;

/// Grid columns of the subject maps: 5 on iPad landscape, 4 on portrait,
/// [phoneColumns] on phones.
int mapColumnsFor(FormFactor f, {required int phoneColumns}) {
  switch (f) {
    case FormFactor.tabletLandscape:
      return 5;
    case FormFactor.tabletPortrait:
      return 4;
    case FormFactor.phone:
      return phoneColumns;
  }
}
