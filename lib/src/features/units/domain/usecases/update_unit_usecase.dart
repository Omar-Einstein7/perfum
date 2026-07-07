import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

class UpdateUnitUseCase {
  final UnitRepository repository;
  UpdateUnitUseCase({required this.repository});

  Future<Either<Failure, Unit>> call(String id, String name) =>
      repository.update(id, name);
}
