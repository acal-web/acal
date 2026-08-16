import 'package:acalapp/features/auth/domain/user_role.dart';

class UserModel {
  final String id;
  final String username;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isActive => deletedAt == null;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UserModel(
      id: data['id'] as String,
      username: data['username'] as String,
      name: data['name'] as String,
      role: UserRole.fromValue(data['role'] as String?) ?? UserRole.administrador,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      deletedAt: data['deleted_at'] != null ? DateTime.parse(data['deleted_at'] as String) : null,
    );
  }
}
