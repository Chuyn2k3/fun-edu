import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PetHatchEvent extends Equatable {
  const PetHatchEvent();
  @override
  List<Object?> get props => [];
}

class TapEggWithHammerEvent extends PetHatchEvent {
  const TapEggWithHammerEvent();
}

class PetHatchState extends Equatable {
  final int cracks;
  final bool isHatched;
  final String? petName;

  const PetHatchState({
    required this.cracks,
    required this.isHatched,
    this.petName,
  });

  @override
  List<Object?> get props => [cracks, isHatched, petName];
}

class PetHatchBloc extends Bloc<PetHatchEvent, PetHatchState> {
  PetHatchBloc({int initialCracks = 0})
      : super(PetHatchState(cracks: initialCracks, isHatched: initialCracks >= 3)) {
    on<TapEggWithHammerEvent>((event, emit) {
      final nextCracks = state.cracks + 1;
      if (nextCracks >= 3) {
        emit(const PetHatchState(
          cracks: 3,
          isHatched: true,
          petName: 'Rồng Con Kẹo Bông',
        ));
      } else {
        emit(PetHatchState(
          cracks: nextCracks,
          isHatched: false,
        ));
      }
    });
  }
}
