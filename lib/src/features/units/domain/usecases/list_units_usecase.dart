import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../repositories/unit_repository.dart';
import '../entities/paginated_response.dart';
import '../entities/unit.dart';

class ListUnitsUseCase {
  final UnitRepository repository;
  ListUnitsUseCase({required this.repository});

  Future<Either<Failure, PaginatedResponse<Unit>>> call({
    int page = 1,
    int limit = 20,
    String? search,
  }) =>
      repository.listUnits(page: page, limit: limit, search: search);
}
