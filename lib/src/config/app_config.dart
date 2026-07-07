import '../imports/core_imports.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:perfum_ahmed_gaper/src/services/service_locator.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;

  static String get baseUrl => _getBaseUrl();

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.info('🌐 [DIO] REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info('✅ [DIO] RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.error('❌ [DIO] ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );

    // JWT interceptor — LAST interceptor in the chain
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokenResult = await SecureStorageService.instance.read(kJwtTokenKey);
          tokenResult.fold(
            (_) => null,
            (token) {
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            },
          );
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await SecureStorageService.instance.deleteAll();
            AuthService.instance.signalUnauthenticated();
          }
          return handler.next(e);
        },
      ),
    );

  }

  static String _getBaseUrl() {
    return dotenv.get('API_BASE_URL', fallback: 'https://localhost:3000');
  }
}
