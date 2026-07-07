import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

class CheckSessionUseCase {
  final AuthRepository _repository;

  CheckSessionUseCase({required AuthRepository repository}) : _repository = repository;

  FutureEither<AppUser?> call() {
    return _repository.checkAuthState();
  }
}
