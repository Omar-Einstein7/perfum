import 'package:dio/dio.dart';
import '../models/token_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<TokenResponseModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getMe();
  Future<List<UserModel>> listUsers();
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String role,
    required Map<String, bool> permissions,
  });
  Future<UserModel> updateUser(
    String id, {
    String? role,
    Map<String, bool>? permissions,
    String? status,
  });
  Future<void> deleteUser(String id);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<TokenResponseModel> login(String email, String password) async {
    final response = await dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return TokenResponseModel.fromJson(data);
  }

  @override
  Future<void> logout() async {
    await dio.post('/api/auth/logout');
  }

  @override
  Future<UserModel> getMe() async {
    final response = await dio.get('/api/auth/me');
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<UserModel>> listUsers() async {
    final response = await dio.get('/api/users');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    final response = await dio.post('/api/users', data: {
      'email': email,
      'password': password,
      'role': role,
      'permissions': permissions,
    });
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateUser(
    String id, {
    String? role,
    Map<String, bool>? permissions,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (permissions != null) body['permissions'] = permissions;
    if (status != null) body['status'] = status;
    final response = await dio.put('/api/users/$id', data: body);
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(String id) async {
    await dio.delete('/api/users/$id');
  }
}
