import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/repositories/unit_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/get_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockUnitRepository extends Mock implements UnitRepository {}

void main() {
  late MockUnitRepository repository;
  late GetUnitUseCase useCase;

  setUp(() {
    repository = MockUnitRepository();
    useCase = GetUnitUseCase(repository: repository);
  });

  test('should call repository.getUnit and return Unit on success', () async {
    final now = DateTime.now();
    final unit = Unit(id: '1', name: 'Carton', abbreviation: 'ctn', type: UnitType.count, createdAt: now, updatedAt: now);
    when(() => repository.getUnit('1')).thenAnswer((_) async => right(unit));

    final result = await useCase('1');
    expect(result.fold((l) => l, (r) => r), unit);
    verify(() => repository.getUnit('1')).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.getUnit('999')).thenAnswer((_) async => left(ServerFailure('Unit not found')));

    final result = await useCase('999');
    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
