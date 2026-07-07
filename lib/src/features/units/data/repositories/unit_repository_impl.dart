import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/unit_repository.dart';
import '../datasources/unit_remote_data_source.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitRemoteDataSource dataSource;

  UnitRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, PaginatedUnits>> list({int page = 1, int limit = 20, String search = ''}) async {
    try {
      final response = await dataSource.list(page: page, limit: limit, search: search);
      return right(PaginatedUnits(
        units: response.units.map((m) => m.toEntity()).toList(),
        total: response.total,
        page: response.page,
        pages: response.pages,
      ));
    } on ServerFailure catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> getById(String id) async {
    try {
      final model = await dataSource.getById(id);
      return right(model.toEntity());
    } on ServerFailure catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> create(String name) async {
    try {
      final model = await dataSource.create(name);
      return right(model.toEntity());
    } on ServerFailure catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> update(String id, String name) async {
    try {
      final model = await dataSource.update(id, name);
      return right(model.toEntity());
    } on ServerFailure catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await dataSource.delete(id);
      return right(null);
    } on ServerFailure catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Unexpected error: $e'));
    }
  }
}
