class Review {
  final int id;
  final int rating;
  final String? comment;
  final int reviewerId;
  final String reviewerFullName;
  final int reviewedUserId;
  final int? requestId;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.reviewerId,
    required this.reviewerFullName,
    required this.reviewedUserId,
    required this.requestId,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      reviewerId: (json['reviewerId'] as num).toInt(),
      reviewerFullName: (json['reviewerFullName'] ?? '') as String,
      reviewedUserId: (json['reviewedUserId'] as num).toInt(),
      requestId: (json['requestId'] as num?)?.toInt(),
      createdAt: DateTime.parse((json['createdAt'] ?? DateTime.now().toUtc().toIso8601String()) as String),
    );
  }
}
