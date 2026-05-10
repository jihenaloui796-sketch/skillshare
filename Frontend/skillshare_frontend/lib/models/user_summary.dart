class UserSummary {
  final int id;
  final String fullName;
  final String email;

  const UserSummary({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: (json['id'] as num).toInt(),
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
    );
  }
}
