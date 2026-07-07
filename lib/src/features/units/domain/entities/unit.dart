import 'package:equatable/equatable.dart';

class Unit extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Unit({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];
}
