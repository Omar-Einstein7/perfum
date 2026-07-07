import 'package:fpdart/fpdart.dart';
import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioService _dio;

  AuthRemoteDataSourceImpl({required DioService dio}) : _dio = dio;

  @override
  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final result = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return result.fold(
      (failure) => Future.value(left<Failure, Map<String, dynamic>?>(failure)),
      (response) => right<Failure, Map<String, dynamic>?>(
        response.data as Map<String, dynamic>?,
      ),
    );
  }

  @override
  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _dio.post('/auth/signup', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return result.fold(
      (failure) => Future.value(left<Failure, Map<String, dynamic>?>(failure)),
      (response) => right<Failure, Map<String, dynamic>?>(
        response.data as Map<String, dynamic>?,
      ),
    );
  }

  @override
  FutureEither<void> forgotPassword({required String email}) async {
    final result = await _dio.post('/auth/forgot-password', data: {
      'email': email,
    });
    return result.fold(
      (failure) => Future.value(left<Failure, void>(failure)),
      (_) => right<Failure, void>(null),
    );
  }

  @override
  FutureEither<void> logout() async {
    final result = await _dio.post('/auth/logout');
    return result.fold(
      (failure) => Future.value(left<Failure, void>(failure)),
      (_) => right<Failure, void>(null),
    );
  }

  @override
  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    final result = await _dio.get('/auth/me');
    return result.fold(
      (failure) => Future.value(left<Failure, Map<String, dynamic>?>(failure)),
      (response) => right<Failure, Map<String, dynamic>?>(
        response.data as Map<String, dynamic>?,
      ),
    );
  }
}
