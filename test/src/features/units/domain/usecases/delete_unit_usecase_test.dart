import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/repositories/unit_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/delete_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockUnitRepository extends Mock implements UnitRepository {}

void main() {
  late MockUnitRepository repository;
  late DeleteUnitUseCase useCase;

  setUp(() {
    repository = MockUnitRepository();
    useCase = DeleteUnitUseCase(repository: repository);
  });

  test('should call repository.delete and return void on success', () async {
    when(() => repository.delete('1')).thenAnswer((_) async => right(null));

    final result = await useCase('1');
    expect(result.isRight(), true);
    verify(() => repository.delete('1')).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.delete('1')).thenAnswer((_) async => left(ServerFailure('Cannot delete unit: it is referenced by 3 material(s)')));

    final result = await useCase('1');
    expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
  });
}
