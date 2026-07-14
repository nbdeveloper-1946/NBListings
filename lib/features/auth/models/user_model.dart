import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? token;
  final String role;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.email,
    this.token,
    required this.role,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final userMap = dataMap['user'] is Map<String, dynamic> ? dataMap['user'] as Map<String, dynamic> : dataMap;
    final token = json['token'] as String? ?? json['accessToken'] as String? ?? dataMap['token'] as String?;
    final role = userMap['role']?.toString() ?? 'Sales';
    final List<String> permissions = List<String>.from(userMap['permissions'] ?? []);

    return UserModel(
      id: userMap['id']?.toString() ?? userMap['uid']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      token: token,
      role: role,
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (token != null) 'token': token,
      'role': role,
      'permissions': permissions,
    };
  }

  @override
  List<Object?> get props => [id, email, token, role, permissions];
}
