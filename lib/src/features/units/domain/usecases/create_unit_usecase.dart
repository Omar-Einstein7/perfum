import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../repositories/unit_repository.dart';
import '../entities/unit.dart';

class CreateUnitUseCase {
  final UnitRepository repository;
  CreateUnitUseCase({required this.repository});

  Future<Either<Failure, Unit>> call({
    required String name,
    required String abbreviation,
    required UnitType type,
    String? description,
  }) =>
      repository.createUnit(name: name, abbreviation: abbreviation, type: type, description: description);
}
