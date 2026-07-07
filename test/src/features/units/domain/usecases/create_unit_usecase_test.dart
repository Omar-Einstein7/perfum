import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/repositories/unit_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/create_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockUnitRepository extends Mock implements UnitRepository {}

void main() {
  late MockUnitRepository repository;
  late CreateUnitUseCase useCase;

  setUp(() {
    repository = MockUnitRepository();
    useCase = CreateUnitUseCase(repository: repository);
  });

  test('should call repository.createUnit and return Unit on success', () async {
    final now = DateTime.now();
    final unit = Unit(id: '1', name: 'Carton', abbreviation: 'ctn', type: UnitType.count, createdAt: now, updatedAt: now);
    when(() => repository.createUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count, description: any(named: 'description')))
        .thenAnswer((_) async => right(unit));

    final result = await useCase(name: 'Carton', abbreviation: 'ctn', type: UnitType.count);
    expect(result.fold((l) => l, (r) => r), unit);
    verify(() => repository.createUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count, description: null)).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.createUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count, description: any(named: 'description')))
        .thenAnswer((_) async => left(ServerFailure('Unit name already exists')));

    final result = await useCase(name: 'Carton', abbreviation: 'ctn', type: UnitType.count);
    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
