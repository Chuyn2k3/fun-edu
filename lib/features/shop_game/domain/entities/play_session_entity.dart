import 'package:equatable/equatable.dart';

class PlaySessionEntity extends Equatable {
  final String id;
  final String levelId;
  final String orderId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int errorsCount;
  final int starsEarned;
  final bool completed;

  const PlaySessionEntity({
    required this.id,
    required this.levelId,
    required this.orderId,
    required this.startedAt,
    this.completedAt,
    required this.errorsCount,
    required this.starsEarned,
    required this.completed,
  });

  @override
  List<Object?> get props => [
        id,
        levelId,
        orderId,
        startedAt,
        completedAt,
        errorsCount,
        starsEarned,
        completed,
      ];
}
