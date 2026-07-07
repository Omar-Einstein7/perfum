import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../entities/unit.dart';

class PaginatedUnits {
  final List<Unit> units;
  final int total;
  final int page;
  final int pages;

  const PaginatedUnits({
    required this.units,
    required this.total,
    required this.page,
    required this.pages,
  });
}

abstract class UnitRepository {
  Future<Either<Failure, PaginatedUnits>> list({int page = 1, int limit = 20, String search = ''});
  Future<Either<Failure, Unit>> getById(String id);
  Future<Either<Failure, Unit>> create(String name);
  Future<Either<Failure, Unit>> update(String id, String name);
  Future<Either<Failure, void>> delete(String id);
}
