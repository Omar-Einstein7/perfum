import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase({required AuthRepository repository}) : _repository = repository;

  FutureEither<AppUser> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.signUp(name: name, email: email, password: password);
  }
}
