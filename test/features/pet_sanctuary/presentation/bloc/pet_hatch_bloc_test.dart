import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/pet_sanctuary/domain/models/pet_egg.dart';
import 'package:fun_edu/features/pet_sanctuary/presentation/bloc/pet_hatch_bloc.dart';

void main() {
  test('PetEgg model calculates isReadyToHatch based on cracks', () {
    const egg1 = PetEgg(id: 'egg_1', cracks: 0, petNameReward: 'Rồng Con');
    expect(egg1.isReadyToHatch, isFalse);

    const egg2 = PetEgg(id: 'egg_2', cracks: 3, petNameReward: 'Rồng Con');
    expect(egg2.isReadyToHatch, isTrue);
  });

  blocTest<PetHatchBloc, PetHatchState>(
    'tap hammer increments cracks and hatches on 3rd tap',
    build: () => PetHatchBloc(initialCracks: 2),
    act: (bloc) => bloc.add(const TapEggWithHammerEvent()),
    expect: () => [
      const PetHatchState(cracks: 3, isHatched: true, petName: 'Rồng Con Kẹo Bông'),
    ],
  );

  blocTest<PetHatchBloc, PetHatchState>(
    'tap hammer increments cracks to 1 on 1st tap',
    build: () => PetHatchBloc(initialCracks: 0),
    act: (bloc) => bloc.add(const TapEggWithHammerEvent()),
    expect: () => [
      const PetHatchState(cracks: 1, isHatched: false),
    ],
  );
}
