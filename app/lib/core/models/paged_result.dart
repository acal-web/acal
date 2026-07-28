import 'package:acalapp/core/models/pagination.dart';

class PagedResult<T> {
  final List<T> data;
  final Pagination pagination;

  const PagedResult({required this.data, required this.pagination});

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      PagedResult(
        data: (json['content'] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: Pagination.fromJson(json),
      );
}
