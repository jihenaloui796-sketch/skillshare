class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final String role;
  final int points;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.bio,
    required this.avatarUrl,
    required this.role,
    required this.points,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: (json['role'] ?? '') as String,
      points: ((json['points'] as num?) ?? 0).toInt(),
    );
  }
}
