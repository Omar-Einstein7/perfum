import 'dart:convert';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.permissions,
    required super.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'staff',
      permissions: _parsePermissions(json['permissions']),
      status: json['status'] as String? ?? 'active',
    );
  }

  factory UserModel.fromJsonString(String source) {
    return UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'permissions': permissions,
      'status': status,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static Map<String, bool> _parsePermissions(dynamic perms) {
    if (perms is Map) {
      return {
        'p_info': perms['p_info'] == true,
        'p_res': perms['p_res'] == true,
        'p_sell': perms['p_sell'] == true,
        'p_snadat': perms['p_snadat'] == true,
        'p_user': perms['p_user'] == true,
        'p_report': perms['p_report'] == true,
        'p_report2': perms['p_report2'] == true,
      };
    }
    return {
      'p_info': false,
      'p_res': false,
      'p_sell': false,
      'p_snadat': false,
      'p_user': false,
      'p_report': false,
      'p_report2': false,
    };
  }
}
