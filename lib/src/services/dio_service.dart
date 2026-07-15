import 'package:dio/dio.dart';
import '../utils/utils.dart';

/// A robust networking service powered by Dio.
class DioService {
  final Dio _dio;

  DioService(this._dio);

  // --- HTTP Methods ---

  FutureEither<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return runTask(() => _dio.get(path, queryParameters: queryParameters), requiresNetwork: true);
  }

  FutureEither<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return runTask(() => _dio.post(path, data: data, queryParameters: queryParameters), requiresNetwork: true);
  }

  FutureEither<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return runTask(() => _dio.put(path, data: data, queryParameters: queryParameters), requiresNetwork: true);
  }

  FutureEither<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return runTask(() => _dio.patch(path, data: data, queryParameters: queryParameters), requiresNetwork: true);
  }

  FutureEither<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return runTask(() => _dio.delete(path, data: data, queryParameters: queryParameters), requiresNetwork: true);
  }
}
