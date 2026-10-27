import 'package:equatable/equatable.dart';

class PetEgg extends Equatable {
  final String id;
  final int cracks; // 0, 1, 2, 3 (nở)
  final String petNameReward;

  const PetEgg({
    required this.id,
    required this.cracks,
    required this.petNameReward,
  });

  bool get isReadyToHatch => cracks >= 3;

  @override
  List<Object?> get props => [id, cracks, petNameReward];
}
