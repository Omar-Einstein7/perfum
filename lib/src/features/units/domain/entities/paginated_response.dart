import 'package:equatable/equatable.dart';

class PaginatedResponse<T> extends Equatable {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const PaginatedResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  @override
  List<Object?> get props => [data, page, limit, total, pages];
}
