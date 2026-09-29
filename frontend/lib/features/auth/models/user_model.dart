class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final int greenPointsBalance;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.greenPointsBalance = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'STUDENT',
      greenPointsBalance: (json['greenPointsBalance'] as num?)?.toInt() ?? 0,
    );
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      user: User.fromJson(json['user'] ?? json),
    );
  }
}
