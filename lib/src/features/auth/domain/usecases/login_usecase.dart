import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  FutureEither<AppUser> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
