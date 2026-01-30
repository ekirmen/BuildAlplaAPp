class UserModel {
  final String username;
  final String name;
  final String role;
  final String? password;
  final String? salt;

  UserModel({
    required this.username,
    required this.name,
    required this.role,
    this.password,
    this.salt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'viewer',
      password: json['password'],
      salt: json['salt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'role': role,
      if (password != null) 'password': password,
      if (salt != null) 'salt': salt,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor' || role == 'admin';
  bool get canEdit => role == 'admin' || role == 'supervisor';
}
