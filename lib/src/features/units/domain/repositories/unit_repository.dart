import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../entities/unit.dart';
import '../entities/paginated_response.dart';

abstract class UnitRepository {
  Future<Either<Failure, PaginatedResponse<Unit>>> listUnits({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Either<Failure, Unit>> getUnit(String id);

  Future<Either<Failure, Unit>> createUnit({
    required String name,
    required String abbreviation,
    required UnitType type,
    String? description,
  });

  Future<Either<Failure, Unit>> updateUnit({
    required String id,
    String? name,
    String? abbreviation,
    UnitType? type,
    String? description,
  });

  Future<Either<Failure, void>> deleteUnit(String id);
}
