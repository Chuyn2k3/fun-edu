import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

class PlaySessionModel {
  final String id;
  final String levelId;
  final String orderId;
  final String startedAt;
  final String? completedAt;
  final int errorsCount;
  final int starsEarned;
  final bool completed;

  const PlaySessionModel({
    required this.id,
    required this.levelId,
    required this.orderId,
    required this.startedAt,
    this.completedAt,
    required this.errorsCount,
    required this.starsEarned,
    required this.completed,
  });

  PlaySessionEntity toEntity() => PlaySessionEntity(
        id: id,
        levelId: levelId,
        orderId: orderId,
        startedAt: DateTime.tryParse(startedAt) ?? DateTime.now(),
        completedAt: completedAt != null ? DateTime.tryParse(completedAt!) : null,
        errorsCount: errorsCount,
        starsEarned: starsEarned,
        completed: completed,
      );

  factory PlaySessionModel.fromEntity(PlaySessionEntity entity) => PlaySessionModel(
        id: entity.id,
        levelId: entity.levelId,
        orderId: entity.orderId,
        startedAt: entity.startedAt.toIso8601String(),
        completedAt: entity.completedAt?.toIso8601String(),
        errorsCount: entity.errorsCount,
        starsEarned: entity.starsEarned,
        completed: entity.completed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'levelId': levelId,
        'orderId': orderId,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'errorsCount': errorsCount,
        'starsEarned': starsEarned,
        'completed': completed,
      };

  factory PlaySessionModel.fromMap(Map<String, dynamic> map) => PlaySessionModel(
        id: map['id'] as String,
        levelId: map['levelId'] as String,
        orderId: map['orderId'] as String,
        startedAt: map['startedAt'] as String,
        completedAt: map['completedAt'] as String?,
        errorsCount: map['errorsCount'] as int,
        starsEarned: map['starsEarned'] as int,
        completed: map['completed'] as bool,
      );
}
