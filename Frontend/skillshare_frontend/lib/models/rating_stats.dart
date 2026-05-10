class RatingStats {
  final double average;
  final int count;
  final Map<int, int> distribution;

  const RatingStats({
    required this.average,
    required this.count,
    required this.distribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final distRaw = (json['distribution'] as Map?)?.cast<String, dynamic>() ?? {};
    final dist = <int, int>{};
    for (final e in distRaw.entries) {
      final k = int.tryParse(e.key) ?? 0;
      final v = (e.value as num?)?.toInt() ?? 0;
      if (k > 0) dist[k] = v;
    }

    return RatingStats(
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      distribution: dist,
    );
  }
}
