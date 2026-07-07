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

  test('should call repository.update and return Unit on success', () async {
    final unit = Unit(id: '1', name: 'Box', createdAt: DateTime.now(), updatedAt: DateTime.now());
    when(() => repository.update('1', 'Box')).thenAnswer((_) async => right(unit));

    final result = await useCase('1', 'Box');
    expect(result.fold((l) => l, (r) => r), unit);
    verify(() => repository.update('1', 'Box')).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.update('999', 'X')).thenAnswer((_) async => left(ServerFailure('Unit not found')));

    final result = await useCase('999', 'X');
    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
