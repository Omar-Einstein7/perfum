import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/repositories/unit_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/update_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockUnitRepository extends Mock implements UnitRepository {}

void main() {
  late MockUnitRepository repository;
  late UpdateUnitUseCase useCase;

  setUp(() {
    repository = MockUnitRepository();
    useCase = UpdateUnitUseCase(repository: repository);
  });

  test('should call repository.updateUnit and return Unit on success', () async {
    final now = DateTime.now();
    final unit = Unit(id: '1', name: 'Box', abbreviation: 'bx', type: UnitType.count, createdAt: now, updatedAt: now);
    when(() => repository.updateUnit(id: '1', name: 'Box', abbreviation: any(named: 'abbreviation'), type: any(named: 'type'), description: any(named: 'description')))
        .thenAnswer((_) async => right(unit));

    final result = await useCase(id: '1', name: 'Box');
    expect(result.fold((l) => l, (r) => r), unit);
    verify(() => repository.updateUnit(id: '1', name: 'Box', abbreviation: null, type: null, description: null)).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.updateUnit(id: '999', name: 'X', abbreviation: any(named: 'abbreviation'), type: any(named: 'type'), description: any(named: 'description')))
        .thenAnswer((_) async => left(ServerFailure('Unit not found')));

    final result = await useCase(id: '999', name: 'X');
    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
