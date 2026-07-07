import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/create_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/delete_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/get_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/list_units_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/update_unit_usecase.dart';
import 'unit_state.dart';

class UnitCubit extends Cubit<UnitState> {
  final ListUnitsUseCase listUnitsUseCase;
  final GetUnitUseCase getUnitUseCase;
  final CreateUnitUseCase createUnitUseCase;
  final UpdateUnitUseCase updateUnitUseCase;
  final DeleteUnitUseCase deleteUnitUseCase;

  UnitCubit({
    required this.listUnitsUseCase,
    required this.getUnitUseCase,
    required this.createUnitUseCase,
    required this.updateUnitUseCase,
    required this.deleteUnitUseCase,
  }) : super(const UnitInitial());

  Future<void> loadUnits({int page = 1, int limit = 20, String? search}) async {
    emit(const UnitLoading());
    final result = await listUnitsUseCase(page: page, limit: limit, search: search);
    result.fold(
      (failure) => emit(UnitError(message: failure.message)),
      (paginated) => emit(UnitLoaded(
        units: paginated.data,
        total: paginated.total,
        page: paginated.page,
        pages: paginated.pages,
      )),
    );
  }

  Future<void> loadUnit(String id) async {
    emit(const UnitLoading());
    final result = await getUnitUseCase(id);
    result.fold(
      (failure) => emit(UnitError(message: failure.message)),
      (unit) => emit(UnitDetailLoaded(unit: unit)),
    );
  }

  Future<void> createUnit({required String name, required String abbreviation, required UnitType type, String? description}) async {
    emit(const UnitLoading());
    final result = await createUnitUseCase(name: name, abbreviation: abbreviation, type: type, description: description);
    result.fold(
      (failure) => emit(UnitError(message: failure.message)),
      (_) => loadUnits(),
    );
  }

  Future<void> updateUnit({required String id, String? name, String? abbreviation, UnitType? type, String? description}) async {
    emit(const UnitLoading());
    final result = await updateUnitUseCase(id: id, name: name, abbreviation: abbreviation, type: type, description: description);
    result.fold(
      (failure) => emit(UnitError(message: failure.message)),
      (_) => loadUnits(),
    );
  }

  Future<void> deleteUnit(String id, {int currentPage = 1}) async {
    emit(const UnitLoading());
    final result = await deleteUnitUseCase(id);
    result.fold(
      (failure) {
        emit(UnitError(message: failure.message));
        return null;
      },
      (_) {
        emit(const UnitDeleted());
        return null;
      },
    );
    if (state is UnitDeleted) {
      final page = currentPage > 1 ? currentPage - 1 : currentPage;
      await loadUnits(page: page);
    }
  }
}
