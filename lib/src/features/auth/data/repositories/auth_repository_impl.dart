import 'package:perfum_ahmed_gaper/src/services/secure_storage_service.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/session_model.dart';

class ServerFailure implements Exception {
  final String message;
  ServerFailure(this.message);
  @override
  String toString() => message;
}

class NetworkFailure implements Exception {
  final String message;
  NetworkFailure(this.message);
  @override
  String toString() => message;
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({required this.dataSource, required this.secureStorage});

  Future<void> _saveToken(String token) =>
      secureStorage.write('jwt_token', token);
  Future<void> _clearToken() => secureStorage.delete('jwt_token');

  @override
  Future<Session> login(String email, String password) async {
    final tokenModel = await dataSource.login(email, password);
    await _saveToken(tokenModel.accessToken);
    return SessionModel(
      accessToken: tokenModel.accessToken,
      refreshToken: tokenModel.refreshToken,
      expiresIn: tokenModel.expiresIn,
    ).toEntity();
  }

  @override
  Future<void> logout() async {
    try {
      await dataSource.logout();
    } catch (_) {}
    await _clearToken();
  }

  @override
  Future<User> getMe() async {
    final user = await dataSource.getMe();
    return user;
  }

  @override
  Future<List<User>> listUsers() async {
    final users = await dataSource.listUsers();
    return users;
  }

  @override
  Future<User> createUser({
    required String email,
    required String password,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    final user = await dataSource.createUser(
      email: email,
      password: password,
      role: role,
      permissions: permissions,
    );
    return user;
  }

  @override
  Future<User> updateUser(
    String id, {
    String? role,
    Map<String, bool>? permissions,
    String? status,
  }) async {
    final user = await dataSource.updateUser(
      id,
      role: role,
      permissions: permissions,
      status: status,
    );
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    await dataSource.deleteUser(id);
  }
}
