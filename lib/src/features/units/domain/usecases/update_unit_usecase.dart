import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../repositories/unit_repository.dart';
import '../entities/unit.dart';

class UpdateUnitUseCase {
  final UnitRepository repository;
  UpdateUnitUseCase({required this.repository});

  Future<Either<Failure, Unit>> call({
    required String id,
    String? name,
    String? abbreviation,
    UnitType? type,
    String? description,
  }) =>
      repository.updateUnit(id: id, name: name, abbreviation: abbreviation, type: type, description: description);
}
