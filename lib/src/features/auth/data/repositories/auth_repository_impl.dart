import 'package:perfum_ahmed_gaper/src/imports/core_imports.dart';
import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Stream<bool> get onAuthStateChanged => _authService.authStateChanges;

  @override
  FutureEither<Employee> login({
    required String username,
    required String password,
  }) async {
    final result = await _authService.login(username: username, password: password);

    return result.map((data) => Employee.fromJson(data));
  }

  @override
  FutureEither<void> logout() {
    return _authService.logout();
  }

  @override
  FutureEither<bool> hasStoredSession() {
    return _authService.hasStoredSession();
  }
}
