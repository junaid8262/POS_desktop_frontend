class User {
  final String email;
  final String password;
  final String role;
  final String id;

  User({
    required this.email,
    required this.password,
    required this.role,
    required this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      email: json['username'],
      password: json['password'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': email,
      'password': password,
      'role': role,
    };
  }

  User copyWith({
    String? email,
    String? password,
    String? role,
    String? id, // Added id parameter to copyWith
  }) {
    return User(
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      id: id ?? this.id, // Updated id in copyWith
    );
  }
}