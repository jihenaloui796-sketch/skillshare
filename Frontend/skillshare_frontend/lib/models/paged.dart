class Paged<T> {
  final List<T> content;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;

  const Paged({
    required this.content,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory Paged.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) mapper) {
    final rawContent = (json['content'] as List?) ?? const [];
    return Paged(
      content: rawContent.whereType<Map>().map((e) => mapper(e.cast<String, dynamic>())).toList(),
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? rawContent.length,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? rawContent.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
