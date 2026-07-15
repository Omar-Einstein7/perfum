import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final int id;
  final String fullName;
  final int branchId;
  final Map<String, dynamic> permissions;

  const Employee({
    required this.id,
    required this.fullName,
    required this.branchId,
    required this.permissions,
  });

  bool get isEmpty => id == 0;
  bool get isNotEmpty => id != 0;

  bool hasPermission(String flag) => permissions[flag] == true;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      branchId: json['branchId'] as int,
      permissions: (json['permissions'] as Map<String, dynamic>?) ?? {},
    );
  }

  @override
  List<Object?> get props => [id, fullName, branchId, permissions];
}
