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

  test('should call repository.create and return Unit on success', () async {
    final unit = Unit(id: '1', name: 'Carton', createdAt: DateTime.now(), updatedAt: DateTime.now());
    when(() => repository.create('Carton')).thenAnswer((_) async => right(unit));

    final result = await useCase('Carton');
    expect(result.fold((l) => l, (r) => r), unit);
    verify(() => repository.create('Carton')).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.create('Carton')).thenAnswer((_) async => left(ServerFailure('Unit name already exists')));

    final result = await useCase('Carton');
    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
