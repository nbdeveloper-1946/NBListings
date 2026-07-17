import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? token;
  final String role;
  final List<String> permissions;
  final String fullName;
  final String? adminId;
  final String? organizationId;

  const UserModel({
    required this.id,
    required this.email,
    this.token,
    required this.role,
    required this.permissions,
    required this.fullName,
    this.adminId,
    this.organizationId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final userMap = dataMap['user'] is Map<String, dynamic> ? dataMap['user'] as Map<String, dynamic> : dataMap;
    final token = json['token'] as String? ?? json['accessToken'] as String? ?? dataMap['token'] as String?;
    final role = userMap['role']?.toString() ?? 'Sales';
    final List<String> permissions = List<String>.from(userMap['permissions'] ?? []);
    final fullName = userMap['full_name']?.toString() ?? userMap['fullName']?.toString() ?? 'User';
    final adminId = userMap['admin_id']?.toString();
    final organizationId = userMap['organization_id']?.toString();

    return UserModel(
      id: userMap['id']?.toString() ?? userMap['uid']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      token: token,
      role: role,
      permissions: permissions,
      fullName: fullName,
      adminId: adminId,
      organizationId: organizationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (token != null) 'token': token,
      'role': role,
      'permissions': permissions,
      'fullName': fullName,
      if (adminId != null) 'admin_id': adminId,
      if (organizationId != null) 'organization_id': organizationId,
    };
  }

  @override
  List<Object?> get props => [id, email, token, role, permissions, fullName, adminId, organizationId];
}
