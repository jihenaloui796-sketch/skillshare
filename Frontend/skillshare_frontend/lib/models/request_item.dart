class RequestItem {
  final int id;
  final int requesterId;
  final String requesterFullName;
  final int skillId;
  final String skillName;
  final int skillOwnerId;
  final String status;
  final String? message;
  final DateTime createdAt;

  const RequestItem({
    required this.id,
    required this.requesterId,
    required this.requesterFullName,
    required this.skillId,
    required this.skillName,
    required this.skillOwnerId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      id: (json['id'] as num).toInt(),
      requesterId: (json['requesterId'] as num).toInt(),
      requesterFullName: (json['requesterFullName'] ?? '') as String,
      skillId: (json['skillId'] as num).toInt(),
      skillName: (json['skillName'] ?? '') as String,
      skillOwnerId: (json['skillOwnerId'] as num).toInt(),
      status: (json['status'] ?? '') as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse((json['createdAt'] ?? DateTime.now().toUtc().toIso8601String()) as String),
    );
  }
}
