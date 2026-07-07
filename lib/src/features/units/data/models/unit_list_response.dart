import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/paginated_response.dart';
import '../../domain/entities/unit.dart';
import 'unit_model.dart';

part 'unit_list_response.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class UnitListResponse with _$UnitListResponse {
  const factory UnitListResponse({
    required List<UnitModel> data,
    required int page,
    required int limit,
    required int total,
    required int pages,
  }) = _UnitListResponse;

  factory UnitListResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final dataList = (json['data'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map((e) => UnitModel.fromJson(e))
            .toList() ??
        [];
    return UnitListResponse(
      data: dataList,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      total: pagination['total'] as int? ?? 0,
      pages: pagination['pages'] as int? ?? 1,
    );
  }
}

extension UnitListResponseX on UnitListResponse {
  PaginatedResponse<Unit> toEntity() => PaginatedResponse<Unit>(
        data: data.map((e) => e.toEntity()).toList(),
        page: page,
        limit: limit,
        total: total,
        pages: pages,
      );
}
