import 'package:perfum_ahmed_gaper/src/utils/utils.dart';

abstract class AuthRemoteDataSource {
  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  });

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
  });

  FutureEither<void> forgotPassword({required String email});

  FutureEither<void> logout();

  FutureEither<Map<String, dynamic>?> getCurrentUser();
}
