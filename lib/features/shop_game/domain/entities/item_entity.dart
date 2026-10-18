import 'package:equatable/equatable.dart';

enum ItemType {
  redApple,
  banana,
  pumpkin,
  orange,
  watermelon,
}

extension ItemTypeExtension on ItemType {
  String get vietnameseName {
    switch (this) {
      case ItemType.redApple:
        return 'Táo đỏ';
      case ItemType.banana:
        return 'Chuối';
      case ItemType.pumpkin:
        return 'Bí ngô';
      case ItemType.orange:
        return 'Cam';
      case ItemType.watermelon:
        return 'Dưa hấu';
    }
  }

  String get emoji {
    switch (this) {
      case ItemType.redApple:
        return '🍎';
      case ItemType.banana:
        return '🍌';
      case ItemType.pumpkin:
        return '🎃';
      case ItemType.orange:
        return '🍊';
      case ItemType.watermelon:
        return '🍉';
    }
  }
}

class ItemEntity extends Equatable {
  final String id;
  final ItemType type;
  final String nameVi;
  final String assetPath;
  final int shelfPosition;

  const ItemEntity({
    required this.id,
    required this.type,
    required this.nameVi,
    required this.assetPath,
    required this.shelfPosition,
  });

  @override
  List<Object?> get props => [id, type, nameVi, assetPath, shelfPosition];
}
