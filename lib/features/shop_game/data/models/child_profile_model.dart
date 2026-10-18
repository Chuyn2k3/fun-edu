import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';

class ChildProfileModel {
  final String id;
  final String name;
  final int age;
  final int totalStars;
  final int totalCoins;
  final Map<String, int> levelStars;
  final String createdAt;

  const ChildProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.totalStars,
    required this.totalCoins,
    required this.levelStars,
    required this.createdAt,
  });

  ChildProfileEntity toEntity() => ChildProfileEntity(
        id: id,
        name: name,
        age: age,
        totalStars: totalStars,
        totalCoins: totalCoins,
        levelStars: Map<String, int>.from(levelStars),
        createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      );

  factory ChildProfileModel.fromEntity(ChildProfileEntity entity) => ChildProfileModel(
        id: entity.id,
        name: entity.name,
        age: entity.age,
        totalStars: entity.totalStars,
        totalCoins: entity.totalCoins,
        levelStars: Map<String, int>.from(entity.levelStars),
        createdAt: entity.createdAt.toIso8601String(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'totalStars': totalStars,
        'totalCoins': totalCoins,
        'levelStars': levelStars,
        'createdAt': createdAt,
      };

  factory ChildProfileModel.fromMap(Map<String, dynamic> map) => ChildProfileModel(
        id: map['id'] as String,
        name: map['name'] as String,
        age: map['age'] as int,
        totalStars: map['totalStars'] as int? ?? 0,
        totalCoins: map['totalCoins'] as int? ?? 0,
        levelStars: Map<String, int>.from(map['levelStars'] as Map? ?? {}),
        createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
}
