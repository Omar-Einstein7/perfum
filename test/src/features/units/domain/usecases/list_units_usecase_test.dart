import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/paginated_response.dart';
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

  test('should call repository.listUnits and return PaginatedResponse on success', () async {
    final paginated = PaginatedResponse<Unit>(data: [], total: 0, page: 1, limit: 20, pages: 1);
    when(() => repository.listUnits(page: 1, limit: 20, search: any(named: 'search')))
        .thenAnswer((_) async => right(paginated));

    final result = await useCase();
    expect(result.fold((l) => l, (r) => r), paginated);
    verify(() => repository.listUnits(page: 1, limit: 20, search: null)).called(1);
  });

  test('should pass search query to repository', () async {
    final paginated = PaginatedResponse<Unit>(data: [], total: 0, page: 1, limit: 20, pages: 1);
    when(() => repository.listUnits(page: 1, limit: 20, search: 'Carton'))
        .thenAnswer((_) async => right(paginated));

    await useCase(search: 'Carton');
    verify(() => repository.listUnits(page: 1, limit: 20, search: 'Carton')).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => repository.listUnits(page: 1, limit: 20, search: any(named: 'search')))
        .thenAnswer((_) async => left(ServerFailure('Failed to list units')));

    final result = await useCase();
    expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
  });
}
