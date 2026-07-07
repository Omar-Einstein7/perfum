import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/paginated_response.dart';
import '../../domain/repositories/unit_repository.dart';
import '../datasources/unit_remote_data_source.dart';
import '../models/unit_model.dart';
import '../models/unit_list_response.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitRemoteDataSource dataSource;

  UnitRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, PaginatedResponse<Unit>>> listUnits({int page = 1, int limit = 20, String? search}) async {
    final result = await dataSource.listUnits(page: page, limit: limit, search: search);
    return result.map((response) => response.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> getUnit(String id) async {
    final result = await dataSource.getUnit(id);
    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> createUnit({required String name, required String abbreviation, required UnitType type, String? description}) async {
    final result = await dataSource.createUnit(name: name, abbreviation: abbreviation, type: type, description: description);
    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> updateUnit({required String id, String? name, String? abbreviation, UnitType? type, String? description}) async {
    final result = await dataSource.updateUnit(id: id, name: name, abbreviation: abbreviation, type: type, description: description);
    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, void>> deleteUnit(String id) async {
    return dataSource.deleteUnit(id);
  }
}
