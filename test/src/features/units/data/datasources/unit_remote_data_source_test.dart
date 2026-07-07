import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:perfum_ahmed_gaper/src/features/units/data/datasources/unit_remote_data_source.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/entities/unit.dart';
import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
import 'package:perfum_ahmed_gaper/src/utils/failure.dart';

class MockDioService extends Mock implements DioService {}

Response _fakeResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return Response(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  late MockDioService dio;
  late UnitRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDioService();
    dataSource = UnitRemoteDataSourceImpl(dio: dio);
  });

  group('listUnits', () {
    test('should return UnitListResponse on success', () async {
      when(
        () => dio.get('/units', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => right(_fakeResponse({
          'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
          'data': [
            {'_id': '1', 'name': 'Carton', 'abbreviation': 'ctn', 'type': 'count', 'active': true, 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
          ],
        })),
      );

      final result = await dataSource.listUnits(page: 1, limit: 20);
      expect(result.isRight(), true);
      final response = result.getRight().toNullable()!;
      expect(response.data.length, 1);
      expect(response.data[0].name, 'Carton');
      expect(response.total, 1);
      expect(response.page, 1);
    });

    test('should return ServerFailure on DioException', () async {
      when(
        () => dio.get('/units', queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => left(ServerFailure('Failed to list units')),
      );

      final result = await dataSource.listUnits();
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
    });
  });

  group('getUnit', () {
    test('should return UnitModel on success', () async {
      when(() => dio.get('/units/1')).thenAnswer(
        (_) async => right(_fakeResponse({
          'data': {'_id': '1', 'name': 'Carton', 'abbreviation': 'ctn', 'type': 'count', 'active': true, 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
        })),
      );

      final result = await dataSource.getUnit('1');
      expect(result.isRight(), true);
      final model = result.getRight().toNullable()!;
      expect(model.name, 'Carton');
    });

    test('should return ServerFailure on failure', () async {
      when(() => dio.get('/units/999')).thenAnswer(
        (_) async => left(ServerFailure('Unit not found')),
      );

      final result = await dataSource.getUnit('999');
      expect(result.isLeft(), true);
    });
  });

  group('createUnit', () {
    test('should return UnitModel on success', () async {
      when(
        () => dio.post('/units', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => right(_fakeResponse({
          'data': {'_id': '3', 'name': 'Piece', 'abbreviation': 'pc', 'type': 'count', 'active': true, 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
        }, statusCode: 201)),
      );

      final result = await dataSource.createUnit(name: 'Piece', abbreviation: 'pc', type: UnitType.count);
      expect(result.isRight(), true);
      final model = result.getRight().toNullable()!;
      expect(model.name, 'Piece');
    });

    test('should return ServerFailure on failure', () async {
      when(
        () => dio.post('/units', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => left(ServerFailure('Unit name already exists')),
      );

      final result = await dataSource.createUnit(name: 'Carton', abbreviation: 'ctn', type: UnitType.count);
      expect(result.isLeft(), true);
    });
  });

  group('updateUnit', () {
    test('should return UnitModel on success', () async {
      when(
        () => dio.put('/units/1', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => right(_fakeResponse({
          'data': {'_id': '1', 'name': 'Box', 'abbreviation': 'bx', 'type': 'count', 'active': true, 'createdAt': '2026-01-01T00:00:00.000Z', 'updatedAt': '2026-01-01T00:00:00.000Z'},
        })),
      );

      final result = await dataSource.updateUnit(id: '1', name: 'Box');
      expect(result.isRight(), true);
      final model = result.getRight().toNullable()!;
      expect(model.name, 'Box');
    });

    test('should return ServerFailure on failure', () async {
      when(
        () => dio.put('/units/999', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => left(ServerFailure('Unit not found')),
      );

      final result = await dataSource.updateUnit(id: '999', name: 'Test');
      expect(result.isLeft(), true);
    });
  });

  group('deleteUnit', () {
    test('should succeed on successful delete', () async {
      when(() => dio.delete('/units/1')).thenAnswer(
        (_) async => right(_fakeResponse({'success': true, 'data': null, 'message': 'Unit deactivated'})),
      );

      final result = await dataSource.deleteUnit('1');
      expect(result.isRight(), true);
      verify(() => dio.delete('/units/1')).called(1);
    });

    test('should return ServerFailure on failure', () async {
      when(() => dio.delete('/units/1')).thenAnswer(
        (_) async => left(ServerFailure('Cannot delete unit: it is referenced by 3 material(s)')),
      );

      final result = await dataSource.deleteUnit('1');
      expect(result.isLeft(), true);
    });
  });
}
