import 'package:equatable/equatable.dart';

class ChildProfileEntity extends Equatable {
  final String id;
  final String name;
  final int age;
  final int totalStars;
  final int totalCoins;
  final Map<String, int> levelStars;
  final DateTime createdAt;

  const ChildProfileEntity({
    required this.id,
    required this.name,
    required this.age,
    required this.totalStars,
    required this.totalCoins,
    required this.levelStars,
    required this.createdAt,
  });

  ChildProfileEntity copyWith({
    String? id,
    String? name,
    int? age,
    int? totalStars,
    int? totalCoins,
    Map<String, int>? levelStars,
    DateTime? createdAt,
  }) {
    return ChildProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      totalStars: totalStars ?? this.totalStars,
      totalCoins: totalCoins ?? this.totalCoins,
      levelStars: levelStars ?? this.levelStars,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        totalStars,
        totalCoins,
        levelStars,
        createdAt,
      ];
}
