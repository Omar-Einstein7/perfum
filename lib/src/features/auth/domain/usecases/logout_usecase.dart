import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase({required AuthRepository repository}) : _repository = repository;

  FutureEither<void> call() {
    return _repository.logout();
  }
}
