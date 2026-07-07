import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository _repository;

  ForgotPasswordUseCase({required AuthRepository repository}) : _repository = repository;

  FutureEither<void> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}
