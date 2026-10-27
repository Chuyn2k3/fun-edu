import 'package:equatable/equatable.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();
  @override
  List<Object?> get props => [];
}

class CoinEarnedEvent extends AppEvent {
  final int amount;
  final String reason;
  const CoinEarnedEvent({required this.amount, required this.reason});
  @override
  List<Object?> get props => [amount, reason];
}

class LessonCompletedEvent extends AppEvent {
  final String lessonId;
  final int stars;
  final int coins;
  const LessonCompletedEvent({
    required this.lessonId,
    required this.stars,
    required this.coins,
  });
  @override
  List<Object?> get props => [lessonId, stars, coins];
}

class TreeWateredEvent extends AppEvent {
  final int currentStreak;
  const TreeWateredEvent({required this.currentStreak});
  @override
  List<Object?> get props => [currentStreak];
}

class PetFedEvent extends AppEvent {
  final String petId;
  final int heartIncrement;
  const PetFedEvent({required this.petId, required this.heartIncrement});
  @override
  List<Object?> get props => [petId, heartIncrement];
}
