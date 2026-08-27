import 'package:acalapp/features/auth/domain/user_role.dart';

class AuthUser {
  final String id;
  final String username;
  final String name;
  final UserRole role;

  AuthUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return AuthUser(
      id: data['id'] as String,
      username: data['username'] as String,
      name: data['name'] as String,
      role: UserRole.fromValue(data['role'] as String?)!,
    );
  }
}
