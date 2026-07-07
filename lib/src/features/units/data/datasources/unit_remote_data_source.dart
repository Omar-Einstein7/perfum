import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
import '../models/unit_list_response.dart';
import '../models/unit_model.dart';

abstract class UnitRemoteDataSource {
  Future<UnitListResponse> list({int page = 1, int limit = 20, String search = ''});
  Future<UnitModel> getById(String id);
  Future<UnitModel> create(String name);
  Future<UnitModel> update(String id, String name);
  Future<void> delete(String id);
}

class UnitRemoteDataSourceImpl implements UnitRemoteDataSource {
  final DioService dio;

  UnitRemoteDataSourceImpl({required this.dio});

  @override
  Future<UnitListResponse> list({int page = 1, int limit = 20, String search = ''}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (search.isNotEmpty) {
      params['search'] = search;
    }
    final result = await dio.get('/api/units', queryParameters: params);
    return result.fold(
      (failure) => throw failure,
      (response) => UnitListResponse.fromJson(response.data as Map<String, dynamic>),
    );
  }

  @override
  Future<UnitModel> getById(String id) async {
    final result = await dio.get('/api/units/$id');
    return result.fold(
      (failure) => throw failure,
      (response) => UnitModel.fromJson(response.data['data'] as Map<String, dynamic>),
    );
  }

  @override
  Future<UnitModel> create(String name) async {
    final result = await dio.post('/api/units', data: {'name': name});
    return result.fold(
      (failure) => throw failure,
      (response) => UnitModel.fromJson(response.data['data'] as Map<String, dynamic>),
    );
  }

  @override
  Future<UnitModel> update(String id, String name) async {
    final result = await dio.put('/api/units/$id', data: {'name': name});
    return result.fold(
      (failure) => throw failure,
      (response) => UnitModel.fromJson(response.data['data'] as Map<String, dynamic>),
    );
  }

  @override
  Future<void> delete(String id) async {
    final result = await dio.delete('/api/units/$id');
    return result.fold(
      (failure) => throw failure,
      (_) => null,
    );
  }
}
