import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/models/token_response_model.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/models/user_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = AuthRemoteDataSourceImpl(dio: dio);
  });

  group('login', () {
    test('should return TokenResponseModel on success', () async {
      when(
        () => dio.post('/api/auth/login', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          data: {
            'success': true,
            'data': {
              'accessToken': 'abc',
              'refreshToken': 'def',
              'expiresIn': 900,
              'user': {
                'id': '1',
                'email': 'test@example.com',
                'role': 'staff',
                'permissions': {
                  'p_info': true,
                  'p_res': false,
                  'p_sell': false,
                  'p_snadat': false,
                  'p_user': false,
                  'p_report': false,
                  'p_report2': false,
                },
                'status': 'active',
              },
            },
          },
          statusCode: 200,
        ),
      );

      final result = await dataSource.login('test@example.com', 'pass');
      expect(result, isA<TokenResponseModel>());
      expect(result.accessToken, 'abc');
      expect(result.user!.email, 'test@example.com');
    });
  });

  group('getMe', () {
    test('should return UserModel on success', () async {
      when(() => dio.get('/api/auth/me')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/auth/me'),
          data: {
            'success': true,
            'data': {
              'id': '1',
              'email': 'test@example.com',
              'role': 'staff',
              'permissions': {
                'p_info': true,
                'p_res': false,
                'p_sell': false,
                'p_snadat': false,
                'p_user': false,
                'p_report': false,
                'p_report2': false,
              },
              'status': 'active',
            },
          },
          statusCode: 200,
        ),
      );

      final result = await dataSource.getMe();
      expect(result, isA<UserModel>());
      expect(result.email, 'test@example.com');
    });
  });
}
