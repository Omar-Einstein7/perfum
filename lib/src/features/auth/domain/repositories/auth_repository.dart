import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Stream<bool> get onAuthStateChanged;

  FutureEither<Employee> login({
    required String username,
    required String password,
  });

  FutureEither<void> logout();

  FutureEither<bool> hasStoredSession();
}
