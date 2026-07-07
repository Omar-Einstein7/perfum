import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockDioService extends Mock implements DioService {}

void main() {
  late MockDioService mockDio;
  late AuthRemoteDataSource dataSource;

  setUp(() {
    mockDio = MockDioService();
    dataSource = AuthRemoteDataSourceImpl(dio: mockDio);
  });

  group('login', () {
    test('should return response data on success', () async {
      final responseData = {'token': 'jwt123', 'user': {'_id': '1', 'email': 'test@test.com'}};
      final response = Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: responseData,
        statusCode: 200,
      );
      when(() => mockDio.post('/auth/login', data: any(named: 'data'))).thenAnswer(
        (_) async => right(response),
      );

      final result = await dataSource.login(email: 'test@test.com', password: 'pass123');

      expect(result.fold((l) => l, (r) => r), responseData);
    });

    test('should return Failure on DioException', () async {
      when(() => mockDio.post('/auth/login', data: any(named: 'data'))).thenAnswer(
        (_) async => left(ServerFailure('Login failed')),
      );

      final result = await dataSource.login(email: 'test@test.com', password: 'wrong');

      expect(result.fold((l) => l, (r) => r), isA<ServerFailure>());
    });
  });

  group('getCurrentUser', () {
    test('should return user data on success', () async {
      final responseData = {'_id': '1', 'email': 'test@test.com'};
      final response = Response(
        requestOptions: RequestOptions(path: '/auth/me'),
        data: responseData,
        statusCode: 200,
      );
      when(() => mockDio.get('/auth/me')).thenAnswer((_) async => right(response));

      final result = await dataSource.getCurrentUser();

      expect(result.fold((l) => l, (r) => r), responseData);
    });

    test('should return null on 401', () async {
      final response = Response(
        requestOptions: RequestOptions(path: '/auth/me'),
        data: null,
        statusCode: 401,
      );
      when(() => mockDio.get('/auth/me')).thenAnswer((_) async => right(response));

      final result = await dataSource.getCurrentUser();

      expect(result.fold((l) => l, (r) => r), isNull);
    });
  });

  group('logout', () {
    test('should succeed on successful logout', () async {
      final response = Response(
        requestOptions: RequestOptions(path: '/auth/logout'),
        data: null,
        statusCode: 200,
      );
      when(() => mockDio.post('/auth/logout')).thenAnswer((_) async => right(response));

      final result = await dataSource.logout();

      expect(result.isRight(), true);
    });
  });
}
