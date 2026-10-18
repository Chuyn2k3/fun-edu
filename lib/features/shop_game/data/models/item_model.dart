import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class ItemModel {
  final String id;
  final ItemType type;
  final String nameVi;
  final String assetPath;
  final int shelfPosition;

  const ItemModel({
    required this.id,
    required this.type,
    required this.nameVi,
    required this.assetPath,
    required this.shelfPosition,
  });

  ItemEntity toEntity() => ItemEntity(
        id: id,
        type: type,
        nameVi: nameVi,
        assetPath: assetPath,
        shelfPosition: shelfPosition,
      );

  factory ItemModel.fromEntity(ItemEntity entity) => ItemModel(
        id: entity.id,
        type: entity.type,
        nameVi: entity.nameVi,
        assetPath: entity.assetPath,
        shelfPosition: entity.shelfPosition,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'nameVi': nameVi,
        'assetPath': assetPath,
        'shelfPosition': shelfPosition,
      };

  factory ItemModel.fromMap(Map<String, dynamic> map) => ItemModel(
        id: map['id'] as String,
        type: ItemType.values.firstWhere((e) => e.name == map['type']),
        nameVi: map['nameVi'] as String,
        assetPath: map['assetPath'] as String,
        shelfPosition: map['shelfPosition'] as int,
      );
}
