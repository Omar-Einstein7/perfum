import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/data/datasources/unit_remote_data_source.dart';
import 'package:perfum_ahmed_gaper/src/features/units/data/models/unit_list_response.dart';
import 'package:perfum_ahmed_gaper/src/features/units/data/models/unit_model.dart';
import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockDioService extends Mock implements DioService {}

void main() {
  late MockDioService dio;
  late UnitRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDioService();
    dataSource = UnitRemoteDataSourceImpl(dio: dio);
  });

  group('list', () {
    test('should return UnitListResponse on success', () async {
      when(
        () => dio.get('/api/units', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => right(Response(
          requestOptions: RequestOptions(path: '/api/units'),
          data: {
            'data': [
              {'id': '1', 'name': 'Carton', 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
            ],
            'meta': {'total': 1, 'page': 1, 'pages': 1},
          },
          statusCode: 200,
        )),
      );

      final result = await dataSource.list(page: 1, limit: 20);
      expect(result, isA<UnitListResponse>());
      expect(result.units.length, 1);
      expect(result.units[0].name, 'Carton');
      expect(result.total, 1);
      expect(result.page, 1);
      expect(result.pages, 1);
    });

    test('should throw ServerFailure on DioException', () async {
      when(
        () => dio.get('/api/units', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => left(ServerFailure('Failed to list units')),
      );

      expect(() => dataSource.list(), throwsA(isA<ServerFailure>()));
    });
  });

  group('getById', () {
    test('should return UnitModel on success', () async {
      when(() => dio.get('/api/units/1')).thenAnswer(
        (_) async => right(Response(
          requestOptions: RequestOptions(path: '/api/units/1'),
          data: {
            'data': {'id': '1', 'name': 'Carton', 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
          },
          statusCode: 200,
        )),
      );

      final result = await dataSource.getById('1');
      expect(result, isA<UnitModel>());
      expect(result.name, 'Carton');
    });

    test('should throw ServerFailure on failure', () async {
      when(() => dio.get('/api/units/999')).thenAnswer(
        (_) async => left(ServerFailure('Unit not found')),
      );

      expect(() => dataSource.getById('999'), throwsA(isA<ServerFailure>()));
    });
  });

  group('create', () {
    test('should return UnitModel on success', () async {
      when(
        () => dio.post('/api/units', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => right(Response(
          requestOptions: RequestOptions(path: '/api/units'),
          data: {
            'data': {'id': '3', 'name': 'Piece', 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
          },
          statusCode: 201,
        )),
      );

      final result = await dataSource.create('Piece');
      expect(result, isA<UnitModel>());
      expect(result.name, 'Piece');
    });

    test('should throw ServerFailure on failure', () async {
      when(
        () => dio.post('/api/units', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => left(ServerFailure('Unit name already exists')),
      );

      expect(() => dataSource.create('Carton'), throwsA(isA<ServerFailure>()));
    });
  });

  group('update', () {
    test('should return UnitModel on success', () async {
      when(
        () => dio.put('/api/units/1', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => right(Response(
          requestOptions: RequestOptions(path: '/api/units/1'),
          data: {
            'data': {'id': '1', 'name': 'Box', 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
          },
          statusCode: 200,
        )),
      );

      final result = await dataSource.update('1', 'Box');
      expect(result, isA<UnitModel>());
      expect(result.name, 'Box');
    });

    test('should throw ServerFailure on failure', () async {
      when(
        () => dio.put('/api/units/999', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => left(ServerFailure('Unit not found')),
      );

      expect(() => dataSource.update('999', 'Test'), throwsA(isA<ServerFailure>()));
    });
  });

  group('delete', () {
    test('should succeed on successful delete', () async {
      when(() => dio.delete('/api/units/1')).thenAnswer(
        (_) async => right(Response(
          requestOptions: RequestOptions(path: '/api/units/1'),
          data: {'success': true, 'data': null, 'message': 'Unit deleted successfully'},
          statusCode: 200,
        )),
      );

      await dataSource.delete('1');
      verify(() => dio.delete('/api/units/1')).called(1);
    });

    test('should throw ServerFailure on failure', () async {
      when(() => dio.delete('/api/units/1')).thenAnswer(
        (_) async => left(ServerFailure('Cannot delete unit: it is referenced by 3 material(s)')),
      );

      expect(() => dataSource.delete('1'), throwsA(isA<ServerFailure>()));
    });
  });
}
