import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:perfum_ahmed_gaper/src/utils/utils.dart';
import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
import '../models/unit_list_response.dart';
import '../models/unit_model.dart';
import '../../domain/entities/unit.dart';

abstract class UnitRemoteDataSource {
  FutureEither<UnitListResponse> listUnits({int page = 1, int limit = 20, String? search});
  FutureEither<UnitModel> getUnit(String id);
  FutureEither<UnitModel> createUnit({required String name, required String abbreviation, required UnitType type, String? description});
  FutureEither<UnitModel> updateUnit({required String id, String? name, String? abbreviation, UnitType? type, String? description});
  FutureEither<void> deleteUnit(String id);
}

class UnitRemoteDataSourceImpl implements UnitRemoteDataSource {
  final DioService dio;

  UnitRemoteDataSourceImpl({required this.dio});

  @override
  FutureEither<UnitListResponse> listUnits({int page = 1, int limit = 20, String? search}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    final result = await dio.get('/units', queryParameters: params);
    return result.map((response) {
      return UnitListResponse.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  FutureEither<UnitModel> getUnit(String id) async {
    final result = await dio.get('/units/$id');
    return result.map((response) {
      final data = response.data is Map<String, dynamic> ? response.data['data'] ?? response.data : response.data;
      return UnitModel.fromJson(data as Map<String, dynamic>);
    });
  }

  @override
  FutureEither<UnitModel> createUnit({required String name, required String abbreviation, required UnitType type, String? description}) async {
    final result = await dio.post('/units', data: {
      'name': name,
      'abbreviation': abbreviation,
      'type': type.toJson(),
      if (description != null) 'description': description,
    });
    return result.map((response) {
      final data = response.data is Map<String, dynamic> ? response.data['data'] ?? response.data : response.data;
      return UnitModel.fromJson(data as Map<String, dynamic>);
    });
  }

  @override
  FutureEither<UnitModel> updateUnit({required String id, String? name, String? abbreviation, UnitType? type, String? description}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (abbreviation != null) body['abbreviation'] = abbreviation;
    if (type != null) body['type'] = type.toJson();
    if (description != null) body['description'] = description;
    final result = await dio.put('/units/$id', data: body);
    return result.map((response) {
      final data = response.data is Map<String, dynamic> ? response.data['data'] ?? response.data : response.data;
      return UnitModel.fromJson(data as Map<String, dynamic>);
    });
  }

  @override
  FutureEither<void> deleteUnit(String id) async {
    final result = await dio.delete('/units/$id');
    return result.fold(
      (failure) => Future.value(left<Failure, void>(failure)),
      (_) => right<Failure, void>(null),
    );
  }
}
