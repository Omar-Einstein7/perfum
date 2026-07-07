import 'package:perfum_ahmed_gaper/src/imports/core_imports.dart';
import 'package:perfum_ahmed_gaper/src/imports/packages_imports.dart';

import 'package:perfum_ahmed_gaper/src/features/auth/domain/entities/user.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/models/user_model.dart';
import 'package:perfum_ahmed_gaper/src/services/service_locator.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final SecureStorageService _secureStorage;
  final AuthService _authService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource dataSource,
    required SecureStorageService secureStorage,
    required AuthService authService,
  })  : _dataSource = dataSource,
        _secureStorage = secureStorage,
        _authService = authService;

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _authService.authStateChanges.map((userData) {
      if (userData == null) return null;
      return _mapToUser(userData);
    });
  }

  @override
  FutureEither<AppUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _dataSource.login(email: email, password: password);

    return result.fold(
      (failure) => Future.value(left<Failure, AppUser>(failure)),
      (rawData) => _saveTokenAndMapUser(rawData, email),
    );
  }

  @override
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _dataSource.signUp(
      name: name,
      email: email,
      password: password,
    );

    return result.fold(
      (failure) => Future.value(left<Failure, AppUser>(failure)),
      (rawData) => _mapUserResult(rawData, email, name),
    );
  }

  @override
  FutureEither<void> forgotPassword({required String email}) {
    return _dataSource.forgotPassword(email: email);
  }

  @override
  FutureEither<void> logout() async {
    await _secureStorage.delete(kJwtTokenKey);
    return _dataSource.logout();
  }

  @override
  FutureEither<AppUser?> checkAuthState() async {
    final result = await _dataSource.getCurrentUser();

    return result.map((rawData) {
      if (rawData == null) return null;
      return _mapToUser(rawData);
    });
  }

  AppUser _mapToUser(Map<String, dynamic> data) {
    final userData = data['user'] ?? data;
    final userModel = UserModel.fromJson({
      '_id': (userData['_id'] ?? userData['id'] ?? '').toString(),
      'email': userData['email'] ?? '',
      'name': userData['name'],
      'photoUrl': userData['photoUrl'],
      'permissions': (userData['permissions'] as int?) ?? 0,
    });
    return userModel.toEntity();
  }

  Future<Either<Failure, AppUser>> _saveTokenAndMapUser(
    Map<String, dynamic>? rawData,
    String email,
  ) async {
    if (rawData == null) {
      return left(const ServerFailure('Login failed: User record not found'));
    }

    final token = rawData['token'] as String? ?? rawData['accessToken'] as String? ?? '';
    if (token.isNotEmpty) {
      await _secureStorage.write(kJwtTokenKey, token);
    }

    _authService.updateAuthState(rawData);

    final userData = rawData['user'] ?? rawData;
    final userModel = UserModel.fromJson({
      '_id': (userData['_id'] ?? userData['id'] ?? '').toString(),
      'email': userData['email'] ?? email,
      'name': userData['name'],
      'photoUrl': userData['photoUrl'],
      'permissions': (userData['permissions'] as int?) ?? 0,
    });
    return right(userModel.toEntity());
  }

  Future<Either<Failure, AppUser>> _mapUserResult(
    Map<String, dynamic>? rawData,
    String email,
    String name,
  ) async {
    if (rawData == null) {
      return left(const ServerFailure('Sign up failed: User record corrupted'));
    }

    _authService.updateAuthState(rawData);

    final userData = rawData['user'] ?? rawData;
    final userModel = UserModel.fromJson({
      '_id': (userData['_id'] ?? userData['id'] ?? '').toString(),
      'email': userData['email'] ?? email,
      'name': userData['name'] ?? name,
      'photoUrl': userData['photoUrl'],
      'permissions': (userData['permissions'] as int?) ?? 0,
    });
    return right(userModel.toEntity());
  }
}
