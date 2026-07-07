import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/repositories/unit_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/list_units_usecase.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockUnitRepository extends Mock implements UnitRepository {}

void main() {
  late MockUnitRepository repository;
  late ListUnitsUseCase useCase;

  setUp(() {
    repository = MockUnitRepository();
    useCase = ListUnitsUseCase(repository: repository);
  });

  test('should call repository.list and return PaginatedUnits on success', () async {
    final paginated = PaginatedUnits(units: [], total: 0, page: 1, pages: 1);
    when(() => repository.list(page: 1, limit: 20, search: '')).thenAnswer((_) async => right(paginated));

    final result = await useCase();
    expect(result.fold((l) => l, (r) => r), paginated);
    verify(() => repository.list(page: 1, limit: 20, search: '')).called(1);
  });

  test('should pass search query to repository', () async {
    final paginated = PaginatedUnits(units: [], total: 0, page: 1, pages: 1);
    when(() => repository.list(page: 1, limit: 20, search: 'Carton')).thenAnswer((_) async => right(paginated));

    await useCase(search: 'Carton');
    verify(() => repository.list(page: 1, limit: 20, search: 'Carton')).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.list(page: 1, limit: 20, search: '')).thenAnswer((_) async => left(ServerFailure('Failed to list units')));

    final result = await useCase();
    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
