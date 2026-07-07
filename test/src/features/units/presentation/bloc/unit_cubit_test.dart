import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/repositories/unit_repository.dart';
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
        when(() => mockListUnits(page: 1, limit: 20, search: '')).thenAnswer(
          (_) async => right(PaginatedUnits(units: [], total: 0, page: 1, pages: 1)),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadUnits(),
      expect: () => [
        const UnitLoading(),
        const UnitLoaded(units: [], total: 0, page: 1, pages: 1),
      ],
    );

    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitError] on failure',
      build: () {
        when(() => mockListUnits(page: 1, limit: 20, search: '')).thenAnswer(
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

  group('createUnit', () {
    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitLoaded] on success',
      build: () {
        when(() => mockCreateUnit('Carton')).thenAnswer(
          (_) async => right(Unit(id: '1', name: 'Carton', createdAt: DateTime.now(), updatedAt: DateTime.now())),
        );
        when(() => mockListUnits(page: 1, limit: 20, search: '')).thenAnswer(
          (_) async => right(PaginatedUnits(units: [], total: 0, page: 1, pages: 1)),
        );
        return cubit;
      },
      act: (cubit) => cubit.createUnit('Carton'),
      expect: () => [
        const UnitLoading(),
        const UnitLoaded(units: [], total: 0, page: 1, pages: 1),
      ],
    );

    blocTest<UnitCubit, UnitState>(
      'emits [UnitLoading, UnitError] on failure',
      build: () {
        when(() => mockCreateUnit('Carton')).thenAnswer(
          (_) async => left(ServerFailure('Unit name already exists')),
        );
        return cubit;
      },
      act: (cubit) => cubit.createUnit('Carton'),
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
        when(() => mockUpdateUnit('1', 'Box')).thenAnswer(
          (_) async => left(ServerFailure('Unit not found')),
        );
        return cubit;
      },
      act: (cubit) => cubit.updateUnit('1', 'Box'),
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
        when(() => mockListUnits(page: 1, limit: 20, search: '')).thenAnswer(
          (_) async => right(const PaginatedUnits(units: [], total: 0, page: 1, pages: 1)),
        );
        return cubit;
      },
      act: (cubit) => cubit.deleteUnit('1'),
      expect: () => [
        const UnitLoading(),
        const UnitDeleted(),
        const UnitLoading(),
        const UnitLoaded(units: [], total: 0, page: 1, pages: 1),
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
