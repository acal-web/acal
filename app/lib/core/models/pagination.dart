class Pagination {
  final int number;
  final int totalPages;
  final int totalElements;
  final int size;
  final bool first;
  final bool last;

  const Pagination({
    required this.number,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.first,
    required this.last,
  });

  int get displayPage => number + 1;
  int? get prevPage => first ? null : number - 1;
  int? get nextPage => last  ? null : number + 1;

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        number: json['number'] as int,
        totalPages: json['totalPages'] as int,
        totalElements: json['totalElements'] as int,
        size: json['size'] as int,
        first: json['first'] as bool,
        last: json['last'] as bool,
      );
}
