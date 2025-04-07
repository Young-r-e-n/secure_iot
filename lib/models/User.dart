class User {
  final int id;
  final String username;
  final String role; // e.g., 'admin', 'it', 'security'
  final String? token; // Authentication token

  User({
    required this.id,
    required this.username,
    required this.role,
    this.token, // Token might be managed separately
  });

  // Manual fromJson - adjust fields based on your actual API response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      token: json['token'] as String?, // Assuming token is part of login response
    );
  }

  // Optional: toJson if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'token': token,
    };
  }
} 