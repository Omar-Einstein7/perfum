import 'dart:async';
import '../utils/utils.dart';
import 'package:dio/dio.dart';
import 'secure_storage_service.dart';

class AuthService {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  AuthService(this._dio) : _secureStorage = SecureStorageService();

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  Stream<bool> get authStateChanges => _authStateController.stream;

  FutureEither<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return runTask(() async {
      final response = await _dio.post<Map<String, dynamic>>('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final data = response.data!;
      await _secureStorage.write('access_token', data['accessToken'] as String);
      await _secureStorage.write('refresh_token', data['refreshToken'] as String);
      _authStateController.add(true);
      return data['employee'] as Map<String, dynamic>;
    }, requiresNetwork: true);
  }

  FutureEither<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return runTask(() async {
      final response = await _dio.post<Map<String, dynamic>>('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      final data = response.data!;
      await _secureStorage.write('access_token', data['accessToken'] as String);
      if (data['refreshToken'] != null) {
        await _secureStorage.write('refresh_token', data['refreshToken'] as String);
      }
      return data['employee'] as Map<String, dynamic>;
    }, requiresNetwork: true);
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      await _secureStorage.delete('access_token');
      await _secureStorage.delete('refresh_token');
      _authStateController.add(false);
    });
  }

  FutureEither<bool> hasStoredSession() async {
    final result = await _secureStorage.read('access_token');
    return result.map((token) => token != null && token.isNotEmpty);
  }

  void dispose() {
    _authStateController.close();
  }
}
