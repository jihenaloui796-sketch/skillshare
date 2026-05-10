class Skill {
  final int id;
  final String name;
  final String? description;
  final String level;
  final int ownerId;
  final String ownerFullName;
  final DateTime createdAt;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.ownerId,
    required this.ownerFullName,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      level: (json['level'] ?? '') as String,
      ownerId: (json['ownerId'] as num).toInt(),
      ownerFullName: (json['ownerFullName'] ?? '') as String,
      createdAt: DateTime.parse((json['createdAt'] ?? DateTime.now().toUtc().toIso8601String()) as String),
    );
  }
}
