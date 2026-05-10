class SessionItem {
  final int id;
  final int? requestId;
  final int? skillId;
  final String? skillName;
  final int? ownerId;
  final int? requesterId;
  final DateTime createdAt;

  const SessionItem({
    required this.id,
    required this.requestId,
    required this.skillId,
    required this.skillName,
    required this.ownerId,
    required this.requesterId,
    required this.createdAt,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    return SessionItem(
      id: (json['id'] as num).toInt(),
      requestId: (json['requestId'] as num?)?.toInt(),
      skillId: (json['skillId'] as num?)?.toInt(),
      skillName: json['skillName'] as String?,
      ownerId: (json['ownerId'] as num?)?.toInt(),
      requesterId: (json['requesterId'] as num?)?.toInt(),
      createdAt: DateTime.parse(
        (json['createdAt'] ?? DateTime.now().toUtc().toIso8601String()) as String,
      ),
    );
  }
}
