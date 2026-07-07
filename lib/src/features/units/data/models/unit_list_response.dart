import 'unit_model.dart';

class UnitListResponse {
  final List<UnitModel> units;
  final int total;
  final int page;
  final int pages;

  const UnitListResponse({
    required this.units,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory UnitListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    return UnitListResponse(
      units: data.map((e) => UnitModel.fromJson(e as Map<String, dynamic>)).toList(),
      total: meta['total'] as int,
      page: meta['page'] as int,
      pages: meta['pages'] as int,
    );
  }
}
