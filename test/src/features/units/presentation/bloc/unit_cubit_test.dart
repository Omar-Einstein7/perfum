import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/paginated_response.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/create_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/delete_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/get_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/list_units_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/update_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_cubit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_state.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockListUnitsUseCase extends Mock implements ListUnitsUseCase {}
class MockGetUnitUseCase extends Mock implements GetUnitUseCase {}
class MockCreateUnitUseCase extends Mock implements CreateUnitUseCase {}
class MockUpdateUnitUseCase extends Mock implements UpdateUnitUseCase {}
class MockDeleteUnitUseCase extends Mock implements DeleteUnitUseCase {}

void main() {
  late MockListUnitsUseCase mockListUnits;
  late MockGetUnitUseCase mockGetUnit;
  late MockCreateUnitUseCase mockCreateUnit;
  late MockUpdateUnitUseCase mockUpdateUnit;
  late MockDeleteUnitUseCase mockDeleteUnit;
  late UnitCubit cubit;

  setUp(() {
    mockListUnits = MockListUnitsUseCase();
    mockGetUnit = MockGetUnitUseCase();
    mockCreateUnit = MockCreateUnitUseCase();
    mockUpdateUnit = MockUpdateUnitUseCase();
    mockDeleteUnit = MockDeleteUnitUseCase();
    cubit = UnitCubit(
      listUnitsUseCase: mockListUnits,
      getUnitUseCase: mockGetUnit,
      createUnitUseCase: mockCreateUnit,
      updateUnitUseCase: mockUpdateUnit,
      deleteUnitUseCase: mockDeleteUnit,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('loadUnits', () {
    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitLoaded] on success',
      build: () {
        when(() => mockListUnits(page: 1, limit: 20, search: any(named: 'search'))).thenAnswer(
          (_) async => right(PaginatedResponse<Unit>(data: [], total: 0, page: 1, limit: 20, pages: 1)),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadUnits(),
      expect: () => [
        const UnitLoading(),
        UnitLoaded(units: [], total: 0, page: 1, pages: 1),
      ],
    );

    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitError] on failure',
      build: () {
        when(() => mockListUnits(page: 1, limit: 20, search: any(named: 'search'))).thenAnswer(
          (_) async => left(ServerFailure('Failed to load')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadUnits(),
      expect: () => [
        const UnitLoading(),
        const UnitError(message: 'Failed to load'),
      ],
    );
  });

  group('loadUnit', () {
    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitDetailLoaded] on success',
      build: () {
        final now = DateTime.now();
        final unit = Unit(id: '1', name: 'Carton', abbreviation: 'ctn', type: UnitType.count, createdAt: now, updatedAt: now);
        when(() => mockGetUnit('1')).thenAnswer((_) async => right(unit));
        return cubit;
      },
      act: (cubit) => cubit.loadUnit('1'),
      expect: () => [
        const UnitLoading(),
        isA<UnitDetailLoaded>(),
      ],
    );

    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitError] on failure',
      build: () {
        when(() => mockGetUnit('1')).thenAnswer((_) async => left(ServerFailure('Not found')));
        return cubit;
      },
      act: (cubit) => cubit.loadUnit('1'),
      expect: () => [
        const UnitLoading(),
        const UnitError(message: 'Not found'),
      ],
    );
  });

  group('createUnit', () {
    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitLoaded] on success',
      build: () {
        final now = DateTime.now();
        final unit = Unit(id: '1', name: 'Carton', abbreviation: 'ctn', type: UnitType.count, createdAt: now, updatedAt: now);
        when(() => mockCreateUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count, description: any(named: 'description')))
            .thenAnswer((_) async => right(unit));
        when(() => mockListUnits(page: 1, limit: 20, search: any(named: 'search')))
            .thenAnswer((_) async => right(PaginatedResponse<Unit>(data: [], total: 0, page: 1, limit: 20, pages: 1)));
        return cubit;
      },
      act: (cubit) => cubit.createUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count),
      expect: () => [
        const UnitLoading(),
        UnitLoaded(units: [], total: 0, page: 1, pages: 1),
      ],
    );

    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitError] on failure',
      build: () {
        when(() => mockCreateUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count, description: any(named: 'description')))
            .thenAnswer((_) async => left(ServerFailure('Unit name already exists')));
        return cubit;
      },
      act: (cubit) => cubit.createUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count),
      expect: () => [
        const UnitLoading(),
        const UnitError(message: 'Unit name already exists'),
      ],
    );
  });

  group('updateUnit', () {
    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitError] on failure',
      build: () {
        when(() => mockUpdateUnit(id: '1', name: 'Box', abbreviation: any(named: 'abbreviation'), type: any(named: 'type'), description: any(named: 'description')))
            .thenAnswer((_) async => left(ServerFailure('Unit not found')));
        return cubit;
      },
      act: (cubit) => cubit.updateUnit(id: '1', name: 'Box'),
      expect: () => [
        const UnitLoading(),
        const UnitError(message: 'Unit not found'),
      ],
    );
  });

  group('deleteUnit', () {
    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitDeleted, UnitLoading, UnitLoaded] on success',
      build: () {
        when(() => mockDeleteUnit('1')).thenAnswer((_) async => right(null));
        when(() => mockListUnits(page: 1, limit: 20, search: any(named: 'search')))
            .thenAnswer((_) async => right(PaginatedResponse<Unit>(data: [], total: 0, page: 1, limit: 20, pages: 1)));
        return cubit;
      },
      act: (cubit) => cubit.deleteUnit('1'),
      expect: () => [
        const UnitLoading(),
        const UnitDeleted(),
        const UnitLoading(),
        UnitLoaded(units: [], total: 0, page: 1, pages: 1),
      ],
    );

    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitError] on failure',
      build: () {
        when(() => mockDeleteUnit('1')).thenAnswer(
          (_) async => left(ServerFailure('Cannot delete: referenced')),
        );
        return cubit;
      },
      act: (cubit) => cubit.deleteUnit('1'),
      expect: () => [
        const UnitLoading(),
        const UnitError(message: 'Cannot delete: referenced'),
      ],
    );
  });
}
