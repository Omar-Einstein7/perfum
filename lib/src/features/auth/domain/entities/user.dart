class User {
  final String id;
  final String email;
  final String role;
  final Map<String, bool> permissions;
  final String status;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.permissions,
    required this.status,
  });

  bool get isActive => status == 'active';
  bool get isSuperadmin => role == 'superadmin';

  bool hasPermission(String flag) => permissions[flag] == true;

  User copyWith({
    String? id,
    String? email,
    String? role,
    Map<String, bool>? permissions,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
    );
  }
}
