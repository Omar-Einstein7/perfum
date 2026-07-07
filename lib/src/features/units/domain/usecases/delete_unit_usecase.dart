import 'package:fpdart/fpdart.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';
import '../repositories/unit_repository.dart';

class DeleteUnitUseCase {
  final UnitRepository repository;
  DeleteUnitUseCase({required this.repository});

  Future<Either<Failure, void>> call(String id) => repository.deleteUnit(id);
}
