import 'package:dio/dio.dart';
import '../utils/utils.dart';
import 'secure_storage_service.dart';
import 'auth_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _dio;

  AuthInterceptor(this._secureStorage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!options.path.contains('/auth/')) {
      final tokenResult = await _secureStorage.read('access_token');
      tokenResult.fold(
        (_) => handler.next(options),
        (token) {
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      );
    } else {
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/refresh')) {
      final refreshTokenResult = await _secureStorage.read('refresh_token');
      final storedToken = refreshTokenResult.fold((_) => null, (token) => token);

      if (storedToken case final token?) {
        try {
          final response = await _dio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': token},
          );

          final data = response.data;
          if (data != null) {
            await _secureStorage.write('access_token', data['accessToken'] as String);
            if (data['refreshToken'] case final newRefresh?) {
              await _secureStorage.write('refresh_token', newRefresh as String);
            }

            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer ${data['accessToken']}';
            final retryResponse = await _dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {}
      }

      await _secureStorage.delete('access_token');
      await _secureStorage.delete('refresh_token');
    }
    handler.next(err);
  }
}
