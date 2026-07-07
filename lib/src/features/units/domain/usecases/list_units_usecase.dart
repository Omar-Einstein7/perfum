import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../repositories/unit_repository.dart';

class ListUnitsUseCase {
  final UnitRepository repository;
  ListUnitsUseCase({required this.repository});

  Future<Either<Failure, PaginatedUnits>> call({int page = 1, int limit = 20, String search = ''}) =>
      repository.list(page: page, limit: limit, search: search);
}
