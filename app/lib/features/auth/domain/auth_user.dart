import 'package:acalapp/features/auth/domain/permission_code.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';

class AuthUser {
  final String id;
  final String username;
  final String name;
  final UserRole role;
  final Set<String> permissions;

  AuthUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.permissions = const {},
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return AuthUser(
      id: data['id'] as String,
      username: data['username'] as String,
      name: data['name'] as String,
      role: UserRole.fromValue(data['role'] as String?)!,
      permissions: (data['permissions'] as List<dynamic>? ?? []).cast<String>().toSet(),
    );
  }

  bool can(PermissionCode permission) => permissions.contains(permission.code);
}
