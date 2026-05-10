class AuthResponse {
  final String token;
  final String tokenType;

  const AuthResponse({required this.token, required this.tokenType});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: (json['token'] ?? '') as String,
      tokenType: (json['tokenType'] ?? 'Bearer') as String,
    );
  }
}
